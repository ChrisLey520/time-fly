#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, '..');
const args = process.argv.slice(2);
const runDevEco = args.includes('--deveco') || args.includes('--full');
const checkDevice = args.includes('--device') || args.includes('--full');
const showHelp = args.includes('--help') || args.includes('-h');

const checks = [
  ['node', ['test/timer_core.test.mjs']],
  ['node', ['test/stats_core.test.mjs']],
  ['node', ['test/task_core.test.mjs']],
  ['node', ['--check', 'scripts/check-deveco-env.mjs']],
  ['git', ['diff', '--check']]
];

function printUsage() {
  console.log('Usage: node scripts/verify.mjs [options]');
  console.log('');
  console.log('Options:');
  console.log('  --deveco   Also run DevEco/Hvigor assemble precheck');
  console.log('  --device   Include hdc device visibility with --deveco');
  console.log('  --full     Run local checks plus DevEco assemble and device check');
  console.log('  --help     Show this help');
}

function run(command, commandArgs) {
  console.log(`\n> ${command} ${commandArgs.join(' ')}`);
  const result = spawnSync(command, commandArgs, {
    cwd: projectRoot,
    stdio: 'inherit'
  });
  return result.status ?? 1;
}

if (showHelp) {
  printUsage();
  process.exit(0);
}

for (const [command, commandArgs] of checks) {
  const status = run(command, commandArgs);
  if (status !== 0) {
    process.exit(status);
  }
}

if (runDevEco) {
  const devEcoArgs = ['scripts/check-deveco-env.mjs', '--assemble'];
  if (checkDevice) {
    devEcoArgs.push('--device');
  }

  const status = run('node', devEcoArgs);
  if (status !== 0) {
    process.exit(status);
  }
}

console.log('\nVerification passed.');
