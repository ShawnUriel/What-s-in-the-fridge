-- =============================================================================
-- "What's in My Fridge?" Recipe Engine - PostgreSQL initialization script
-- Run with: psql -d fridge -f server/db/schema.sql
-- Idempotent: safe to re-run during development.
-- =============================================================================

BEGIN;

-- gen_random_uuid() is built in on PG 13+. pgcrypto covers older servers.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP TABLE IF EXISTS recipe_ingredients;
DROP TABLE IF EXISTS recipes;
DROP TABLE IF EXISTS ingredients;

-- -----------------------------------------------------------------------------
-- recipes
-- -----------------------------------------------------------------------------
CREATE TABLE recipes (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title              VARCHAR(255) NOT NULL UNIQUE,
    instructions       TEXT         NOT NULL,
    prep_time_minutes  INTEGER      NOT NULL CHECK (prep_time_minutes >= 0),
    image_url          VARCHAR(512)
);

-- -----------------------------------------------------------------------------
-- ingredients
-- -----------------------------------------------------------------------------
CREATE TABLE ingredients (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name      VARCHAR(120) NOT NULL UNIQUE,
    category  VARCHAR(60)  NOT NULL
);

-- -----------------------------------------------------------------------------
-- recipe_ingredients (join table, composite PK)
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_ingredients (
    recipe_id             UUID NOT NULL REFERENCES recipes(id)     ON DELETE CASCADE,
    ingredient_id         UUID NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
    quantity_description  VARCHAR(120) NOT NULL,
    PRIMARY KEY (recipe_id, ingredient_id)
);

-- The match query joins from recipe_ingredients on both sides; the composite PK
-- already indexes (recipe_id, ...), so we only need the reverse lookup.
CREATE INDEX idx_recipe_ingredients_ingredient_id
    ON recipe_ingredients (ingredient_id);

CREATE INDEX idx_ingredients_category ON ingredients (category);

-- =============================================================================
-- Seed data. Ids come from gen_random_uuid(); the join rows below are linked by
-- natural key (title / name), which keeps the seed readable and lets the
-- consistency check at the bottom catch a mistyped name.
-- =============================================================================

INSERT INTO ingredients (name, category) VALUES
    -- produce
    ('Tomato','produce'), ('Onion','produce'), ('Garlic','produce'),
    ('Bell Pepper','produce'), ('Spinach','produce'), ('Broccoli','produce'),
    ('Carrot','produce'), ('Potato','produce'), ('Mushroom','produce'),
    ('Lemon','produce'), ('Lime','produce'), ('Avocado','produce'),
    ('Zucchini','produce'), ('Green Onion','produce'), ('Lettuce','produce'),
    ('Cucumber','produce'), ('Ginger','produce'), ('Sweet Potato','produce'),
    ('Banana','produce'), ('Corn','produce'),
    -- dairy
    ('Milk','dairy'), ('Butter','dairy'), ('Cheddar Cheese','dairy'),
    ('Parmesan','dairy'), ('Mozzarella','dairy'), ('Greek Yogurt','dairy'),
    ('Sour Cream','dairy'), ('Cream Cheese','dairy'), ('Heavy Cream','dairy'),
    ('Feta','dairy'),
    -- protein
    ('Egg','protein'), ('Chicken Breast','protein'), ('Ground Beef','protein'),
    ('Bacon','protein'), ('Shrimp','protein'), ('Salmon','protein'),
    ('Tofu','protein'), ('Black Beans','protein'), ('Chickpeas','protein'),
    ('Canned Tuna','protein'), ('Ground Pork','protein'), ('Sausage','protein'),
    -- grains
    ('White Rice','grains'), ('Spaghetti','grains'), ('Penne','grains'),
    ('Bread','grains'), ('Tortilla','grains'), ('Rolled Oats','grains'),
    ('Quinoa','grains'), ('Flour','grains'), ('Ramen Noodles','grains'),
    ('Breadcrumbs','grains'),
    -- pantry
    ('Olive Oil','pantry'), ('Vegetable Oil','pantry'), ('Sesame Oil','pantry'),
    ('Soy Sauce','pantry'), ('Honey','pantry'), ('Peanut Butter','pantry'),
    ('Canned Tomatoes','pantry'), ('Chicken Broth','pantry'), ('Vinegar','pantry'),
    ('Sugar','pantry'), ('Maple Syrup','pantry'), ('Coconut Milk','pantry'),
    ('Hot Sauce','pantry'), ('Mayonnaise','pantry'), ('Ketchup','pantry'),
    ('Mustard','pantry'), ('Salsa','pantry'), ('Nutritional Yeast','pantry'),
    -- spices
    ('Salt','spices'), ('Black Pepper','spices'), ('Paprika','spices'),
    ('Cumin','spices'), ('Chili Flakes','spices'), ('Oregano','spices'),
    ('Basil','spices'), ('Cinnamon','spices'), ('Curry Powder','spices'),
    ('Garlic Powder','spices'), ('Baking Powder','spices'), ('Vanilla Extract','spices');

