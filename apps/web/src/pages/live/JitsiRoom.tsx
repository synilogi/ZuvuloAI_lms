import { useEffect, useRef, useState } from 'react';

import { Button } from '@/components/ui/Button/Button';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Spinner } from '@/components/ui/Spinner/Spinner';
import type { RoomJoin } from '@/services';
import styles from './Live.module.css';

/**
 * The academy's own live room, on the video service the API names (lib/liveRoom.ts): a public Jitsi server,
 * or 8x8 JaaS with a token signed for this person. The API mints the room's name when the host starts the
 * class and hands it only to people who may join, so a class id alone never opens it.
 *
 * The room is embedded rather than opened in a tab so the class stays inside the platform.
 */

interface JitsiApi {
  dispose(): void;
  addListener(event: string, handler: (...args: unknown[]) => void): void;
  executeCommand(command: string, ...args: unknown[]): void;
}

type JitsiConstructor = new (domain: string, options: Record<string, unknown>) => JitsiApi;

declare global {
  interface Window {
    JitsiMeetExternalAPI?: JitsiConstructor;
  }
}

/** JaaS serves its script per app (`8x8.vc/<appId>/external_api.js`); a Jitsi server at its root. */
const scriptUrl = (room: RoomJoin) =>
  room.provider === 'jaas' ? `https://${room.domain}/${room.room.split('/')[0]}/external_api.js` : `https://${room.domain}/external_api.js`;

/** The longest the connecting screen covers the meeting before the meeting's own screens show through. */
const CONNECTING_MAX_MS = 10_000;

/** Loads the external API script once per script URL and resolves with the constructor. */
const scripts = new Map<string, Promise<JitsiConstructor>>();
function loadJitsi(src: string): Promise<JitsiConstructor> {
  const pending = scripts.get(src);
  if (pending) return pending;
  const promise = new Promise<JitsiConstructor>((resolve, reject) => {
    const el = document.createElement('script');
    el.src = src;
    el.async = true;
    el.onload = () => (window.JitsiMeetExternalAPI ? resolve(window.JitsiMeetExternalAPI) : reject(new Error('The meeting library did not load.')));
    el.onerror = () => {
      scripts.delete(src);
      reject(new Error('Could not reach the meeting server.'));
    };
    document.head.appendChild(el);
  });
  scripts.set(src, promise);
  return promise;
}

/**
 * The room itself, filling the screen until the host or learner leaves. Camera and microphone start in the
 * state chosen on the check screen before it. The host can end the class for everyone from the bar.
 */
