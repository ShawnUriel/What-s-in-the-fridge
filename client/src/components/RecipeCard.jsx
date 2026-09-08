import { useState } from 'react';
import styles from './RecipeCard.module.css';

/**
 * Presentational recipe card. The match badge stays inside the orange palette:
 * solid orange at a perfect 100%, outlined for anything below.
 */
export default function RecipeCard({ recipe }) {
  const {
    title,
    prepTimeMinutes,
    matchPercentage,
    missingIngredients,
    imageUrl,
    haveCount,
    needCount,
  } = recipe;
  const isPerfect = matchPercentage === 100;

  // image_url is optional and its host may be unreachable offline. Drop the
  // element on error rather than leaving an empty frame at the top of the card.
  const [imageFailed, setImageFailed] = useState(false);

  return (
    <article className={styles.card}>
      {imageUrl && !imageFailed && (
        <img
          className={styles.image}
          src={imageUrl}
          alt=""
          loading="lazy"
          onError={() => setImageFailed(true)}
        />
      )}

      <div className={styles.body}>
        <div className={styles.topRow}>
          <h3 className={styles.title}>{title}</h3>
          <span
            className={`${styles.badge} ${isPerfect ? styles.perfect : styles.partial}`}
          >
            {matchPercentage}%
          </span>
        </div>

        <p className={styles.meta}>
          {prepTimeMinutes} min prep
          {needCount != null && (
            <>
              {' \u00b7 '}
              you have {haveCount} of {needCount}
            </>
          )}
        </p>

        <div className={styles.divider} />

        {missingIngredients.length === 0 ? (
          <p className={styles.haveAll}>You have everything.</p>
        ) : (
          <div className={styles.missing}>
            <span className={styles.missingLabel}>
              Still need {missingIngredients.length}
            </span>
            <ul className={styles.missingList}>
              {missingIngredients.map((name) => (
                <li key={name} className={styles.missingItem}>
                  {name}
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </article>
  );
}
