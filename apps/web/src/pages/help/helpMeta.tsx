import { useLocation } from 'react-router-dom';
import { Books, ClipboardText, GearSix, Certificate, ChartLineUp, Rocket, UsersThree, VideoCamera, type Icon } from '@phosphor-icons/react';
import type { HelpAudience, HelpCategoryIcon, Role } from '@syniastrolms/domain';
import { Badge, IconChip } from '@/components/ui/Badge/Badge';

export const CATEGORY_ICON: Record<HelpCategoryIcon, Icon> = {
  rocket: Rocket,
  book: Books,
  clipboard: ClipboardText,
  video: VideoCamera,
  certificate: Certificate,
  chart: ChartLineUp,
  gear: GearSix,
  users: UsersThree,
};

/** The Help Centre for the workspace in the URL — same three-way split as notifications and calendar, plus the public copy reached from the marketing site. */
export function useHelpBase() {
  const { pathname } = useLocation();
  if (pathname.startsWith('/admin/')) return '/admin/help';
  if (pathname.startsWith('/teach/')) return '/teach/help';
  if (pathname.startsWith('/support')) return '/support';
  return '/help';
}

/** Where a role's Help Centre lives, for links built outside a Help page (the header dialog, the profile menu). */
const HELP_HOME: Record<Role, string> = {
  student: '/help',
  instructor: '/teach/help',
  admin: '/admin/help',
  // Super Admin has no workspace copy of the Help Centre yet; `/help` is the role-neutral one.
  superadmin: '/help',
};

export const helpHome = (role: Role) => HELP_HOME[role];

export function HelpCategoryGlyph({ icon, size = 'md' }: { icon: HelpCategoryIcon; size?: 'md' | 'lg' }) {
  const Glyph = CATEGORY_ICON[icon];
  return (
    <IconChip tone="accent" size={size === 'lg' ? 'xl' : 'md'}>
      <Glyph size={size === 'lg' ? 26 : 18} weight="duotone" />
    </IconChip>
  );
}

/** "3 min read" */
export const readTime = (minutes: number) => `${minutes} min read`;

const AUDIENCE_LABEL: Record<HelpAudience, string> = { all: '', student: 'For learners', instructor: 'For instructors', admin: 'For admins' };

/** A quiet "For instructors" hint — informational only, never hides an article from another role. */
export function AudienceBadge({ audience }: { audience: HelpAudience }) {
  if (audience === 'all') return null;
  return (
    <Badge size="sm" tone="neutral">
      {AUDIENCE_LABEL[audience]}
    </Badge>
  );
}
