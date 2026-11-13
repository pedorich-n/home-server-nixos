# Mail archive

Mail is archived by [mbsync](https://isync.sourceforge.io/), which pulls from
IMAP into Maildir under `/mnt/store/mail/archive`. There is no mail server on
the host; the archive is a readable copy, not a delivery target.

## What is synced

- **Gmail:** only `[Gmail]/All Mail`, which already contains Inbox and Sent
  Mail. Syncing the label folders as well would store a second copy of every
  message. The `[Gmail]` prefix follows the account's UI language.
- **Other accounts:** everything except their spam and trash folders.

Junk is kept out at ingest, not cleaned up afterwards.

## Guarantees

- `Sync Pull` — the remote is only ever read. Nothing is uploaded, so a local
  mistake cannot delete mail on the server.
- `Expunge None` — syncing never deletes. An upstream deletion only sets the
  Maildir `T` (deleted) flag on the local copy; the file stays.
- `CopyArrivalDate` — file timestamps match the server's arrival time, not the
  download time.

## Removing what was deleted upstream

Mail deleted on the server is retained with the `T` flag and reclaimed by a
weekly run of `mbsync --noop --expunge-near`. `--noop` propagates nothing, so
the only action is removing local files that no longer exist upstream; nothing
is uploaded and no surviving message is touched.

The interval is the grace period: the flag appears within a sync interval, the
file disappears at the next weekly run. Providers keep deleted mail in their
own Trash longer than that, so a mistaken deletion is still recoverable there.
Setting `expungeNearTimer` to `null` keeps everything instead.

## Layout

One directory per account, one per folder, each a Maildir with `cur`, `new` and
`tmp`. Folder names are the server's verbatim, so they may contain spaces and
non-ASCII characters. The account directory itself is not a Maildir, and Gmail
accounts have exactly one folder.
