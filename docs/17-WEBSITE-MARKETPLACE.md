# 17. The public website's marketplace

The public website as a course marketplace: a home page built from the platform's own records, course bundles, a mentor directory,
a blog, and Super Admin management of what shows. It extends `docs/16` §2.6.

## Rules

- **Nothing invented.** Figures are counted from the records when asked for (`GET /public/stats`) and cannot be typed in, only hidden.
  Courses, bundles, categories and mentors are read from their tables. Testimonials start empty, and a section with nothing real to
  show stays off the page.
- **No income promises.** The affiliate section describes how the program works and always carries the note that income is never
  guaranteed (D-PLAT-13).
- **No contact details.** `GET /public/mentors` returns no email, phone or account detail.

## Decisions

| ID | Decision |
| --- | --- |
| D-WEB-01 | The brand stays ZuviloAI. The brief named ShubhLMS; the owner confirmed ZuviloAI on 2 Nov 2026. |
| D-WEB-02 | A bundle earns no affiliate volume, and cannot hold a course on the active plan. The owner chose this on 2 Nov 2026. |
| D-WEB-03 | The reference site blocks automated visits, so the design follows the section list in the owner's brief. It was not compared with the live site. |
| D-WEB-04 | Coupons apply to single courses. A bundle is already priced as a package, and a coupon redemption needs one purchase to point at. |
| D-WEB-05 | "Add to cart" is not built: Buy now is the only purchase path, for a course or a bundle. |

## Course bundles

A bundle is several published, listed, paid courses at one price, in whole rupees. It is on sale while it is published, past its
`publishAt`, holds at least two courses, and every course still qualifies. A bundle that stops qualifying, because a course was
unpublished or joined the affiliate plan, leaves the website and refuses new orders by itself.

### Buying one (`lib/bundlePurchases.ts`)

`BundlePurchase` holds the gateway order and payment. Its amount, learner, bundle and courses are fixed when the order is made, by
trigger. On payment each course gets a child `CoursePurchase` with provider `bundle` and its share of the charge, split by list price
so the shares add up to exactly the charge (`allocateByWeight`). The rule that an enrolment in a paid course needs a paid purchase of
that course (`Enrollment_purchase_paid_*`) therefore still holds, and sales figures and receipts read as usual.

The tenancy checks read committed rows, so settling happens in two steps:

1. The children are committed, unpaid. Any open single-course order for those courses is closed first.
2. One transaction claims the payment, marks the children paid and opens the enrolments.

A crash between them leaves an unpaid order that the next check settles, and existing children are reused rather than re-divided. As
with a single course, only the gateway's own answer opens anything. The confirmation, the webhook, a status check and the recovery
job can all bring the same payment, and it settles once.

A course the learner already has is skipped when the order is divided, and the whole charge is shared across the others. If they
have every course, the order is refused. If they gain one after the division, that share is flagged for review.

### Affiliate volume

Three things keep a bundle out of the affiliate program: saving a bundle refuses an eligible course, no purchase hook runs for a
child, and `recordMlmOrder` and the repair job both skip anything with a `bundlePurchaseId`.

### Refunds

A refund is always the whole order. Starting one from any of the bundle's course orders (`refundCoursePurchase`) refunds the bundle's
payment and closes every course it opened. A refusal changes nothing and can be retried; no clear answer leaves it pending for a
person to check. The gateway's refund and chargeback webhooks are handled the same way as for a single course, except that no volume
needs reversing.

**Known limit:** an order paid when the learner already held every course has no child orders, so it does not appear in the Super
Admin's order list. It raises `payment.unmatched`, carries a `reviewReason` on `BundlePurchase`, and has to be refunded at the gateway.

## Website content

The `SiteContent` document grew new fields. A document saved earlier still reads correctly: missing fields take their defaults, and
`orderedSections` adds any section it does not know yet. `GET /public/site` removes testimonials and banners that are switched off or
outside their dates; the Super Admin's read keeps them.

Images: an upload is private until `POST /superadmin/sales/site/images` places it on the website. `GET /public/images/:id` serves only
placed images and active instructors' photos. Everything else is the same 404, so course material and learners' hand-ins stay behind
the session.

Links in the document must be `https://` or a path on this site, so nothing saved can run code when clicked.

## Pages and routes

| Address | What it is |
| --- | --- |
| `/`, `/welcome` | The home page. Sections in the order the Super Admin set |
| `/bundles`, `/bundles/:slug` | Bundle listing and bundle page, with checkout |
| `/mentors`, `/mentors/:id` | Mentor directory and profile |
| `/blog`, `/blog/:slug` | Blog and resources, filterable by kind |
| `/superadmin/website` | Hero, sections, figures, picks, banners, stories, questions, footer, social links, search text |
| `/superadmin/website/posts` | Posts, with drafts and scheduling |
| `/superadmin/sales/bundles` | Bundles, with drafts, scheduling and archiving |

## Migration

`20261102120000_website_marketplace` is additive: new tables and one nullable column on `CoursePurchase`. No existing row changes.
`deploy.sh` applies it. The Prisma client must be regenerated with it, since every course purchase now reads the new column.

## After deploying

- A saved `SiteContent` row keeps its old headline, since the document is the owner's. The new default headline shows only where
  nothing was saved; change it at `/superadmin/website`.
- Categories come from the records. The ten subjects named in the brief are not created automatically: an empty category would be a
  dead end, so the home page hides any category with no courses. Add them at `/admin/categories` as courses are ready.
- A bundle needs at least two paid courses outside the affiliate plan.

## Not covered

The Flutter app is unchanged and does not show bundles or the blog. A bundle bought on the website opens its courses there as usual.
Live Razorpay was not exercised; bundle checkout was tested through the sandbox gateway and a fake provider.