INSERT INTO recipes (title, instructions, prep_time_minutes) VALUES
    ('Tomato Egg Stir-fry', E'1. Beat the eggs with a pinch of salt.\n2. Scramble in hot oil until just set, then remove.\n3. Cook the tomatoes down into a loose sauce, return the eggs, toss and serve.', 15),
    ('Cheese Omelette', E'1. Whisk the eggs with the milk.\n2. Pour into a buttered pan over low heat.\n3. Scatter cheese over one half, fold, and slide onto a plate.', 10),
    ('Spaghetti Aglio e Olio', E'1. Boil the spaghetti until al dente, saving a cup of the water.\n2. Warm sliced garlic and chili flakes in olive oil until fragrant, never brown.\n3. Toss the pasta through with a splash of the water.', 20),
    ('Garlic Butter Shrimp', E'1. Pat the shrimp dry and season.\n2. Sear in foaming butter with the garlic, about two minutes a side.\n3. Finish with lemon juice and cracked pepper.', 15),
    ('Chicken Fried Rice', E'1. Scramble the egg and set aside.\n2. Stir-fry the chicken and carrot, then add cold rice and press it flat to crisp.\n3. Return the egg, season with soy sauce and sesame oil, finish with green onion.', 20),
    ('Avocado Toast', E'1. Toast the bread hard.\n2. Mash the avocado with lemon juice and salt.\n3. Pile it on, then finish with chili flakes.', 5),
    ('Black Bean Quesadilla', E'1. Warm the beans with cumin and diced onion.\n2. Fill a tortilla with beans and cheese, then fold.\n3. Griddle until the cheese runs and the outside blisters.', 15),
    ('Creamy Tomato Pasta', E'1. Soften garlic in oil, add tomatoes, simmer ten minutes.\n2. Stir in cream and the cooked penne.\n3. Finish with parmesan and torn basil.', 25),
    ('Overnight Oats', E'1. Stir oats, milk, yogurt and honey together in a jar.\n2. Dust with cinnamon.\n3. Refrigerate overnight and eat cold.', 5),
    ('Beef Tacos', E'1. Brown the beef with onion, cumin and paprika.\n2. Warm the tortillas.\n3. Fill, then top with cheese and salsa.', 20),
    ('Upgraded Ramen', E'1. Soft-boil an egg for seven minutes.\n2. Cook the noodles, seasoning the broth with soy sauce and sesame oil.\n3. Wilt in the spinach, halve the egg on top, finish with green onion.', 12),
    ('Loaded Baked Potato', E'1. Bake the potato until the skin crisps, about fifty minutes.\n2. Split it and fork the inside up with butter.\n3. Load with cheese, sour cream, bacon and green onion.', 55),
    ('Chickpea Curry', E'1. Fry onion, garlic and ginger until soft.\n2. Add curry powder, then the chickpeas and coconut milk; simmer fifteen minutes.\n3. Serve over rice.', 30),
    ('Tuna Salad Sandwich', E'1. Mix the drained tuna with mayonnaise, minced onion and pepper.\n2. Pile onto bread with lettuce.\n3. Press, halve, eat.', 10),
    ('Caprese Salad', E'1. Slice the tomato and mozzarella thickly.\n2. Shingle them with basil leaves.\n3. Douse with olive oil and salt.', 10),
    ('Veggie Stir-fry', E'1. Get the pan properly hot.\n2. Stir-fry broccoli, pepper and carrot with garlic for four minutes.\n3. Season with soy sauce and sesame oil, then serve over rice.', 20),
    ('Creamy Mushroom Pasta', E'1. Brown the mushrooms hard before salting them.\n2. Add garlic and butter, then the cream.\n3. Toss with penne and a shower of parmesan.', 25),
    ('Shakshuka', E'1. Soften onion and pepper in olive oil with paprika and cumin.\n2. Add the tomatoes and simmer until thick.\n3. Crack the eggs into wells and cover until the whites set.', 30),
    ('Grilled Cheese', E'1. Butter the outside of the bread.\n2. Fill it with cheese.\n3. Griddle low and slow until deep gold.', 8),
    ('Pancakes', E'1. Whisk flour, sugar and baking powder, then add egg and milk.\n2. Rest the batter ten minutes.\n3. Cook in butter and serve with maple syrup.', 20),
    ('Lemon Garlic Salmon', E'1. Season the salmon and lay it skin-down in a hot oiled pan.\n2. Add the garlic near the end so it will not burn.\n3. Finish with lemon and pepper.', 18),
    ('Tofu Scramble', E'1. Press the tofu, then crumble it.\n2. Fry with onion and pepper until the edges catch.\n3. Season with paprika and salt.', 15),
    ('Quinoa Power Bowl', E'1. Cook the quinoa and let it cool slightly.\n2. Toss with chickpeas, cucumber and tomato.\n3. Dress with lemon and olive oil.', 25),
    ('Garlic Butter Noodles', E'1. Boil the spaghetti.\n2. Melt butter with garlic and chili flakes.\n3. Toss it through with parmesan.', 12),
    ('Egg Fried Toast', E'1. Cut a hole in the middle of the bread and butter both sides.\n2. Fry the bread, cracking the egg into the hole.\n3. Flip once, season, eat standing up.', 7),
    ('Sweet Potato Hash', E'1. Dice the sweet potato small so it cooks through.\n2. Fry with onion and pepper until the edges caramelise.\n3. Season with paprika and top with a fried egg.', 25);

