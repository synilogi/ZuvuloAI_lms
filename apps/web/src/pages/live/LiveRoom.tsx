import { useEffect, useState } from 'react';
import { ArrowSquareOut, Microphone, MicrophoneSlash, VideoCamera, VideoCameraSlash } from '@phosphor-icons/react';
import type { LiveClass } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDate, formatDuration } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button } from '@/components/ui/Button/Button';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { useSession } from '@/providers/SessionProvider';
import { services, type RoomJoin } from '@/services';
import { JitsiRoom } from './JitsiRoom';
import { externalLinkOf } from './liveRules';
import styles from './Live.module.css';

/**
 * Staff open a class's outside meeting (Google Meet, Zoom …) from the link their own view carries. Called straight
 * from the click so the browser treats it as a user gesture and does not block it.
 */
export function openExternalRoom(liveClass: Pick<LiveClass, 'meeting'>): boolean {
  const link = liveClass.meeting?.kind === 'external' ? liveClass.meeting.link : undefined;
  if (!link) return false;
  window.open(link, '_blank', 'noopener,noreferrer');
  return true;
}

/**
 * A tab opened from the click itself, so no popup blocker stops it, and pointed at the meeting once the API has handed
 * the link over. Null when the browser refused it.
 */
function openPendingTab(): Window | null {
  try {
    const tab = window.open('', '_blank');
    if (tab) {
      try {
        tab.document.title = 'Opening the meeting…';
        tab.document.body.textContent = 'Opening the meeting…';
      } catch {
        /* a tab we can't write to still navigates */
      }
    }
    return tab;
  } catch {
    return null;
  }
}

function sendTab(tab: Window | null, link: string) {
  if (!tab || tab.closed) return false;
  // The meeting gets no handle back on the LMS's page.
  tab.opener = null;
  tab.location.replace(link);
  return true;
}

/** The way into a built-in room; the API takes a place for the learner if they had none, and marks them as joined. */
async function enterRoom(id: string) {
  const j = await services.live.join(id);
  if (j.kind !== 'room') throw new Error('This class runs on an outside meeting link.');
  return j.room;
}

/**
 * A learner joining a class. An outside meeting's link is never in the learner's data: the API hands it over from
 * `join` — only to a learner allowed in, inside the join window — and it opens in a new tab. The built-in room opens
 * over the page after the camera and microphone check. Every refusal (full, not enrolled, not open yet) is shown.
 */
export function useLiveJoin(onChange?: () => void) {
  const { user } = useSession();
  const toast = useToast();
  const [room, setRoom] = useState<LiveClass | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [ready, setReady] = useState<{ title: string; link: string } | null>(null);

  const join = async (cls: LiveClass) => {
    if (cls.meeting?.kind !== 'external') {
      setRoom(cls);
      return;
    }
    if (busyId) return;
    const tab = openPendingTab();
    setBusyId(cls.id);
    try {
      const link = externalLinkOf(await services.live.join(cls.id));
      // The browser blocked the tab: the learner opens the link with a click of their own.
      if (!sendTab(tab, link)) setReady({ title: cls.title, link });
      onChange?.();
    } catch (e) {
      tab?.close();
      toast({ kind: 'error', title: 'Couldn’t join the class', text: (e as Error).message });
    } finally {
      setBusyId(null);
    }
  };

  const element = (
    <>
      {room && (
        <RoomCheck
          open
          onClose={() => {
            setRoom(null);
            onChange?.();
          }}
          liveClass={room}
          name={user.name}
          enter={() => enterRoom(room.id)}
        />
      )}
      {ready && (
        <Modal
          open
          onClose={() => setReady(null)}
          title="Your meeting is ready"
          description={ready.title}
          footer={
            <>
              <Button onClick={() => setReady(null)}>Close</Button>
              <Button
                variant="primary"
                iconStart={<ArrowSquareOut size={16} />}
                onClick={() => {
                  window.open(ready.link, '_blank', 'noopener,noreferrer');
                  setReady(null);
                }}
              >
                Open the meeting
              </Button>
            </>
          }
        >
          <p className={styles.muted}>Your browser didn’t open a new tab. Open the meeting from here.</p>
        </Modal>
      )}
    </>
  );

  return { join, busyId, inRoom: room !== null, element };
}

/**
 * The check before entering a live room — camera and microphone. Confirming asks the API for the way in
 * (`enter`: starting the class for a host, joining it for a learner), then opens the academy's own room
 * (`JitsiRoom`) over the page; leaving it closes the whole thing.
 */
