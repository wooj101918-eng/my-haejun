# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

"해준이의 성장과정" — a Korean-language baby growth diary, deployed as a static site via GitHub Pages (`origin`: `wooj101918-eng/my-haejun`, branch `main`). There is no build system, package manager, linter, or test suite: the entire app (HTML, CSS, JS) lives in a single self-contained file. Data lives in Supabase.

- `index.html` — the page GitHub Pages serves. This is the source of truth.
- `haejun.html` — a byte-identical copy of `index.html`. If you edit one, keep the other in sync (`cp index.html haejun.html`), or ask the user whether the duplicate can be removed.
- `해준-1490-2.jpg`, `haejun-entry.jpg` — hero/section photos, referenced by relative path.
- `supabase/migrations/*.sql` — schema history. Applied via the Management API, not the CLI (`supabase db push` needs direct DB access that may be blocked).

## Backend (Supabase)

Project `haejun-diary`, ref `fvexrjssywmhbbyvvpkm`, region ap-northeast-2. The CLI is linked (`supabase/.temp/`, gitignored).

- **Tables**: `entries` (`id` text PK, `date`, `title`, `body`, `cover_path`, `attachment_paths` text[], `created_at`, `updated_at` via trigger) and `comments` (`entry_id` FK cascade, `name`, `body`, `created_at`).
  Note the DB column is `body`; the in-memory entry field is still `text`. `rowToEntry()` maps between them.
- **Storage**: public bucket `photos`, 10 MB/file, images only. Paths are `<year>/<timestamp>-<rand>.<ext>`.
- **RLS**: anyone may read entries, comments and photos; only authenticated users may write entries or upload photos; comment insert is open (family guestbook). Changing this means editing the policies in `supabase/migrations/`, not the client.
- **Secrets** (access token, DB password, service/secret keys, login password) live in `C:\Users\wooj1\haejun-supabase-비밀정보.txt`, deliberately outside this repo. Never commit them, and never put anything but the publishable key in `index.html`.

## Running locally

Serve the folder over HTTP rather than opening `index.html` as a `file://` URL — Supabase auth and REST need a real origin. Any static server works. Deploying = committing and pushing to `main`.

## Architecture (inside `index.html`)

- **Styling**: CSS custom properties in `:root` (pastel palette, shadows, radius); Pretendard font from jsDelivr. Single responsive breakpoint at `max-width: 720px`.
- **Pages**: Two in-page "pages" (`#page-home`, `#page-archive`) toggled via the `hidden` attribute by `switchPage()`; header nav buttons carry `data-page`. No router or URL state.
- **Script**: One IIFE in strict mode. The only external JS dependency is `@supabase/supabase-js` (pinned UMD build from jsDelivr, exposes `window.supabase`).
- **Data layer**: `dbGetAllEntries()`, `dbSaveEntry()`, `dbDeleteEntry()`, `dbAddComment()`, `uploadPhoto()`. `dbDeleteEntry` also removes the entry's photos from storage.
- **Entry shape (in memory)**: `{ id: "e-<timestamp>", date: "YYYY-MM-DD", title, text, coverPath, attachmentPaths, cover, attachments, comments: [{id, name, text, date}] }`. `cover`/`attachments` are public URL strings; the `*Path` fields are the storage keys needed for deletion. Uploads pass through `compressImage()` (max 1600px JPEG, q 0.82) before reaching storage.
- **Auth**: `currentUser` plus `applyAuthState()`, which toggles the write form, the locked notice, the delete buttons and the migrate bar. Session is restored in `init()` via `sb.auth.getSession()`.
- **Legacy migration**: earlier versions stored everything in IndexedDB (`haejunDiaryDB`). `idbGetAllEntries()` still reads it, and the `#migrate-bar` button uploads those entries to Supabase. Keep this until the user confirms every device has been migrated.
- **Archive**: Drill-down years → months → days driven by `archiveState = { view, year, month }`, rendered by `renderArchive()`. `archiveBlobUrl` / `releaseArchiveUrls` are now pass-through no-ops kept so the render code did not have to change.
- **UI helpers**: lightbox for images (`.lightbox-trigger` with `data-src`), toast notifications, `IntersectionObserver`-based `.fade-up` animations (`observeFadeUps()`), and a hero intro that briefly locks scrolling (`initHeroIntro()`).
- User-provided text is inserted via template strings — always pass it through `escapeHtml()`.
