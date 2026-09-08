import 'dotenv/config';
import { createApp } from './app.js';
import { pool } from './db/pool.js';

const PORT = Number(process.env.PORT ?? 4000);

const server = createApp().listen(PORT, () => {
  console.log(`[api] listening on http://localhost:${PORT}`);
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    server.close(() => pool.end().then(() => process.exit(0)));
  });
}
