/** Thin fetch wrapper. Vite proxies /api to the Express server on :4000. */
async function request(path, options) {
  const res = await fetch(`/api${path}`, options);
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(body.message ?? `Request failed (${res.status})`);
  }
  return body;
}

export function fetchIngredients() {
  return request('/ingredients').then((b) => b.ingredients ?? []);
}

/** `signal` lets a newer selection cancel an in-flight match request. */
export function matchRecipes(userIngredients, signal) {
  return request('/recipes/match', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userIngredients }),
    signal,
  }).then((b) => ({ matches: b.matches ?? [], nearMisses: b.nearMisses ?? [] }));
}
