/* Drops and recreates the database DATABASE_URL names, for the test runs that start from nothing. Its name must end in `_test` or
 * `_e2e`, so this can never reach a real database. */
import { PrismaClient } from '@prisma/client';

const parsed = new URL(process.env.DATABASE_URL ?? '');
const name = parsed.pathname.slice(1);
if (!/^\w+_(test|e2e)$/.test(name)) throw new Error('[recreate-database] The database name must end in _test or _e2e.');

// Connected to the server's own `mysql` schema, since this database may not exist yet.
parsed.pathname = '/mysql';
const server = new PrismaClient({ datasourceUrl: parsed.toString() });
try {
  await server.$executeRawUnsafe(`DROP DATABASE IF EXISTS \`${name}\``);
  await server.$executeRawUnsafe(`CREATE DATABASE \`${name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
} finally {
  await server.$disconnect();
}
