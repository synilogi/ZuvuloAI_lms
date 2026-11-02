import type { ReactNode } from 'react';
import {
  ChatCircleText,
  Megaphone,
  Handshake,
  Tray,
  PaintBrush,
  BookOpenText,
  CalendarBlank,
  Certificate,
  ChartLineUp,
  ChalkboardTeacher,
  ClipboardText,
  ClockCounterClockwise,
  CreditCard,
  IdentificationCard,
  Pulse,
  Question,
  Compass,
  Exam,
  GearSix,
  Globe,
  House,
  ShieldStar,
  SquaresFour,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';

export interface NavLeaf {
  label: string;
  to: string;
}

export interface NavItem {
  id: string;
  label: string;
  /** Label for the mobile bottom bar, where space allows one short word. */
  short?: string;
  icon: ReactNode;
  to: string;
  /** The tone of the badge when `shell/NavCounts` has a real count for this item. `danger` is the live marker. */
  countTone?: Tone;
  children?: NavLeaf[];
  /** Other paths that belong to this destination, e.g. a lesson inside My learning. */
  also?: string[];
}

export interface NavGroup {
  id: string;
  label?: string;
  items: NavItem[];
}

const I = (Icon: typeof House) => <Icon size={19} />;

/**
 * Navigation per role. Students see a short, flat list; instructors and admins get grouped,
 * nested areas that open on demand. Counts are the only live data in the nav.
 */
export const navigation: Record<Role, NavGroup[]> = {
  student: [
    { id: 'home', items: [{ id: 'home', label: 'Home', icon: I(House), to: '/home' }] },
    {
      id: 'learn',
      label: 'My study',
      items: [
        { id: 'explore', label: 'Browse courses', short: 'Browse', icon: I(Compass), to: '/explore' },
        {
          id: 'my-learning',
          label: 'My courses',
          short: 'Courses',
          icon: I(BookOpenText),
          to: '/my-learning',
          also: ['/learn'],
          children: [
            { label: 'In progress', to: '/my-learning/in-progress' },
            { label: 'Completed', to: '/my-learning/completed' },
            { label: 'Saved', to: '/my-learning/saved' },
          ],
        },
        { id: 'live', label: 'Live classes', short: 'Live', icon: I(VideoCamera), to: '/live', countTone: 'danger' },
        { id: 'assignments', label: 'Assignments', icon: I(ClipboardText), to: '/assignments' },
        { id: 'assessments', label: 'Tests', icon: I(Exam), to: '/assessments' },
        { id: 'certificates', label: 'Certificates', icon: I(Certificate), to: '/certificates' },
      ],
    },
    // The affiliate program (MLM-001): the learner's referral link, team and, module by module, earnings and wallet.
    {
      id: 'earn',
      label: 'Earn',
      items: [
        {
          id: 'affiliate',
          label: 'Affiliate program',
          short: 'Affiliate',
          icon: I(Handshake),
          to: '/affiliate',
          children: [
            { label: 'Overview', to: '/affiliate' },
            { label: 'My team', to: '/affiliate/tree' },
            { label: 'Team list', to: '/affiliate/team' },
            { label: 'Volume', to: '/affiliate/volume' },
          ],
        },
      ],
    },
    { id: 'support', label: 'Support', items: [{ id: 'help', label: 'Help', icon: I(Question), to: '/help' }] },
  ],
  instructor: [
    { id: 'overview', items: [{ id: 'overview', label: 'Overview', icon: I(SquaresFour), to: '/teach' }] },
    {
      id: 'teach',
      label: 'Teach',
      items: [
        { id: 'courses', label: 'My courses', short: 'Courses', icon: I(BookOpenText), to: '/teach/courses' },
        { id: 'course-sales', label: 'Course sales', short: 'Sales', icon: I(ChartLineUp), to: '/teach/course-sales' },
        { id: 'reports', label: 'Performance', icon: I(ChartLineUp), to: '/teach/reports' },
        { id: 'reviews', label: 'Reviews', icon: I(ChatCircleText), to: '/teach/reviews' },
        { id: 'quizzes', label: 'Tests & quizzes', short: 'Tests', icon: I(Exam), to: '/teach/quizzes' },
        { id: 'assignments', label: 'Assignments', short: 'Marking', icon: I(ClipboardText), to: '/teach/assignments', countTone: 'warn' },
        { id: 'live', label: 'Live classes', short: 'Live', icon: I(VideoCamera), to: '/teach/live', countTone: 'danger' },
      ],
    },
    {
      id: 'people',
      label: 'Students & schedule',
      items: [
        { id: 'students', label: 'My students', short: 'Students', icon: I(UsersThree), to: '/teach/students' },
        { id: 'calendar', label: 'Calendar', icon: I(CalendarBlank), to: '/teach/calendar' },
        { id: 'help', label: 'Help', icon: I(Question), to: '/teach/help' },
      ],
    },
  ],
  // The staff admin (docs/16, D-PLAT-03): the platform's courses, people, reports and settings, as far as its
  // permissions reach.
  admin: [
    { id: 'dashboard', items: [{ id: 'dashboard', label: 'Dashboard', icon: I(SquaresFour), to: '/admin' }] },
    {
      id: 'catalog',
      label: 'Catalog',
      items: [
        {
          id: 'courses',
          label: 'Courses',
          icon: I(BookOpenText),
          to: '/admin/courses',
          children: [
            { label: 'All courses', to: '/admin/courses' },
            { label: 'Categories', to: '/admin/categories' },
          ],
        },
        { id: 'quizzes', label: 'Quizzes', icon: I(Exam), to: '/admin/quizzes' },
        { id: 'assignments', label: 'Assignments', icon: I(ClipboardText), to: '/admin/assignments', countTone: 'warn' },
        { id: 'live', label: 'Live classes', short: 'Live', icon: I(VideoCamera), to: '/admin/live', countTone: 'danger' },
        {
          id: 'certificates',
          label: 'Certificates',
          icon: I(Certificate),
          to: '/admin/certificates',
          children: [
            { label: 'Issued', to: '/admin/certificates' },
            { label: 'Templates', to: '/admin/certificates/templates' },
          ],
        },
      ],
    },
    {
      id: 'people',
      label: 'People',
      items: [
        { id: 'students', label: 'Students', icon: I(UsersThree), to: '/admin/students' },
        { id: 'instructors', label: 'Instructors', icon: I(ChalkboardTeacher), to: '/admin/instructors' },
      ],
    },
    {
      id: 'insight',
      label: 'Insight',
      items: [
        { id: 'reports', label: 'Reports', icon: I(ChartLineUp), to: '/admin/reports' },
        { id: 'reviews', label: 'Reviews', icon: I(ChatCircleText), to: '/admin/reviews' },
        { id: 'calendar', label: 'Calendar', icon: I(CalendarBlank), to: '/admin/calendar' },
        {
          id: 'settings',
          label: 'Settings',
          icon: I(GearSix),
          to: '/admin/settings',
          children: [
            { label: 'General', to: '/admin/settings/general' },
            { label: 'Courses', to: '/admin/settings/courses' },
            { label: 'Learning', to: '/admin/settings/learning' },
            { label: 'Certificates', to: '/admin/settings/certificates' },
            { label: 'Notifications', to: '/admin/settings/notifications' },
          ],
        },
        { id: 'help', label: 'Help Centre', icon: I(Question), to: '/admin/help' },
      ],
    },
  ],
  // The platform's owner (docs/16 §2.2). What only the owner does lives under /superadmin; the courses, people and
  // settings of the workspace are the same screens the staff admin uses, under /admin.
  superadmin: [
    { id: 'platform', items: [{ id: 'platform', label: 'Dashboard', icon: I(ShieldStar), to: '/superadmin' }] },
    {
      id: 'workspace',
      label: 'Workspace',
      items: [
        {
          id: 'workspace-courses',
          label: 'Courses',
          icon: I(BookOpenText),
          to: '/admin/courses',
          children: [
            { label: 'All courses', to: '/admin/courses' },
            { label: 'Categories', to: '/admin/categories' },
            { label: 'Quizzes', to: '/admin/quizzes' },
            { label: 'Assignments', to: '/admin/assignments' },
            { label: 'Live classes', to: '/admin/live' },
            { label: 'Certificates', to: '/admin/certificates' },
          ],
        },
        { id: 'workspace-students', label: 'Students', icon: I(UsersThree), to: '/admin/students' },
        { id: 'workspace-instructors', label: 'Instructors', icon: I(ChalkboardTeacher), to: '/admin/instructors' },
        { id: 'workspace-reports', label: 'Reports', icon: I(ChartLineUp), to: '/admin/reports' },
        { id: 'workspace-reviews', label: 'Reviews', icon: I(ChatCircleText), to: '/admin/reviews' },
        { id: 'workspace-settings', label: 'Platform settings', short: 'Settings', icon: I(GearSix), to: '/admin/settings' },
      ],
    },
    {
      id: 'accounts',
      label: 'Accounts',
      items: [
        // Staff admin accounts, each limited by the permission catalogue.
        { id: 'platform-admins', label: 'Admin users', short: 'Admins', icon: I(IdentificationCard), to: '/superadmin/admins' },
        { id: 'platform-users', label: 'All users', short: 'Users', icon: I(UsersThree), to: '/superadmin/users' },
      ],
    },
    {
      id: 'sales',
      label: 'Sales',
      items: [
        // The platform's gateway: course money settles here (docs/16, D-PLAT-07).
        {
          id: 'platform-sales',
          label: 'Orders & payments',
          short: 'Sales',
          icon: I(CreditCard),
          to: '/superadmin/sales/orders',
          children: [
            { label: 'Orders', to: '/superadmin/sales/orders' },
            { label: 'Course bundles', to: '/superadmin/sales/bundles' },
            { label: 'Coupons', to: '/superadmin/sales/coupons' },
            { label: 'Payment events', to: '/superadmin/sales/events' },
            { label: 'Payment setup', to: '/superadmin/payment-gateways' },
          ],
        },
      ],
    },
    {
      id: 'affiliates',
      label: 'Affiliates',
      items: [
        // The affiliate program (docs/15): its plan, and — module by module — members, network, ledgers, wallets and payouts.
        {
          id: 'platform-affiliates',
          label: 'Affiliate program',
          short: 'Affiliates',
          icon: I(Handshake),
          to: '/superadmin/affiliates/overview',
          children: [
            { label: 'Overview', to: '/superadmin/affiliates/overview' },
            { label: 'Members', to: '/superadmin/affiliates/members' },
            { label: 'Network', to: '/superadmin/affiliates/network' },
            { label: 'Sponsors', to: '/superadmin/affiliates/sponsors' },
            { label: 'Placements', to: '/superadmin/affiliates/placements' },
            { label: 'Orders', to: '/superadmin/affiliates/orders' },
            { label: 'Ledgers', to: '/superadmin/affiliates/ledgers' },
            { label: 'Matching', to: '/superadmin/affiliates/matching' },
            { label: 'Ranks', to: '/superadmin/affiliates/ranks' },
            { label: 'Rewards', to: '/superadmin/affiliates/rewards' },
            { label: 'Wallets', to: '/superadmin/affiliates/wallets' },
            { label: 'Withdrawals', to: '/superadmin/affiliates/withdrawals' },
            { label: 'Identity checks', to: '/superadmin/affiliates/kyc' },
            { label: 'Courses', to: '/superadmin/affiliates/products' },
            { label: 'Plan', to: '/superadmin/affiliates/plan' },
            { label: 'Activity', to: '/superadmin/audit?prefix=mlm.' },
          ],
        },
      ],
    },
    {
      id: 'platform-tools',
      label: 'Platform',
      items: [
        // Contact and support requests from the website.
        {
          id: 'platform-website',
          label: 'Website',
          icon: I(Globe),
          to: '/superadmin/website',
          children: [
            { label: 'Home page and content', to: '/superadmin/website' },
            { label: 'Blog and resources', to: '/superadmin/website/posts' },
            { label: 'Visitors', to: '/superadmin/website/visitors' },
          ],
        },
        { id: 'platform-inbox', label: 'Inbox', icon: I(Tray), to: '/superadmin/inquiries' },
        { id: 'platform-notifications', label: 'Notifications', icon: I(Megaphone), to: '/superadmin/notifications' },
        { id: 'platform-audit', label: 'Activity log', short: 'Activity', icon: I(ClockCounterClockwise), to: '/superadmin/audit' },
        { id: 'platform-system', label: 'System health', short: 'System', icon: I(Pulse), to: '/superadmin/system' },
        { id: 'platform-branding', label: 'Logo & branding', short: 'Branding', icon: I(PaintBrush), to: '/superadmin/branding' },
      ],
    },
  ],
};

/** Primary destinations for the mobile bottom bar — four plus More. */
export const bottomDestinations: Record<Role, string[]> = {
  student: ['home', 'explore', 'my-learning', 'live'],
  instructor: ['overview', 'courses', 'assignments', 'live'],
  admin: ['dashboard', 'courses', 'students', 'reports'],
  superadmin: ['platform', 'workspace-courses', 'platform-sales', 'platform-inbox'],
};

export const workspaceLabel: Record<Role, string> = {
  student: 'Learning',
  instructor: 'Instructor',
  admin: 'Admin',
  superadmin: 'Platform owner',
};

/**
 * The navigation an account actually sees. Only the admin workspace is filtered — every other role
 * gets its tree untouched, because no other role is governed by permissions.
 *
 * A destination is kept when its own page is open, or when at least one of its children is: an admin
 * who may read the catalog but not manage categories still sees Courses, with only the child they
 * can open underneath it.
 */
export function visibleNavigation(role: Role, canOpen: (to: string) => boolean): NavGroup[] {
  if (role !== 'admin') return navigation[role];
  return navigation[role]
    .map((group) => ({
      ...group,
      items: group.items
        .map((item) => ({ ...item, children: item.children?.filter((leaf) => canOpen(leaf.to)) }))
        .filter((item) => canOpen(item.to) || (item.children?.length ?? 0) > 0),
    }))
    .filter((group) => group.items.length > 0);
}

/**
 * Where an admin who may not open the dashboard lands instead: the first destination in their navigation they
 * can open. Undefined when there is none, and the shell explains the refusal. Signing in lands on `/admin`, so
 * without this an admin without "View reports" met a refusal first thing.
 */
export function firstOpenDestination(groups: NavGroup[], canOpen: (to: string) => boolean, skip: string): string | undefined {
  for (const group of groups) {
    for (const item of group.items) {
      const entries = [item, ...(item.children ?? [])];
      const open = entries.find((entry) => entry.to !== skip && canOpen(entry.to));
      if (open) return open.to;
    }
  }
  return undefined;
}

export function flatItems(role: Role) {
  return navigation[role].flatMap((g) => g.items);
}

/** The nav item and child label matching a pathname — used for breadcrumbs and mobile titles. */
const WORKSPACE_ROOTS = ['/admin', '/teach', '/home', '/superadmin'];

export function locate(role: Role, pathname: string) {
  const own = locateIn(role, pathname);
  // The owner opens workspace pages its sidebar does not list (the dashboard, calendar, help): the staff tree names them.
  return own ?? (role === 'superadmin' && pathname.startsWith('/admin') ? locateIn('admin', pathname) : undefined);
}

function locateIn(role: Role, pathname: string) {
  let best: { item: NavItem; leaf?: NavLeaf; group?: NavGroup; score: number } | undefined;
  for (const group of navigation[role]) {
    for (const item of group.items) {
      const candidates: { leaf?: NavLeaf; to: string }[] = [
        { to: item.to },
        ...(item.also ?? []).map((to) => ({ to })),
        ...(item.children ?? []).map((leaf) => ({ leaf, to: leaf.to })),
      ];
      for (const c of candidates) {
        // A workspace's overview matches only itself, so pages outside the navigation don't claim it.
        const root = WORKSPACE_ROOTS.includes(c.to);
        const matches = pathname === c.to || (!root && pathname.startsWith(`${c.to}/`));
        if (matches && (!best || c.to.length > best.score)) best = { item, leaf: c.leaf, group, score: c.to.length };
      }
    }
  }
  return best;
}
