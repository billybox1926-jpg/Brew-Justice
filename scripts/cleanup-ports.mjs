// scripts/cleanup-ports.mjs
// Utility script to kill any process using specified ports before CI steps.
// Usage: node scripts/cleanup-ports.mjs <port1> <port2> ...

import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const ports = process.argv.slice(2).map(Number).filter(Boolean);
if (!ports.length) {
  console.error('Usage: node cleanup-ports.mjs <port1> <port2> ...');
  process.exit(1);
}

for (const port of ports) {
  try {
    await execAsync(`lsof -ti:${port} | xargs kill -9`);
    console.log(`✅ Cleaned port ${port}`);
  } catch {
    console.log(`ℹ️  No process on port ${port}`);
  }
}
