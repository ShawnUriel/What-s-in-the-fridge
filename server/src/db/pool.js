import pg from 'pg';

const { Pool } = pg;

/**
 * Single shared connection pool. No ORM anywhere in this project - every call
 * site writes raw, parameterized SQL through this pool.
 */
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: Number(process.env.PG_POOL_MAX ?? 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  // An idle client blew up (network drop, server restart). Log and let the pool
  // replace it rather than crashing the process.
  console.error('[pg] idle client error:', err.message);
});

/**
 * @param {string} text  SQL with $1..$n placeholders - never string-interpolated.
 * @param {unknown[]} params
 */
export function query(text, params) {
  return pool.query(text, params);
}
