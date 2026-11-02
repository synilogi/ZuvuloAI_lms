-- The leg a sponsor's share link named (`?leg=A|B`), separate from `preferredLeg`, which says where the member's own
-- future referrals go. Held on the pending registration until its code is confirmed, then on the affiliate so that the
-- scheduler's catch-up (`mlm-placement`) places the member on the same leg. Null: the link named none, so placement
-- uses the sponsor's preferred leg.
ALTER TABLE "PendingAccount" ADD COLUMN "requestedLeg" TEXT;
ALTER TABLE "Affiliate" ADD COLUMN "requestedLeg" TEXT;
