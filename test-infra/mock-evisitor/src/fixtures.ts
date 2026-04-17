import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

export interface EvisitorEnvelope {
  SystemMessage: string;
  UserMessage: string;
}

export interface LoginCredentialsFixture {
  username: string;
  password: string;
  sessionToken: string;
}

export interface Fixtures {
  loginCredentials: LoginCredentialsFixture;
  submitSuccess: EvisitorEnvelope;
  submitErrorValidation: EvisitorEnvelope;
  submitErrorDuplicate: EvisitorEnvelope;
  submitErrorSession: EvisitorEnvelope;
  submitErrorUnavailable: EvisitorEnvelope;
  redirectLoginHtml: string;
}

const FIXTURE_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '../fixtures');

function readJson<T>(relativePath: string, validator: (v: unknown) => v is T): T {
  const raw = readFileSync(resolve(FIXTURE_DIR, relativePath), 'utf8');
  const parsed: unknown = JSON.parse(raw);
  if (!validator(parsed)) {
    throw new Error(`[fixtures] Invalid shape in ${relativePath}`);
  }
  return parsed;
}

function isEnvelope(v: unknown): v is EvisitorEnvelope {
  return (
    typeof v === 'object' && v !== null &&
    typeof (v as { SystemMessage?: unknown }).SystemMessage === 'string' &&
    typeof (v as { UserMessage?: unknown }).UserMessage === 'string'
  );
}

function isLoginFixture(v: unknown): v is LoginCredentialsFixture {
  return (
    typeof v === 'object' && v !== null &&
    typeof (v as { username?: unknown }).username === 'string' &&
    typeof (v as { password?: unknown }).password === 'string' &&
    typeof (v as { sessionToken?: unknown }).sessionToken === 'string'
  );
}

export function loadFixtures(): Fixtures {
  return {
    loginCredentials: readJson('login_success.json', isLoginFixture),
    submitSuccess: readJson('submit_success.json', isEnvelope),
    submitErrorValidation: readJson('submit_error_validation.json', isEnvelope),
    submitErrorDuplicate: readJson('submit_error_duplicate.json', isEnvelope),
    submitErrorSession: readJson('submit_error_session.json', isEnvelope),
    submitErrorUnavailable: readJson('submit_error_unavailable.json', isEnvelope),
    redirectLoginHtml: readFileSync(resolve(FIXTURE_DIR, 'submit_redirect_login.html'), 'utf8'),
  };
}
