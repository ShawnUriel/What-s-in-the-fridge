import { useMemo, useState } from 'react';
import styles from './PantrySidebar.module.css';

/** Groups a flat ingredient list into [category, items] pairs. */
function groupByCategory(list) {
  const map = new Map();
  for (const ing of list) {
    if (!map.has(ing.category)) map.set(ing.category, []);
    map.get(ing.category).push(ing);
  }
  return [...map.entries()];
}

/**
 * The full pantry, searchable. Selection state lives in <App />; the search
 * query is local because nothing else needs to know about it.
 */
export default function PantrySidebar({
  ingredients,
  selectedIngredients,
  onToggle,
  onClear,
}) {
  const [query, setQuery] = useState('');

  const term = query.trim().toLowerCase();
  const filtered = useMemo(
    () => (term ? ingredients.filter((i) => i.name.toLowerCase().includes(term)) : ingredients),
    [ingredients, term],
  );
  const groups = useMemo(() => groupByCategory(filtered), [filtered]);

  // Chips need names, and a selected item may be filtered out of view.
  const selected = useMemo(
    () => ingredients.filter((i) => selectedIngredients.includes(i.id)),
    [ingredients, selectedIngredients],
  );

  return (
    <aside className={styles.sidebar}>
      <div className={styles.headRow}>
        <h2 className={styles.heading}>My Pantry</h2>
        {selected.length > 0 && (
          <button type="button" className={styles.clear} onClick={onClear}>
            Clear
          </button>
        )}
      </div>

      <div className={styles.searchWrap}>
        <input
          type="search"
          className={styles.search}
          placeholder="Search ingredients&hellip;"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          aria-label="Search ingredients"
        />
      </div>

      {selected.length > 0 && (
        <div className={styles.selectedBlock}>
          <span className={styles.selectedLabel}>In your fridge ({selected.length})</span>
          <ul className={styles.chips}>
            {selected.map((ing) => (
              <li key={ing.id}>
                <button
                  type="button"
                  className={styles.chip}
                  onClick={() => onToggle(ing.id)}
                  aria-label={`Remove ${ing.name}`}
                >
                  {ing.name}
                  <span aria-hidden="true" className={styles.chipX}>
                    &times;
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className={styles.list}>
        {ingredients.length === 0 ? (
          <p className={styles.empty}>Loading ingredients&hellip;</p>
        ) : groups.length === 0 ? (
          <p className={styles.empty}>Nothing matches &ldquo;{query.trim()}&rdquo;.</p>
        ) : (
          groups.map(([category, items]) => (
            <fieldset key={category} className={styles.group}>
              <legend className={styles.legend}>{category}</legend>
              {items.map((ing) => (
                <label key={ing.id} className={styles.item}>
                  <input
                    type="checkbox"
                    checked={selectedIngredients.includes(ing.id)}
                    onChange={() => onToggle(ing.id)}
                  />
                  <span>{ing.name}</span>
                </label>
              ))}
            </fieldset>
          ))
        )}
      </div>

      <p className={styles.footNote}>
        {term
          ? `${filtered.length} of ${ingredients.length} shown`
          : `${ingredients.length} ingredients`}
      </p>
    </aside>
  );
}
