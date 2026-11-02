import { Link } from 'react-router-dom';
import { API_MODE } from '@/lib/apiMode';
import { MarketingChrome } from './MarketingChrome';
import { COMPANY, COMPANY_ADDRESS, SUPPORT_EMAIL } from './siteContent';
import styles from './Marketing.module.css';

/** Privacy policy for the website and the Android app — a public reading page, linked from the app's store listing. */
export default function PrivacyPage() {
  return (
    <MarketingChrome embeddable>
      <article className={styles.legal}>
        <header className={styles.legalHead}>
          <h1>Privacy policy</h1>
          <p className={styles.muted}>Last updated 1 November 2026</p>
        </header>

        <section>
          <h2>Who we are</h2>
          <p>
            ZuviloAI is a product of {COMPANY.legalName}, {COMPANY_ADDRESS}. We decide what is collected on the platform and why, as this policy describes.
          </p>
        </section>

        <section>
          <h2>What this page covers</h2>
          <p>
            This policy explains what ZuviloAI collects when you use the platform, why, and how you can control it. It applies to the website, the ZuviloAI
            Android app, the learner, instructor, affiliate and admin workspaces, and any email we send from a zuviloai.com address.
          </p>
        </section>

        <section>
          <h2>The platform</h2>
          <p>
            ZuviloAI is one platform where learners buy and take courses from approved instructors. Our staff run it, and they see only what their job needs.
          </p>
        </section>

        <section>
          <h2>What we collect</h2>
          <ul>
            <li>
              <strong>Account details</strong> — your name, email address, and the workspace role assigned to you (learner, instructor or admin).
            </li>
            <li>
              <strong>Learning activity</strong> — course progress, quiz and assignment submissions, live-class attendance, and certificates issued to you.
            </li>
            <li>
              <strong>Files you upload</strong> — documents and images you choose to attach to an assignment, from the website or the app. Nothing is uploaded
              unless you pick it.
            </li>
            <li>
              <strong>Order details</strong> — for learners who buy a course: the order, its amount and its payment reference. Card and bank details are entered
              with our payment partner and never reach or stay on our servers; we keep only what an order needs and the payment’s reference.
            </li>
            <li>
              <strong>Messages to our team</strong> — what you send through the contact form (your name, email, phone if given, and your message), used only to
              reply to you.
            </li>
            <li>
              <strong>Device and connection data</strong> — your IP address and a description of the browser or device you sign in from, from the website and
              the app, used only to keep the service secure and working: limiting repeated sign-in attempts and showing you where you are signed in.
            </li>
          </ul>
        </section>

        <section>
          <h2>The Android app</h2>
          <ul>
            <li>
              On your device the app keeps only your sign-in session (in Android's secure storage), your app preferences, and cached images and course media so
              lessons load quickly. None of it is backed up to the cloud.
            </li>
            <li>
              Camera and microphone: asked for only when you join a live class, and used only while you are in it. The class itself runs on a video-meeting
              service (Jitsi); if your instructor records a class, we keep the recording with the other course media.
            </li>
            <li>
              Notifications: with your permission, the app shows reminders and messages from the platform. To deliver them, the device is registered with
              Google’s Firebase Cloud Messaging; the registration is removed when you sign out.
            </li>
            <li>The app asks for no location, contacts or other device permissions.</li>
            <li>
              The app contains no advertising and uses no advertising identifiers. Firebase is used only to deliver notifications: its analytics collection is
              switched off, and the app sends no crash reports.
            </li>
          </ul>
        </section>

        <section>
          <h2>How we use it</h2>
          <p>
            Your learning activity is used to run your courses: unlocking chapters, routing submissions to the right instructor, issuing certificates, and
            showing you and your instructors accurate progress. We do not use your coursework to train models without asking first.
          </p>
        </section>

        <section>
          <h2>Sharing and security</h2>
          <p>
            We do not sell your data or share it with third parties, except the service providers that run the platform for us — hosting, email delivery, and
            payment processing for course purchases — who handle it only to provide that service. Everything travels between your browser or the app and the
            platform encrypted over HTTPS.
          </p>
        </section>

        <section>
          <h2>Who can see what</h2>
          <p>
            Instructors see progress and submissions only for learners enrolled in their own courses. Our admins can see platform-wide reports — completion
            rates, certificates issued, instructor performance — but not the content of private messages between a learner and an instructor.
          </p>
        </section>

        <section>
          <h2>How long we keep it</h2>
          <p>
            Account and learning records are kept for as long as your account is active. When you delete your account, your name and email are removed, your
            notes, bookmarks, saved courses, drafts, live-class registrations, notifications and registered devices are erased, and you are signed out
            everywhere. Course progress, quiz and assignment records and issued certificates are kept under an anonymous name, so a certificate someone already
            relies on keeps verifying — without showing who earned it. The details are on the <Link to="/delete-account">delete your account</Link> page.
          </p>
        </section>

        <section>
          <h2>Your choices</h2>
          <ul>
            <li>Review and update your profile details from your account menu at any time.</li>
            <li>Turn individual notification types on or off from notification preferences.</li>
            <li>
              Delete your learner account yourself — in the app from Profile → Delete account, or on the web from the{' '}
              <Link to="/delete-account">delete your account</Link> page. Instructor and staff accounts are closed by our team.
            </li>
            <li>Request a copy of your data by writing to the address below.</li>
          </ul>
        </section>

        <section>
          <h2>Contact and grievances</h2>
          <p>
            Questions about this policy, requests about your data, and complaints go to {COMPANY.legalName} at{' '}
            <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a> or <a href={COMPANY.phoneHref}>{COMPANY.phone}</a>, or by post to {COMPANY_ADDRESS}. Mark a
            complaint “Grievance” and we acknowledge it within 24 hours and resolve it within 30 days. For help using the platform, see the{' '}
            <Link to="/support">Help Centre</Link>.
          </p>
        </section>

        {/* True of the demo build only. Against the real API accounts and personal data are real, so the note would be a lie. */}
        {API_MODE === 'mock' && (
          <p className={styles.legalNote}>This is a UI demo build — no real accounts, emails or personal data are collected or stored.</p>
        )}
      </article>
    </MarketingChrome>
  );
}
