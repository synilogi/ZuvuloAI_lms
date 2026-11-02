-- CreateTable
CREATE TABLE `Tenant` (
    `id` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'active',
    `statusReason` TEXT NULL,
    `statusChangedAt` DATETIME(3) NULL,
    `ownerUserId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Tenant_slug_key`(`slug`),
    INDEX `Tenant_status_idx`(`status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Plan` (
    `id` VARCHAR(191) NOT NULL,
    `code` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `description` TEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `displayOrder` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `archivedAt` DATETIME(3) NULL,

    UNIQUE INDEX `Plan_code_key`(`code`),
    INDEX `Plan_status_displayOrder_idx`(`status`, `displayOrder`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlanVersion` (
    `id` VARCHAR(191) NOT NULL,
    `planId` VARCHAR(191) NOT NULL,
    `version` INTEGER NOT NULL,
    `currency` TEXT NOT NULL,
    `monthlyPrice` INTEGER NULL,
    `annualPrice` INTEGER NULL,
    `trialDays` INTEGER NOT NULL DEFAULT 0,
    `featureCount` INTEGER NOT NULL DEFAULT 0,
    `limitCount` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PlanVersion_planId_version_key`(`planId`, `version`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Feature` (
    `id` VARCHAR(191) NOT NULL,
    `group` TEXT NOT NULL,
    `label` TEXT NOT NULL,
    `description` TEXT NOT NULL,
    `displayOrder` INTEGER NOT NULL,
    `enforcement` TEXT NOT NULL DEFAULT ('route'),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LimitDefinition` (
    `id` VARCHAR(191) NOT NULL,
    `label` TEXT NOT NULL,
    `unit` TEXT NOT NULL,
    `period` TEXT NOT NULL,
    `displayOrder` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlanFeature` (
    `planVersionId` VARCHAR(191) NOT NULL,
    `featureKey` VARCHAR(191) NOT NULL,

    INDEX `PlanFeature_featureKey_idx`(`featureKey`),
    PRIMARY KEY (`planVersionId`, `featureKey`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlanLimit` (
    `planVersionId` VARCHAR(191) NOT NULL,
    `limitKey` VARCHAR(191) NOT NULL,
    `value` BIGINT NULL,

    INDEX `PlanLimit_limitKey_idx`(`limitKey`),
    PRIMARY KEY (`planVersionId`, `limitKey`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `UsageGuard` (
    `tenantId` VARCHAR(191) NOT NULL,
    `limitKey` VARCHAR(191) NOT NULL,
    `touchedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`tenantId`, `limitKey`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `TaxRule` (
    `id` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `country` VARCHAR(191) NOT NULL,
    `region` VARCHAR(191) NULL,
    `inclusive` BOOLEAN NOT NULL DEFAULT false,
    `componentCount` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `retiredAt` DATETIME(3) NULL,

    INDEX `TaxRule_country_region_idx`(`country`, `region`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `TaxRuleComponent` (
    `ruleId` VARCHAR(191) NOT NULL,
    `code` VARCHAR(191) NOT NULL,
    `label` TEXT NOT NULL,
    `rateBps` INTEGER NOT NULL,
    `position` INTEGER NOT NULL,

    PRIMARY KEY (`ruleId`, `code`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BillingProfile` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `legalName` TEXT NOT NULL,
    `email` TEXT NOT NULL,
    `addressLine1` TEXT NOT NULL,
    `addressLine2` TEXT NULL,
    `city` TEXT NOT NULL,
    `region` TEXT NULL,
    `postalCode` TEXT NOT NULL,
    `country` TEXT NOT NULL,
    `taxRegistration` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `BillingProfile_tenantId_key`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Subscription` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `planId` VARCHAR(191) NOT NULL,
    `planVersionId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `billingCycle` TEXT NOT NULL,
    `currency` TEXT NOT NULL,
    `amount` INTEGER NOT NULL,
    `trialStartAt` DATETIME(3) NULL,
    `trialEndAt` DATETIME(3) NULL,
    `currentPeriodStartAt` DATETIME(3) NOT NULL,
    `currentPeriodEndAt` DATETIME(3) NOT NULL,
    `cancelAtPeriodEnd` BOOLEAN NOT NULL DEFAULT false,
    `cancelRequestedAt` DATETIME(3) NULL,
    `canceledAt` DATETIME(3) NULL,
    `cancellationReason` TEXT NULL,
    `pausedAt` DATETIME(3) NULL,
    `resumesAt` DATETIME(3) NULL,
    `pastDueAt` DATETIME(3) NULL,
    `pastDueReason` TEXT NULL,
    `gracePeriodStartAt` DATETIME(3) NULL,
    `gracePeriodEndAt` DATETIME(3) NULL,
    `provider` VARCHAR(191) NULL,
    `providerCustomerId` TEXT NULL,
    `providerSubscriptionId` VARCHAR(191) NULL,
    `sourceInvoiceId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Subscription_sourceInvoiceId_key`(`sourceInvoiceId`),
    INDEX `Subscription_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `Subscription_planVersionId_idx`(`planVersionId`),
    INDEX `Subscription_status_currentPeriodEndAt_idx`(`status`, `currentPeriodEndAt`),
    UNIQUE INDEX `Subscription_provider_providerSubscriptionId_key`(`provider`, `providerSubscriptionId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlanChange` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `subscriptionId` VARCHAR(191) NOT NULL,
    `kind` TEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `fromPlanVersionId` VARCHAR(191) NOT NULL,
    `fromCycle` TEXT NOT NULL,
    `fromAmount` INTEGER NOT NULL,
    `toPlanId` VARCHAR(191) NOT NULL,
    `toPlanVersionId` VARCHAR(191) NOT NULL,
    `toCycle` TEXT NOT NULL,
    `toAmount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL,
    `credit` INTEGER NOT NULL DEFAULT 0,
    `charge` INTEGER NOT NULL DEFAULT 0,
    `forfeited` INTEGER NOT NULL DEFAULT 0,
    `periodStartAt` DATETIME(3) NOT NULL,
    `periodEndAt` DATETIME(3) NOT NULL,
    `quotedAt` DATETIME(3) NOT NULL,
    `conflictsJson` TEXT NOT NULL DEFAULT ('[]'),
    `requestedById` TEXT NULL,
    `appliedAt` DATETIME(3) NULL,
    `closedAt` DATETIME(3) NULL,
    `closedReason` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `PlanChange_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    INDEX `PlanChange_subscriptionId_status_idx`(`subscriptionId`, `status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SubscriptionEvent` (
    `id` INTEGER NOT NULL AUTO_INCREMENT,
    `tenantId` VARCHAR(191) NOT NULL,
    `subscriptionId` VARCHAR(191) NOT NULL,
    `event` TEXT NOT NULL,
    `transition` TEXT NOT NULL,
    `fromStatus` TEXT NULL,
    `toStatus` TEXT NOT NULL,
    `actorType` TEXT NOT NULL,
    `actorId` TEXT NULL,
    `source` TEXT NULL,
    `metaJson` TEXT NOT NULL DEFAULT ('{}'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `SubscriptionEvent_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    INDEX `SubscriptionEvent_subscriptionId_id_idx`(`subscriptionId`, `id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `InvoiceSequence` (
    `series` VARCHAR(191) NOT NULL,
    `next` INTEGER NOT NULL,

    PRIMARY KEY (`series`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Invoice` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `number` VARCHAR(191) NOT NULL,
    `purpose` TEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `subscriptionId` VARCHAR(191) NULL,
    `planChangeId` VARCHAR(191) NULL,
    `currency` TEXT NOT NULL,
    `subtotal` INTEGER NOT NULL,
    `taxTotal` INTEGER NOT NULL,
    `total` INTEGER NOT NULL,
    `inclusive` BOOLEAN NOT NULL,
    `taxRuleId` TEXT NULL,
    `linesJson` TEXT NOT NULL,
    `taxLinesJson` TEXT NOT NULL,
    `billedToJson` TEXT NOT NULL,
    `periodStartAt` DATETIME(3) NULL,
    `periodEndAt` DATETIME(3) NULL,
    `issuedAt` DATETIME(3) NOT NULL,
    `dueAt` DATETIME(3) NOT NULL,
    `paidAt` DATETIME(3) NULL,
    `voidedAt` DATETIME(3) NULL,
    `voidReason` TEXT NULL,
    `provider` VARCHAR(191) NULL,
    `providerInvoiceId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `planVersionId` TEXT NULL,
    `billingCycle` TEXT NULL,

    UNIQUE INDEX `Invoice_number_key`(`number`),
    INDEX `Invoice_tenantId_issuedAt_idx`(`tenantId`, `issuedAt`),
    INDEX `Invoice_subscriptionId_idx`(`subscriptionId`),
    INDEX `Invoice_status_idx`(`status`),
    UNIQUE INDEX `Invoice_provider_providerInvoiceId_key`(`provider`, `providerInvoiceId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Payment` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `invoiceId` VARCHAR(191) NULL,
    `subscriptionId` VARCHAR(191) NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerPaymentId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL,
    `status` TEXT NOT NULL,
    `failureCode` TEXT NULL,
    `failureMessage` TEXT NULL,
    `methodKind` TEXT NULL,
    `methodBrand` TEXT NULL,
    `methodLast4` TEXT NULL,
    `paidAt` DATETIME(3) NULL,
    `failedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `Payment_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    INDEX `Payment_invoiceId_idx`(`invoiceId`),
    UNIQUE INDEX `Payment_provider_providerPaymentId_key`(`provider`, `providerPaymentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PaymentOrder` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `invoiceId` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerOrderId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL,
    `status` TEXT NOT NULL DEFAULT ('created'),
    `providerPaymentId` TEXT NULL,
    `environment` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `paidAt` DATETIME(3) NULL,

    INDEX `PaymentOrder_invoiceId_idx`(`invoiceId`),
    INDEX `PaymentOrder_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    UNIQUE INDEX `PaymentOrder_provider_providerOrderId_key`(`provider`, `providerOrderId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `WebhookEvent` (
    `id` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerEventId` VARCHAR(191) NOT NULL,
    `eventType` TEXT NOT NULL,
    `payloadHash` VARCHAR(191) NOT NULL,
    `referenceJson` TEXT NOT NULL DEFAULT ('{}'),
    `status` VARCHAR(191) NOT NULL DEFAULT 'received',
    `attempts` INTEGER NOT NULL DEFAULT 1,
    `note` TEXT NULL,
    `receivedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `processedAt` DATETIME(3) NULL,

    INDEX `WebhookEvent_provider_payloadHash_idx`(`provider`, `payloadHash`),
    INDEX `WebhookEvent_status_receivedAt_idx`(`status`, `receivedAt`),
    UNIQUE INDEX `WebhookEvent_provider_providerEventId_key`(`provider`, `providerEventId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PaymentGatewayConfig` (
    `id` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `enabled` BOOLEAN NOT NULL DEFAULT false,
    `isActive` BOOLEAN NOT NULL DEFAULT false,
    `environment` TEXT NOT NULL DEFAULT ('test'),
    `version` INTEGER NOT NULL DEFAULT 1,
    `updatedById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PaymentGatewayConfig_provider_key`(`provider`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PaymentGatewayCredential` (
    `id` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `environment` VARCHAR(191) NOT NULL,
    `cipher` TEXT NOT NULL,
    `keyId` TEXT NOT NULL,
    `hint` TEXT NOT NULL DEFAULT ('{}'),
    `configuredAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PaymentGatewayCredential_provider_environment_key`(`provider`, `environment`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Refund` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `paymentId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL,
    `reason` TEXT NOT NULL,
    `status` TEXT NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerRefundId` VARCHAR(191) NULL,
    `requestedById` TEXT NULL,
    `failureMessage` TEXT NULL,
    `settledAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `Refund_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    INDEX `Refund_paymentId_idx`(`paymentId`),
    UNIQUE INDEX `Refund_provider_providerRefundId_key`(`provider`, `providerRefundId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PaymentMethod` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerMethodRef` VARCHAR(191) NOT NULL,
    `kind` TEXT NOT NULL,
    `brand` TEXT NOT NULL,
    `last4` TEXT NULL,
    `expMonth` INTEGER NULL,
    `expYear` INTEGER NULL,
    `isDefault` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `removedAt` DATETIME(3) NULL,

    INDEX `PaymentMethod_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `PaymentMethod_provider_providerMethodRef_key`(`provider`, `providerMethodRef`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `User` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `email` VARCHAR(191) NOT NULL,
    `phone` TEXT NULL,
    `passwordHash` TEXT NOT NULL,
    `name` TEXT NOT NULL,
    `role` TEXT NOT NULL,
    `descriptor` TEXT NOT NULL DEFAULT (''),
    `instructorId` VARCHAR(191) NULL,
    `deactivatedAt` DATETIME(3) NULL,
    `tokensValidAfter` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `User_email_key`(`email`),
    INDEX `User_instructorId_idx`(`instructorId`),
    INDEX `User_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `DeviceToken` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `userId` VARCHAR(191) NOT NULL,
    `sessionId` VARCHAR(191) NULL,
    `platform` TEXT NOT NULL,
    `token` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `lastSeenAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `DeviceToken_token_key`(`token`),
    INDEX `DeviceToken_userId_idx`(`userId`),
    INDEX `DeviceToken_sessionId_idx`(`sessionId`),
    INDEX `DeviceToken_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PushDelivery` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `userId` TEXT NOT NULL,
    `notificationId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'queued',
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `nextAttemptAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `lastAttemptAt` DATETIME(3) NULL,
    `sentAt` DATETIME(3) NULL,
    `delivered` INTEGER NOT NULL DEFAULT 0,
    `error` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PushDelivery_notificationId_key`(`notificationId`),
    INDEX `PushDelivery_status_nextAttemptAt_idx`(`status`, `nextAttemptAt`),
    INDEX `PushDelivery_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `UserSession` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `userId` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `expiresAt` DATETIME(3) NOT NULL,
    `revokedAt` DATETIME(3) NULL,
    `revokedReason` TEXT NULL,
    `userAgent` TEXT NULL,

    INDEX `UserSession_userId_idx`(`userId`),
    INDEX `UserSession_tenantId_idx`(`tenantId`),
    INDEX `UserSession_expiresAt_idx`(`expiresAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PasswordResetToken` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `userId` VARCHAR(191) NOT NULL,
    `tokenHash` VARCHAR(191) NOT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `usedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PasswordResetToken_tokenHash_key`(`tokenHash`),
    INDEX `PasswordResetToken_userId_idx`(`userId`),
    INDEX `PasswordResetToken_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PendingSignup` (
    `id` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `adminName` TEXT NOT NULL,
    `academyName` TEXT NOT NULL,
    `slug` TEXT NOT NULL,
    `passwordHash` TEXT NOT NULL,
    `codeHash` TEXT NOT NULL,
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `expiresAt` DATETIME(3) NOT NULL,
    `lastSentAt` DATETIME(3) NOT NULL,
    `sendCount` INTEGER NOT NULL DEFAULT 1,
    `consumedAt` DATETIME(3) NULL,
    `planId` TEXT NULL,
    `cycle` TEXT NULL,
    `createdAcademyId` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `PendingSignup_email_idx`(`email`),
    INDEX `PendingSignup_expiresAt_idx`(`expiresAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PendingAccount` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `role` TEXT NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `title` TEXT NULL,
    `passwordHash` TEXT NOT NULL,
    `codeHash` TEXT NOT NULL,
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `sendCount` INTEGER NOT NULL DEFAULT 1,
    `expiresAt` DATETIME(3) NOT NULL,
    `lastSentAt` DATETIME(3) NOT NULL,
    `consumedAt` DATETIME(3) NULL,
    `invitationId` TEXT NULL,
    `courseId` TEXT NULL,
    `createdUserId` TEXT NULL,
    `phone` TEXT NULL,
    `profileJson` TEXT NULL,
    `referralCode` TEXT NULL,
    `preferredLeg` TEXT NULL,
    `requestedLeg` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `PendingAccount_tenantId_email_idx`(`tenantId`, `email`),
    INDEX `PendingAccount_email_idx`(`email`),
    INDEX `PendingAccount_expiresAt_idx`(`expiresAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Inquiry` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `kind` TEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'new',
    `name` TEXT NOT NULL,
    `email` TEXT NOT NULL,
    `organisation` TEXT NULL,
    `phone` TEXT NULL,
    `size` TEXT NULL,
    `subject` TEXT NULL,
    `message` TEXT NOT NULL,
    `userId` TEXT NULL,
    `note` TEXT NULL,
    `handledById` TEXT NULL,
    `closedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Inquiry_tenantId_idx`(`tenantId`),
    INDEX `Inquiry_status_createdAt_idx`(`status`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AdminPermission` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `grantedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `grantedBy` TEXT NULL,

    INDEX `AdminPermission_userId_idx`(`userId`),
    INDEX `AdminPermission_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `AdminPermission_userId_key_key`(`userId`, `key`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AuditLog` (
    `id` VARCHAR(191) NOT NULL,
    `actorId` VARCHAR(191) NULL,
    `actorEmail` TEXT NOT NULL,
    `actorRole` TEXT NOT NULL,
    `actorType` TEXT NOT NULL DEFAULT ('user'),
    `source` TEXT NULL,
    `action` VARCHAR(191) NOT NULL,
    `targetType` TEXT NOT NULL,
    `targetId` TEXT NULL,
    `metaJson` TEXT NOT NULL DEFAULT ('{}'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `AuditLog_createdAt_idx`(`createdAt`),
    INDEX `AuditLog_actorId_idx`(`actorId`),
    INDEX `AuditLog_action_idx`(`action`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `EmailOutbox` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `toEmail` VARCHAR(191) NOT NULL,
    `toName` TEXT NULL,
    `subject` TEXT NOT NULL,
    `text` TEXT NOT NULL,
    `templateKey` TEXT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'queued',
    `error` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `sentAt` DATETIME(3) NULL,
    `attempts` INTEGER NOT NULL DEFAULT 0,
    `nextAttemptAt` DATETIME(3) NULL,
    `lastAttemptAt` DATETIME(3) NULL,
    `dedupKey` VARCHAR(191) NULL,
    `providerMessageId` TEXT NULL,

    INDEX `EmailOutbox_status_createdAt_idx`(`status`, `createdAt`),
    INDEX `EmailOutbox_status_nextAttemptAt_idx`(`status`, `nextAttemptAt`),
    INDEX `EmailOutbox_dedupKey_idx`(`dedupKey`),
    INDEX `EmailOutbox_toEmail_idx`(`toEmail`),
    INDEX `EmailOutbox_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MediaAsset` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `ownerUserId` VARCHAR(191) NOT NULL,
    `kind` TEXT NOT NULL,
    `originalName` TEXT NOT NULL,
    `mime` TEXT NOT NULL,
    `sizeBytes` INTEGER NOT NULL,
    `storageName` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `MediaAsset_storageName_key`(`storageName`),
    INDEX `MediaAsset_ownerUserId_idx`(`ownerUserId`),
    INDEX `MediaAsset_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Level` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `order` INTEGER NOT NULL,
    `summary` TEXT NULL,

    INDEX `Level_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Category` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `description` TEXT NOT NULL,
    `order` INTEGER NOT NULL,
    `status` TEXT NOT NULL,
    `glyph` TEXT NOT NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Category_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CategoryLevel` (
    `categoryId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `levelId` VARCHAR(191) NOT NULL,

    INDEX `CategoryLevel_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`categoryId`, `levelId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Instructor` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `title` TEXT NOT NULL,
    `yearsTeaching` INTEGER NULL,
    `email` VARCHAR(191) NOT NULL,
    `bio` TEXT NOT NULL DEFAULT (''),
    `expertiseJson` TEXT NOT NULL DEFAULT ('[]'),
    `status` TEXT NOT NULL,
    `joinedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `city` TEXT NOT NULL DEFAULT (''),
    `languagesJson` TEXT NOT NULL DEFAULT ('[]'),
    `phone` TEXT NULL,
    `photoJson` TEXT NULL,
    `linksJson` TEXT NOT NULL DEFAULT ('[]'),

    UNIQUE INDEX `Instructor_email_key`(`email`),
    INDEX `Instructor_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Course` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `subtitle` TEXT NOT NULL DEFAULT (''),
    `description` TEXT NOT NULL DEFAULT (''),
    `levelId` VARCHAR(191) NOT NULL,
    `categoryId` VARCHAR(191) NOT NULL,
    `format` TEXT NOT NULL,
    `language` TEXT NOT NULL DEFAULT ('en-IN'),
    `coverMotif` TEXT NOT NULL,
    `liveSessions` INTEGER NOT NULL DEFAULT 0,
    `estimatedWeeks` INTEGER NULL,
    `certificateTitle` TEXT NULL,
    `priceAmount` INTEGER NULL,
    `priceCurrency` TEXT NOT NULL DEFAULT ('INR'),
    `salePrice` INTEGER NULL,
    `pricing` TEXT NOT NULL DEFAULT ('unset'),
    `enrolledCount` INTEGER NOT NULL DEFAULT 0,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `visibility` TEXT NOT NULL DEFAULT ('public'),
    `outcomesJson` TEXT NOT NULL DEFAULT ('[]'),
    `tagsJson` TEXT NOT NULL DEFAULT ('[]'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `publishedAt` DATETIME(3) NULL,
    `rating` DOUBLE NULL,
    `ratingCount` INTEGER NULL,
    `certificateTemplateId` VARCHAR(191) NULL,
    `coverImageId` VARCHAR(191) NULL,

    INDEX `Course_categoryId_idx`(`categoryId`),
    INDEX `Course_coverImageId_idx`(`coverImageId`),
    INDEX `Course_levelId_idx`(`levelId`),
    INDEX `Course_status_idx`(`status`),
    UNIQUE INDEX `Course_tenantId_slug_key`(`tenantId`, `slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CourseInstructor` (
    `courseId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `instructorId` VARCHAR(191) NOT NULL,

    INDEX `CourseInstructor_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`courseId`, `instructorId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Chapter` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `summary` TEXT NULL,
    `objective` TEXT NULL,
    `estimatedMin` INTEGER NULL,
    `status` TEXT NOT NULL DEFAULT ('draft'),
    `position` INTEGER NOT NULL,

    INDEX `Chapter_courseId_idx`(`courseId`),
    INDEX `Chapter_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Lesson` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `chapterId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `type` TEXT NOT NULL,
    `durationMin` INTEGER NOT NULL DEFAULT 0,
    `isPreview` BOOLEAN NOT NULL DEFAULT false,
    `status` TEXT NOT NULL DEFAULT ('draft'),
    `updatedAt` DATETIME(3) NOT NULL,
    `description` TEXT NULL,
    `objectivesJson` TEXT NOT NULL DEFAULT ('[]'),
    `contentJson` TEXT NOT NULL DEFAULT ('{}'),
    `settingsJson` TEXT NOT NULL DEFAULT ('{}'),
    `position` INTEGER NOT NULL,

    INDEX `Lesson_chapterId_idx`(`chapterId`),
    INDEX `Lesson_courseId_idx`(`courseId`),
    INDEX `Lesson_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Student` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `phone` TEXT NULL,
    `city` TEXT NOT NULL DEFAULT (''),
    `joinedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `lastActiveAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `suspended` BOOLEAN NOT NULL DEFAULT false,
    `suspendReason` TEXT NULL,
    `rankId` VARCHAR(191) NULL,
    `nudgedAt` DATETIME(3) NULL,

    UNIQUE INDEX `Student_userId_key`(`userId`),
    INDEX `Student_rankId_idx`(`rankId`),
    INDEX `Student_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Enrollment` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `enrolledAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `status` TEXT NOT NULL DEFAULT ('active'),
    `progress` INTEGER NOT NULL DEFAULT 0,
    `source` TEXT NOT NULL DEFAULT ('self'),
    `lastActiveAt` DATETIME(3) NULL,
    `completedAt` DATETIME(3) NULL,
    `expiresAt` DATETIME(3) NULL,
    `lastLessonId` TEXT NULL,
    `purchaseId` VARCHAR(191) NULL,

    UNIQUE INDEX `Enrollment_purchaseId_key`(`purchaseId`),
    INDEX `Enrollment_courseId_idx`(`courseId`),
    INDEX `Enrollment_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `Enrollment_studentId_courseId_key`(`studentId`, `courseId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LessonProgress` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `lessonId` VARCHAR(191) NOT NULL,
    `state` TEXT NOT NULL DEFAULT ('not-started'),
    `fraction` DOUBLE NULL,
    `positionSec` INTEGER NULL,
    `completedAt` DATETIME(3) NULL,
    `lastAccessedAt` DATETIME(3) NULL,

    INDEX `LessonProgress_lessonId_idx`(`lessonId`),
    INDEX `LessonProgress_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `LessonProgress_studentId_lessonId_key`(`studentId`, `lessonId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LessonNote` (
    `studentId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `lessonId` VARCHAR(191) NOT NULL,
    `text` TEXT NOT NULL DEFAULT (''),
    `savedAt` DATETIME(3) NOT NULL,

    INDEX `LessonNote_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`studentId`, `lessonId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LessonBookmark` (
    `studentId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `lessonId` VARCHAR(191) NOT NULL,

    INDEX `LessonBookmark_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`studentId`, `lessonId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CourseReview` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `rating` INTEGER NOT NULL,
    `comment` TEXT NOT NULL DEFAULT (''),
    `status` VARCHAR(191) NOT NULL DEFAULT 'published',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `CourseReview_courseId_status_idx`(`courseId`, `status`),
    INDEX `CourseReview_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `CourseReview_studentId_courseId_key`(`studentId`, `courseId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SavedCourse` (
    `studentId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `savedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `SavedCourse_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`studentId`, `courseId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Rank` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `order` INTEGER NOT NULL,
    `descriptor` TEXT NOT NULL,
    `criteriaJson` TEXT NOT NULL DEFAULT ('[]'),

    INDEX `Rank_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Quiz` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `chapterId` TEXT NULL,
    `lessonId` VARCHAR(191) NULL,
    `title` TEXT NOT NULL,
    `instructions` TEXT NOT NULL DEFAULT (''),
    `status` TEXT NOT NULL DEFAULT ('draft'),
    `questionsJson` TEXT NOT NULL DEFAULT ('[]'),
    `settingsJson` TEXT NOT NULL DEFAULT ('{}'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `Quiz_lessonId_key`(`lessonId`),
    INDEX `Quiz_courseId_idx`(`courseId`),
    INDEX `Quiz_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `QuizAttempt` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `quizId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `answersJson` TEXT NOT NULL DEFAULT ('{}'),
    `resultJson` TEXT NOT NULL DEFAULT ('{}'),
    `percent` INTEGER NOT NULL DEFAULT 0,
    `passed` BOOLEAN NOT NULL DEFAULT false,
    `durationSec` INTEGER NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `sessionId` VARCHAR(191) NULL,

    UNIQUE INDEX `QuizAttempt_sessionId_key`(`sessionId`),
    INDEX `QuizAttempt_quizId_idx`(`quizId`),
    INDEX `QuizAttempt_studentId_idx`(`studentId`),
    INDEX `QuizAttempt_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `QuizSession` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `quizId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `attemptNo` INTEGER NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'active',
    `startedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `deadlineAt` DATETIME(3) NULL,
    `questionsJson` TEXT NOT NULL,
    `settingsJson` TEXT NOT NULL DEFAULT ('{}'),
    `orderJson` TEXT NOT NULL DEFAULT ('{}'),
    `answersJson` TEXT NOT NULL DEFAULT ('{}'),
    `answersSeq` INTEGER NOT NULL DEFAULT 0,
    `answersSavedAt` DATETIME(3) NULL,
    `startKey` TEXT NULL,
    `finishedAt` DATETIME(3) NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `QuizSession_studentId_quizId_idx`(`studentId`, `quizId`),
    INDEX `QuizSession_status_deadlineAt_idx`(`status`, `deadlineAt`),
    INDEX `QuizSession_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `QuizSession_quizId_studentId_attemptNo_key`(`quizId`, `studentId`, `attemptNo`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CourseAssignment` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `chapterId` TEXT NULL,
    `lessonId` VARCHAR(191) NULL,
    `title` TEXT NOT NULL,
    `instructions` TEXT NOT NULL DEFAULT (''),
    `attachmentsJson` TEXT NOT NULL DEFAULT ('[]'),
    `format` TEXT NOT NULL DEFAULT ('text'),
    `wordLimit` INTEGER NULL,
    `dueJson` TEXT NOT NULL DEFAULT ('{"kind":"none"}'),
    `acceptsLate` BOOLEAN NOT NULL DEFAULT true,
    `latePenalty` INTEGER NOT NULL DEFAULT 0,
    `rubricJson` TEXT NOT NULL DEFAULT ('[]'),
    `maxScore` INTEGER NOT NULL DEFAULT 100,
    `passMark` INTEGER NOT NULL DEFAULT 60,
    `status` TEXT NOT NULL DEFAULT ('draft'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `CourseAssignment_lessonId_key`(`lessonId`),
    INDEX `CourseAssignment_courseId_idx`(`courseId`),
    INDEX `CourseAssignment_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AssignmentDraft` (
    `studentId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `assignmentId` VARCHAR(191) NOT NULL,
    `text` TEXT NOT NULL DEFAULT (''),
    `filesJson` TEXT NOT NULL DEFAULT ('[]'),
    `chartJson` TEXT NULL,
    `savedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `AssignmentDraft_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`studentId`, `assignmentId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Submission` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `assignmentId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `attempt` INTEGER NOT NULL DEFAULT 1,
    `submittedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `late` BOOLEAN NOT NULL DEFAULT false,
    `text` TEXT NULL,
    `filesJson` TEXT NOT NULL DEFAULT ('[]'),
    `chartJson` TEXT NULL,
    `reviewStatus` TEXT NOT NULL DEFAULT ('waiting'),
    `reviewerId` TEXT NULL,
    `scoresJson` TEXT NOT NULL DEFAULT ('{}'),
    `points` DOUBLE NULL,
    `score` DOUBLE NULL,
    `feedback` TEXT NOT NULL DEFAULT (''),
    `privateNote` TEXT NULL,
    `reviewUpdatedAt` DATETIME(3) NULL,
    `overdueNotifiedAt` DATETIME(3) NULL,

    INDEX `Submission_assignmentId_idx`(`assignmentId`),
    INDEX `Submission_studentId_idx`(`studentId`),
    INDEX `Submission_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CertificateTemplate` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `style` TEXT NOT NULL,
    `accent` TEXT NOT NULL,
    `heading` TEXT NOT NULL,
    `statement` TEXT NOT NULL,
    `signatoriesJson` TEXT NOT NULL DEFAULT ('[]'),
    `showScore` BOOLEAN NOT NULL DEFAULT true,
    `showHours` BOOLEAN NOT NULL DEFAULT true,
    `isDefault` BOOLEAN NOT NULL DEFAULT false,
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `CertificateTemplate_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `IssuedCertificate` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `credentialId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `templateId` VARCHAR(191) NOT NULL,
    `status` TEXT NOT NULL DEFAULT ('pending'),
    `completedAt` DATETIME(3) NOT NULL,
    `issuedAt` DATETIME(3) NULL,
    `revokedAt` DATETIME(3) NULL,
    `revokedReason` TEXT NULL,
    `finalScore` DOUBLE NULL,
    `hours` DOUBLE NOT NULL DEFAULT 0,
    `verifications` INTEGER NOT NULL DEFAULT 0,

    UNIQUE INDEX `IssuedCertificate_credentialId_key`(`credentialId`),
    INDEX `IssuedCertificate_studentId_idx`(`studentId`),
    INDEX `IssuedCertificate_courseId_idx`(`courseId`),
    INDEX `IssuedCertificate_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LiveClass` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `instructorId` VARCHAR(191) NOT NULL,
    `startsAt` DATETIME(3) NOT NULL,
    `durationMin` INTEGER NOT NULL,
    `capacity` INTEGER NULL,
    `cancelled` BOOLEAN NOT NULL DEFAULT false,
    `cancelReason` TEXT NULL,
    `startedAt` DATETIME(3) NULL,
    `endedAt` DATETIME(3) NULL,
    `roomName` VARCHAR(191) NULL,
    `recordingJson` TEXT NULL,
    `description` TEXT NULL,
    `agendaJson` TEXT NOT NULL DEFAULT ('[]'),
    `visibility` TEXT NOT NULL DEFAULT ('enrolled'),
    `meetingJson` TEXT NOT NULL DEFAULT ('{"kind":"room"}'),
    `remindersJson` TEXT NOT NULL DEFAULT ('[]'),
    `remindersSentJson` TEXT NOT NULL DEFAULT ('[]'),
    `chapterId` TEXT NULL,

    UNIQUE INDEX `LiveClass_roomName_key`(`roomName`),
    INDEX `LiveClass_courseId_idx`(`courseId`),
    INDEX `LiveClass_instructorId_idx`(`instructorId`),
    INDEX `LiveClass_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LiveRegistration` (
    `liveClassId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `registeredAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `attended` BOOLEAN NULL,
    `joinedAt` DATETIME(3) NULL,

    INDEX `LiveRegistration_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`liveClassId`, `studentId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CalendarEvent` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `type` TEXT NOT NULL,
    `title` TEXT NOT NULL,
    `description` TEXT NULL,
    `timing` TEXT NOT NULL,
    `startsAt` DATETIME(3) NOT NULL,
    `durationMin` INTEGER NULL,
    `courseId` VARCHAR(191) NULL,
    `chapterId` TEXT NULL,
    `instructorId` VARCHAR(191) NULL,
    `quizId` TEXT NULL,
    `milestone` TEXT NULL,
    `audience` TEXT NULL,
    `ownerId` VARCHAR(191) NULL,
    `notifyMin` INTEGER NULL,
    `notifiedAt` DATETIME(3) NULL,
    `done` BOOLEAN NOT NULL DEFAULT false,
    `cancelled` BOOLEAN NOT NULL DEFAULT false,
    `sourceJson` TEXT NULL,

    INDEX `CalendarEvent_courseId_idx`(`courseId`),
    INDEX `CalendarEvent_startsAt_idx`(`startsAt`),
    INDEX `CalendarEvent_ownerId_idx`(`ownerId`),
    INDEX `CalendarEvent_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AppNotification` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `recipientId` VARCHAR(191) NOT NULL,
    `category` TEXT NOT NULL,
    `title` TEXT NOT NULL,
    `summary` TEXT NOT NULL,
    `bodyJson` TEXT NOT NULL DEFAULT ('[]'),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `readAt` DATETIME(3) NULL,
    `important` BOOLEAN NOT NULL DEFAULT false,
    `actor` TEXT NULL,
    `factsJson` TEXT NULL,
    `actionJson` TEXT NULL,
    `secondaryActionJson` TEXT NULL,

    INDEX `AppNotification_recipientId_createdAt_idx`(`recipientId`, `createdAt`),
    INDEX `AppNotification_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `NotificationSettings` (
    `userId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `categoriesJson` TEXT NOT NULL DEFAULT ('[]'),
    `emailDigest` TEXT NOT NULL DEFAULT ('instant'),
    `quietHoursJson` TEXT NOT NULL DEFAULT ('{"enabled":false,"from":"22:00","to":"07:00"}'),
    `pausedUntil` DATETIME(3) NULL,
    `smsNumber` TEXT NOT NULL DEFAULT (''),
    `lastDigestAt` DATETIME(3) NULL,

    INDEX `NotificationSettings_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`userId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Settings` (
    `tenantId` VARCHAR(191) NOT NULL,
    `generalJson` TEXT NOT NULL,
    `coursesJson` TEXT NOT NULL,
    `learningJson` TEXT NOT NULL,
    `certificatesJson` TEXT NOT NULL,
    `notificationsJson` TEXT NOT NULL,
    `appearanceJson` TEXT NOT NULL,
    `updatedAtJson` TEXT NOT NULL,
    `updatedByJson` TEXT NOT NULL,

    PRIMARY KEY (`tenantId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `PlatformBrandAsset` (
    `kind` VARCHAR(191) NOT NULL,
    `storageName` VARCHAR(191) NOT NULL,
    `originalName` TEXT NOT NULL,
    `mime` TEXT NOT NULL,
    `sizeBytes` INTEGER NOT NULL,
    `width` INTEGER NOT NULL,
    `height` INTEGER NOT NULL,
    `updatedById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `PlatformBrandAsset_storageName_key`(`storageName`),
    PRIMARY KEY (`kind`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `HelpCategory` (
    `id` VARCHAR(191) NOT NULL,
    `name` TEXT NOT NULL,
    `description` TEXT NOT NULL,
    `icon` TEXT NOT NULL,
    `order` INTEGER NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `HelpArticle` (
    `id` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `categoryId` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `summary` TEXT NOT NULL,
    `body` TEXT NOT NULL,
    `audience` TEXT NOT NULL DEFAULT ('all'),
    `tagsJson` TEXT NOT NULL DEFAULT ('[]'),
    `readMinutes` INTEGER NOT NULL DEFAULT 3,
    `updatedAt` DATETIME(3) NOT NULL,
    `popular` BOOLEAN NOT NULL DEFAULT false,

    UNIQUE INDEX `HelpArticle_slug_key`(`slug`),
    INDEX `HelpArticle_categoryId_idx`(`categoryId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `JobLease` (
    `job` VARCHAR(191) NOT NULL,
    `holder` TEXT NOT NULL,
    `acquiredAt` DATETIME(3) NOT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `lastRunAt` DATETIME(3) NULL,
    `lastOutcome` TEXT NULL,
    `lastHolder` TEXT NULL,

    PRIMARY KEY (`job`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Invitation` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `role` TEXT NOT NULL DEFAULT ('student'),
    `tokenHash` VARCHAR(191) NOT NULL,
    `email` TEXT NULL,
    `createdById` TEXT NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `usedAt` DATETIME(3) NULL,
    `usedByUserId` TEXT NULL,
    `revokedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Invitation_tokenHash_key`(`tokenHash`),
    INDEX `Invitation_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AcademyPaymentConfig` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `provider` TEXT NOT NULL DEFAULT ('razorpay'),
    `environment` TEXT NOT NULL DEFAULT ('test'),
    `enabled` BOOLEAN NOT NULL DEFAULT false,
    `updatedById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `AcademyPaymentConfig_tenantId_key`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AcademyGatewayCredential` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `environment` VARCHAR(191) NOT NULL,
    `cipher` TEXT NOT NULL,
    `keyId` TEXT NOT NULL,
    `hint` TEXT NOT NULL DEFAULT ('{}'),
    `updatedById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `AcademyGatewayCredential_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `AcademyGatewayCredential_tenantId_provider_environment_key`(`tenantId`, `provider`, `environment`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CoursePurchase` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL DEFAULT ('INR'),
    `listPrice` INTEGER NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `environment` TEXT NOT NULL,
    `providerOrderId` VARCHAR(191) NOT NULL,
    `providerPaymentId` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'created',
    `failureCode` TEXT NULL,
    `failureMessage` TEXT NULL,
    `reviewReason` TEXT NULL,
    `orderNumber` VARCHAR(191) NULL,
    `discountAmount` INTEGER NOT NULL DEFAULT 0,
    `couponId` TEXT NULL,
    `couponCode` TEXT NULL,
    `refundedAt` DATETIME(3) NULL,
    `chargebackAt` DATETIME(3) NULL,
    `bundlePurchaseId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `paidAt` DATETIME(3) NULL,
    `expiresAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `CoursePurchase_orderNumber_key`(`orderNumber`),
    INDEX `CoursePurchase_tenantId_idx`(`tenantId`),
    INDEX `CoursePurchase_studentId_courseId_idx`(`studentId`, `courseId`),
    INDEX `CoursePurchase_courseId_idx`(`courseId`),
    INDEX `CoursePurchase_status_createdAt_idx`(`status`, `createdAt`),
    INDEX `CoursePurchase_bundlePurchaseId_idx`(`bundlePurchaseId`),
    UNIQUE INDEX `CoursePurchase_provider_providerOrderId_key`(`provider`, `providerOrderId`),
    UNIQUE INDEX `CoursePurchase_provider_providerPaymentId_key`(`provider`, `providerPaymentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CoursePaymentEvent` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `eventId` VARCHAR(191) NOT NULL,
    `eventType` TEXT NOT NULL,
    `payloadHash` TEXT NOT NULL,
    `receivedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `processedAt` DATETIME(3) NULL,

    INDEX `CoursePaymentEvent_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `CoursePaymentEvent_tenantId_provider_eventId_key`(`tenantId`, `provider`, `eventId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmPlanVersion` (
    `id` VARCHAR(191) NOT NULL,
    `version` INTEGER NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `programTenantId` VARCHAR(191) NOT NULL,
    `eligibleCourseIdsJson` TEXT NOT NULL DEFAULT ('[]'),
    `currency` TEXT NOT NULL DEFAULT ('INR'),
    `cvBasisPoints` INTEGER NOT NULL DEFAULT 10000,
    `matchingRateBps` INTEGER NOT NULL DEFAULT 1000,
    `payoutCeilingBps` INTEGER NOT NULL DEFAULT 2500,
    `normalPayoutBps` INTEGER NOT NULL DEFAULT 1500,
    `matchingRunHourIst` INTEGER NOT NULL DEFAULT 2,
    `cvEligibilityDelayDays` INTEGER NOT NULL DEFAULT 0,
    `capOverflowPolicy` TEXT NOT NULL DEFAULT ('flush'),
    `carryForwardPolicy` TEXT NOT NULL DEFAULT ('indefinite'),
    `carryExpiryDays` INTEGER NULL,
    `spilloverRule` TEXT NOT NULL DEFAULT ('extreme-outer'),
    `withdrawalMinAmount` BIGINT NOT NULL DEFAULT 0,
    `withdrawalRequiresKyc` BOOLEAN NOT NULL DEFAULT true,
    `tdsBps` INTEGER NOT NULL DEFAULT 0,
    `liabilityPeriod` TEXT NOT NULL DEFAULT ('month'),
    `note` TEXT NOT NULL DEFAULT (''),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `activatedAt` DATETIME(3) NULL,
    `retiredAt` DATETIME(3) NULL,

    UNIQUE INDEX `MlmPlanVersion_version_key`(`version`),
    INDEX `MlmPlanVersion_status_idx`(`status`),
    INDEX `MlmPlanVersion_programTenantId_idx`(`programTenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmCapBand` (
    `id` VARCHAR(191) NOT NULL,
    `planVersionId` VARCHAR(191) NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `label` TEXT NOT NULL,
    `dailyCap` BIGINT NOT NULL,
    `order` INTEGER NOT NULL,

    UNIQUE INDEX `MlmCapBand_planVersionId_key_key`(`planVersionId`, `key`),
    UNIQUE INDEX `MlmCapBand_planVersionId_order_key`(`planVersionId`, `order`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmRankTier` (
    `id` VARCHAR(191) NOT NULL,
    `planVersionId` VARCHAR(191) NOT NULL,
    `order` INTEGER NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `groupCv` BIGINT NOT NULL,
    `rewardKind` TEXT NOT NULL,
    `rewardAmount` BIGINT NOT NULL DEFAULT 0,
    `rewardCapAmount` BIGINT NULL,
    `capBandKey` TEXT NOT NULL,
    `vestingDays` INTEGER NOT NULL DEFAULT 0,

    UNIQUE INDEX `MlmRankTier_planVersionId_order_key`(`planVersionId`, `order`),
    UNIQUE INDEX `MlmRankTier_planVersionId_name_key`(`planVersionId`, `name`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Affiliate` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `code` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'pending',
    `sponsorId` VARCHAR(191) NULL,
    `placementParentId` VARCHAR(191) NULL,
    `placementLeg` VARCHAR(191) NULL,
    `pathIdsJson` TEXT NOT NULL DEFAULT ('[]'),
    `depth` INTEGER NOT NULL DEFAULT 0,
    `preferredLeg` TEXT NOT NULL DEFAULT ('A'),
    `requestedLeg` TEXT NULL,
    `activatedAt` DATETIME(3) NULL,
    `activationPurchaseId` TEXT NULL,
    `kycStatus` TEXT NOT NULL DEFAULT ('none'),
    `currentRankOrder` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Affiliate_userId_key`(`userId`),
    UNIQUE INDEX `Affiliate_studentId_key`(`studentId`),
    UNIQUE INDEX `Affiliate_code_key`(`code`),
    INDEX `Affiliate_tenantId_idx`(`tenantId`),
    INDEX `Affiliate_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `Affiliate_sponsorId_idx`(`sponsorId`),
    INDEX `Affiliate_placementParentId_idx`(`placementParentId`),
    UNIQUE INDEX `Affiliate_placementParentId_placementLeg_key`(`placementParentId`, `placementLeg`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmPlacementHistory` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `fromParentId` TEXT NULL,
    `fromLeg` TEXT NULL,
    `toParentId` TEXT NULL,
    `toLeg` TEXT NULL,
    `reason` TEXT NOT NULL,
    `actorType` TEXT NOT NULL DEFAULT ('system'),
    `actorId` TEXT NULL,
    `note` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmPlacementHistory_tenantId_idx`(`tenantId`),
    INDEX `MlmPlacementHistory_tenantId_createdAt_idx`(`tenantId`, `createdAt`),
    INDEX `MlmPlacementHistory_affiliateId_idx`(`affiliateId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmOrder` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `purchaseId` VARCHAR(191) NOT NULL,
    `buyerAffiliateId` VARCHAR(191) NULL,
    `sponsorAffiliateIdAtSale` TEXT NULL,
    `planVersionId` VARCHAR(191) NOT NULL,
    `netAmount` BIGINT NOT NULL,
    `cv` BIGINT NOT NULL,
    `currency` TEXT NOT NULL DEFAULT ('INR'),
    `status` VARCHAR(191) NOT NULL DEFAULT 'pending',
    `paidAt` DATETIME(3) NOT NULL,
    `eligibleAt` DATETIME(3) NULL,
    `reversedAt` DATETIME(3) NULL,
    `reversalReason` TEXT NULL,
    `creditedAncestors` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `MlmOrder_purchaseId_key`(`purchaseId`),
    INDEX `MlmOrder_tenantId_idx`(`tenantId`),
    INDEX `MlmOrder_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `MlmOrder_buyerAffiliateId_idx`(`buyerAffiliateId`),
    INDEX `MlmOrder_paidAt_idx`(`paidAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmCvLedger` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `leg` TEXT NOT NULL,
    `orderId` VARCHAR(191) NOT NULL,
    `kind` VARCHAR(191) NOT NULL,
    `amount` BIGINT NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmCvLedger_tenantId_idx`(`tenantId`),
    INDEX `MlmCvLedger_affiliateId_createdAt_idx`(`affiliateId`, `createdAt`),
    UNIQUE INDEX `MlmCvLedger_orderId_affiliateId_kind_key`(`orderId`, `affiliateId`, `kind`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmLegBalance` (
    `affiliateId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `lifetimeA` BIGINT NOT NULL DEFAULT 0,
    `lifetimeB` BIGINT NOT NULL DEFAULT 0,
    `unmatchedA` BIGINT NOT NULL DEFAULT 0,
    `unmatchedB` BIGINT NOT NULL DEFAULT 0,
    `matchedLifetime` BIGINT NOT NULL DEFAULT 0,
    `lastMatchingRunDate` TEXT NULL,
    `version` INTEGER NOT NULL DEFAULT 0,
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmLegBalance_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`affiliateId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `OrderSequence` (
    `year` INTEGER NOT NULL,
    `last` INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (`year`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Coupon` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `code` VARCHAR(191) NOT NULL,
    `description` TEXT NOT NULL DEFAULT (''),
    `kind` TEXT NOT NULL,
    `percentBps` INTEGER NULL,
    `amountOff` INTEGER NULL,
    `startsAt` DATETIME(3) NULL,
    `endsAt` DATETIME(3) NULL,
    `maxUses` INTEGER NULL,
    `perLearnerLimit` INTEGER NOT NULL DEFAULT 1,
    `courseId` VARCHAR(191) NULL,
    `status` TEXT NOT NULL DEFAULT ('active'),
    `usedCount` INTEGER NOT NULL DEFAULT 0,
    `createdById` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Coupon_tenantId_code_key`(`tenantId`, `code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CouponRedemption` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `couponId` VARCHAR(191) NOT NULL,
    `purchaseId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `discountAmount` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `CouponRedemption_purchaseId_key`(`purchaseId`),
    INDEX `CouponRedemption_tenantId_idx`(`tenantId`),
    INDEX `CouponRedemption_couponId_studentId_idx`(`couponId`, `studentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CoursePurchaseRefund` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `purchaseId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `reason` TEXT NOT NULL,
    `note` TEXT NULL,
    `requestedById` TEXT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `providerRefundId` VARCHAR(191) NULL,
    `status` TEXT NOT NULL,
    `failureMessage` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `settledAt` DATETIME(3) NULL,

    INDEX `CoursePurchaseRefund_tenantId_idx`(`tenantId`),
    INDEX `CoursePurchaseRefund_purchaseId_idx`(`purchaseId`),
    UNIQUE INDEX `CoursePurchaseRefund_provider_providerRefundId_key`(`provider`, `providerRefundId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SiteContent` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `contentJson` TEXT NOT NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `SiteContent_tenantId_key`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SiteImage` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `mediaId` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `SiteImage_mediaId_key`(`mediaId`),
    INDEX `SiteImage_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BlogPost` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `kind` TEXT NOT NULL DEFAULT ('article'),
    `title` TEXT NOT NULL,
    `excerpt` TEXT NOT NULL DEFAULT (''),
    `body` TEXT NOT NULL DEFAULT (''),
    `coverUrl` TEXT NOT NULL DEFAULT (''),
    `externalUrl` TEXT NOT NULL DEFAULT (''),
    `eventAt` DATETIME(3) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'draft',
    `publishAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `BlogPost_status_publishAt_idx`(`status`, `publishAt`),
    UNIQUE INDEX `BlogPost_tenantId_slug_key`(`tenantId`, `slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CourseBundle` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `title` TEXT NOT NULL,
    `summary` TEXT NOT NULL DEFAULT (''),
    `description` TEXT NOT NULL DEFAULT (''),
    `coverUrl` TEXT NOT NULL DEFAULT (''),
    `price` INTEGER NOT NULL,
    `status` TEXT NOT NULL DEFAULT ('draft'),
    `publishAt` DATETIME(3) NULL,
    `order` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `CourseBundle_tenantId_slug_key`(`tenantId`, `slug`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `CourseBundleCourse` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `bundleId` VARCHAR(191) NOT NULL,
    `courseId` VARCHAR(191) NOT NULL,
    `order` INTEGER NOT NULL DEFAULT 0,

    INDEX `CourseBundleCourse_tenantId_idx`(`tenantId`),
    INDEX `CourseBundleCourse_courseId_idx`(`courseId`),
    UNIQUE INDEX `CourseBundleCourse_bundleId_courseId_key`(`bundleId`, `courseId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BundlePurchase` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `studentId` VARCHAR(191) NOT NULL,
    `bundleId` VARCHAR(191) NOT NULL,
    `amount` INTEGER NOT NULL,
    `currency` TEXT NOT NULL DEFAULT ('INR'),
    `price` INTEGER NOT NULL,
    `termsJson` TEXT NOT NULL,
    `provider` VARCHAR(191) NOT NULL,
    `environment` TEXT NOT NULL,
    `providerOrderId` VARCHAR(191) NOT NULL,
    `providerPaymentId` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'created',
    `failureCode` TEXT NULL,
    `failureMessage` TEXT NULL,
    `reviewReason` TEXT NULL,
    `orderNumber` VARCHAR(191) NULL,
    `refundStatus` TEXT NULL,
    `providerRefundId` TEXT NULL,
    `refundedAt` DATETIME(3) NULL,
    `chargebackAt` DATETIME(3) NULL,
    `paidAt` DATETIME(3) NULL,
    `expiresAt` DATETIME(3) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `BundlePurchase_orderNumber_key`(`orderNumber`),
    INDEX `BundlePurchase_tenantId_idx`(`tenantId`),
    INDEX `BundlePurchase_studentId_bundleId_idx`(`studentId`, `bundleId`),
    INDEX `BundlePurchase_status_createdAt_idx`(`status`, `createdAt`),
    UNIQUE INDEX `BundlePurchase_provider_providerOrderId_key`(`provider`, `providerOrderId`),
    UNIQUE INDEX `BundlePurchase_provider_providerPaymentId_key`(`provider`, `providerPaymentId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmMatchingRun` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `runDate` VARCHAR(191) NOT NULL,
    `planVersionId` TEXT NOT NULL,
    `rankOrderAtRun` INTEGER NOT NULL,
    `capBandKey` TEXT NOT NULL,
    `availableA` BIGINT NOT NULL,
    `availableB` BIGINT NOT NULL,
    `matchedCv` BIGINT NOT NULL,
    `grossIncome` BIGINT NOT NULL,
    `dailyCap` BIGINT NOT NULL,
    `cappedIncome` BIGINT NOT NULL,
    `flushedCv` BIGINT NOT NULL,
    `carryAAfter` BIGINT NOT NULL,
    `carryBAfter` BIGINT NOT NULL,
    `heldByCeiling` BIGINT NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmMatchingRun_tenantId_runDate_idx`(`tenantId`, `runDate`),
    UNIQUE INDEX `MlmMatchingRun_affiliateId_runDate_key`(`affiliateId`, `runDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmRankHistory` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `tierOrder` INTEGER NOT NULL,
    `tierName` TEXT NOT NULL,
    `lifetimeA` BIGINT NOT NULL,
    `lifetimeB` BIGINT NOT NULL,
    `planVersionId` TEXT NOT NULL,
    `achievedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmRankHistory_tenantId_achievedAt_idx`(`tenantId`, `achievedAt`),
    UNIQUE INDEX `MlmRankHistory_affiliateId_tierOrder_key`(`affiliateId`, `tierOrder`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmReward` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `rankHistoryId` VARCHAR(191) NOT NULL,
    `tierOrder` INTEGER NOT NULL,
    `tierName` TEXT NOT NULL,
    `groupCv` BIGINT NOT NULL,
    `kind` TEXT NOT NULL,
    `amount` BIGINT NOT NULL,
    `capAmount` BIGINT NULL,
    `vestingDays` INTEGER NOT NULL DEFAULT 0,
    `status` VARCHAR(191) NOT NULL DEFAULT 'qualified',
    `vestsAt` DATETIME(3) NULL,
    `note` TEXT NULL,
    `needsReview` BOOLEAN NOT NULL DEFAULT false,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `MlmReward_rankHistoryId_key`(`rankHistoryId`),
    INDEX `MlmReward_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `MlmReward_affiliateId_idx`(`affiliateId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmCommission` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `kind` TEXT NOT NULL,
    `amount` BIGINT NOT NULL,
    `status` VARCHAR(191) NOT NULL,
    `holdReason` TEXT NULL,
    `period` VARCHAR(191) NULL,
    `heldPeriod` TEXT NULL,
    `runId` TEXT NULL,
    `rewardId` TEXT NULL,
    `orderId` VARCHAR(191) NULL,
    `planVersionId` TEXT NOT NULL,
    `splitFromId` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `settledAt` DATETIME(3) NULL,

    INDEX `MlmCommission_tenantId_status_createdAt_idx`(`tenantId`, `status`, `createdAt`),
    INDEX `MlmCommission_tenantId_period_idx`(`tenantId`, `period`),
    INDEX `MlmCommission_affiliateId_createdAt_idx`(`affiliateId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmWallet` (
    `affiliateId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `available` BIGINT NOT NULL DEFAULT 0,
    `held` BIGINT NOT NULL DEFAULT 0,
    `paid` BIGINT NOT NULL DEFAULT 0,
    `updatedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmWallet_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`affiliateId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmWalletEntry` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `availableDelta` BIGINT NOT NULL DEFAULT 0,
    `heldDelta` BIGINT NOT NULL DEFAULT 0,
    `paidDelta` BIGINT NOT NULL DEFAULT 0,
    `commissionId` VARCHAR(191) NULL,
    `withdrawalId` VARCHAR(191) NULL,
    `note` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `MlmWalletEntry_tenantId_idx`(`tenantId`),
    INDEX `MlmWalletEntry_affiliateId_createdAt_idx`(`affiliateId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmKyc` (
    `affiliateId` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'submitted',
    `legalName` TEXT NOT NULL,
    `sealed` TEXT NOT NULL,
    `sealedKeyId` TEXT NOT NULL,
    `panLast4` TEXT NOT NULL,
    `bankAccountLast4` TEXT NOT NULL,
    `ifsc` TEXT NOT NULL,
    `accountHolder` TEXT NOT NULL,
    `upiId` TEXT NULL,
    `documentIdsJson` TEXT NOT NULL DEFAULT ('[]'),
    `rejectionReason` TEXT NULL,
    `submittedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `reviewedAt` DATETIME(3) NULL,

    INDEX `MlmKyc_tenantId_status_idx`(`tenantId`, `status`),
    PRIMARY KEY (`affiliateId`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmPayoutBatch` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `reference` VARCHAR(191) NOT NULL,
    `count` INTEGER NOT NULL,
    `total` BIGINT NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `exportedAt` DATETIME(3) NULL,
    `closedAt` DATETIME(3) NULL,

    UNIQUE INDEX `MlmPayoutBatch_reference_key`(`reference`),
    INDEX `MlmPayoutBatch_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmWithdrawal` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `affiliateId` VARCHAR(191) NOT NULL,
    `amount` BIGINT NOT NULL,
    `tdsAmount` BIGINT NOT NULL DEFAULT 0,
    `netAmount` BIGINT NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'requested',
    `bankSnapshotJson` TEXT NOT NULL,
    `sealed` TEXT NOT NULL,
    `sealedKeyId` TEXT NOT NULL,
    `payoutBatchId` TEXT NULL,
    `reference` TEXT NULL,
    `rejectionReason` TEXT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `decidedAt` DATETIME(3) NULL,
    `paidAt` DATETIME(3) NULL,

    INDEX `MlmWithdrawal_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `MlmWithdrawal_affiliateId_idx`(`affiliateId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `MlmProgramState` (
    `tenantId` VARCHAR(191) NOT NULL,
    `key` VARCHAR(191) NOT NULL,
    `value` TEXT NOT NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`tenantId`, `key`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `Tenant` ADD CONSTRAINT `Tenant_ownerUserId_fkey` FOREIGN KEY (`ownerUserId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_planId_fkey` FOREIGN KEY (`planId`) REFERENCES `Plan`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanFeature` ADD CONSTRAINT `PlanFeature_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `PlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanFeature` ADD CONSTRAINT `PlanFeature_featureKey_fkey` FOREIGN KEY (`featureKey`) REFERENCES `Feature`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanLimit` ADD CONSTRAINT `PlanLimit_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `PlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanLimit` ADD CONSTRAINT `PlanLimit_limitKey_fkey` FOREIGN KEY (`limitKey`) REFERENCES `LimitDefinition`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `UsageGuard` ADD CONSTRAINT `UsageGuard_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `TaxRuleComponent` ADD CONSTRAINT `TaxRuleComponent_ruleId_fkey` FOREIGN KEY (`ruleId`) REFERENCES `TaxRule`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BillingProfile` ADD CONSTRAINT `BillingProfile_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_planId_fkey` FOREIGN KEY (`planId`) REFERENCES `Plan`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `PlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_subscriptionId_fkey` FOREIGN KEY (`subscriptionId`) REFERENCES `Subscription`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_toPlanId_fkey` FOREIGN KEY (`toPlanId`) REFERENCES `Plan`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_toPlanVersionId_fkey` FOREIGN KEY (`toPlanVersionId`) REFERENCES `PlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_fromPlanVersionId_fkey` FOREIGN KEY (`fromPlanVersionId`) REFERENCES `PlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SubscriptionEvent` ADD CONSTRAINT `SubscriptionEvent_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SubscriptionEvent` ADD CONSTRAINT `SubscriptionEvent_subscriptionId_fkey` FOREIGN KEY (`subscriptionId`) REFERENCES `Subscription`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_subscriptionId_fkey` FOREIGN KEY (`subscriptionId`) REFERENCES `Subscription`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_planChangeId_fkey` FOREIGN KEY (`planChangeId`) REFERENCES `PlanChange`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_invoiceId_fkey` FOREIGN KEY (`invoiceId`) REFERENCES `Invoice`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_subscriptionId_fkey` FOREIGN KEY (`subscriptionId`) REFERENCES `Subscription`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PaymentOrder` ADD CONSTRAINT `PaymentOrder_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PaymentOrder` ADD CONSTRAINT `PaymentOrder_invoiceId_fkey` FOREIGN KEY (`invoiceId`) REFERENCES `Invoice`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Refund` ADD CONSTRAINT `Refund_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Refund` ADD CONSTRAINT `Refund_paymentId_fkey` FOREIGN KEY (`paymentId`) REFERENCES `Payment`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PaymentMethod` ADD CONSTRAINT `PaymentMethod_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `User` ADD CONSTRAINT `User_instructorId_fkey` FOREIGN KEY (`instructorId`) REFERENCES `Instructor`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `User` ADD CONSTRAINT `User_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `DeviceToken` ADD CONSTRAINT `DeviceToken_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `DeviceToken` ADD CONSTRAINT `DeviceToken_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PushDelivery` ADD CONSTRAINT `PushDelivery_notificationId_fkey` FOREIGN KEY (`notificationId`) REFERENCES `AppNotification`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PushDelivery` ADD CONSTRAINT `PushDelivery_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `UserSession` ADD CONSTRAINT `UserSession_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `UserSession` ADD CONSTRAINT `UserSession_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PasswordResetToken` ADD CONSTRAINT `PasswordResetToken_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PasswordResetToken` ADD CONSTRAINT `PasswordResetToken_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `PendingAccount` ADD CONSTRAINT `PendingAccount_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Inquiry` ADD CONSTRAINT `Inquiry_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AdminPermission` ADD CONSTRAINT `AdminPermission_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AdminPermission` ADD CONSTRAINT `AdminPermission_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AuditLog` ADD CONSTRAINT `AuditLog_actorId_fkey` FOREIGN KEY (`actorId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmailOutbox` ADD CONSTRAINT `EmailOutbox_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MediaAsset` ADD CONSTRAINT `MediaAsset_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Level` ADD CONSTRAINT `Level_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Category` ADD CONSTRAINT `Category_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CategoryLevel` ADD CONSTRAINT `CategoryLevel_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `Category`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CategoryLevel` ADD CONSTRAINT `CategoryLevel_levelId_fkey` FOREIGN KEY (`levelId`) REFERENCES `Level`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CategoryLevel` ADD CONSTRAINT `CategoryLevel_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Instructor` ADD CONSTRAINT `Instructor_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Course` ADD CONSTRAINT `Course_levelId_fkey` FOREIGN KEY (`levelId`) REFERENCES `Level`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Course` ADD CONSTRAINT `Course_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `Category`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Course` ADD CONSTRAINT `Course_certificateTemplateId_fkey` FOREIGN KEY (`certificateTemplateId`) REFERENCES `CertificateTemplate`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Course` ADD CONSTRAINT `Course_coverImageId_fkey` FOREIGN KEY (`coverImageId`) REFERENCES `MediaAsset`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Course` ADD CONSTRAINT `Course_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseInstructor` ADD CONSTRAINT `CourseInstructor_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseInstructor` ADD CONSTRAINT `CourseInstructor_instructorId_fkey` FOREIGN KEY (`instructorId`) REFERENCES `Instructor`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseInstructor` ADD CONSTRAINT `CourseInstructor_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Chapter` ADD CONSTRAINT `Chapter_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Chapter` ADD CONSTRAINT `Chapter_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Lesson` ADD CONSTRAINT `Lesson_chapterId_fkey` FOREIGN KEY (`chapterId`) REFERENCES `Chapter`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Lesson` ADD CONSTRAINT `Lesson_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Student` ADD CONSTRAINT `Student_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Student` ADD CONSTRAINT `Student_rankId_fkey` FOREIGN KEY (`rankId`) REFERENCES `Rank`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Student` ADD CONSTRAINT `Student_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Enrollment` ADD CONSTRAINT `Enrollment_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `CoursePurchase`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Enrollment` ADD CONSTRAINT `Enrollment_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Enrollment` ADD CONSTRAINT `Enrollment_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Enrollment` ADD CONSTRAINT `Enrollment_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonProgress` ADD CONSTRAINT `LessonProgress_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonProgress` ADD CONSTRAINT `LessonProgress_lessonId_fkey` FOREIGN KEY (`lessonId`) REFERENCES `Lesson`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonProgress` ADD CONSTRAINT `LessonProgress_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonNote` ADD CONSTRAINT `LessonNote_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonNote` ADD CONSTRAINT `LessonNote_lessonId_fkey` FOREIGN KEY (`lessonId`) REFERENCES `Lesson`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonNote` ADD CONSTRAINT `LessonNote_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonBookmark` ADD CONSTRAINT `LessonBookmark_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonBookmark` ADD CONSTRAINT `LessonBookmark_lessonId_fkey` FOREIGN KEY (`lessonId`) REFERENCES `Lesson`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LessonBookmark` ADD CONSTRAINT `LessonBookmark_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SavedCourse` ADD CONSTRAINT `SavedCourse_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SavedCourse` ADD CONSTRAINT `SavedCourse_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Rank` ADD CONSTRAINT `Rank_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Quiz` ADD CONSTRAINT `Quiz_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Quiz` ADD CONSTRAINT `Quiz_lessonId_fkey` FOREIGN KEY (`lessonId`) REFERENCES `Lesson`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Quiz` ADD CONSTRAINT `Quiz_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizAttempt` ADD CONSTRAINT `QuizAttempt_quizId_fkey` FOREIGN KEY (`quizId`) REFERENCES `Quiz`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizAttempt` ADD CONSTRAINT `QuizAttempt_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizAttempt` ADD CONSTRAINT `QuizAttempt_sessionId_fkey` FOREIGN KEY (`sessionId`) REFERENCES `QuizSession`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizAttempt` ADD CONSTRAINT `QuizAttempt_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizSession` ADD CONSTRAINT `QuizSession_quizId_fkey` FOREIGN KEY (`quizId`) REFERENCES `Quiz`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizSession` ADD CONSTRAINT `QuizSession_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `QuizSession` ADD CONSTRAINT `QuizSession_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseAssignment` ADD CONSTRAINT `CourseAssignment_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseAssignment` ADD CONSTRAINT `CourseAssignment_lessonId_fkey` FOREIGN KEY (`lessonId`) REFERENCES `Lesson`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseAssignment` ADD CONSTRAINT `CourseAssignment_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AssignmentDraft` ADD CONSTRAINT `AssignmentDraft_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AssignmentDraft` ADD CONSTRAINT `AssignmentDraft_assignmentId_fkey` FOREIGN KEY (`assignmentId`) REFERENCES `CourseAssignment`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AssignmentDraft` ADD CONSTRAINT `AssignmentDraft_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Submission` ADD CONSTRAINT `Submission_assignmentId_fkey` FOREIGN KEY (`assignmentId`) REFERENCES `CourseAssignment`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Submission` ADD CONSTRAINT `Submission_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Submission` ADD CONSTRAINT `Submission_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CertificateTemplate` ADD CONSTRAINT `CertificateTemplate_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IssuedCertificate` ADD CONSTRAINT `IssuedCertificate_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IssuedCertificate` ADD CONSTRAINT `IssuedCertificate_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IssuedCertificate` ADD CONSTRAINT `IssuedCertificate_templateId_fkey` FOREIGN KEY (`templateId`) REFERENCES `CertificateTemplate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `IssuedCertificate` ADD CONSTRAINT `IssuedCertificate_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveClass` ADD CONSTRAINT `LiveClass_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveClass` ADD CONSTRAINT `LiveClass_instructorId_fkey` FOREIGN KEY (`instructorId`) REFERENCES `Instructor`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveClass` ADD CONSTRAINT `LiveClass_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveRegistration` ADD CONSTRAINT `LiveRegistration_liveClassId_fkey` FOREIGN KEY (`liveClassId`) REFERENCES `LiveClass`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveRegistration` ADD CONSTRAINT `LiveRegistration_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LiveRegistration` ADD CONSTRAINT `LiveRegistration_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CalendarEvent` ADD CONSTRAINT `CalendarEvent_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CalendarEvent` ADD CONSTRAINT `CalendarEvent_instructorId_fkey` FOREIGN KEY (`instructorId`) REFERENCES `Instructor`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CalendarEvent` ADD CONSTRAINT `CalendarEvent_ownerId_fkey` FOREIGN KEY (`ownerId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CalendarEvent` ADD CONSTRAINT `CalendarEvent_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AppNotification` ADD CONSTRAINT `AppNotification_recipientId_fkey` FOREIGN KEY (`recipientId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AppNotification` ADD CONSTRAINT `AppNotification_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `NotificationSettings` ADD CONSTRAINT `NotificationSettings_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `NotificationSettings` ADD CONSTRAINT `NotificationSettings_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Settings` ADD CONSTRAINT `Settings_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `HelpArticle` ADD CONSTRAINT `HelpArticle_categoryId_fkey` FOREIGN KEY (`categoryId`) REFERENCES `HelpCategory`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Invitation` ADD CONSTRAINT `Invitation_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AcademyPaymentConfig` ADD CONSTRAINT `AcademyPaymentConfig_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AcademyGatewayCredential` ADD CONSTRAINT `AcademyGatewayCredential_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchase` ADD CONSTRAINT `CoursePurchase_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchase` ADD CONSTRAINT `CoursePurchase_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchase` ADD CONSTRAINT `CoursePurchase_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchase` ADD CONSTRAINT `CoursePurchase_bundlePurchaseId_fkey` FOREIGN KEY (`bundlePurchaseId`) REFERENCES `BundlePurchase`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePaymentEvent` ADD CONSTRAINT `CoursePaymentEvent_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_programTenantId_fkey` FOREIGN KEY (`programTenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCapBand` ADD CONSTRAINT `MlmCapBand_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `MlmPlanVersion`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `MlmPlanVersion`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_sponsorId_fkey` FOREIGN KEY (`sponsorId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_placementParentId_fkey` FOREIGN KEY (`placementParentId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `CoursePurchase`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_buyerAffiliateId_fkey` FOREIGN KEY (`buyerAffiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_planVersionId_fkey` FOREIGN KEY (`planVersionId`) REFERENCES `MlmPlanVersion`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_orderId_fkey` FOREIGN KEY (`orderId`) REFERENCES `MlmOrder`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmLegBalance` ADD CONSTRAINT `MlmLegBalance_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmLegBalance` ADD CONSTRAINT `MlmLegBalance_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Coupon` ADD CONSTRAINT `Coupon_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Coupon` ADD CONSTRAINT `Coupon_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CouponRedemption` ADD CONSTRAINT `CouponRedemption_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CouponRedemption` ADD CONSTRAINT `CouponRedemption_couponId_fkey` FOREIGN KEY (`couponId`) REFERENCES `Coupon`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CouponRedemption` ADD CONSTRAINT `CouponRedemption_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `CoursePurchase`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchaseRefund` ADD CONSTRAINT `CoursePurchaseRefund_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CoursePurchaseRefund` ADD CONSTRAINT `CoursePurchaseRefund_purchaseId_fkey` FOREIGN KEY (`purchaseId`) REFERENCES `CoursePurchase`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SiteContent` ADD CONSTRAINT `SiteContent_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SiteImage` ADD CONSTRAINT `SiteImage_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SiteImage` ADD CONSTRAINT `SiteImage_mediaId_fkey` FOREIGN KEY (`mediaId`) REFERENCES `MediaAsset`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BlogPost` ADD CONSTRAINT `BlogPost_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseBundle` ADD CONSTRAINT `CourseBundle_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseBundleCourse` ADD CONSTRAINT `CourseBundleCourse_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseBundleCourse` ADD CONSTRAINT `CourseBundleCourse_bundleId_fkey` FOREIGN KEY (`bundleId`) REFERENCES `CourseBundle`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `CourseBundleCourse` ADD CONSTRAINT `CourseBundleCourse_courseId_fkey` FOREIGN KEY (`courseId`) REFERENCES `Course`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BundlePurchase` ADD CONSTRAINT `BundlePurchase_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BundlePurchase` ADD CONSTRAINT `BundlePurchase_studentId_fkey` FOREIGN KEY (`studentId`) REFERENCES `Student`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BundlePurchase` ADD CONSTRAINT `BundlePurchase_bundleId_fkey` FOREIGN KEY (`bundleId`) REFERENCES `CourseBundle`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmMatchingRun` ADD CONSTRAINT `MlmMatchingRun_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmMatchingRun` ADD CONSTRAINT `MlmMatchingRun_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmRankHistory` ADD CONSTRAINT `MlmRankHistory_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmRankHistory` ADD CONSTRAINT `MlmRankHistory_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmReward` ADD CONSTRAINT `MlmReward_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmReward` ADD CONSTRAINT `MlmReward_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCommission` ADD CONSTRAINT `MlmCommission_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmCommission` ADD CONSTRAINT `MlmCommission_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWallet` ADD CONSTRAINT `MlmWallet_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWallet` ADD CONSTRAINT `MlmWallet_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWalletEntry` ADD CONSTRAINT `MlmWalletEntry_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWalletEntry` ADD CONSTRAINT `MlmWalletEntry_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmKyc` ADD CONSTRAINT `MlmKyc_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmKyc` ADD CONSTRAINT `MlmKyc_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmPayoutBatch` ADD CONSTRAINT `MlmPayoutBatch_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWithdrawal` ADD CONSTRAINT `MlmWithdrawal_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmWithdrawal` ADD CONSTRAINT `MlmWithdrawal_affiliateId_fkey` FOREIGN KEY (`affiliateId`) REFERENCES `Affiliate`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `MlmProgramState` ADD CONSTRAINT `MlmProgramState_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- ─── Conditional unique indexes ─────────────────────────────────────────────
-- SQLite's partial indexes, as functional key parts: a row outside the condition carries NULL, which a unique index ignores.
CREATE UNIQUE INDEX `BundlePurchase_one_open_per_learner_bundle` ON `BundlePurchase` (`studentId`, `bundleId`, (CASE WHEN `status` = 'created' THEN 1 END));
CREATE UNIQUE INDEX `CoursePurchaseRefund_one_live` ON `CoursePurchaseRefund` (`purchaseId`, (CASE WHEN `status` <> 'failed' THEN 1 END));
CREATE UNIQUE INDEX `CoursePurchase_one_open_per_learner_course` ON `CoursePurchase` (`studentId`, `courseId`, (CASE WHEN `status` = 'created' THEN 1 END));
CREATE UNIQUE INDEX `Invoice_one_open_first_purchase` ON `Invoice` (`tenantId`, (CASE WHEN `purpose` = 'new_subscription' AND `status` = 'open' THEN 1 END));
CREATE UNIQUE INDEX `Invoice_one_per_plan_change` ON `Invoice` (`planChangeId`, (CASE WHEN `planChangeId` IS NOT NULL AND `status` <> 'void' THEN 1 END));
CREATE UNIQUE INDEX `Invoice_one_per_renewal_period` ON `Invoice` (`subscriptionId`, `periodStartAt`, (CASE WHEN `purpose` = 'renewal' AND `status` <> 'void' THEN 1 END));
CREATE UNIQUE INDEX `MlmCommission_one_reversal` ON `MlmCommission` (`orderId`, `affiliateId`, (CASE WHEN `kind` = 'reversal' THEN 1 END));
CREATE UNIQUE INDEX `MlmWalletEntry_one_per_commission` ON `MlmWalletEntry` (`commissionId`, (CASE WHEN `commissionId` IS NOT NULL THEN 1 END));
CREATE UNIQUE INDEX `MlmWalletEntry_one_per_withdrawal_type` ON `MlmWalletEntry` (`withdrawalId`, `type`, (CASE WHEN `withdrawalId` IS NOT NULL THEN 1 END));
CREATE UNIQUE INDEX `MlmWithdrawal_one_open` ON `MlmWithdrawal` (`affiliateId`, (CASE WHEN `status` IN ('requested', 'approved', 'processing') THEN 1 END));
CREATE UNIQUE INDEX `PaymentGatewayConfig_one_active` ON `PaymentGatewayConfig` (`isActive`, (CASE WHEN `isActive` = 1 THEN 1 END));
CREATE UNIQUE INDEX `PlanChange_one_open_per_subscription` ON `PlanChange` (`subscriptionId`, (CASE WHEN `status` IN ('pending_payment', 'scheduled') THEN 1 END));
CREATE UNIQUE INDEX `Subscription_one_live_per_tenant` ON `Subscription` (`tenantId`, (CASE WHEN `status` NOT IN ('canceled', 'expired') THEN 1 END));
CREATE UNIQUE INDEX `TaxRule_one_active_per_place` ON `TaxRule` (`country`, (CAST(IFNULL(`region`, '') AS CHAR(64))), (CASE WHEN `retiredAt` IS NULL THEN 1 END));

-- ─── Value rules (SQLite CHECK constraints) ─────────────────────────────────
ALTER TABLE `Plan` ADD CONSTRAINT `Plan_chk_1` CHECK (`status` IN ('draft', 'active', 'archived'));
ALTER TABLE `Plan` ADD CONSTRAINT `Plan_chk_2` CHECK (CAST(`code` AS BINARY) = CAST(UPPER(`code`) AS BINARY) AND CHAR_LENGTH(`code`) BETWEEN 2 AND 24);
ALTER TABLE `Plan` ADD CONSTRAINT `Plan_chk_3` CHECK ((`status` = 'archived') = (`archivedAt` IS NOT NULL));
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_1` CHECK (TRUE AND `featureCount` >= 0);
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_2` CHECK (TRUE AND `limitCount` >= 0);
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_3` CHECK (TRUE AND `version` >= 1);
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_4` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_5` CHECK (`monthlyPrice` IS NULL OR (TRUE AND `monthlyPrice` >= 0));
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_6` CHECK (`annualPrice` IS NULL OR (TRUE AND `annualPrice` >= 0));
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_7` CHECK (`monthlyPrice` IS NOT NULL OR `annualPrice` IS NOT NULL);
ALTER TABLE `PlanVersion` ADD CONSTRAINT `PlanVersion_chk_8` CHECK (TRUE AND `trialDays` BETWEEN 0 AND 90);
ALTER TABLE `LimitDefinition` ADD CONSTRAINT `LimitDefinition_chk_1` CHECK (`unit` IN ('count', 'bytes'));
ALTER TABLE `LimitDefinition` ADD CONSTRAINT `LimitDefinition_chk_2` CHECK (`period` IN ('total', 'month'));
ALTER TABLE `PlanLimit` ADD CONSTRAINT `PlanLimit_chk_1` CHECK (`value` IS NULL OR (TRUE AND `value` >= 1));
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_1` CHECK ((`gracePeriodStartAt` IS NULL) = (`gracePeriodEndAt` IS NULL) AND (`gracePeriodEndAt` IS NULL OR `gracePeriodEndAt` >= `gracePeriodStartAt`));
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_2` CHECK (`status` IN ('trialing', 'active', 'past_due', 'paused', 'canceling', 'canceled', 'expired'));
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_3` CHECK (`billingCycle` IN ('monthly', 'annual'));
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_4` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_5` CHECK (TRUE AND `amount` >= 0);
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_6` CHECK (`currentPeriodEndAt` > `currentPeriodStartAt`);
ALTER TABLE `Subscription` ADD CONSTRAINT `Subscription_chk_7` CHECK ((`trialStartAt` IS NULL) = (`trialEndAt` IS NULL) AND (`trialEndAt` IS NULL OR `trialEndAt` > `trialStartAt`));
ALTER TABLE `SubscriptionEvent` ADD CONSTRAINT `SubscriptionEvent_chk_1` CHECK (`actorType` IN ('user', 'system', 'provider'));
ALTER TABLE `SubscriptionEvent` ADD CONSTRAINT `SubscriptionEvent_chk_2` CHECK (`actorType` <> 'user' OR `actorId` IS NOT NULL);
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_1` CHECK (`kind` IN ('upgrade', 'cycle_upgrade', 'downgrade', 'scheduled_change'));
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_2` CHECK (`status` IN ('pending_payment', 'scheduled', 'applied', 'canceled', 'void', 'expired'));
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_3` CHECK (`fromCycle` IN ('monthly', 'annual') AND `toCycle` IN ('monthly', 'annual'));
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_4` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_5` CHECK (TRUE AND `fromAmount` >= 0 AND TRUE AND `toAmount` >= 0 AND TRUE AND `credit` >= 0 AND TRUE AND `charge` >= 0 AND TRUE AND `forfeited` >= 0);
ALTER TABLE `PlanChange` ADD CONSTRAINT `PlanChange_chk_6` CHECK (`periodEndAt` > `periodStartAt`);
ALTER TABLE `TaxRule` ADD CONSTRAINT `TaxRule_chk_1` CHECK (REGEXP_LIKE(`country`, '^[A-Z][A-Z]$', 'c'));
ALTER TABLE `TaxRule` ADD CONSTRAINT `TaxRule_chk_2` CHECK (TRUE AND `componentCount` BETWEEN 1 AND 5);
ALTER TABLE `TaxRuleComponent` ADD CONSTRAINT `TaxRuleComponent_chk_1` CHECK (TRUE AND `rateBps` BETWEEN 0 AND 10000);
ALTER TABLE `TaxRuleComponent` ADD CONSTRAINT `TaxRuleComponent_chk_2` CHECK (CHAR_LENGTH(`code`) BETWEEN 1 AND 16);
ALTER TABLE `BillingProfile` ADD CONSTRAINT `BillingProfile_chk_1` CHECK (REGEXP_LIKE(`country`, '^[A-Z][A-Z]$', 'c'));
ALTER TABLE `InvoiceSequence` ADD CONSTRAINT `InvoiceSequence_chk_1` CHECK (TRUE AND `next` >= 1);
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_chk_1` CHECK (`purpose` IN ('new_subscription', 'renewal', 'plan_change'));
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_chk_2` CHECK (`status` IN ('open', 'paid', 'void'));
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_chk_3` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_chk_4` CHECK (TRUE AND `subtotal` >= 0 AND TRUE AND `taxTotal` >= 0 AND TRUE AND `total` = `subtotal` + `taxTotal`);
ALTER TABLE `Invoice` ADD CONSTRAINT `Invoice_chk_5` CHECK (REGEXP_LIKE(`number`, '^INV-[0-9][0-9][0-9][0-9]-[0-9]', 'c'));
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_chk_1` CHECK (`status` IN ('pending', 'paid', 'failed'));
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_chk_2` CHECK (TRUE AND `amount` >= 0);
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_chk_3` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_chk_4` CHECK (`methodLast4` IS NULL OR REGEXP_LIKE(`methodLast4`, '^[0-9][0-9][0-9][0-9]$', 'c'));
ALTER TABLE `Payment` ADD CONSTRAINT `Payment_chk_5` CHECK ((`status` = 'paid') = (`paidAt` IS NOT NULL) AND (`status` = 'failed') = (`failedAt` IS NOT NULL));
ALTER TABLE `Refund` ADD CONSTRAINT `Refund_chk_1` CHECK (`status` IN ('pending', 'succeeded', 'failed'));
ALTER TABLE `Refund` ADD CONSTRAINT `Refund_chk_2` CHECK (TRUE AND `amount` >= 1);
ALTER TABLE `Refund` ADD CONSTRAINT `Refund_chk_3` CHECK (CHAR_LENGTH(trim(`reason`)) >= 3);
ALTER TABLE `PaymentMethod` ADD CONSTRAINT `PaymentMethod_chk_1` CHECK (`kind` IN ('card', 'upi', 'netbanking', 'mandate', 'invoice'));
ALTER TABLE `PaymentMethod` ADD CONSTRAINT `PaymentMethod_chk_2` CHECK (`last4` IS NULL OR REGEXP_LIKE(`last4`, '^[0-9][0-9][0-9][0-9]$', 'c'));
ALTER TABLE `PaymentMethod` ADD CONSTRAINT `PaymentMethod_chk_3` CHECK ((`expMonth` IS NULL OR `expMonth` BETWEEN 1 AND 12) AND (`expYear` IS NULL OR `expYear` BETWEEN 2000 AND 2100));
ALTER TABLE `PaymentMethod` ADD CONSTRAINT `PaymentMethod_chk_4` CHECK (CHAR_LENGTH(`brand`) BETWEEN 1 AND 40 AND NOT REGEXP_LIKE(`brand`, '[0-9][0-9][0-9][0-9][0-9][0-9]', 'c'));
ALTER TABLE `PaymentOrder` ADD CONSTRAINT `PaymentOrder_chk_1` CHECK (TRUE AND `amount` > 0);
ALTER TABLE `PaymentOrder` ADD CONSTRAINT `PaymentOrder_chk_2` CHECK (`status` IN ('created', 'paid'));
ALTER TABLE `PaymentOrder` ADD CONSTRAINT `PaymentOrder_chk_3` CHECK (`environment` IS NULL OR `environment` IN ('test', 'live'));
ALTER TABLE `WebhookEvent` ADD CONSTRAINT `WebhookEvent_chk_1` CHECK (CHAR_LENGTH(`providerEventId`) BETWEEN 1 AND 128);
ALTER TABLE `WebhookEvent` ADD CONSTRAINT `WebhookEvent_chk_2` CHECK (CHAR_LENGTH(`payloadHash`) = 64);
ALTER TABLE `WebhookEvent` ADD CONSTRAINT `WebhookEvent_chk_3` CHECK (`status` IN ('received', 'processed', 'ignored', 'failed'));
ALTER TABLE `WebhookEvent` ADD CONSTRAINT `WebhookEvent_chk_4` CHECK (TRUE AND `attempts` >= 1);
ALTER TABLE `PaymentGatewayCredential` ADD CONSTRAINT `PaymentGatewayCredential_chk_1` CHECK (`provider` IN ('razorpay', 'vyapargateway'));
ALTER TABLE `PaymentGatewayCredential` ADD CONSTRAINT `PaymentGatewayCredential_chk_2` CHECK (`environment` IN ('test', 'live'));
ALTER TABLE `PaymentGatewayConfig` ADD CONSTRAINT `PaymentGatewayConfig_chk_1` CHECK (`provider` IN ('razorpay', 'vyapargateway'));
ALTER TABLE `PaymentGatewayConfig` ADD CONSTRAINT `PaymentGatewayConfig_chk_2` CHECK (`environment` IN ('test', 'live'));
ALTER TABLE `PaymentGatewayConfig` ADD CONSTRAINT `PaymentGatewayConfig_chk_3` CHECK (TRUE AND `version` >= 1);
ALTER TABLE `PaymentGatewayConfig` ADD CONSTRAINT `PaymentGatewayConfig_chk_4` CHECK (`isActive` = 0 OR `enabled` = 1);
ALTER TABLE `PlatformBrandAsset` ADD CONSTRAINT `PlatformBrandAsset_chk_1` CHECK (`kind` IN ('logo', 'favicon'));
ALTER TABLE `PlatformBrandAsset` ADD CONSTRAINT `PlatformBrandAsset_chk_2` CHECK (`sizeBytes` > 0);
ALTER TABLE `PlatformBrandAsset` ADD CONSTRAINT `PlatformBrandAsset_chk_3` CHECK (`width` > 0);
ALTER TABLE `PlatformBrandAsset` ADD CONSTRAINT `PlatformBrandAsset_chk_4` CHECK (`height` > 0);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_1` CHECK (TRUE AND `version` >= 1);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_2` CHECK (`status` IN ('draft', 'active', 'retired'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_3` CHECK (REGEXP_LIKE(`currency`, '^[A-Z][A-Z][A-Z]$', 'c'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_4` CHECK (TRUE AND `cvBasisPoints` BETWEEN 1 AND 10000);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_5` CHECK (TRUE AND `matchingRateBps` BETWEEN 1 AND 5000);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_6` CHECK (TRUE AND `payoutCeilingBps` BETWEEN 1 AND 10000);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_7` CHECK (TRUE AND `normalPayoutBps` BETWEEN 0 AND 10000);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_8` CHECK (TRUE AND `matchingRunHourIst` BETWEEN 0 AND 23);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_9` CHECK (TRUE AND `cvEligibilityDelayDays` BETWEEN 0 AND 90);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_10` CHECK (`capOverflowPolicy` IN ('flush', 'carry'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_11` CHECK (`carryForwardPolicy` IN ('indefinite', 'expire-days'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_12` CHECK (`carryExpiryDays` IS NULL OR (TRUE AND `carryExpiryDays` BETWEEN 1 AND 365));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_13` CHECK (`spilloverRule` IN ('extreme-outer', 'breadth-first'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_14` CHECK (TRUE AND `withdrawalMinAmount` >= 0);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_15` CHECK (TRUE AND `tdsBps` BETWEEN 0 AND 5000);
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_16` CHECK (`liabilityPeriod` IN ('month'));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_17` CHECK ((`status` = 'draft') = (`activatedAt` IS NULL));
ALTER TABLE `MlmPlanVersion` ADD CONSTRAINT `MlmPlanVersion_chk_18` CHECK ((`status` = 'retired') = (`retiredAt` IS NOT NULL));
ALTER TABLE `MlmCapBand` ADD CONSTRAINT `MlmCapBand_chk_1` CHECK (TRUE AND `dailyCap` >= 1);
ALTER TABLE `MlmCapBand` ADD CONSTRAINT `MlmCapBand_chk_2` CHECK (TRUE AND `order` >= 1);
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_1` CHECK (TRUE AND `order` >= 1);
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_2` CHECK (TRUE AND `groupCv` >= 2 AND `groupCv` % 2 = 0);
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_3` CHECK (`rewardKind` IN ('recognition', 'certificate', 'cash'));
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_4` CHECK (TRUE AND `rewardAmount` >= 0);
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_5` CHECK (`rewardCapAmount` IS NULL OR (TRUE AND `rewardCapAmount` >= 1));
ALTER TABLE `MlmRankTier` ADD CONSTRAINT `MlmRankTier_chk_6` CHECK (TRUE AND `vestingDays` BETWEEN 0 AND 3650);
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_1` CHECK (`status` IN ('pending', 'active', 'suspended', 'terminated'));
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_2` CHECK (CHAR_LENGTH(`code`) = 8 AND CAST(`code` AS BINARY) = CAST(UPPER(`code`) AS BINARY));
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_3` CHECK (`placementLeg` IS NULL OR `placementLeg` IN ('A', 'B'));
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_5` CHECK (`preferredLeg` IN ('A', 'B'));
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_6` CHECK (TRUE AND `depth` >= 0);
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_8` CHECK (`kycStatus` IN ('none', 'submitted', 'verified', 'rejected'));
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_9` CHECK (TRUE AND `currentRankOrder` >= 0);
ALTER TABLE `Affiliate` ADD CONSTRAINT `Affiliate_chk_10` CHECK (`status` <> 'pending' OR `activatedAt` IS NULL);
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_1` CHECK (`reason` IN ('sponsor-direct', 'spillover', 'manual', 'root'));
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_2` CHECK (`actorType` IN ('system', 'user'));
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_3` CHECK (`fromLeg` IS NULL OR `fromLeg` IN ('A', 'B'));
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_4` CHECK (`toLeg` IS NULL OR `toLeg` IN ('A', 'B'));
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_5` CHECK ((`fromParentId` IS NULL) = (`fromLeg` IS NULL));
ALTER TABLE `MlmPlacementHistory` ADD CONSTRAINT `MlmPlacementHistory_chk_6` CHECK ((`toParentId` IS NULL) = (`toLeg` IS NULL));
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_chk_1` CHECK (`status` IN ('pending', 'eligible', 'reversed'));
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_chk_2` CHECK (TRUE AND `netAmount` >= 0 AND TRUE AND `cv` >= 0);
ALTER TABLE `MlmOrder` ADD CONSTRAINT `MlmOrder_chk_3` CHECK ((`status` = 'reversed') = (`reversedAt` IS NOT NULL) AND (`reversalReason` IS NULL OR `reversalReason` IN ('refund', 'chargeback', 'manual')));
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_chk_1` CHECK (`leg` IN ('A', 'B'));
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_chk_2` CHECK (`kind` IN ('sale', 'reversal'));
ALTER TABLE `MlmCvLedger` ADD CONSTRAINT `MlmCvLedger_chk_3` CHECK (TRUE AND ((`kind` = 'sale' AND `amount` > 0) OR (`kind` = 'reversal' AND `amount` < 0)));
ALTER TABLE `MlmLegBalance` ADD CONSTRAINT `MlmLegBalance_chk_1` CHECK (`lifetimeA` >= 0 AND `lifetimeB` >= 0 AND `unmatchedA` >= 0 AND `unmatchedB` >= 0 AND `matchedLifetime` >= 0);
ALTER TABLE `Coupon` ADD CONSTRAINT `Coupon_chk_1` CHECK (`kind` IN ('percent', 'fixed'));
ALTER TABLE `Coupon` ADD CONSTRAINT `Coupon_chk_2` CHECK (`status` IN ('active', 'disabled'));
ALTER TABLE `Coupon` ADD CONSTRAINT `Coupon_chk_3` CHECK ((`kind` = 'percent' AND `percentBps` BETWEEN 1 AND 10000 AND `amountOff` IS NULL) OR (`kind` = 'fixed' AND `amountOff` > 0 AND `percentBps` IS NULL));
ALTER TABLE `CoursePurchaseRefund` ADD CONSTRAINT `CoursePurchaseRefund_chk_1` CHECK (`amount` > 0);
ALTER TABLE `CoursePurchaseRefund` ADD CONSTRAINT `CoursePurchaseRefund_chk_2` CHECK (`status` IN ('requested', 'pending', 'succeeded', 'failed'));
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_chk_1` CHECK (`rating` BETWEEN 1 AND 5);
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_chk_2` CHECK (CHAR_LENGTH(`comment`) <= 2000);
ALTER TABLE `CourseReview` ADD CONSTRAINT `CourseReview_chk_3` CHECK (`status` IN ('published', 'hidden'));

-- ─── The database's own guarantees ──────────────────────────────────────────
-- Translated rule for rule from the SQLite triggers. `<=>` is SQLite's `IS` between values.
CREATE TRIGGER `Affiliate_identity_fixed` BEFORE UPDATE ON `Affiliate` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`userId` <=> OLD.`userId`) OR NOT (NEW.`studentId` <=> OLD.`studentId`) OR NOT (NEW.`code` <=> OLD.`code`)) AND (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`userId` <=> OLD.`userId`) OR NOT (NEW.`studentId` <=> OLD.`studentId`) OR NOT (NEW.`code` <=> OLD.`code`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate''s academy, person and code cannot change'; END IF; END;
CREATE TRIGGER `Affiliate_no_delete` BEFORE DELETE ON `Affiliate` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate is never deleted; terminate it instead'; END;
CREATE TRIGGER `Affiliate_same_academy_insert` BEFORE INSERT ON `Affiliate` FOR EACH ROW BEGIN IF (NEW.`sponsorId` IS NOT NULL AND NOT ((SELECT `tenantId` FROM `Affiliate` WHERE `id` = NEW.`sponsorId`) <=> NEW.`tenantId`)) OR (NEW.`placementParentId` IS NOT NULL AND NOT ((SELECT `tenantId` FROM `Affiliate` WHERE `id` = NEW.`placementParentId`) <=> NEW.`tenantId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate''s sponsor and placement parent must be in the same academy'; END IF; END;
CREATE TRIGGER `Affiliate_same_academy_update` BEFORE UPDATE ON `Affiliate` FOR EACH ROW BEGIN IF (NOT (NEW.`sponsorId` <=> OLD.`sponsorId`) OR NOT (NEW.`placementParentId` <=> OLD.`placementParentId`)) AND ((NEW.`sponsorId` IS NOT NULL AND NOT ((SELECT `tenantId` FROM `Affiliate` WHERE `id` = NEW.`sponsorId`) <=> NEW.`tenantId`)) OR (NEW.`placementParentId` IS NOT NULL AND NOT ((SELECT `tenantId` FROM `Affiliate` WHERE `id` = NEW.`placementParentId`) <=> NEW.`tenantId`))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate''s sponsor and placement parent must be in the same academy'; END IF; END;
CREATE TRIGGER `Affiliate_terminated_is_final` BEFORE UPDATE ON `Affiliate` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (OLD.`status` = 'terminated' AND NEW.`status` <> 'terminated') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A terminated affiliate cannot be reinstated'; END IF; END;
CREATE TRIGGER `AuditLog_actor_shape` BEFORE INSERT ON `AuditLog` FOR EACH ROW BEGIN IF NEW.`actorType` NOT IN ('user', 'system', 'provider') OR (NEW.`actorType` = 'user' AND NEW.`source` IS NOT NULL) OR (NEW.`actorType` <> 'user' AND (NEW.`source` IS NULL OR trim(NEW.`source`) = '' OR NEW.`actorId` IS NOT NULL)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AuditLog: a person has no source; a system or provider event names its source and no person'; END IF; END;
CREATE TRIGGER `AuditLog_append_only_delete` BEFORE DELETE ON `AuditLog` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AuditLog is append-only'; END;
CREATE TRIGGER `AuditLog_append_only_update` BEFORE UPDATE ON `AuditLog` FOR EACH ROW BEGIN IF NOT ( NEW.`actorId` IS NULL AND OLD.`actorId` IS NOT NULL AND NEW.`id` = OLD.`id` AND NEW.`actorEmail` = OLD.`actorEmail` AND NEW.`actorRole` = OLD.`actorRole` AND NEW.`actorType` = OLD.`actorType` AND NEW.`source` <=> OLD.`source` AND NEW.`action` = OLD.`action` AND NEW.`targetType` = OLD.`targetType` AND NEW.`targetId` <=> OLD.`targetId` AND NEW.`metaJson` = OLD.`metaJson` AND NEW.`createdAt` = OLD.`createdAt` ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'AuditLog is append-only'; END IF; END;
CREATE TRIGGER `BundlePurchase_paid_is_final` BEFORE UPDATE ON `BundlePurchase` FOR EACH ROW BEGIN IF OLD.`status` = 'paid' AND (NEW.`status` <> 'paid' OR NOT (NEW.`providerPaymentId` <=> OLD.`providerPaymentId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A paid bundle order stays paid, by that payment.'; END IF; END;
CREATE TRIGGER `BundlePurchase_terms_fixed` BEFORE UPDATE ON `BundlePurchase` FOR EACH ROW BEGIN IF NEW.`amount` <> OLD.`amount` OR NEW.`currency` <> OLD.`currency` OR NEW.`studentId` <> OLD.`studentId` OR NEW.`bundleId` <> OLD.`bundleId` OR NEW.`termsJson` <> OLD.`termsJson` OR NEW.`providerOrderId` <> OLD.`providerOrderId` THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A bundle order''s terms are fixed when it is made.'; END IF; END;
CREATE TRIGGER `CouponRedemption_no_delete` BEFORE DELETE ON `CouponRedemption` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A coupon redemption is never deleted.'; END;
CREATE TRIGGER `CouponRedemption_no_update` BEFORE UPDATE ON `CouponRedemption` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A coupon redemption is never changed.'; END;
CREATE TRIGGER `Coupon_no_delete` BEFORE DELETE ON `Coupon` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A coupon is disabled, never deleted.'; END;
CREATE TRIGGER `Coupon_terms_fixed` BEFORE UPDATE ON `Coupon` FOR EACH ROW BEGIN IF NEW.`tenantId` <> OLD.`tenantId` OR NEW.`code` <> OLD.`code` OR NEW.`kind` <> OLD.`kind` OR NOT (NEW.`percentBps` <=> OLD.`percentBps`) OR NOT (NEW.`amountOff` <=> OLD.`amountOff`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A coupon''s code and discount are fixed. Disable it and make another.'; END IF; END;
CREATE TRIGGER `CoursePurchaseRefund_fixed` BEFORE UPDATE ON `CoursePurchaseRefund` FOR EACH ROW BEGIN IF NEW.`amount` <> OLD.`amount` OR NEW.`purchaseId` <> OLD.`purchaseId` OR NEW.`tenantId` <> OLD.`tenantId` OR OLD.`status` = 'succeeded' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A refund''s amount is fixed, and a settled refund is final.'; END IF; END;
CREATE TRIGGER `CoursePurchaseRefund_no_delete` BEFORE DELETE ON `CoursePurchaseRefund` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A refund is never deleted.'; END;
CREATE TRIGGER `CoursePurchase_order_terms_fixed` BEFORE UPDATE ON `CoursePurchase` FOR EACH ROW BEGIN IF (OLD.`orderNumber` IS NOT NULL AND NOT (NEW.`orderNumber` <=> OLD.`orderNumber`)) OR NEW.`discountAmount` <> OLD.`discountAmount` OR NOT (NEW.`couponId` <=> OLD.`couponId`) OR NOT (NEW.`couponCode` <=> OLD.`couponCode`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An order''s number and discount are fixed when it is made.'; END IF; END;
CREATE TRIGGER `CoursePurchase_paid_is_final` BEFORE UPDATE ON `CoursePurchase` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`) OR NOT (NEW.`providerPaymentId` <=> OLD.`providerPaymentId`)) AND ((OLD.`status` = 'paid' AND NOT (NEW.`status` <=> 'paid')) OR (OLD.`providerPaymentId` IS NOT NULL AND NOT (NEW.`providerPaymentId` <=> OLD.`providerPaymentId`))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A paid course purchase cannot be changed.'; END IF; END;
CREATE TRIGGER `CoursePurchase_terms_fixed` BEFORE UPDATE ON `CoursePurchase` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`studentId` <=> OLD.`studentId`) OR NOT (NEW.`courseId` <=> OLD.`courseId`) OR NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`listPrice` <=> OLD.`listPrice`) OR NOT (NEW.`provider` <=> OLD.`provider`) OR NOT (NEW.`environment` <=> OLD.`environment`) OR NOT (NEW.`providerOrderId` <=> OLD.`providerOrderId`)) AND (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`studentId` <=> OLD.`studentId`) OR NOT (NEW.`courseId` <=> OLD.`courseId`) OR NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`listPrice` <=> OLD.`listPrice`) OR NOT (NEW.`provider` <=> OLD.`provider`) OR NOT (NEW.`environment` <=> OLD.`environment`) OR NOT (NEW.`providerOrderId` <=> OLD.`providerOrderId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A course purchase''s terms cannot change.'; END IF; END;
CREATE TRIGGER `Enrollment_paid_course_not_self` BEFORE INSERT ON `Enrollment` FOR EACH ROW BEGIN IF NEW.`source` = 'self' AND EXISTS (SELECT 1 FROM `Course` c WHERE c.`id` = NEW.`courseId` AND c.`pricing` = 'paid') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A paid course is enrolled by purchase.'; END IF; END;
CREATE TRIGGER `Enrollment_purchase_paid_insert` BEFORE INSERT ON `Enrollment` FOR EACH ROW BEGIN IF NEW.`purchaseId` IS NOT NULL AND NOT EXISTS ( SELECT 1 FROM `CoursePurchase` p WHERE p.`id` = NEW.`purchaseId` AND p.`status` = 'paid' AND p.`studentId` = NEW.`studentId` AND p.`courseId` = NEW.`courseId` AND p.`tenantId` = NEW.`tenantId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An enrolment can only be opened by a paid purchase of that course by that learner.'; END IF; END;
CREATE TRIGGER `Enrollment_purchase_paid_update` BEFORE UPDATE ON `Enrollment` FOR EACH ROW BEGIN IF (NOT (NEW.`purchaseId` <=> OLD.`purchaseId`)) AND (NEW.`purchaseId` IS NOT NULL AND NOT EXISTS ( SELECT 1 FROM `CoursePurchase` p WHERE p.`id` = NEW.`purchaseId` AND p.`status` = 'paid' AND p.`studentId` = NEW.`studentId` AND p.`courseId` = NEW.`courseId` AND p.`tenantId` = NEW.`tenantId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An enrolment can only be opened by a paid purchase of that course by that learner.'; END IF; END;
CREATE TRIGGER `Feature_no_delete` BEFORE DELETE ON `Feature` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Catalogue features are never deleted'; END;
CREATE TRIGGER `Inquiry_no_delete` BEFORE DELETE ON `Inquiry` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An inquiry is kept on the record: close it instead.'; END;
CREATE TRIGGER `Invitation_fixed_scope` BEFORE UPDATE ON `Invitation` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`role` <=> OLD.`role`) OR NOT (NEW.`tokenHash` <=> OLD.`tokenHash`) OR NOT (NEW.`email` <=> OLD.`email`)) AND (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`role` <=> OLD.`role`) OR NOT (NEW.`tokenHash` <=> OLD.`tokenHash`) OR NOT (NEW.`email` <=> OLD.`email`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invitation keeps its workspace, role, token and address.'; END IF; END;
CREATE TRIGGER `Invitation_role_student` BEFORE INSERT ON `Invitation` FOR EACH ROW BEGIN IF NEW.`role` <> 'student' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invitation is for a learner.'; END IF; END;
CREATE TRIGGER `InvoiceSequence_no_delete` BEFORE DELETE ON `InvoiceSequence` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invoice series is never deleted'; END;
CREATE TRIGGER `InvoiceSequence_up` BEFORE UPDATE ON `InvoiceSequence` FOR EACH ROW BEGIN IF NEW.`next` <= OLD.`next` OR NOT (NEW.`series` <=> OLD.`series`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invoice number is never reused'; END IF; END;
CREATE TRIGGER `Invoice_fixed` BEFORE UPDATE ON `Invoice` FOR EACH ROW BEGIN IF NOT (NEW.`number` <=> OLD.`number`) OR NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`purpose` <=> OLD.`purpose`) OR NOT (NEW.`subscriptionId` <=> OLD.`subscriptionId`) OR NOT (NEW.`planChangeId` <=> OLD.`planChangeId`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`subtotal` <=> OLD.`subtotal`) OR NOT (NEW.`taxTotal` <=> OLD.`taxTotal`) OR NOT (NEW.`total` <=> OLD.`total`) OR NOT (NEW.`inclusive` <=> OLD.`inclusive`) OR NOT (NEW.`taxRuleId` <=> OLD.`taxRuleId`) OR NOT (NEW.`linesJson` <=> OLD.`linesJson`) OR NOT (NEW.`taxLinesJson` <=> OLD.`taxLinesJson`) OR NOT (NEW.`billedToJson` <=> OLD.`billedToJson`) OR NOT (NEW.`periodStartAt` <=> OLD.`periodStartAt`) OR NOT (NEW.`periodEndAt` <=> OLD.`periodEndAt`) OR NOT (NEW.`issuedAt` <=> OLD.`issuedAt`) OR NOT (NEW.`dueAt` <=> OLD.`dueAt`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`) OR (OLD.`provider` IS NOT NULL AND NOT (NEW.`provider` <=> OLD.`provider`)) OR (OLD.`providerInvoiceId` IS NOT NULL AND NOT (NEW.`providerInvoiceId` <=> OLD.`providerInvoiceId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An issued invoice is never altered'; END IF; END;
CREATE TRIGGER `Invoice_insert_open` BEFORE INSERT ON `Invoice` FOR EACH ROW BEGIN IF NEW.`status` <> 'open' OR NEW.`paidAt` IS NOT NULL OR NEW.`voidedAt` IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invoice is issued open'; END IF; END;
CREATE TRIGGER `Invoice_no_delete` BEFORE DELETE ON `Invoice` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invoices are never deleted'; END;
CREATE TRIGGER `Invoice_paid_by_payment` BEFORE UPDATE ON `Invoice` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NEW.`status` = 'paid' AND OLD.`status` = 'open' AND NOT EXISTS ( SELECT 1 FROM `Payment` p WHERE p.`invoiceId` = NEW.`id` AND p.`status` = 'paid' AND p.`amount` = NEW.`total` AND p.`currency` = NEW.`currency` )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invoice is paid only by a paid payment of its total'; END IF; END;
CREATE TRIGGER `Invoice_sale_fixed` BEFORE UPDATE ON `Invoice` FOR EACH ROW BEGIN IF (NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`billingCycle` <=> OLD.`billingCycle`)) AND (NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`billingCycle` <=> OLD.`billingCycle`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An issued invoice is never altered'; END IF; END;
CREATE TRIGGER `Invoice_sale_on_insert` BEFORE INSERT ON `Invoice` FOR EACH ROW BEGIN IF (NEW.`purpose` = 'new_subscription' AND ( NEW.`planVersionId` IS NULL OR NEW.`billingCycle` IS NULL OR NEW.`billingCycle` NOT IN ('monthly', 'annual') OR NOT EXISTS (SELECT 1 FROM `PlanVersion` v WHERE v.`id` = NEW.`planVersionId`) )) OR (NEW.`purpose` <> 'new_subscription' AND (NEW.`planVersionId` IS NOT NULL OR NEW.`billingCycle` IS NOT NULL)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A first-purchase invoice names the plan version and cycle it sells; no other invoice does'; END IF; END;
CREATE TRIGGER `Invoice_status_path` BEFORE UPDATE ON `Invoice` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`) OR NOT (NEW.`paidAt` <=> OLD.`paidAt`) OR NOT (NEW.`voidedAt` <=> OLD.`voidedAt`) OR NOT (NEW.`voidReason` <=> OLD.`voidReason`)) AND ((NOT (NEW.`status` <=> OLD.`status`) AND NOT (OLD.`status` = 'open' AND NEW.`status` IN ('paid', 'void'))) OR (OLD.`status` <> 'open' AND (NOT (NEW.`paidAt` <=> OLD.`paidAt`) OR NOT (NEW.`voidedAt` <=> OLD.`voidedAt`) OR NOT (NEW.`voidReason` <=> OLD.`voidReason`))) OR (NEW.`status` = 'paid' AND NEW.`paidAt` IS NULL) OR (NEW.`status` = 'void' AND (NEW.`voidedAt` IS NULL OR NEW.`voidReason` IS NULL))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An invoice moves once: open to paid, or open to void'; END IF; END;
CREATE TRIGGER `LimitDefinition_no_delete` BEFORE DELETE ON `LimitDefinition` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Catalogue limits are never deleted'; END;
CREATE TRIGGER `MlmCapBand_sealed_delete` BEFORE DELETE ON `MlmCapBand` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = OLD.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The cap bands of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmCapBand_sealed_insert` BEFORE INSERT ON `MlmCapBand` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = NEW.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The cap bands of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmCapBand_sealed_update` BEFORE UPDATE ON `MlmCapBand` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = OLD.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The cap bands of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmCommission_money_fixed` BEFORE UPDATE ON `MlmCommission` FOR EACH ROW BEGIN IF OLD.`status` <> 'held' OR NEW.`status` NOT IN ('paid_to_wallet', 'written_off', 'split') OR NEW.`amount` <> OLD.`amount` OR NEW.`kind` <> OLD.`kind` OR NEW.`affiliateId` <> OLD.`affiliateId` THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A commission is fixed: only a held one can be released, split or written off.'; END IF; END;
CREATE TRIGGER `MlmCommission_no_delete` BEFORE DELETE ON `MlmCommission` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A commission is never deleted.'; END;
CREATE TRIGGER `MlmCvLedger_no_delete` BEFORE DELETE ON `MlmCvLedger` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The CV ledger is never deleted'; END;
CREATE TRIGGER `MlmCvLedger_no_update` BEFORE UPDATE ON `MlmCvLedger` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The CV ledger is immutable'; END;
CREATE TRIGGER `MlmMatchingRun_no_delete` BEFORE DELETE ON `MlmMatchingRun` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A matching run is never deleted.'; END;
CREATE TRIGGER `MlmMatchingRun_no_update` BEFORE UPDATE ON `MlmMatchingRun` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A matching run is never changed.'; END;
CREATE TRIGGER `MlmOrder_no_delete` BEFORE DELETE ON `MlmOrder` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate order is never deleted'; END;
CREATE TRIGGER `MlmOrder_reversed_is_final` BEFORE UPDATE ON `MlmOrder` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (OLD.`status` = 'reversed' AND NEW.`status` <> 'reversed') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A reversed affiliate order stays reversed'; END IF; END;
CREATE TRIGGER `MlmOrder_terms_fixed` BEFORE UPDATE ON `MlmOrder` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`purchaseId` <=> OLD.`purchaseId`) OR NOT (NEW.`buyerAffiliateId` <=> OLD.`buyerAffiliateId`) OR NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`netAmount` <=> OLD.`netAmount`) OR NOT (NEW.`cv` <=> OLD.`cv`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`paidAt` <=> OLD.`paidAt`)) AND (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`purchaseId` <=> OLD.`purchaseId`) OR NOT (NEW.`buyerAffiliateId` <=> OLD.`buyerAffiliateId`) OR NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`netAmount` <=> OLD.`netAmount`) OR NOT (NEW.`cv` <=> OLD.`cv`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`paidAt` <=> OLD.`paidAt`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate order''s terms cannot change'; END IF; END;
CREATE TRIGGER `MlmPlacementHistory_no_delete` BEFORE DELETE ON `MlmPlacementHistory` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Placement history is never deleted'; END;
CREATE TRIGGER `MlmPlacementHistory_no_update` BEFORE UPDATE ON `MlmPlacementHistory` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Placement history is immutable'; END;
CREATE TRIGGER `MlmPlanVersion_no_delete` BEFORE DELETE ON `MlmPlanVersion` FOR EACH ROW BEGIN IF OLD.`status` <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate plan version that has been active is never deleted'; END IF; END;
CREATE TRIGGER `MlmPlanVersion_one_active` BEFORE UPDATE ON `MlmPlanVersion` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NEW.`status` = 'active' AND OLD.`status` <> 'active' AND EXISTS (SELECT 1 FROM `MlmPlanVersion` WHERE `status` = 'active' AND `id` <> NEW.`id`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another affiliate plan version is already active'; END IF; END;
CREATE TRIGGER `MlmPlanVersion_one_active_insert` BEFORE INSERT ON `MlmPlanVersion` FOR EACH ROW BEGIN IF NEW.`status` = 'active' AND EXISTS (SELECT 1 FROM `MlmPlanVersion` WHERE `status` = 'active') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another affiliate plan version is already active'; END IF; END;
CREATE TRIGGER `MlmPlanVersion_status_forward` BEFORE UPDATE ON `MlmPlanVersion` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NOT ((OLD.`status` = 'draft' AND NEW.`status` = 'active') OR (OLD.`status` = 'active' AND NEW.`status` = 'retired') OR NEW.`status` = OLD.`status`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An affiliate plan version moves draft → active → retired and never back'; END IF; END;
CREATE TRIGGER `MlmPlanVersion_terms_fixed` BEFORE UPDATE ON `MlmPlanVersion` FOR EACH ROW BEGIN IF (NOT (NEW.`version` <=> OLD.`version`) OR NOT (NEW.`programTenantId` <=> OLD.`programTenantId`) OR NOT (NEW.`eligibleCourseIdsJson` <=> OLD.`eligibleCourseIdsJson`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`cvBasisPoints` <=> OLD.`cvBasisPoints`) OR NOT (NEW.`matchingRateBps` <=> OLD.`matchingRateBps`) OR NOT (NEW.`payoutCeilingBps` <=> OLD.`payoutCeilingBps`) OR NOT (NEW.`normalPayoutBps` <=> OLD.`normalPayoutBps`) OR NOT (NEW.`matchingRunHourIst` <=> OLD.`matchingRunHourIst`) OR NOT (NEW.`cvEligibilityDelayDays` <=> OLD.`cvEligibilityDelayDays`) OR NOT (NEW.`capOverflowPolicy` <=> OLD.`capOverflowPolicy`) OR NOT (NEW.`carryForwardPolicy` <=> OLD.`carryForwardPolicy`) OR NOT (NEW.`carryExpiryDays` <=> OLD.`carryExpiryDays`) OR NOT (NEW.`spilloverRule` <=> OLD.`spilloverRule`) OR NOT (NEW.`withdrawalMinAmount` <=> OLD.`withdrawalMinAmount`) OR NOT (NEW.`withdrawalRequiresKyc` <=> OLD.`withdrawalRequiresKyc`) OR NOT (NEW.`tdsBps` <=> OLD.`tdsBps`) OR NOT (NEW.`liabilityPeriod` <=> OLD.`liabilityPeriod`)) AND (OLD.`status` <> 'draft' AND NOT ( NEW.`version` <=> OLD.`version` AND NEW.`programTenantId` <=> OLD.`programTenantId` AND NEW.`currency` <=> OLD.`currency` AND NEW.`cvBasisPoints` <=> OLD.`cvBasisPoints` AND NEW.`matchingRateBps` <=> OLD.`matchingRateBps` AND NEW.`payoutCeilingBps` <=> OLD.`payoutCeilingBps` AND NEW.`normalPayoutBps` <=> OLD.`normalPayoutBps` AND NEW.`matchingRunHourIst` <=> OLD.`matchingRunHourIst` AND NEW.`cvEligibilityDelayDays` <=> OLD.`cvEligibilityDelayDays` AND NEW.`capOverflowPolicy` <=> OLD.`capOverflowPolicy` AND NEW.`carryForwardPolicy` <=> OLD.`carryForwardPolicy` AND NEW.`carryExpiryDays` <=> OLD.`carryExpiryDays` AND NEW.`spilloverRule` <=> OLD.`spilloverRule` AND NEW.`withdrawalMinAmount` <=> OLD.`withdrawalMinAmount` AND NEW.`withdrawalRequiresKyc` <=> OLD.`withdrawalRequiresKyc` AND NEW.`tdsBps` <=> OLD.`tdsBps` AND NEW.`liabilityPeriod` <=> OLD.`liabilityPeriod` AND (OLD.`status` = 'active' OR NEW.`eligibleCourseIdsJson` <=> OLD.`eligibleCourseIdsJson`) )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The terms of an affiliate plan version cannot change once it has left draft: add a new version'; END IF; END;
CREATE TRIGGER `MlmRankHistory_no_delete` BEFORE DELETE ON `MlmRankHistory` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rank history is never deleted.'; END;
CREATE TRIGGER `MlmRankHistory_no_update` BEFORE UPDATE ON `MlmRankHistory` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rank history is never changed.'; END;
CREATE TRIGGER `MlmRankTier_sealed_delete` BEFORE DELETE ON `MlmRankTier` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = OLD.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The ranks of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmRankTier_sealed_insert` BEFORE INSERT ON `MlmRankTier` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = NEW.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The ranks of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmRankTier_sealed_update` BEFORE UPDATE ON `MlmRankTier` FOR EACH ROW BEGIN IF (SELECT `status` FROM `MlmPlanVersion` WHERE `id` = OLD.`planVersionId`) <> 'draft' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The ranks of an affiliate plan version cannot change once it has left draft'; END IF; END;
CREATE TRIGGER `MlmWalletEntry_no_delete` BEFORE DELETE ON `MlmWalletEntry` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A wallet entry is never deleted.'; END;
CREATE TRIGGER `MlmWalletEntry_no_update` BEFORE UPDATE ON `MlmWalletEntry` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A wallet entry is never changed.'; END;
CREATE TRIGGER `MlmWithdrawal_no_delete` BEFORE DELETE ON `MlmWithdrawal` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A withdrawal is never deleted.'; END;
CREATE TRIGGER `MlmWithdrawal_paid_final` BEFORE UPDATE ON `MlmWithdrawal` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (OLD.`status` = 'paid' AND NEW.`status` <> 'paid') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A paid withdrawal stays paid.'; END IF; END;
CREATE TRIGGER `PaymentGatewayConfig_active_ready_insert` BEFORE INSERT ON `PaymentGatewayConfig` FOR EACH ROW BEGIN IF NEW.`isActive` = 1 AND NOT EXISTS ( SELECT 1 FROM `PaymentGatewayCredential` c WHERE c.`provider` = NEW.`provider` AND c.`environment` = NEW.`environment` ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentGatewayConfig: only a configured gateway can be active'; END IF; END;
CREATE TRIGGER `PaymentGatewayConfig_active_ready_update` BEFORE UPDATE ON `PaymentGatewayConfig` FOR EACH ROW BEGIN IF NEW.`isActive` = 1 AND NOT EXISTS ( SELECT 1 FROM `PaymentGatewayCredential` c WHERE c.`provider` = NEW.`provider` AND c.`environment` = NEW.`environment` ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentGatewayConfig: only a configured gateway can be active'; END IF; END;
CREATE TRIGGER `PaymentGatewayConfig_no_delete` BEFORE DELETE ON `PaymentGatewayConfig` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentGatewayConfig: a gateway is disabled, never deleted'; END;
CREATE TRIGGER `PaymentGatewayCredential_fixed` BEFORE UPDATE ON `PaymentGatewayCredential` FOR EACH ROW BEGIN IF NEW.`provider` <> OLD.`provider` OR NEW.`environment` <> OLD.`environment` THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentGatewayCredential: provider and environment are fixed'; END IF; END;
CREATE TRIGGER `PaymentGatewayCredential_no_delete` BEFORE DELETE ON `PaymentGatewayCredential` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentGatewayCredential: credentials are replaced, never deleted'; END;
CREATE TRIGGER `PaymentMethod_fixed` BEFORE UPDATE ON `PaymentMethod` FOR EACH ROW BEGIN IF NOT (NEW.`provider` <=> OLD.`provider`) OR NOT (NEW.`providerMethodRef` <=> OLD.`providerMethodRef`) OR NOT (NEW.`kind` <=> OLD.`kind`) OR NOT (NEW.`brand` <=> OLD.`brand`) OR NOT (NEW.`last4` <=> OLD.`last4`) OR NOT (NEW.`tenantId` <=> OLD.`tenantId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A payment method is replaced, never rewritten'; END IF; END;
CREATE TRIGGER `PaymentMethod_no_delete` BEFORE DELETE ON `PaymentMethod` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment methods are removed, never deleted'; END;
CREATE TRIGGER `PaymentOrder_environment_fixed` BEFORE UPDATE ON `PaymentOrder` FOR EACH ROW BEGIN IF (NOT (NEW.`environment` <=> OLD.`environment`)) AND (NOT (NEW.`environment` <=> OLD.`environment`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentOrder: the environment an order was created in never changes'; END IF; END;
CREATE TRIGGER `PaymentOrder_invoice_gateway` BEFORE INSERT ON `PaymentOrder` FOR EACH ROW BEGIN IF EXISTS (SELECT 1 FROM `Invoice` i WHERE i.`id` = NEW.`invoiceId` AND i.`provider` IS NOT NULL AND i.`provider` <> NEW.`provider`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentOrder: an invoice is paid through the gateway it was started with'; END IF; END;
CREATE TRIGGER `PaymentOrder_matches_invoice` BEFORE INSERT ON `PaymentOrder` FOR EACH ROW BEGIN IF NOT EXISTS ( SELECT 1 FROM `Invoice` i WHERE i.`id` = NEW.`invoiceId` AND i.`tenantId` = NEW.`tenantId` AND i.`status` = 'open' AND i.`total` = NEW.`amount` AND i.`currency` = NEW.`currency` ) OR NEW.`status` <> 'created' OR NEW.`providerPaymentId` IS NOT NULL OR NEW.`paidAt` IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentOrder: an order is created for an open invoice of its academy, at exactly its total and currency'; END IF; END;
CREATE TRIGGER `PaymentOrder_no_delete` BEFORE DELETE ON `PaymentOrder` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentOrder: never deleted'; END;
CREATE TRIGGER `PaymentOrder_settles_once` BEFORE UPDATE ON `PaymentOrder` FOR EACH ROW BEGIN IF NEW.`id` <> OLD.`id` OR NEW.`tenantId` <> OLD.`tenantId` OR NEW.`invoiceId` <> OLD.`invoiceId` OR NEW.`provider` <> OLD.`provider` OR NEW.`providerOrderId` <> OLD.`providerOrderId` OR NEW.`amount` <> OLD.`amount` OR NEW.`currency` <> OLD.`currency` OR NEW.`createdAt` <> OLD.`createdAt` OR OLD.`status` <> 'created' OR NEW.`status` <> 'paid' OR NEW.`providerPaymentId` IS NULL OR NEW.`paidAt` IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PaymentOrder: fixed once made, and settles once — created to paid'; END IF; END;
CREATE TRIGGER `Payment_fixed` BEFORE UPDATE ON `Payment` FOR EACH ROW BEGIN IF NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`provider` <=> OLD.`provider`) OR NOT (NEW.`providerPaymentId` <=> OLD.`providerPaymentId`) OR NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`invoiceId` <=> OLD.`invoiceId`) OR NOT (NEW.`subscriptionId` <=> OLD.`subscriptionId`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A payment''s amount and references are never altered'; END IF; END;
CREATE TRIGGER `Payment_no_delete` BEFORE DELETE ON `Payment` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payments are never deleted'; END;
CREATE TRIGGER `Payment_same_tenant` BEFORE INSERT ON `Payment` FOR EACH ROW BEGIN IF NEW.`invoiceId` IS NOT NULL AND NOT (NEW.`tenantId` <=> (SELECT `tenantId` FROM `Invoice` WHERE `id` = NEW.`invoiceId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A payment belongs to its invoice''s academy'; END IF; END;
CREATE TRIGGER `Payment_settles_once` BEFORE UPDATE ON `Payment` FOR EACH ROW BEGIN IF OLD.`status` <> 'pending' OR NEW.`status` NOT IN ('paid', 'failed') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A settled payment is never updated'; END IF; END;
CREATE TRIGGER `PendingAccount_fixed_scope` BEFORE UPDATE ON `PendingAccount` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`role` <=> OLD.`role`) OR NOT (NEW.`email` <=> OLD.`email`)) AND (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`role` <=> OLD.`role`) OR NOT (NEW.`email` <=> OLD.`email`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A self-registration keeps its academy, role and address.'; END IF; END;
CREATE TRIGGER `PendingAccount_role` BEFORE INSERT ON `PendingAccount` FOR EACH ROW BEGIN IF NEW.`role` NOT IN ('student', 'instructor') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A self-registration is for a learner or an instructor.'; END IF; END;
CREATE TRIGGER `PlanChange_applied_with_event` BEFORE UPDATE ON `PlanChange` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NEW.`status` = 'applied' AND OLD.`status` <> 'applied' AND NOT EXISTS ( SELECT 1 FROM `SubscriptionEvent` e WHERE e.`id` = (SELECT max(`id`) FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`subscriptionId`) AND e.`transition` = 'change_plan' AND JSON_UNQUOTE(JSON_EXTRACT(e.`metaJson`, '$.planChangeId')) = NEW.`id` )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan change is applied only by the subscription''s change_plan transition'; END IF; END;
CREATE TRIGGER `PlanChange_consistent` BEFORE INSERT ON `PlanChange` FOR EACH ROW BEGIN IF NOT ((SELECT `planId` FROM `PlanVersion` WHERE `id` = NEW.`toPlanVersionId`) <=> NEW.`toPlanId`) OR NOT (NEW.`tenantId` <=> (SELECT `tenantId` FROM `Subscription` WHERE `id` = NEW.`subscriptionId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan change must name a version of its plan, in its subscription''s academy'; END IF; END;
CREATE TRIGGER `PlanChange_initial` BEFORE INSERT ON `PlanChange` FOR EACH ROW BEGIN IF NOT ( (NEW.`kind` IN ('upgrade', 'cycle_upgrade') AND NEW.`status` = 'pending_payment') OR (NEW.`kind` IN ('downgrade', 'scheduled_change') AND NEW.`status` = 'scheduled' AND NEW.`credit` = 0 AND NEW.`charge` = 0 AND NEW.`forfeited` = 0) ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan change starts awaiting payment (upgrades) or scheduled (everything else)'; END IF; END;
CREATE TRIGGER `PlanChange_no_delete` BEFORE DELETE ON `PlanChange` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Plan changes are never deleted'; END;
CREATE TRIGGER `PlanChange_quote_fixed` BEFORE UPDATE ON `PlanChange` FOR EACH ROW BEGIN IF (NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`subscriptionId` <=> OLD.`subscriptionId`) OR NOT (NEW.`kind` <=> OLD.`kind`) OR NOT (NEW.`fromPlanVersionId` <=> OLD.`fromPlanVersionId`) OR NOT (NEW.`fromCycle` <=> OLD.`fromCycle`) OR NOT (NEW.`fromAmount` <=> OLD.`fromAmount`) OR NOT (NEW.`toPlanId` <=> OLD.`toPlanId`) OR NOT (NEW.`toPlanVersionId` <=> OLD.`toPlanVersionId`) OR NOT (NEW.`toCycle` <=> OLD.`toCycle`) OR NOT (NEW.`toAmount` <=> OLD.`toAmount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`credit` <=> OLD.`credit`) OR NOT (NEW.`charge` <=> OLD.`charge`) OR NOT (NEW.`forfeited` <=> OLD.`forfeited`) OR NOT (NEW.`periodStartAt` <=> OLD.`periodStartAt`) OR NOT (NEW.`periodEndAt` <=> OLD.`periodEndAt`) OR NOT (NEW.`quotedAt` <=> OLD.`quotedAt`) OR NOT (NEW.`conflictsJson` <=> OLD.`conflictsJson`) OR NOT (NEW.`requestedById` <=> OLD.`requestedById`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`)) AND (NOT (NEW.`kind` <=> OLD.`kind`) OR NOT (NEW.`fromAmount` <=> OLD.`fromAmount`) OR NOT (NEW.`toAmount` <=> OLD.`toAmount`) OR NOT (NEW.`credit` <=> OLD.`credit`) OR NOT (NEW.`charge` <=> OLD.`charge`) OR NOT (NEW.`forfeited` <=> OLD.`forfeited`) OR NOT (NEW.`fromPlanVersionId` <=> OLD.`fromPlanVersionId`) OR NOT (NEW.`toPlanVersionId` <=> OLD.`toPlanVersionId`) OR NOT (NEW.`toPlanId` <=> OLD.`toPlanId`) OR NOT (NEW.`fromCycle` <=> OLD.`fromCycle`) OR NOT (NEW.`toCycle` <=> OLD.`toCycle`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`periodStartAt` <=> OLD.`periodStartAt`) OR NOT (NEW.`periodEndAt` <=> OLD.`periodEndAt`) OR NOT (NEW.`quotedAt` <=> OLD.`quotedAt`) OR NOT (NEW.`subscriptionId` <=> OLD.`subscriptionId`) OR NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`conflictsJson` <=> OLD.`conflictsJson`) OR NOT (NEW.`requestedById` <=> OLD.`requestedById`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan change quote is never altered'; END IF; END;
CREATE TRIGGER `PlanChange_status_path` BEFORE UPDATE ON `PlanChange` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NOT (NEW.`status` <=> OLD.`status`) AND NOT ( (OLD.`status` = 'pending_payment' AND NEW.`status` IN ('applied', 'canceled', 'void', 'expired')) OR (OLD.`status` = 'scheduled' AND NEW.`status` IN ('applied', 'canceled', 'void')) )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan change cannot move to that status'; END IF; END;
CREATE TRIGGER `PlanFeature_no_delete` BEFORE DELETE ON `PlanFeature` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanFeature rows are immutable and are never deleted'; END;
CREATE TRIGGER `PlanFeature_no_update` BEFORE UPDATE ON `PlanFeature` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanFeature rows are immutable: add a new plan version instead'; END;
CREATE TRIGGER `PlanFeature_sealed` BEFORE INSERT ON `PlanFeature` FOR EACH ROW BEGIN IF (SELECT count(*) FROM `PlanFeature` WHERE `planVersionId` = NEW.`planVersionId`) >= (SELECT `featureCount` FROM `PlanVersion` WHERE `id` = NEW.`planVersionId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This plan version already grants every feature it declared'; END IF; END;
CREATE TRIGGER `PlanLimit_no_delete` BEFORE DELETE ON `PlanLimit` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanLimit rows are immutable and are never deleted'; END;
CREATE TRIGGER `PlanLimit_no_update` BEFORE UPDATE ON `PlanLimit` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanLimit rows are immutable: add a new plan version instead'; END;
CREATE TRIGGER `PlanLimit_sealed` BEFORE INSERT ON `PlanLimit` FOR EACH ROW BEGIN IF (SELECT count(*) FROM `PlanLimit` WHERE `planVersionId` = NEW.`planVersionId`) >= (SELECT `limitCount` FROM `PlanVersion` WHERE `id` = NEW.`planVersionId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This plan version already sets every limit it declared'; END IF; END;
CREATE TRIGGER `PlanVersion_no_delete` BEFORE DELETE ON `PlanVersion` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanVersion rows are immutable and are never deleted'; END;
CREATE TRIGGER `PlanVersion_no_update` BEFORE UPDATE ON `PlanVersion` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PlanVersion rows are immutable: add a new version instead'; END;
CREATE TRIGGER `Plan_code_fixed` BEFORE UPDATE ON `Plan` FOR EACH ROW BEGIN IF (NOT (NEW.`code` <=> OLD.`code`)) AND (OLD.`status` <> 'draft' AND NEW.`code` <> OLD.`code`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A plan code cannot change once the plan has left draft'; END IF; END;
CREATE TRIGGER `Refund_fixed` BEFORE UPDATE ON `Refund` FOR EACH ROW BEGIN IF NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`paymentId` <=> OLD.`paymentId`) OR NOT (NEW.`tenantId` <=> OLD.`tenantId`) OR NOT (NEW.`reason` <=> OLD.`reason`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`) OR NOT (NEW.`requestedById` <=> OLD.`requestedById`) OR OLD.`status` <> 'pending' OR NEW.`status` NOT IN ('succeeded', 'failed') OR (OLD.`providerRefundId` IS NOT NULL AND NOT (NEW.`providerRefundId` <=> OLD.`providerRefundId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A refund settles once and is otherwise never altered'; END IF; END;
CREATE TRIGGER `Refund_no_delete` BEFORE DELETE ON `Refund` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Refunds are never deleted'; END;
CREATE TRIGGER `Refund_within_payment` BEFORE INSERT ON `Refund` FOR EACH ROW BEGIN IF NEW.`status` <> 'pending' OR NOT ((SELECT `status` FROM `Payment` WHERE `id` = NEW.`paymentId`) <=> 'paid') OR NOT ((SELECT `currency` FROM `Payment` WHERE `id` = NEW.`paymentId`) <=> NEW.`currency`) OR NOT ((SELECT `tenantId` FROM `Payment` WHERE `id` = NEW.`paymentId`) <=> NEW.`tenantId`) OR NEW.`amount` + IFNULL((SELECT sum(`amount`) FROM `Refund` WHERE `paymentId` = NEW.`paymentId` AND `status` <> 'failed'), 0) > (SELECT `amount` FROM `Payment` WHERE `id` = NEW.`paymentId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A refund is against a paid payment and never more than is left of it'; END IF; END;
CREATE TRIGGER `SubscriptionEvent_create` BEFORE INSERT ON `SubscriptionEvent` FOR EACH ROW BEGIN IF NEW.`transition` = 'create' AND ( NEW.`fromStatus` IS NOT NULL OR NOT (NEW.`toStatus` <=> (SELECT `status` FROM `Subscription` WHERE `id` = NEW.`subscriptionId`)) OR EXISTS (SELECT 1 FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`subscriptionId`) ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A subscription is created once, in the status it starts in'; END IF; END;
CREATE TRIGGER `SubscriptionEvent_no_delete` BEFORE DELETE ON `SubscriptionEvent` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lifecycle events are never deleted'; END;
CREATE TRIGGER `SubscriptionEvent_no_update` BEFORE UPDATE ON `SubscriptionEvent` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lifecycle events are immutable'; END;
CREATE TRIGGER `SubscriptionEvent_same_tenant` BEFORE INSERT ON `SubscriptionEvent` FOR EACH ROW BEGIN IF NOT (NEW.`tenantId` <=> (SELECT `tenantId` FROM `Subscription` WHERE `id` = NEW.`subscriptionId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A lifecycle event belongs to its subscription''s academy'; END IF; END;
CREATE TRIGGER `SubscriptionEvent_transition` BEFORE INSERT ON `SubscriptionEvent` FOR EACH ROW BEGIN IF NEW.`transition` <> 'create' AND ( NOT (NEW.`fromStatus` <=> (SELECT `status` FROM `Subscription` WHERE `id` = NEW.`subscriptionId`)) OR NOT ((NEW.`fromStatus` = 'trialing' AND NEW.`toStatus` = 'active') OR (NEW.`fromStatus` = 'active' AND NEW.`toStatus` = 'active') OR (NEW.`fromStatus` = 'past_due' AND NEW.`toStatus` = 'active') OR (NEW.`fromStatus` = 'trialing' AND NEW.`toStatus` = 'past_due') OR (NEW.`fromStatus` = 'active' AND NEW.`toStatus` = 'past_due') OR (NEW.`fromStatus` = 'past_due' AND NEW.`toStatus` = 'past_due') OR (NEW.`fromStatus` = 'trialing' AND NEW.`toStatus` = 'expired') OR (NEW.`fromStatus` = 'active' AND NEW.`toStatus` = 'canceling') OR (NEW.`fromStatus` = 'trialing' AND NEW.`toStatus` = 'canceled') OR (NEW.`fromStatus` = 'active' AND NEW.`toStatus` = 'canceled') OR (NEW.`fromStatus` = 'past_due' AND NEW.`toStatus` = 'canceled') OR (NEW.`fromStatus` = 'paused' AND NEW.`toStatus` = 'canceled') OR (NEW.`fromStatus` = 'canceling' AND NEW.`toStatus` = 'canceled') OR (NEW.`fromStatus` = 'canceling' AND NEW.`toStatus` = 'active') OR (NEW.`fromStatus` = 'paused' AND NEW.`toStatus` = 'active') OR (NEW.`fromStatus` = 'active' AND NEW.`toStatus` = 'paused') OR (NEW.`fromStatus` = 'past_due' AND NEW.`toStatus` = 'expired') OR (NEW.`fromStatus` = 'trialing' AND NEW.`toStatus` = 'trialing')) ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'That is not an allowed subscription transition'; END IF; END;
CREATE TRIGGER `Subscription_from_invoice` BEFORE INSERT ON `Subscription` FOR EACH ROW BEGIN IF NEW.`sourceInvoiceId` IS NOT NULL AND ( NEW.`status` <> 'active' OR NOT EXISTS ( SELECT 1 FROM `Invoice` i WHERE i.`id` = NEW.`sourceInvoiceId` AND i.`tenantId` = NEW.`tenantId` AND i.`purpose` = 'new_subscription' AND i.`status` = 'paid' AND i.`planVersionId` = NEW.`planVersionId` AND i.`billingCycle` = NEW.`billingCycle` AND i.`currency` = NEW.`currency` ) ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A purchased subscription is created only from its paid first-purchase invoice, for exactly what it sold'; END IF; END;
CREATE TRIGGER `Subscription_grace_by_transition` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`gracePeriodStartAt` <=> OLD.`gracePeriodStartAt`) OR NOT (NEW.`gracePeriodEndAt` <=> OLD.`gracePeriodEndAt`)) AND (NEW.`gracePeriodEndAt` IS NOT NULL AND (NOT (NEW.`gracePeriodEndAt` <=> OLD.`gracePeriodEndAt`) OR NOT (NEW.`gracePeriodStartAt` <=> OLD.`gracePeriodStartAt`)) AND NOT EXISTS ( SELECT 1 FROM `SubscriptionEvent` e WHERE e.`id` = (SELECT max(`id`) FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`id`) AND e.`transition` = 'grace_started' AND CAST(JSON_EXTRACT(e.`metaJson`, '$.graceEndsAtMs') AS UNSIGNED) = TIMESTAMPDIFF(MICROSECOND, '1970-01-01 00:00:00', NEW.`gracePeriodEndAt`) DIV 1000 )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A grace period is set only by the grace_started transition'; END IF; END;
CREATE TRIGGER `Subscription_initial_status` BEFORE INSERT ON `Subscription` FOR EACH ROW BEGIN IF NEW.`status` NOT IN ('trialing', 'active') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A subscription starts as trialing or active'; END IF; END;
CREATE TRIGGER `Subscription_no_delete` BEFORE DELETE ON `Subscription` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Subscriptions are never deleted'; END;
CREATE TRIGGER `Subscription_period_by_transition` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`currentPeriodStartAt` <=> OLD.`currentPeriodStartAt`) OR NOT (NEW.`currentPeriodEndAt` <=> OLD.`currentPeriodEndAt`)) AND ((NOT (NEW.`currentPeriodStartAt` <=> OLD.`currentPeriodStartAt`) OR NOT (NEW.`currentPeriodEndAt` <=> OLD.`currentPeriodEndAt`)) AND NOT EXISTS ( SELECT 1 FROM `SubscriptionEvent` e WHERE e.`id` = (SELECT max(`id`) FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`id`) AND CAST(JSON_EXTRACT(e.`metaJson`, '$.period.startMs') AS UNSIGNED) = TIMESTAMPDIFF(MICROSECOND, '1970-01-01 00:00:00', NEW.`currentPeriodStartAt`) DIV 1000 AND CAST(JSON_EXTRACT(e.`metaJson`, '$.period.endMs') AS UNSIGNED) = TIMESTAMPDIFF(MICROSECOND, '1970-01-01 00:00:00', NEW.`currentPeriodEndAt`) DIV 1000 )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A subscription''s period dates change only through a recorded transition'; END IF; END;
CREATE TRIGGER `Subscription_source_fixed` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`sourceInvoiceId` <=> OLD.`sourceInvoiceId`)) AND (NOT (NEW.`sourceInvoiceId` <=> OLD.`sourceInvoiceId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The invoice a subscription came from never changes'; END IF; END;
CREATE TRIGGER `Subscription_status_by_transition` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`status` <=> OLD.`status`)) AND (NEW.`status` <> OLD.`status` AND NOT EXISTS ( SELECT 1 FROM `SubscriptionEvent` e WHERE e.`id` = (SELECT max(`id`) FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`id`) AND e.`fromStatus` = OLD.`status` AND e.`toStatus` = NEW.`status` )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A subscription status changes only through a recorded transition'; END IF; END;
CREATE TRIGGER `Subscription_terms_by_transition` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`planId` <=> OLD.`planId`) OR NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`billingCycle` <=> OLD.`billingCycle`)) AND ((NOT (NEW.`planVersionId` <=> OLD.`planVersionId`) OR NOT (NEW.`amount` <=> OLD.`amount`) OR NOT (NEW.`currency` <=> OLD.`currency`) OR NOT (NEW.`billingCycle` <=> OLD.`billingCycle`)) AND NOT EXISTS ( SELECT 1 FROM `SubscriptionEvent` e WHERE e.`id` = (SELECT max(`id`) FROM `SubscriptionEvent` WHERE `subscriptionId` = NEW.`id`) AND e.`transition` = 'change_plan' AND JSON_UNQUOTE(JSON_EXTRACT(e.`metaJson`, '$.to.planVersionId')) = NEW.`planVersionId` AND JSON_UNQUOTE(JSON_EXTRACT(e.`metaJson`, '$.to.amount')) = NEW.`amount` AND JSON_UNQUOTE(JSON_EXTRACT(e.`metaJson`, '$.to.currency')) = NEW.`currency` AND JSON_UNQUOTE(JSON_EXTRACT(e.`metaJson`, '$.to.billingCycle')) = NEW.`billingCycle` )) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A subscription''s plan and price change only through a recorded plan change'; END IF; END;
CREATE TRIGGER `Subscription_trial_fixed` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`trialStartAt` <=> OLD.`trialStartAt`) OR NOT (NEW.`trialEndAt` <=> OLD.`trialEndAt`)) AND (NOT (NEW.`trialStartAt` <=> OLD.`trialStartAt`) OR NOT (NEW.`trialEndAt` <=> OLD.`trialEndAt`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A trial''s dates are fixed when it starts'; END IF; END;
CREATE TRIGGER `Subscription_version_of_plan_insert` BEFORE INSERT ON `Subscription` FOR EACH ROW BEGIN IF NOT ((SELECT `planId` FROM `PlanVersion` WHERE `id` = NEW.`planVersionId`) <=> NEW.`planId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The plan version does not belong to the plan'; END IF; END;
CREATE TRIGGER `Subscription_version_of_plan_update` BEFORE UPDATE ON `Subscription` FOR EACH ROW BEGIN IF (NOT (NEW.`planId` <=> OLD.`planId`) OR NOT (NEW.`planVersionId` <=> OLD.`planVersionId`)) AND (NOT ((SELECT `planId` FROM `PlanVersion` WHERE `id` = NEW.`planVersionId`) <=> NEW.`planId`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The plan version does not belong to the plan'; END IF; END;
CREATE TRIGGER `TaxRuleComponent_no_delete` BEFORE DELETE ON `TaxRuleComponent` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tax rule components are never deleted'; END;
CREATE TRIGGER `TaxRuleComponent_no_update` BEFORE UPDATE ON `TaxRuleComponent` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tax rule components are never altered'; END;
CREATE TRIGGER `TaxRuleComponent_sealed` BEFORE INSERT ON `TaxRuleComponent` FOR EACH ROW BEGIN IF (SELECT count(*) FROM `TaxRuleComponent` WHERE `ruleId` = NEW.`ruleId`) >= (SELECT `componentCount` FROM `TaxRule` WHERE `id` = NEW.`ruleId`) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This tax rule already has every component it declared'; END IF; END;
CREATE TRIGGER `TaxRule_fixed` BEFORE UPDATE ON `TaxRule` FOR EACH ROW BEGIN IF NOT (NEW.`name` <=> OLD.`name`) OR NOT (NEW.`country` <=> OLD.`country`) OR NOT (NEW.`region` <=> OLD.`region`) OR NOT (NEW.`inclusive` <=> OLD.`inclusive`) OR NOT (NEW.`componentCount` <=> OLD.`componentCount`) OR NOT (NEW.`createdAt` <=> OLD.`createdAt`) OR (OLD.`retiredAt` IS NOT NULL AND NOT (NEW.`retiredAt` <=> OLD.`retiredAt`)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A tax rule is never altered: retire it and add a new one'; END IF; END;
CREATE TRIGGER `TaxRule_no_delete` BEFORE DELETE ON `TaxRule` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tax rules are never deleted'; END;
CREATE TRIGGER `WebhookEvent_no_delete` BEFORE DELETE ON `WebhookEvent` FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WebhookEvent: never deleted'; END;
CREATE TRIGGER `WebhookEvent_receipt` BEFORE UPDATE ON `WebhookEvent` FOR EACH ROW BEGIN IF NEW.`id` <> OLD.`id` OR NEW.`provider` <> OLD.`provider` OR NEW.`providerEventId` <> OLD.`providerEventId` OR NEW.`eventType` <> OLD.`eventType` OR NEW.`payloadHash` <> OLD.`payloadHash` OR NEW.`receivedAt` <> OLD.`receivedAt` OR OLD.`status` IN ('processed', 'ignored') OR NEW.`attempts` < OLD.`attempts` THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WebhookEvent: the receipt is fixed, and a processed or ignored event is final'; END IF; END;
CREATE TRIGGER `Affiliate_chk_4_i` BEFORE INSERT ON `Affiliate` FOR EACH ROW BEGIN IF ((NEW.`placementParentId` IS NULL) = (NEW.`placementLeg` IS NULL)) IS FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check failed: Affiliate_chk_4'; END IF; END;
CREATE TRIGGER `Affiliate_chk_4_u` BEFORE UPDATE ON `Affiliate` FOR EACH ROW BEGIN IF ((NEW.`placementParentId` IS NULL) = (NEW.`placementLeg` IS NULL)) IS FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check failed: Affiliate_chk_4'; END IF; END;
CREATE TRIGGER `Affiliate_chk_7_i` BEFORE INSERT ON `Affiliate` FOR EACH ROW BEGIN IF (NOT (NEW.`placementParentId` <=> NEW.`id`) AND NOT (NEW.`sponsorId` <=> NEW.`id`)) IS FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check failed: Affiliate_chk_7'; END IF; END;
CREATE TRIGGER `Affiliate_chk_7_u` BEFORE UPDATE ON `Affiliate` FOR EACH ROW BEGIN IF (NOT (NEW.`placementParentId` <=> NEW.`id`) AND NOT (NEW.`sponsorId` <=> NEW.`id`)) IS FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Check failed: Affiliate_chk_7'; END IF; END;

-- ─── The rows the old migrations created ────────────────────────────────────
-- The platform's one workspace (docs/16, D-PLAT-01).
INSERT INTO `Tenant` (`id`, `name`, `slug`, `status`, `createdAt`, `updatedAt`) VALUES ('tenant-1', 'ZuviloAI', 'default', 'active', CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));
