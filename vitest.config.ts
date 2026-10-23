import fs from 'node:fs'
import path from 'node:path'
import { defineConfig } from 'vitest/config'

// Integration tests talk to the Supabase project in .env.local (service role +
// throwaway zz-test-* organisations they create and remove themselves).
if (fs.existsSync('.env.local')) process.loadEnvFile('.env.local')

export default defineConfig({
  resolve: { alias: { '@': path.resolve(__dirname) } },
  test: {
    // Integration files each create their own orgs; run them one at a time
    // against the live project
    fileParallelism: false,
    projects: [
      {
        extends: true,
        test: { name: 'unit', include: ['tests/unit/**/*.test.ts'], environment: 'node' },
      },
      {
        extends: true,
        test: {
          name: 'integration',
          include: ['tests/integration/**/*.test.ts'],
          environment: 'node',
          testTimeout: 60_000,
          hookTimeout: 120_000,
        },
      },
    ],
  },
})
