import RecipeCard from './RecipeCard.jsx';
import styles from './RecipeGrid.module.css';

function Section({ label, note, recipes, dimmed }) {
  return (
    <section className={styles.section}>
      <p className={styles.count}>
        {label}
        {note && <span className={styles.note}> &middot; {note}</span>}
      </p>
      <div className={`${styles.grid} ${dimmed ? styles.dimmed : ''}`}>
        {recipes.map((recipe) => (
          <RecipeCard key={recipe.recipeId} recipe={recipe} />
        ))}
      </div>
    </section>
  );
}

/**
 * Renders the two result bands: recipes at or above the 50% threshold, then the
 * closest recipes below it so a small pantry still gets a useful answer.
 */
export default function RecipeGrid({ recipes, nearMisses, isLoading, hasSearched }) {
  const hasAnything = recipes.length > 0 || nearMisses.length > 0;

  // Keep previous results on screen while a newer search is in flight, so the
  // grid does not flash empty on every tick.
  if (isLoading && !hasAnything) {
    return (
      <div className={styles.centered}>
        <div className={styles.spinner} role="status" aria-label="Loading recipes" />
        <p className={styles.muted}>Checking the cookbook&hellip;</p>
      </div>
    );
  }

  if (!hasSearched && !hasAnything) {
    return (
      <div className={styles.centered}>
        <p className={styles.muted}>
          Tick anything in your pantry and the matches appear here on their own.
        </p>
      </div>
    );
  }

  if (!hasAnything) {
    return (
      <div className={styles.centered}>
        <p className={styles.muted}>
          Nothing in the cookbook uses those yet. Try a staple like eggs, bread or rice.
        </p>
      </div>
    );
  }

  return (
    <>
      {recipes.length > 0 && (
        <Section
          label={`Ready to cook \u00b7 ${recipes.length}`}
          note={isLoading ? 'updating' : null}
          recipes={recipes}
        />
      )}
      {nearMisses.length > 0 && (
        <Section
          label={`Almost there \u00b7 ${nearMisses.length}`}
          note="a few ingredients short"
          recipes={nearMisses}
          dimmed
        />
      )}
    </>
  );
}
