# Okami

A simple, modern app store for Linux — built on Kirigami/QtQuick, backed by [Flathub](https://flathub.org).

Okami browses and installs apps straight from Flathub using its public JSON API, and hands off the actual install/uninstall/launch work to the `flatpak` CLI. No scraping, no bundled runtime, no background container — just a thin, native front end over tooling your system already has.

## Features

- Browse **Discover**, **Productivity**, **Development**, **Multimedia**, and **Games** categories
- Search apps by name, filtered instantly against the currently loaded category
- One-click install with live progress
- **Installed** view backed directly by `flatpak list`
- Launch installed apps straight from the store
- Clean, rounded, light UI with soft shadows and a single blue accent

## Requirements

- Qt 6 (QtQuick, QtQuick Controls, QtQuick Layouts, QtQuick Effects)
- [Kirigami](https://develop.kde.org/frameworks/kirigami/) (KDE Frameworks 6)
- [`flatpak`](https://flatpak.org/) installed and on `PATH`
- [Flathub](https://flathub.org/setup) added as a remote:
  ```bash
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  ```
- Network access to `flathub.org`

## Building

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

*(Adjust to your actual build system — swap in your real `CMakeLists.txt`/`.pro` invocation if this differs.)*

## Project layout

| File                  | Purpose                                                             |
|------------------------|----------------------------------------------------------------------|
| `Okami.qml`            | UI — category drawer, search bar, app grid, install/open flow       |
| `kstorebackend.h/.cpp` | `KStoreBackend` — talks to the Flathub API and shells out to `flatpak` |

### How it works

1. **Browsing** — `fetchApps(category)` hits either `GET /api/v2/collection/recently-added` (Discover) or `POST /api/v2/search` (everything else) on `flathub.org/api/v2`, gets back a list of app ids, then resolves each one via `GET /api/v2/appstream/:id` for its name, icon, and category.
2. **Searching** — `filterApps(text)` filters the already-loaded category client-side, so typing doesn't hit the network on every keystroke.
3. **Installing** — `installApp()` runs `flatpak install -y --noninteractive flathub <id>`, scraping stdout for progress.
4. **Installed apps** — `flatpak list --app --columns=application` is the source of truth; no local bookkeeping files.
5. **Launching** — `flatpak run <id>`.

Flatpak handles exporting `.desktop` files and icons for installed apps on its own, so Okami doesn't manage any of that itself.

## Known limitations

- The exact shape of Flathub's `/search` response isn't officially documented; parsing is defensive but may need tweaking if Flathub changes it.
- Progress percentage is scraped from `flatpak`'s stdout, which isn't a stable interface across flatpak versions.
- Sidebar categories are mapped to best-guess Flathub search terms rather than true category filters.

## License

Copyright (c) 2026 Kiba Labs, LLC.
