-- Daily counts of public page views (docs/19). Additive: one new table.
CREATE TABLE `SiteMetricDay` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `day` VARCHAR(10) NOT NULL,
    `path` VARCHAR(191) NOT NULL,
    `count` INTEGER NOT NULL DEFAULT 0,

    INDEX `SiteMetricDay_day_idx`(`day`),
    UNIQUE INDEX `SiteMetricDay_tenantId_day_path_key`(`tenantId`, `day`, `path`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `SiteMetricDay` ADD CONSTRAINT `SiteMetricDay_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `Tenant`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
