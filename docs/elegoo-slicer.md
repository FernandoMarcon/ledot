# ElegooSlicer

Slicer for Elegoo 3D printers (an OrcaSlicer fork). Installed by `setup/elegoo.sh`. It isn't part of the full `install.sh` run.

```bash
bash ~/ledot/install.sh elegoo                       # latest release AppImage (fast)
bash ~/ledot/setup/elegoo.sh --source                # build it from source (hours)
bash ~/ledot/setup/elegoo.sh --source path/to.tar.gz # build from a specific source tarball
```

| What | Where |
|---|---|
| AppImage | `~/.local/share/elegoo-slicer/ElegooSlicer.AppImage` |
| Launcher | `~/.local/bin/elegoo-slicer` |
| Menu entry | `~/.local/share/applications/elegoo-slicer.desktop` (opens `.stl`, `.3mf`, `.obj`, `.amf`) |
| Source tree (`--source`) | `~/src/elegoo-slicer` |
| Runtime packages | `pkgs/elegoo.list` (`libfuse2t64` for AppImages, `libwebkit2gtk-4.1-0`, GStreamer) |
| User config/profiles | `~/.config/ElegooSlicer` |

The script reads the latest release from `github.com/ELEGOO-3D/ElegooSlicer`. Re-running it does nothing if that version is already installed; when a newer release comes out, it updates. `install.sh --state` shows which version is installed and whether it came from the release or a source build.

## Building from source

`--source` extracts the tarball to `~/src/elegoo-slicer` and applies three fixes. Then it runs the upstream script: `sudo ./build_linux.sh -u` (installs system build deps), then `./build_linux.sh -dsi` (deps, app, AppImage). Don't run the build itself with `sudo`, or root will own files throughout the source tree.

Fixes needed for v1.5.3.5 on Ubuntu 26.04 (GCC 15, CMake 4):

| Error | Cause | Fix |
|---|---|---|
| `ninja: error: '/home/…/ElegooSlicer-1.5.md.5/…/libcurl-symbols.md' … missing` | curl 8.14's `docs/libcurl/CMakeLists.txt` runs `string(REPLACE ".3" ".md" …)` on the full path, so it also rewrites the `.3` in `1.5.3.5` | `deps/CURL/CURL.cmake`: `-DBUILD_LIBCURL_DOCS=OFF -DBUILD_MISC_DOCS=OFF -DENABLE_CURL_MANUAL=OFF`. The script also extracts to a path with no `.3` in it |
| `requires at least 10G of 'available' mem (system has only 10G available)` | `build_linux.sh` compares with `-le` | `-le` → `-lt` (`-r` also skips the check) |
| `event_system.h: 'find_if' is not a member of 'std'` (dep `elegoolink`) | GCC 15 no longer includes `<algorithm>` through other headers. elegoolink is cloned from `origin/main`, so you can't patch its source in the tarball | `deps/elegoolink/elegoolink.cmake`: `"-DCMAKE_CXX_FLAGS:STRING=-include algorithm"` |

If a build fails partway, fix the problem and run `./build_linux.sh -dsi` again in `~/src/elegoo-slicer`. Finished deps aren't rebuilt. To make CMake reconfigure one dep after you change its args, remove `deps/build/dep_<Name>-prefix` first.