-- Dish photography. The files live in client/public/recipes/ and are served by
-- the frontend, so the app carries no external image dependency. Each is the
-- lead image of the English Wikipedia article named alongside it (CC BY-SA or
-- public domain); keep those names for attribution.
UPDATE recipes r
   SET image_url = v.url
  FROM (VALUES
    ('Tomato Egg Stir-fry', '/recipes/tomato-egg-stir-fry.jpg'), -- Stir-fried tomato and scrambled eggs
    ('Cheese Omelette', '/recipes/cheese-omelette.jpg'),       -- Omelette
    ('Spaghetti Aglio e Olio', '/recipes/spaghetti-aglio-e-olio.jpg'), -- Spaghetti aglio e olio
    ('Garlic Butter Shrimp', '/recipes/garlic-butter-shrimp.jpg'), -- Scampi
    ('Chicken Fried Rice', '/recipes/chicken-fried-rice.jpg'), -- Fried rice
    ('Avocado Toast', '/recipes/avocado-toast.jpg'),           -- Avocado toast
    ('Black Bean Quesadilla', '/recipes/black-bean-quesadilla.jpg'), -- Quesadilla
    ('Creamy Tomato Pasta', '/recipes/creamy-tomato-pasta.jpg'), -- Penne alla vodka
    ('Overnight Oats', '/recipes/overnight-oats.jpg'),         -- Muesli
    ('Beef Tacos', '/recipes/beef-tacos.jpg'),                 -- Taco
    ('Upgraded Ramen', '/recipes/upgraded-ramen.jpg'),         -- Ramen
    ('Loaded Baked Potato', '/recipes/loaded-baked-potato.jpg'), -- Baked potato
    ('Chickpea Curry', '/recipes/chickpea-curry.jpg'),         -- Chana masala
    ('Tuna Salad Sandwich', '/recipes/tuna-salad-sandwich.jpg'), -- Tuna salad
    ('Caprese Salad', '/recipes/caprese-salad.jpg'),           -- Caprese salad
    ('Veggie Stir-fry', '/recipes/veggie-stir-fry.jpg'),       -- Chop suey
    ('Creamy Mushroom Pasta', '/recipes/creamy-mushroom-pasta.jpg'), -- Tagliatelle
    ('Shakshuka', '/recipes/shakshuka.jpg'),                   -- Shakshouka
    ('Grilled Cheese', '/recipes/grilled-cheese.jpg'),         -- Cheese sandwich
    ('Pancakes', '/recipes/pancakes.jpg'),                     -- Pancake
    ('Lemon Garlic Salmon', '/recipes/lemon-garlic-salmon.jpg'), -- Salmon as food
    ('Tofu Scramble', '/recipes/tofu-scramble.jpg'),           -- Tofu
    ('Quinoa Power Bowl', '/recipes/quinoa-power-bowl.jpg'),   -- Buddha bowl
    ('Garlic Butter Noodles', '/recipes/garlic-butter-noodles.jpg'), -- Garlic noodles
    ('Egg Fried Toast', '/recipes/egg-fried-toast.jpg'),       -- Egg in the basket
    ('Sweet Potato Hash', '/recipes/sweet-potato-hash.jpg')    -- Hash (food)
  ) AS v(title, url)
 WHERE r.title = v.title;

