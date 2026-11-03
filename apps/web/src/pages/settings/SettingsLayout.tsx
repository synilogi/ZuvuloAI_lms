import { useCallback, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { BellSimple, BookOpenText, Certificate, CreditCard, GraduationCap, PaintBrush, SlidersHorizontal, type Icon } from '@phosphor-icons/react';
import type { SettingsRecord, SettingsSection } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { Field, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import styles from './Settings.module.css';

export const SETTINGS_BASE = '/admin/settings';

/** The settings record's sections, and Course payments — the academy's own gateway, saved apart from the record. */
export type SettingsPage = SettingsSection | 'payments';

export const SECTION_META: Record<SettingsPage, { label: string; description: string; icon: Icon }> = {
  general: { label: 'General', description: 'Name, enrolment and lesson defaults', icon: SlidersHorizontal },
  courses: { label: 'Courses', description: 'Format, release, review and catalog', icon: BookOpenText },
  learning: { label: 'Learning', description: 'Progress, completion and attempts', icon: GraduationCap },
  certificates: { label: 'Certificates', description: 'Issuing, fields and verification', icon: Certificate },
  notifications: { label: 'Notifications', description: 'What the platform sends, and when', icon: BellSimple },
  appearance: { label: 'Appearance', description: 'Brand, colour and a live preview', icon: PaintBrush },
  payments: { label: 'Course payments', description: 'Razorpay keys and course sales', icon: CreditCard },
};

/** The sections with a page here: payments and branding are the Super Admin's, under /superadmin. */
const ORDER: SettingsPage[] = ['general', 'courses', 'learning', 'certificates', 'notifications'];

export interface SettingsOutlet {
  record: SettingsRecord;
  onSaved: (record: SettingsRecord) => void;
}

export default function SettingsLayout() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const query = useAsync('lms-settings', () => services.settings.get());
  const [latest, setLatest] = useState<SettingsRecord | null>(null);
  const record = latest ?? query.data;
  const current = ORDER.find((s) => pathname.startsWith(`${SETTINGS_BASE}/${s}`)) ?? 'general';
  const onSaved = useCallback((next: SettingsRecord) => setLatest(next), []);

  return (
    <div className={styles.page}>
      <PageHeader
        title="Settings"
        description="How the platform behaves for learners and staff. Each section saves on its own; existing courses, lessons and certificates keep the settings they were created with."
      />
      <div className={styles.layout}>
        <nav aria-label="Settings sections" className={styles.nav}>
          <ul>
            {ORDER.map((s) => {
              const meta = SECTION_META[s];
              const Glyph = meta.icon;
              return (
                <li key={s}>
                  <NavLink to={`${SETTINGS_BASE}/${s}`} className={({ isActive }) => `${styles.navItem} ${isActive ? styles.navActive : ''}`}>
                    <Glyph size={18} weight="duotone" aria-hidden="true" />
                    <span className={styles.navText}>
                      <span className={styles.navLabel}>{meta.label}</span>
                      <span className={styles.navDescription}>{meta.description}</span>
                    </span>
                  </NavLink>
                </li>
              );
            })}
          </ul>
        </nav>
        <div className={styles.sectionPicker}>
          <Field label="Settings section">
            <Select value={current} onChange={(e) => navigate(`${SETTINGS_BASE}/${e.target.value}`)}>
              {ORDER.map((s) => (
                <option key={s} value={s}>
                  {SECTION_META[s].label} — {SECTION_META[s].description}
                </option>
              ))}
            </Select>
          </Field>
        </div>
        <div className={styles.content}>
          {query.status === 'error' && !record ? (
            <StateMessage
              kind="error"
              title="Settings didn’t load"
              actions={
                <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                  Try again
                </Button>
              }
            >
              {query.error.message}
            </StateMessage>
          ) : !record ? (
            <div className={styles.skeleton} aria-busy="true">
              <Skeleton width="30%" height={22} radius="var(--r-xs)" />
              <Skeleton width="60%" height={12} />
              <Skeleton height={180} radius="var(--r-md)" />
              <Skeleton height={180} radius="var(--r-md)" />
            </div>
          ) : (
            <Outlet context={{ record, onSaved } satisfies SettingsOutlet} />
          )}
        </div>
      </div>
    </div>
  );
}
