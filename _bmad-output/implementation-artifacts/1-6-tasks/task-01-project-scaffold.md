# Task 1 — Project scaffold (Fastify 5 + TS strip-types + Node 22)

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#1, #15, #16**.

**Goal:** Create the `test-infra/mock-evisitor/` TypeScript project that boots a Fastify 5 server on `0.0.0.0:8080`. No business logic in this task — just the runnable skeleton.

**Load skill first:** `.claude/skills/fastify/SKILL.md` + `rules/typescript.md` + `rules/configuration.md` + `rules/plugins.md`.

## Scope

- **In:** Project files, tsconfig, package.json, `src/server.ts` with `buildApp()` factory + `main()`, `.nvmrc`, `.gitignore` entries.
- **Out:** Routes (tasks 3/5/6), fixtures (task 2), tests (task 7), README (task 9), repo-root workspace file (task 9).

## Deliverables

### `test-infra/mock-evisitor/package.json`

```json
{
  "name": "mock-evisitor",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": ">=22 <23" },
  "scripts": {
    "dev": "node --watch --experimental-strip-types src/server.ts",
    "start": "node --experimental-strip-types src/server.ts",
    "build": "tsc -p .",
    "typecheck": "tsc -p . --noEmit",
    "test": "node --experimental-strip-types --test test/**/*.test.ts"
  },
  "dependencies": {
    "fastify": "^5.0.0",
    "@fastify/cookie": "^11.0.0",
    "@fastify/formbody": "^8.0.0",
    "fast-xml-parser": "^4.5.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "@types/node": "^22.0.0"
  }
}
```

### `test-infra/mock-evisitor/tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "verbatimModuleSyntax": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src",
    "resolveJsonModule": true,
    "declaration": false
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist", "test"]
}
```

### `test-infra/mock-evisitor/.nvmrc`

```
22
```

### `test-infra/mock-evisitor/src/server.ts`

```typescript
import Fastify, { type FastifyInstance } from 'fastify';
import cookie from '@fastify/cookie';
import formbody from '@fastify/formbody';

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

  // Routes are registered in later tasks (2-6).

  app.setErrorHandler((err, _req, reply) => {
    app.log.error({ err }, 'unhandled');
    reply.code(500).send({ SystemMessage: 'Internal mock error', UserMessage: '' });
  });

  return app;
}

async function main(): Promise<void> {
  const app = await buildApp();
  const port = Number(process.env.PORT ?? 8080);
  try {
    await app.listen({ host: '0.0.0.0', port });
  } catch (err) {
    app.log.error({ err }, 'failed to start');
    process.exit(1);
  }
}

// Run as CLI unless imported by tests.
if (import.meta.url === `file://${process.argv[1]}`) {
  void main();
}
```

### Repo-root `.gitignore` (add to existing file)

```
# test-infra — TypeScript mock server
test-infra/**/node_modules
test-infra/**/dist
test-infra/**/coverage
test-infra/**/.yarn
```

## Acceptance checks

- [ ] `cd test-infra/mock-evisitor && yarn install` completes without errors and creates `yarn.lock`
- [ ] `yarn typecheck` → zero TS errors
- [ ] `yarn dev` → server logs "Server listening at http://0.0.0.0:8080"
- [ ] `curl -v http://10.0.2.2:8080` from an AVD shell returns an HTTP response (404 is fine — no routes yet; what matters is the TCP connection succeeds, proving bind-address is correct)
- [ ] `yarn build` produces `dist/server.js` with no errors

## Commit

`test-infra(mock-evisitor): scaffold Fastify 5 + Node 22 strip-types project`