export function JitsiRoom({
  room,
  camera,
  mic,
  onClose,
  onEnd,
}: {
  room: RoomJoin;
  camera: boolean;
  mic: boolean;
  onClose: () => void;
  /** The host only: closes the class on the server; the room is then ended for everyone. */
  onEnd?: () => Promise<void>;
}) {
  const holder = useRef<HTMLDivElement>(null);
  const api = useRef<JitsiApi | null>(null);
  /** The room itself could not load: there is no call to keep, so the message takes its place. */
  const [error, setError] = useState<string | null>(null);
  /** Ending the class failed: the call carries on and the host can try again. */
  const [endError, setEndError] = useState<string | null>(null);
  const [confirmEnd, setConfirmEnd] = useState(false);
  // JaaS signs the host in as the moderator; on the public server the host is one only if meet.jit.si makes them one.
  const hostControls = room.provider === 'jaas' && room.moderator;
  const [ending, setEnding] = useState(false);
  /** Until the call has joined: a quiet black screen with a small loader over the meeting as it boots. */
  const [connecting, setConnecting] = useState(true);

  useEffect(() => {
    let cancelled = false;
    loadJitsi(scriptUrl(room))
      .then((JitsiMeetExternalAPI) => {
        if (cancelled || !holder.current) return;
        api.current = new JitsiMeetExternalAPI(room.domain, {
          roomName: room.room,
          ...(room.jwt ? { jwt: room.jwt } : {}),
          parentNode: holder.current,
          width: '100%',
          height: '100%',
          userInfo: { displayName: room.displayName, email: room.email },
          configOverwrite: {
            startWithAudioMuted: !mic,
            startWithVideoMuted: !camera,
            prejoinPageEnabled: false,
            prejoinConfig: { enabled: false },
            disableDeepLinking: true,
            subject: room.subject,
          },
          interfaceConfigOverwrite: { MOBILE_APP_PROMO: false, SHOW_JITSI_WATERMARK: false },
        });
        // The loader gives way once the call has joined — or when the meeting needs the person (an error, a password).
        const shown = () => setConnecting(false);
        for (const event of ['videoConferenceJoined', 'errorOccurred', 'passwordRequired']) api.current.addListener(event, shown);
        // Leaving the room (or being shown the door when the host ends it) returns to the class page.
        api.current.addListener('readyToClose', onClose);
        api.current.addListener('videoConferenceLeft', onClose);
      })
      .catch((e: Error) => !cancelled && setError(e.message));
    // Never longer than this: a lobby or a sign-in screen inside the meeting must not stay hidden behind the loader.
    const fallback = window.setTimeout(() => setConnecting(false), CONNECTING_MAX_MS);

    return () => {
      cancelled = true;
      window.clearTimeout(fallback);
      api.current?.dispose();
      api.current = null;
    };
    // The room is built once per join; the toggles only seed its starting state.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [room.room, room.jwt]);

  const endForEveryone = async () => {
    if (!onEnd) return;
    setEnding(true);
    setEndError(null);
    try {
      await onEnd();
      // A moderator's command closes the meeting for every participant; then the host leaves too.
      try {
        api.current?.executeCommand('endConference');
      } catch {
        api.current?.executeCommand('hangup');
      }
      onClose();
    } catch (e) {
      // The call stays up: only the class's state on the server failed to change.
      setEndError((e as Error).message);
      setEnding(false);
      setConfirmEnd(false);
    }
  };

  return (
    <div className={styles.roomStage} role="dialog" aria-modal="true" aria-label={`${room.subject} — live room`}>
      <header className={styles.roomStageBar}>
        <span className={styles.roomStageTitle}>
          {room.subject}
          {room.moderator && <span className={styles.roomStageRole}>{hostControls ? ' · you are the host' : ' · you are hosting'}</span>}
        </span>
        <span className={styles.roomStageActions}>
          {onEnd &&
            (confirmEnd ? (
              <>
                <span className={styles.roomStageRole}>{hostControls ? 'End the class for everyone?' : 'End the class? Nobody new can join.'}</span>
                <Button size="sm" onClick={() => setConfirmEnd(false)} disabled={ending}>
                  Keep teaching
                </Button>
                <Button size="sm" variant="danger" loading={ending} onClick={endForEveryone}>
                  End class
                </Button>
              </>
            ) : (
              <Button size="sm" variant="danger" onClick={() => setConfirmEnd(true)}>
                End class
              </Button>
            ))}
          <Button size="sm" onClick={onClose} disabled={ending}>
            Leave
          </Button>
        </span>
      </header>
      {endError && (
        <div className={styles.roomStageNotice} role="alert">
          <InlineMessage kind="error" title="The class didn’t end">
            {endError} You’re still in the room — try End class again.
          </InlineMessage>
        </div>
      )}
      {error ? (
        <div className={styles.roomStageError}>
          <p>{error}</p>
          <p className={styles.muted}>Check your connection and try again. If it keeps failing, the platform’s meeting server may be unreachable.</p>
        </div>
      ) : (
        <div className={styles.roomStageBody}>
          <div className={styles.roomStageFrame} ref={holder} />
          {connecting && (
            <div className={styles.roomStageConnecting}>
              <Spinner size={22} label="" />
              <span role="status">Connecting to the class…</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
