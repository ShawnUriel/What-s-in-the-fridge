import { query } from '../db/pool.js';

/** At or above this, a recipe is "ready to cook". */
const MATCH_THRESHOLD_PERCENT = 50;

/** Below the threshold we still return the closest few, so the grid is never
 *  mysteriously empty. These are reported separately from `matches`. */
const NEAR_MISS_LIMIT = 12;

/** Guards against a caller pasting an unbounded array into the pantry. */
const MAX_USER_INGREDIENTS = 200;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * The match engine, expressed as one set-based query.
 *
 *   matchPercentage = (overlapping ingredients / total ingredients required) * 100
 *
 * `matched` collapses each recipe's ingredient rows into three numbers: how many
 * the recipe needs, how many the user has, and the names of the rest. Recipes
 * with no ingredient rows never appear here, which is what keeps the division
 * safe.
 *
 * Every recipe sharing at least one ingredient is returned; the 50% split
 * happens in JS below so a single query serves both sections. The percentage is
 * floored to match the API contract (2/3 -> 66, not 67).
 */
const MATCH_QUERY = `
  WITH matched AS (
    SELECT
      ri.recipe_id,
      COUNT(*)::int AS total_required,
      COUNT(*) FILTER (WHERE ri.ingredient_id = ANY($1::uuid[]))::int AS matched_count,
      ARRAY_AGG(i.name ORDER BY i.name)
        FILTER (WHERE NOT (ri.ingredient_id = ANY($1::uuid[]))) AS missing_ingredients
    FROM recipe_ingredients ri
    JOIN ingredients i ON i.id = ri.ingredient_id
    GROUP BY ri.recipe_id
  )
  SELECT
    r.id                AS recipe_id,
    r.title,
    r.prep_time_minutes,
    r.image_url,
    m.matched_count,
    m.total_required,
    FLOOR(m.matched_count * 100.0 / m.total_required)::int AS match_percentage,
    COALESCE(m.missing_ingredients, ARRAY[]::varchar[])    AS missing_ingredients
  FROM matched m
  JOIN recipes r ON r.id = m.recipe_id
  WHERE m.matched_count > 0
  ORDER BY match_percentage DESC, r.prep_time_minutes ASC, r.title ASC;
`;

function toMatch(row) {
  return {
    recipeId: row.recipe_id,
    title: row.title,
    prepTimeMinutes: row.prep_time_minutes,
    imageUrl: row.image_url,
    matchPercentage: row.match_percentage,
    haveCount: row.matched_count,
    needCount: row.total_required,
    missingIngredients: row.missing_ingredients,
  };
}

/**
 * POST /api/recipes/match
 * Body:     { "userIngredients": ["uuid-1", "uuid-2"] }
 * Response: { "matches": [...], "nearMisses": [...] }
 *
 * `matches` is the contract: recipes at 50% or above, sorted descending.
 * `nearMisses` carries the closest recipes below that line, so a small pantry
 * still shows the user what they are short of.
 */
export async function matchRecipes(req, res, next) {
  const { userIngredients } = req.body ?? {};

  if (!Array.isArray(userIngredients)) {
    return res.status(400).json({
      error: 'BAD_REQUEST',
      message: '"userIngredients" must be an array of ingredient UUIDs.',
    });
  }

  if (userIngredients.length > MAX_USER_INGREDIENTS) {
    return res.status(400).json({
      error: 'BAD_REQUEST',
      message: `"userIngredients" accepts at most ${MAX_USER_INGREDIENTS} ids.`,
    });
  }

  const invalid = userIngredients.filter(
    (id) => typeof id !== 'string' || !UUID_RE.test(id),
  );
  if (invalid.length > 0) {
    // Reject before the DB so a malformed id surfaces as 400, not a 22P02 cast error.
    return res.status(400).json({
      error: 'BAD_REQUEST',
      message: 'Every entry in "userIngredients" must be a valid UUID.',
      invalid: invalid.slice(0, 5),
    });
  }

  // Duplicates would not change the result, but they do bloat the array parameter.
  const ingredientIds = [...new Set(userIngredients.map((id) => id.toLowerCase()))];

  if (ingredientIds.length === 0) {
    return res.json({ matches: [], nearMisses: [] });
  }

  try {
    const { rows } = await query(MATCH_QUERY, [ingredientIds]);

    const matches = [];
    const nearMisses = [];
    for (const row of rows) {
      if (row.match_percentage >= MATCH_THRESHOLD_PERCENT) matches.push(toMatch(row));
      else if (nearMisses.length < NEAR_MISS_LIMIT) nearMisses.push(toMatch(row));
    }

    return res.json({ matches, nearMisses });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/ingredients
 * Feeds <PantrySidebar />, which groups the list by category client-side.
 */
export async function listIngredients(_req, res, next) {
  try {
    const { rows } = await query(
      `SELECT id, name, category
         FROM ingredients
        ORDER BY category ASC, name ASC;`,
    );
    return res.json({ ingredients: rows });
  } catch (err) {
    return next(err);
  }
}
