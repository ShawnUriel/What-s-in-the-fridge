import express from 'express';
import cors from 'cors';
import apiRoutes from './routes/recipeRoutes.js';

export function createApp() {
  const app = express();

  app.use(cors({ origin: process.env.CORS_ORIGIN ?? 'http://localhost:5173' }));
  app.use(express.json({ limit: '64kb' }));

  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/api', apiRoutes);

  app.use((_req, res) => {
    res.status(404).json({ error: 'NOT_FOUND', message: 'No such endpoint.' });
  });

  // Central error handler - never leak SQL text or stack traces to the client.
  app.use((err, _req, res, _next) => {
    console.error('[api] unhandled error:', err);
    res.status(500).json({
      error: 'INTERNAL_ERROR',
      message: 'Something went wrong on our end.',
    });
  });

  return app;
}
