import { Link } from 'react-router-dom';
import type { PublicMentor } from '@syniastrolms/domain';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { plural } from '@/lib/format';
import { siteImageSrc } from './siteImage';
import styles from './Home.module.css';

export function MentorPhoto({ mentor, size }: { mentor: Pick<PublicMentor, 'name' | 'photoUrl'>; size: number }) {
  const src = siteImageSrc(mentor.photoUrl);
  return src ? (
    <img src={src} alt="" width={size} height={size} loading="lazy" className={styles.mentorPhoto} style={{ width: size, height: size }} />
  ) : (
    <Avatar name={mentor.name} size={size} />
  );
}

/** A mentor from the platform's records: photo, name, designation, a short biography and what they teach. */
export function MentorCard({ mentor, headingLevel: Heading = 'h3' }: { mentor: PublicMentor; headingLevel?: 'h2' | 'h3' }) {
  return (
    <li className={styles.mentorCard}>
      <MentorPhoto mentor={mentor} size={72} />
      <Heading className={styles.mentorName}>
        <Link to={`/mentors/${mentor.id}`}>{mentor.name}</Link>
      </Heading>
      {mentor.title && <p className={styles.mentorTitle}>{mentor.title}</p>}
      {mentor.bio && <p className={styles.mentorBio}>{mentor.bio}</p>}
      <p className={styles.mentorFacts}>{plural(mentor.courseCount, 'course')}</p>
      <span className={styles.mentorLink}>View profile</span>
    </li>
  );
}
