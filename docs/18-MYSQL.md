# 18. MySQL

The platform runs on MySQL 8.4. It ran on SQLite until 2 Nov 2026; that history is kept in `apps/api/prisma/migrations-sqlite/` for
reference and is not applied.

## The baseline

`prisma/migrations/20261103000000_mysql_baseline` builds the whole database at once:

- 103 tables, from the Prisma schema.
- 14 conditional unique indexes. SQLite's partial indexes became functional key parts: a row outside the condition carries NULL, which
  a unique index ignores.
- 124 `CHECK` constraints, translated from SQLite's. Two more that use a column a foreign key can change by itself (MySQL refuses those
  as `CHECK`) are held by triggers instead, on insert and on update.
- 123 triggers, translated rule for rule. `RAISE(ABORT, …)` became `SIGNAL SQLSTATE '45000'`, and SQLite's `IS` between values became
  `<=>`. MySQL has no `UPDATE OF`, so those triggers first test whether one of the named columns changed.

These rules are not in `schema.prisma`, because Prisma cannot express them, so a new table's rules are added by hand in its migration.

## What differs from SQLite

| Area | Difference | What the code does |
| --- | --- | --- |
| Text | `String` defaults to `VARCHAR(191)` | Anything not an id, a key or indexed is `@db.Text`. A default on it is `dbgenerated("('x')")`, MySQL's expression form |
| Concurrency | Writers overlap, so deadlocks are real | `lib/db.ts` runs transactions at read committed and retries deadlock victims. A transaction must therefore never call a gateway or send mail itself |
| Connections | Each open transaction needs a second connection for the tenancy reference checks | `pooledUrl` sizes the pool (20 by default), and `transactionSlots` keeps half of it free of transactions |
| Comparison | Text compares without regard to case or accents | A rule about case compares bytes (`CAST(x AS BINARY)`). Unique keys on text also ignore case |
| Foreign keys | A cascade does not fire triggers on the rows it touches | Nothing relies on one: guarded ledgers use `RESTRICT` |

A write that still loses after five attempts answers 503, "The server is busy right now, and nothing was saved. Please try again."

## Running it

`DATABASE_URL` is a `mysql://` address. Characters that mean something in an address must be percent-encoded in the password: `@` is `%40`
and `#` is `%23`.

Tests need a MySQL server and a user who can create databases:

```bash
TEST_DATABASE_URL=mysql://root:root@127.0.0.1:3306/zuviloai_test npm test -w @syniastrolms/api
E2E_DATABASE_URL=mysql://root:root@127.0.0.1:3306/zuviloai_e2e npm run e2e
```

Each drops and rebuilds its database, and refuses a name that does not end in `_test` or `_e2e`. The demo seed runs only on a database on
this machine whose name ends in `_dev`, `_test` or `_e2e`.

Backups are `npm run db:backup -w @syniastrolms/api`: a gzipped `mysqldump` of a consistent snapshot. `deploy.sh` takes one before every
migration. Restore one with `gunzip -c <file> | mysql <database>`.
