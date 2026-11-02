-- SAAS-017 · Test and live gateway credentials kept apart.
--
-- A gateway's credentials move to their own table, one row per (provider, environment), so saving live keys
-- never overwrites test keys and a test key can never serve a live payment. `PaymentGatewayConfig.environment`
-- now says which of the two new payments use, and the active gateway's environment must have credentials.
-- Every checkout order records the environment it was created in: it is confirmed, reconciled and refunded
-- with that environment's credentials, whatever the gateway uses later.

-- CreateTable
CREATE TABLE "PaymentGatewayCredential" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL CHECK ("provider" IN ('razorpay', 'vyapargateway')),
    "environment" TEXT NOT NULL CHECK ("environment" IN ('test', 'live')),
    "cipher" TEXT NOT NULL,
    "keyId" TEXT NOT NULL,
    "hint" TEXT NOT NULL DEFAULT '{}',
    "configuredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGatewayCredential_provider_environment_key" ON "PaymentGatewayCredential"("provider", "environment");

-- Credentials are replaced in place, never deleted: payments taken with them must keep resolving them.
CREATE TRIGGER "PaymentGatewayCredential_no_delete" BEFORE DELETE ON "PaymentGatewayCredential"
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayCredential: credentials are replaced, never deleted');
END;

-- The provider and environment of a credential row never change.
CREATE TRIGGER "PaymentGatewayCredential_fixed" BEFORE UPDATE ON "PaymentGatewayCredential"
WHEN NEW."provider" <> OLD."provider" OR NEW."environment" <> OLD."environment"
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayCredential: provider and environment are fixed');
END;

-- Existing credentials move, unchanged, into the slot of the environment they were saved for.
INSERT INTO "PaymentGatewayCredential" ("id", "provider", "environment", "cipher", "keyId", "hint", "configuredAt", "updatedById", "createdAt", "updatedAt")
SELECT 'pgc_' || "id", "provider", "environment", "credentialsCipher", "credentialsKeyId", "credentialHint",
       COALESCE("configuredAt", "updatedAt"), "updatedById", "createdAt", "updatedAt"
FROM "PaymentGatewayConfig"
WHERE "credentialsCipher" IS NOT NULL;

-- RedefineTable: PaymentGatewayConfig without the credential columns.
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_PaymentGatewayConfig" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL CHECK ("provider" IN ('razorpay', 'vyapargateway')),
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "environment" TEXT NOT NULL DEFAULT 'test' CHECK ("environment" IN ('test', 'live')),
    "version" INTEGER NOT NULL DEFAULT 1 CHECK (typeof("version") = 'integer' AND "version" >= 1),
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Only an enabled gateway can be the active one (its credentials: trigger below).
    CHECK ("isActive" = 0 OR "enabled" = 1)
);
INSERT INTO "new_PaymentGatewayConfig" ("id", "provider", "enabled", "isActive", "environment", "version", "updatedById", "createdAt", "updatedAt")
SELECT "id", "provider", "enabled", "isActive", "environment", "version", "updatedById", "createdAt", "updatedAt" FROM "PaymentGatewayConfig";
DROP TABLE "PaymentGatewayConfig";
ALTER TABLE "new_PaymentGatewayConfig" RENAME TO "PaymentGatewayConfig";
CREATE UNIQUE INDEX "PaymentGatewayConfig_provider_key" ON "PaymentGatewayConfig"("provider");
-- At most one active gateway.
CREATE UNIQUE INDEX "PaymentGatewayConfig_one_active" ON "PaymentGatewayConfig"("isActive") WHERE "isActive" = 1;
PRAGMA foreign_keys=ON;

CREATE TRIGGER "PaymentGatewayConfig_no_delete" BEFORE DELETE ON "PaymentGatewayConfig"
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayConfig: a gateway is disabled, never deleted');
END;

-- The active gateway has credentials for the environment it takes payments in.
CREATE TRIGGER "PaymentGatewayConfig_active_ready_insert" BEFORE INSERT ON "PaymentGatewayConfig"
WHEN NEW."isActive" = 1 AND NOT EXISTS (
    SELECT 1 FROM "PaymentGatewayCredential" c WHERE c."provider" = NEW."provider" AND c."environment" = NEW."environment"
)
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayConfig: only a configured gateway can be active');
END;

CREATE TRIGGER "PaymentGatewayConfig_active_ready_update" BEFORE UPDATE ON "PaymentGatewayConfig"
WHEN NEW."isActive" = 1 AND NOT EXISTS (
    SELECT 1 FROM "PaymentGatewayCredential" c WHERE c."provider" = NEW."provider" AND c."environment" = NEW."environment"
)
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayConfig: only a configured gateway can be active');
END;

-- AlterTable: the environment a checkout order was created in, fixed once made. Existing orders keep null:
-- which keys created them was never recorded, and it is not guessed.
ALTER TABLE "PaymentOrder" ADD COLUMN "environment" TEXT CHECK ("environment" IS NULL OR "environment" IN ('test', 'live'));

CREATE TRIGGER "PaymentOrder_environment_fixed" BEFORE UPDATE OF "environment" ON "PaymentOrder"
WHEN NEW."environment" IS NOT OLD."environment"
BEGIN
    SELECT RAISE(ABORT, 'PaymentOrder: the environment an order was created in never changes');
END;