export function RoomCheck({
  open,
  onClose,
  liveClass,
  name,
  host,
  enter,
  onEnd,
  provider,
}: {
  open: boolean;
  onClose: () => void;
  liveClass: LiveClass;
  name: string;
  host?: boolean;
  enter: () => Promise<RoomJoin>;
  /** The host only: ends the class on the server from inside the room. */
  onEnd?: () => Promise<void>;
  /** The video service the API reports (staff only), so the host is told what the public server can't do. */
  provider?: RoomJoin['provider'];
}) {
  const [camera, setCamera] = useState(Boolean(host));
  const [mic, setMic] = useState(Boolean(host));
  const [room, setRoom] = useState<RoomJoin | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (room)
    return (
      <JitsiRoom
        room={room}
        camera={camera}
        mic={mic}
        onEnd={onEnd}
        onClose={() => {
          setRoom(null);
          onClose();
        }}
      />
    );

  const go = async () => {
    setBusy(true);
    setError(null);
    try {
      setRoom(await enter());
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      width={560}
      title={host ? (liveClass.startedAt ? 'Back to your class' : 'Ready to teach?') : 'Join the class'}
      description={liveClass.title}
      footer={
        <>
          <Button onClick={onClose}>Not yet</Button>
          <Button variant="primary" iconStart={<VideoCamera size={16} />} loading={busy} onClick={go}>
            {host ? (liveClass.startedAt ? 'Rejoin as host' : 'Start the class') : 'Join now'}
          </Button>
        </>
      }
    >
      <div className={styles.roomCheck}>
        <div className={cx(styles.preview, camera && styles.previewOn)}>
          <Avatar name={name} size={72} />
          <span className={styles.previewLabel}>{camera ? 'Camera on' : 'Camera off'}</span>
        </div>
        <div className={styles.roomToggles}>
          <Button iconStart={camera ? <VideoCamera size={16} /> : <VideoCameraSlash size={16} />} aria-pressed={camera} onClick={() => setCamera((c) => !c)}>
            {camera ? 'Turn camera off' : 'Turn camera on'}
          </Button>
          <Button iconStart={mic ? <Microphone size={16} /> : <MicrophoneSlash size={16} />} aria-pressed={mic} onClick={() => setMic((m) => !m)}>
            {mic ? 'Mute' : 'Unmute'}
          </Button>
        </div>
        {host && !liveClass.startedAt && (
          <p className={styles.muted}>Starting opens the room: learners of the course are told the class is live and can join.</p>
        )}
        {host && provider === 'jitsi' && <PublicServerNote />}
        {!host && (
          <p className={styles.muted}>Your browser will ask to use your camera and microphone. You can turn either on in the room to ask a question.</p>
        )}
        {error && <InlineMessage kind="error">{error}</InlineMessage>}
      </div>
    </Modal>
  );
}

/** What the public meet.jit.si server means for a host: it is not the academy's own, and it promises little. */
export function PublicServerNote() {
  return (
    <InlineMessage kind="info" title="This room runs on the public meet.jit.si server">
      To start the class you may be asked to sign in to meet.jit.si (with Google, GitHub or Facebook) as its moderator. Calls embedded from the public server
      can be cut off after a few minutes, nothing is recorded, and muting or removing others works only once meet.jit.si makes you the moderator.
    </InlineMessage>
  );
}

/** A class recording: played from the academy’s copy, through a short-lived link the browser’s player can open. */
export function RecordingViewer({ open, onClose, liveClass }: { open: boolean; onClose: () => void; liveClass: LiveClass }) {
  const status = liveClass.recording?.status;
  const [src, setSrc] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open || status !== 'ready') return;
    let cancelled = false;
    services.live
      .recordingLink(liveClass.id)
      .then(({ url }) => !cancelled && setSrc(url))
      .catch((e: Error) => !cancelled && setError(e.message));
    return () => {
      cancelled = true;
    };
  }, [open, status, liveClass.id]);

  return (
    <Modal
      open={open}
      onClose={onClose}
      width={760}
      title={liveClass.title}
      description={`Recorded ${formatDate(liveClass.startsAt)} · ${formatDuration(liveClass.recording?.durationMin ?? liveClass.durationMin)}`}
    >
      <div className={styles.recording}>
        {status === 'ready' && src && !error ? (
          <video className={styles.recordingFrame} src={src} controls autoPlay playsInline preload="metadata" />
        ) : (
          <div className={styles.recordingFrame}>
            <span className={styles.recordingNote}>
              {error ??
                (status === 'ready'
                  ? 'Loading the recording…'
                  : status === 'processing'
                    ? 'The recording is being prepared. It is usually ready a few minutes after the class ends.'
                    : 'This recording can’t be played here.')}
            </span>
          </div>
        )}
        {liveClass.recording && <p className={styles.muted}>Available until {formatDate(liveClass.recording.availableUntil)}.</p>}
      </div>
    </Modal>
  );
}
