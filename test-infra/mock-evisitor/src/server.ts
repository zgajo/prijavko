import Fastify, { type FastifyInstance } from 'fastify';
import cookie from '@fastify/cookie';
import formbody from '@fastify/formbody';
import { pathToFileURL } from 'node:url';
import { loadFixtures, type Fixtures } from './fixtures.js';

export interface BuildAppOptions {
  logger?: boolean;
}

export async function buildApp(opts: BuildAppOptions = {}): Promise<FastifyInstance> {
  const app = Fastify({
    logger: opts.logger ?? true,
    disableRequestLogging: false,
    bodyLimit: 1_048_576, // 1 MB — generous for XML batch bodies
  });

  await app.register(cookie);
  await app.register(formbody);

  // Fail-fast at boot if fixtures malformed
  const fixtures = loadFixtures();
  app.decorate('fixtures', fixtures);

  // Routes are registered in later tasks (2-6).

  app.setErrorHandler((err, _req, reply) => {
    app.log.error({ err }, 'unhandled');
    reply.code(500).send({ SystemMessage: 'Internal mock error', UserMessage: '' });
  });

  return app;
}

// Augment Fastify instance with fixtures
declare module 'fastify' {
  interface FastifyInstance {
    fixtures: Fixtures;
  }
}

function resolvePort(): number {
  const raw = process.env['PORT'];
  if (raw === undefined) return 8080;
  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    throw new Error(`Invalid PORT "${raw}": must be an integer between 1 and 65535`);
  }
  return parsed;
}

async function main(): Promise<void> {
  const port = resolvePort();
  const app = await buildApp();
  try {
    await app.listen({ host: '0.0.0.0', port });
  } catch (err) {
    app.log.error({ err }, 'failed to start');
    process.exit(1);
  }
}

// Run as CLI unless imported by tests.
if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  main().catch((err: unknown) => {
    console.error(err);
    process.exit(1);
  });
}
