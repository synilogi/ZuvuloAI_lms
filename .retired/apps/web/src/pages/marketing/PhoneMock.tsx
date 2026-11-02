import { Bell, BookOpenText, CellSignalFull, Exam, House, Play, UserCircle, VideoCamera, WifiHigh } from '@phosphor-icons/react';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { cx } from '@/lib/cx';
import assignmentsArt from '@/assets/illustrations/assignments.png';
import certificatesArt from '@/assets/illustrations/certificates.png';
import coursesArt from '@/assets/illustrations/courses.png';
import ranksArt from '@/assets/illustrations/ranks.png';
import styles from './PhoneMock.module.css';

/*
 * The student app, redrawn for the company website: the mobile app's Home as it ships — a greeting, Continue learning,
 * the four shortcuts with their 3D art (the app's own Fluent Emoji 3D files, MIT), your courses, and the bottom bar
 * Home · Courses · Live · Tests · Profile. Names and numbers are sample data; the whole phone is one image to
 * assistive technology.
 */

const SHORTCUTS = [
  { label: 'My Courses', art: coursesArt, hue: 'violet' },
  { label: 'Assignments', art: assignmentsArt, hue: 'orange' },
  { label: 'Certificates', art: certificatesArt, hue: 'gold' },
  { label: 'Ranks', art: ranksArt, hue: 'blue' },
] as const;

const TABS = [
  { label: 'Home', icon: House, on: true },
  { label: 'Courses', icon: BookOpenText },
  { label: 'Live', icon: VideoCamera, dot: true },
  { label: 'Tests', icon: Exam },
  { label: 'Profile', icon: UserCircle },
];

/** `parallax` marks the phone as one of the pieces the home page's hero moves (see landingMotion.ts). */
export function PhoneMock({ label, className, parallax }: { label: string; className?: string; parallax?: boolean }) {
  return (
    <div className={cx(styles.phone, className)} role="img" aria-label={label} data-mock="phone" data-parallax={parallax || undefined}>
      <div className={styles.screen} aria-hidden="true">
        <div className={styles.status}>
          <span>9:41</span>
          <span className={styles.island} />
          <span className={styles.statusIcons}>
            <CellSignalFull size={13} weight="fill" />
            <WifiHigh size={13} weight="bold" />
            <span className={styles.battery} />
          </span>
        </div>

        <div className={styles.body}>
          <div className={styles.hello}>
            <span>
              <small>Good morning</small>
              <strong>Hello, Aditi</strong>
            </span>
            <span className={styles.bell}>
              <Bell size={16} weight="bold" />
              <i />
            </span>
            <span className={styles.me}>AS</span>
          </div>

          <div className={styles.continue}>
            <span className={styles.continueText}>
              <small>Continue learning</small>
              <strong>Fractions on the number line</strong>
              <span className={styles.continueMeta}>Maths Foundations · Class 6–8</span>
              <span className={styles.continueBar}>
                <span style={{ width: '60%' }} />
              </span>
              <small>60% completed</small>
            </span>
            <span className={styles.play}>
              <Play size={14} weight="fill" />
            </span>
          </div>

          <div className={styles.shortcuts}>
            {SHORTCUTS.map((s) => (
              <span key={s.label} className={styles.shortcut} data-hue={s.hue}>
                <span className={styles.shortcutTile}>
                  <img src={s.art} alt="" width={40} height={40} />
                </span>
                {s.label}
              </span>
            ))}
          </div>

          <div className={styles.sectionHead}>
            <strong>Your courses</strong>
            <small>View all</small>
          </div>
          <div className={styles.course}>
            <CourseCover motif="houses" className={styles.cover} />
            <span className={styles.courseText}>
              <strong>Maths Foundations</strong>
              <small>12 lessons · 3h 20m</small>
              <span className={styles.courseBar}>
                <span style={{ width: '60%' }} />
              </span>
            </span>
            <small className={styles.coursePct}>60%</small>
          </div>
          <div className={styles.course}>
            <CourseCover motif="orbits" className={styles.cover} />
            <span className={styles.courseText}>
              <strong>Logical Reasoning</strong>
              <small>8 lessons · 2h 05m</small>
              <span className={styles.courseBar}>
                <span style={{ width: '32%' }} />
              </span>
            </span>
            <small className={styles.coursePct}>32%</small>
          </div>
        </div>

        <div className={styles.tabs}>
          {TABS.map((t) => (
            <span key={t.label} className={cx(styles.tab, t.on && styles.tabOn)}>
              <span className={styles.tabIcon}>
                <t.icon size={17} weight={t.on ? 'fill' : 'regular'} />
                {t.dot && <i />}
              </span>
              {t.label}
            </span>
          ))}
        </div>
        <span className={styles.homeBar} />
      </div>
    </div>
  );
}
