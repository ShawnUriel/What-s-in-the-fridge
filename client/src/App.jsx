import { useEffect, useState } from 'react';
import PantrySidebar from './components/PantrySidebar.jsx';
import RecipeGrid from './components/RecipeGrid.jsx';
import { fetchIngredients, matchRecipes } from './api.js';
import styles from './App.module.css';

/** Wait this long after the last tick before asking the server. */
const DEBOUNCE_MS = 300;

const EMPTY_RESULTS = { matches: [], nearMisses: [] };

/**
 * Owns all global state: selectedIngredients, recipeResults, isLoading.
 * Children stay presentational and talk back through callbacks.
 */
export default function App() {
  const [ingredients, setIngredients] = useState([]);
  const [selectedIngredients, setSelectedIngredients] = useState([]);
  const [recipeResults, setRecipeResults] = useState(EMPTY_RESULTS);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [hasSearched, setHasSearched] = useState(false);

  useEffect(() => {
    fetchIngredients()
      .then(setIngredients)
      .catch((err) => setError(err.message));
  }, []);

  // Matching runs on its own whenever the pantry changes - no submit button.
  // Debounced so ticking four boxes quickly costs one request, and aborted on
  // change so a slow earlier response can never overwrite a newer one.
  useEffect(() => {
    if (selectedIngredients.length === 0) {
      setRecipeResults(EMPTY_RESULTS);
      setHasSearched(false);
      setIsLoading(false);
      return undefined;
    }

    const controller = new AbortController();
    setIsLoading(true);

    const timer = setTimeout(() => {
      matchRecipes(selectedIngredients, controller.signal)
        .then((results) => {
          setRecipeResults(results);
          setHasSearched(true);
          setError(null);
          setIsLoading(false);
        })
        .catch((err) => {
          if (err.name === 'AbortError') return; // superseded, not a failure
          setError(err.message);
          setRecipeResults(EMPTY_RESULTS);
          setIsLoading(false);
        });
    }, DEBOUNCE_MS);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [selectedIngredients]);

  function toggleIngredient(id) {
    setSelectedIngredients((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    );
  }

  function clearSelection() {
    setSelectedIngredients([]);
  }

  return (
    <div className={styles.app}>
      <header className={styles.header}>
        <div className={styles.headerInner}>
          <span className={styles.eyebrow}>The Dorm Room Cookbook</span>
          <h1 className={styles.title}>What&rsquo;s in My Fridge?</h1>
          <div className={styles.rule} />
          <p className={styles.subtitle}>
            Tick what you actually have. We&rsquo;ll do the deciding.
          </p>
        </div>
      </header>

      <div className={styles.layout}>
        <PantrySidebar
          ingredients={ingredients}
          selectedIngredients={selectedIngredients}
          onToggle={toggleIngredient}
          onClear={clearSelection}
        />
        <main className={styles.main}>
          {error && <p className={styles.error}>{error}</p>}
          <RecipeGrid
            recipes={recipeResults.matches}
            nearMisses={recipeResults.nearMisses}
            isLoading={isLoading}
            hasSearched={hasSearched}
          />
        </main>
      </div>
    </div>
  );
}
