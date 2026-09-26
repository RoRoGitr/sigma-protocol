import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { chmodSync, existsSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

test('detection offers only supported CLI providers when a retired binary remains on PATH', (t) => {
  // Given: installed CLI names, including a retired binary; no API-key environment.
  const directory = mkdtempSync(path.join(tmpdir(), 'provider-retirement-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  for (const name of ['claude', 'codex', 'gitnexus']) {
    const binary = path.join(directory, name);
    writeFileSync(binary, '#!/bin/sh\nexit 99\n');
    chmodSync(binary, 0o755);
  }
  // When: availability is detected without writing the cache or running a voice.
  const result = spawnSync(process.execPath, [path.join(root, 'scripts/fusion/detect-providers.mjs'), '--json', '--no-cache'], {
    encoding: 'utf8', env: { PATH: `${directory}:/usr/bin:/bin`, HOME: directory },
  });
  // Then: retired provider variants are not offered.
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(result.stdout).map((voice) => voice.id), ['claude', 'codex']);
});

test('setup refuses a retired provider choice without writing a configuration', (t) => {
  // Given: an explicit retired choice and an isolated output path.
  const directory = mkdtempSync(path.join(tmpdir(), 'provider-retirement-'));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  const configuration = path.join(directory, 'providers.config.json');
  // When: setup receives the choice without detection.
  const result = spawnSync(process.execPath, [path.join(root, 'scripts/fusion/setup-providers.mjs'), '--no-detect', '--enable', 'gitnexus-kimi'], {
    encoding: 'utf8', env: { PATH: '/usr/bin:/bin', HOME: directory, SIGMA_PROVIDERS_CONFIG_PATH: configuration },
  });
  // Then: the removed provider is unknown and no configuration is created.
  assert.equal(result.status, 1);
  assert.match(result.stderr, /unknown enable id/);
  assert.equal(existsSync(configuration), false);
});