-- Every recipe must end up with a picture; a renamed dish would otherwise slip
-- through with a blank card.
DO $$
DECLARE
    unpictured INTEGER := (SELECT COUNT(*) FROM recipes WHERE image_url IS NULL);
BEGIN
    IF unpictured > 0 THEN
        RAISE EXCEPTION 'Seed error: % recipe(s) have no image_url.', unpictured;
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Join rows, declared by name and resolved to ids in one INSERT ... SELECT.
-- -----------------------------------------------------------------------------
CREATE TEMP TABLE seed_pairs (recipe TEXT, ingredient TEXT, qty TEXT) ON COMMIT DROP;

INSERT INTO seed_pairs (recipe, ingredient, qty) VALUES
    ('Tomato Egg Stir-fry','Egg','3 large'),
    ('Tomato Egg Stir-fry','Tomato','2 medium, chopped'),
    ('Tomato Egg Stir-fry','Green Onion','1 stalk, sliced'),
    ('Tomato Egg Stir-fry','Vegetable Oil','1 tbsp'),
    ('Tomato Egg Stir-fry','Salt','1 pinch'),

    ('Cheese Omelette','Egg','2 large'),
    ('Cheese Omelette','Cheddar Cheese','1/4 cup, grated'),
    ('Cheese Omelette','Milk','1 splash'),
    ('Cheese Omelette','Butter','1 tsp'),
    ('Cheese Omelette','Salt','1 pinch'),

    ('Spaghetti Aglio e Olio','Spaghetti','200 g'),
    ('Spaghetti Aglio e Olio','Garlic','4 cloves, sliced'),
    ('Spaghetti Aglio e Olio','Olive Oil','1/4 cup'),
    ('Spaghetti Aglio e Olio','Chili Flakes','1/2 tsp'),
    ('Spaghetti Aglio e Olio','Salt','to taste'),

    ('Garlic Butter Shrimp','Shrimp','300 g, peeled'),
    ('Garlic Butter Shrimp','Garlic','3 cloves, minced'),
    ('Garlic Butter Shrimp','Butter','2 tbsp'),
    ('Garlic Butter Shrimp','Lemon','1/2, juiced'),
    ('Garlic Butter Shrimp','Black Pepper','to taste'),

    ('Chicken Fried Rice','White Rice','2 cups, cooked and cold'),
    ('Chicken Fried Rice','Chicken Breast','1, diced'),
    ('Chicken Fried Rice','Egg','1 large'),
    ('Chicken Fried Rice','Carrot','1, diced small'),
    ('Chicken Fried Rice','Soy Sauce','2 tbsp'),
    ('Chicken Fried Rice','Sesame Oil','1 tsp'),
    ('Chicken Fried Rice','Green Onion','2 stalks'),

    ('Avocado Toast','Bread','2 slices'),
    ('Avocado Toast','Avocado','1 ripe'),
    ('Avocado Toast','Lemon','1 squeeze'),
    ('Avocado Toast','Chili Flakes','1 pinch'),
    ('Avocado Toast','Salt','1 pinch'),

    ('Black Bean Quesadilla','Tortilla','2 large'),
    ('Black Bean Quesadilla','Black Beans','1 cup, drained'),
    ('Black Bean Quesadilla','Cheddar Cheese','1/2 cup, grated'),
    ('Black Bean Quesadilla','Onion','1/2, diced'),
    ('Black Bean Quesadilla','Cumin','1/2 tsp'),

    ('Creamy Tomato Pasta','Penne','200 g'),
    ('Creamy Tomato Pasta','Canned Tomatoes','1 can'),
    ('Creamy Tomato Pasta','Heavy Cream','1/3 cup'),
    ('Creamy Tomato Pasta','Garlic','2 cloves'),
    ('Creamy Tomato Pasta','Parmesan','1/4 cup'),
    ('Creamy Tomato Pasta','Basil','a few leaves'),

    ('Overnight Oats','Rolled Oats','1/2 cup'),
    ('Overnight Oats','Milk','1/2 cup'),
    ('Overnight Oats','Greek Yogurt','1/4 cup'),
    ('Overnight Oats','Honey','1 tbsp'),
    ('Overnight Oats','Cinnamon','1 pinch'),

    ('Beef Tacos','Tortilla','4 small'),
    ('Beef Tacos','Ground Beef','400 g'),
    ('Beef Tacos','Onion','1, diced'),
    ('Beef Tacos','Salsa','1/2 cup'),
    ('Beef Tacos','Cheddar Cheese','1/2 cup'),
    ('Beef Tacos','Cumin','1 tsp'),
    ('Beef Tacos','Paprika','1 tsp'),

    ('Upgraded Ramen','Ramen Noodles','1 packet'),
    ('Upgraded Ramen','Egg','1 large'),
    ('Upgraded Ramen','Spinach','1 handful'),
    ('Upgraded Ramen','Green Onion','1 stalk'),
    ('Upgraded Ramen','Soy Sauce','1 tbsp'),
    ('Upgraded Ramen','Sesame Oil','1 tsp'),

    ('Loaded Baked Potato','Potato','1 large'),
    ('Loaded Baked Potato','Butter','1 tbsp'),
    ('Loaded Baked Potato','Sour Cream','2 tbsp'),
    ('Loaded Baked Potato','Cheddar Cheese','1/3 cup'),
    ('Loaded Baked Potato','Bacon','2 rashers'),
    ('Loaded Baked Potato','Green Onion','1 stalk'),

    ('Chickpea Curry','Chickpeas','1 can, drained'),
    ('Chickpea Curry','Coconut Milk','1 can'),
    ('Chickpea Curry','Onion','1, diced'),
    ('Chickpea Curry','Garlic','2 cloves'),
    ('Chickpea Curry','Ginger','1 thumb'),
    ('Chickpea Curry','Curry Powder','1 tbsp'),
    ('Chickpea Curry','White Rice','to serve'),

    ('Tuna Salad Sandwich','Canned Tuna','1 can'),
    ('Tuna Salad Sandwich','Mayonnaise','2 tbsp'),
    ('Tuna Salad Sandwich','Bread','2 slices'),
    ('Tuna Salad Sandwich','Onion','2 tbsp, minced'),
    ('Tuna Salad Sandwich','Lettuce','2 leaves'),
    ('Tuna Salad Sandwich','Black Pepper','to taste'),

    ('Caprese Salad','Tomato','2 large'),
    ('Caprese Salad','Mozzarella','1 ball'),
    ('Caprese Salad','Basil','a handful'),
    ('Caprese Salad','Olive Oil','2 tbsp'),
    ('Caprese Salad','Salt','flaky, to finish'),

    ('Veggie Stir-fry','Broccoli','1 head, in florets'),
    ('Veggie Stir-fry','Bell Pepper','1, sliced'),
    ('Veggie Stir-fry','Carrot','1, julienned'),
    ('Veggie Stir-fry','Garlic','2 cloves'),
    ('Veggie Stir-fry','Soy Sauce','2 tbsp'),
    ('Veggie Stir-fry','Sesame Oil','1 tsp'),
    ('Veggie Stir-fry','White Rice','to serve'),

    ('Creamy Mushroom Pasta','Penne','200 g'),
    ('Creamy Mushroom Pasta','Mushroom','250 g, sliced'),
    ('Creamy Mushroom Pasta','Heavy Cream','1/3 cup'),
    ('Creamy Mushroom Pasta','Garlic','2 cloves'),
    ('Creamy Mushroom Pasta','Parmesan','1/4 cup'),
    ('Creamy Mushroom Pasta','Butter','1 tbsp'),

    ('Shakshuka','Egg','4 large'),
    ('Shakshuka','Canned Tomatoes','1 can'),
    ('Shakshuka','Bell Pepper','1, diced'),
    ('Shakshuka','Onion','1, diced'),
    ('Shakshuka','Garlic','3 cloves'),
    ('Shakshuka','Paprika','1 tsp'),
    ('Shakshuka','Cumin','1 tsp'),
    ('Shakshuka','Olive Oil','2 tbsp'),

    ('Grilled Cheese','Bread','2 slices'),
    ('Grilled Cheese','Cheddar Cheese','2 thick slices'),
    ('Grilled Cheese','Butter','1 tbsp'),

    ('Pancakes','Flour','1 cup'),
    ('Pancakes','Egg','1 large'),
    ('Pancakes','Milk','3/4 cup'),
    ('Pancakes','Sugar','2 tbsp'),
    ('Pancakes','Baking Powder','2 tsp'),
    ('Pancakes','Butter','for the pan'),
    ('Pancakes','Maple Syrup','to serve'),

    ('Lemon Garlic Salmon','Salmon','2 fillets'),
    ('Lemon Garlic Salmon','Lemon','1, juiced'),
    ('Lemon Garlic Salmon','Garlic','2 cloves'),
    ('Lemon Garlic Salmon','Olive Oil','1 tbsp'),
    ('Lemon Garlic Salmon','Black Pepper','to taste'),

    ('Tofu Scramble','Tofu','1 block, firm'),
    ('Tofu Scramble','Onion','1/2, diced'),
    ('Tofu Scramble','Bell Pepper','1/2, diced'),
    ('Tofu Scramble','Paprika','1 tsp'),
    ('Tofu Scramble','Olive Oil','1 tbsp'),
    ('Tofu Scramble','Salt','to taste'),

    ('Quinoa Power Bowl','Quinoa','1 cup, cooked'),
    ('Quinoa Power Bowl','Chickpeas','1/2 can'),
    ('Quinoa Power Bowl','Cucumber','1/2, diced'),
    ('Quinoa Power Bowl','Tomato','1, diced'),
    ('Quinoa Power Bowl','Lemon','1/2, juiced'),
    ('Quinoa Power Bowl','Olive Oil','2 tbsp'),

    ('Garlic Butter Noodles','Spaghetti','200 g'),
    ('Garlic Butter Noodles','Butter','3 tbsp'),
    ('Garlic Butter Noodles','Garlic','3 cloves'),
    ('Garlic Butter Noodles','Parmesan','1/4 cup'),
    ('Garlic Butter Noodles','Chili Flakes','1 pinch'),

    ('Egg Fried Toast','Bread','1 thick slice'),
    ('Egg Fried Toast','Egg','1 large'),
    ('Egg Fried Toast','Butter','1 tbsp'),
    ('Egg Fried Toast','Salt','1 pinch'),

    ('Sweet Potato Hash','Sweet Potato','1 large, diced'),
    ('Sweet Potato Hash','Onion','1/2, diced'),
    ('Sweet Potato Hash','Bell Pepper','1/2, diced'),
    ('Sweet Potato Hash','Egg','1 large'),
    ('Sweet Potato Hash','Paprika','1 tsp'),
    ('Sweet Potato Hash','Olive Oil','1 tbsp');

INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity_description)
SELECT r.id, i.id, s.qty
  FROM seed_pairs s
  JOIN recipes r     ON r.title = s.recipe
  JOIN ingredients i ON i.name  = s.ingredient;

-- A mistyped recipe or ingredient name would silently drop its join row, which
-- would then quietly skew every match percentage. Fail the load instead.
DO $$
DECLARE
    declared INTEGER := (SELECT COUNT(*) FROM seed_pairs);
    linked   INTEGER := (SELECT COUNT(*) FROM recipe_ingredients);
BEGIN
    IF declared <> linked THEN
        RAISE EXCEPTION
            'Seed mismatch: % pairs declared but % linked. Check for a typo in a recipe title or ingredient name.',
            declared, linked;
    END IF;
END $$;

COMMIT;
