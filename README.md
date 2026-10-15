# GridWars

This repository holds the source code of GridWars, created originally by Mark Incitti in 2006. It includes later Linux and Raspberry Pi compatibility work.


## Project overview

The game is written in BlitzMax, a BASIC-like language. BlitzMax NG translates it to C and uses the system C/C++ toolchain to produce a native executable. There is no separate engine executable to install.

| Files | Purpose |
| --- | --- |
| `gridwars.bmx` | Entry point, game loop, enemies, weapons, scoring |
| `gridparttrail.bmx` | Graphics setup, deformable grid, particles and trails |
| `gameinput.bmx` | SDL mapped gamepads, hotplug, input switching and menu actions |
| `control.bmx` | Settings menus and configuration persistence |
| `images.bmx`, `sound.bmx` | PNG sprites and WAV sound effects |
| `utils.bmx`, `vectorfont.bmx`, `colordefs.bmx` | Drawing helpers, vector text and colours |
| `gfx/`, `sounds/`, `music/` | Runtime assets; keep these next to the executable |

Desktop Linux uses `SDL.GLSDLMax2D`, the SDL backend for the game's fixed-function OpenGL drawing. This avoids the old `BRL.GLMax2D` backend's dependency on the XFree86 VidMode extension, whose absence can crash display-mode enumeration. The OpenGL ES path remains separate.

## Building on modern Linux (x86-64)

The tested toolchain is Ubuntu 24.04 x86-64, GCC 13, and [BlitzMax NG 0.165.3.61.202610110603](https://github.com/bmx-ng/bmx-ng/releases/tag/v0.165.3.61.202610110603.linux.x64) (`bcc` 0.165, `bmk` 3.61). This is a pinned weekly release. The separate `bcc2/bmk2` releases have not been tested with this project. The previously documented compiler was `0.138.3.53`.

Install the development dependencies on Ubuntu/Debian:

```sh
sudo apt-get update
sudo apt-get install --no-install-recommends \
  build-essential curl ca-certificates xz-utils \
  libgl1-mesa-dev libglu1-mesa-dev libasound2-dev libpulse-dev \
  libx11-dev libxext-dev libxft-dev libxxf86vm-dev libxrandr-dev \
  libxcursor-dev libxi-dev libxinerama-dev libxss-dev \
  libdbus-1-dev libudev-dev libaudio-dev
```

BlitzMax ships the SDL source it builds against, so a separate SDL development package is not required. The full IDE's GTK/WebKit dependencies are also unnecessary for this command-line build. See the [upstream Linux setup guide](https://blitzmax.org/docs/en/setup/linux/) for other distributions; its older Ubuntu package list is not directly applicable to current Ubuntu releases.

Download and verify the tested compiler, then extract it into a user-writable directory:

```sh
mkdir -p "$HOME/.local/opt/gridwars-blitzmax"
cd "$HOME/.local/opt/gridwars-blitzmax"
curl --fail --location --retry 3 \
  -o BlitzMax_linux_x64_0.165.3.61.202610110603.tar.xz \
  https://github.com/bmx-ng/bmx-ng/releases/download/v0.165.3.61.202610110603.linux.x64/BlitzMax_linux_x64_0.165.3.61.202610110603.tar.xz
printf '%s\n' '7fceb285d30d83bdfdab51b98c690d2faad6569a81ad3e5961eb33ddca6f2406  BlitzMax_linux_x64_0.165.3.61.202610110603.tar.xz' | sha256sum --check -
# Continue only if the checksum reports OK.
tar -xJf BlitzMax_linux_x64_0.165.3.61.202610110603.tar.xz
export PATH="$HOME/.local/opt/gridwars-blitzmax/BlitzMax/bin:$PATH"
```

Return to the game checkout and build:

```sh
cd /path/to/GridWars
make
./gridwars
```

Alternatively, without changing `PATH`:

```sh
make BMK="$HOME/.local/opt/gridwars-blitzmax/BlitzMax/bin/bmk"
```

The equivalent direct compiler command is:

```sh
bmk makeapp -t gui -g x64 -r -w -o gridwars gridwars.bmx
```

Keep `-w`: the original code relies on implicit numeric argument conversions, which current NG otherwise rejects. Warnings about these conversions are expected. The project's rectangle helper is named `DrawGameRect` to avoid a collision with the current Max2D API.

`make debug` produces `gridwars.debug` with runtime checks; `make run` builds and launches the release executable. Both accept `BMK=...`. The first build compiles the imported BlitzMax modules and takes longer than subsequent builds. No 32-bit compatibility libraries are needed.

## Running and configuring

The supplied compiler's SDL backend uses X11. On a Wayland desktop, XWayland must be available; native Wayland support is not enabled in this compiler package. The game requires a compatibility OpenGL context, which preserves its immediate-mode grid drawing.

The game requests 1024x768 fullscreen by default and falls back to a window if that fullscreen mode cannot be created. Window sizes do not have to match the monitor's display modes.

Press **Enter**, **Space**, or the gamepad's **south face button** to start. **Esc** or **Start/Menu** opens the pause/options menu.

The default keyboard/mouse layout uses **WASD** to move, mouse aim with **left click** to fire, and **Space/right click** for a bomb. **Settings → Controls** also offers keyboard-only and mouse-only play, keyboard bindings, mouse options and the gamepad stick deadzone. Keyboard-only mode uses the arrow keys to fire. Existing bindings and mouse preferences are preserved when loading an older configuration; the old Dual Analog/Joypad modes migrate to the new automatic gamepad support.

| Action | Gamepad |
| --- | --- |
| Move | Left stick |
| Aim and fire | Right stick; release to stop firing |
| Bomb | South face button, right bumper or right trigger; one bomb per press |
| Pause/resume | Start/Menu |
| Navigate menus / change values | D-pad or left stick |
| Confirm / back | South / east face button |
| Enter a high-score name | Up/down changes the letter; left/right changes position; west changes case; east erases; south saves |

“South” means the bottom face button (A on Xbox, Cross on PlayStation); “east” means the right face button. These position-based prompts also work when Steam presents another controller as a virtual Xbox pad.

Gamepads use SDL's controller mappings instead of numbered joystick ports and manual axis calibration. Mapped controllers can connect or disconnect while the game runs; intentional controller or keyboard/mouse activity switches the input source automatically. The sticks use a circular, adjustable deadzone with normalized diagonal movement. Losing window focus or disconnecting the active controller pauses gameplay and requires an explicit resume. A stationary mouse no longer changes menu selection while using a controller.

Settings, colours and high scores are saved under `~/.config/gridwars/`. Set `GRIDWARS_CONFIG_DIR` to use a separate profile, for example while testing this branch alongside the Linux version. Old joystick calibration entries are discarded when the new configuration is saved. The `Config.txt`, `Colours.txt` and `hiscores.dat` in the checkout are reference files; they are not loaded automatically from there. Both the exit menu and a window-manager close save settings and scores.

## Launching through Steam

This branch first targets a **non-Steam game shortcut**. Build the Linux executable, then add `gridwars` to Steam with this checkout as its **Start In** directory. For a Steam Controller, Steam Deck or another device managed by Steam Input, select a **Gamepad** layout: left stick outputs left joystick, right stick/trackpad outputs right joystick, and the buttons output gamepad buttons. The game receives the mapped controller through SDL; no Steamworks SDK or App ID is required.

If desired, isolate the shortcut's settings using Steam's launch options:

```sh
env GRIDWARS_CONFIG_DIR=/absolute/path/to/gridwars-steam-settings %command%
```

The game respects SDL/Steam's device filtering and controller mappings, and does not alter Steam's global configuration. Unmapped raw joysticks are not supported. SDL's `SDL_GAMECONTROLLERCONFIG` environment variable can supply a mapping for a controller missing from the bundled SDL database.

Native Steam Input action sets/glyphs, Steamworks overlay callbacks, achievements, Cloud saves and Steam Runtime packaging are separate future work. Focus-loss pause is implemented here; an overlay that does not remove focus still needs the future Steamworks callback integration. This branch has not been certified or tested on a physical Steam Deck/Steam Controller.

WAV sound effects are supported. Background music is not implemented on Linux: the Linux music functions in `sound.bmx` are empty, while the original `.it` tracks use a Windows-only BASS wrapper. This is a pre-existing limitation, not a missing build dependency.

The checkout also lacks `sounds/shieldwarning.wav`, so that particular effect is silent. Both explosion effects use the supplied `sounds/Explo1.wav`, with its exact case for Linux filesystems.

## Validation

The automated controller tests use real SDL virtual devices, plus a temporary instrumented copy of the game. They cover mapped axes, radial deadzones, button edges, menu repeats, input switching, multiple controllers, hotplug, focus, gameplay, settings navigation, confirmation cancellation, high-score entry and saved configuration migration. Test devices and hooks are excluded from the shipped game, and tests use a temporary settings directory.

```sh
# With a display available:
make test BMK=/path/to/BlitzMax/bin/bmk
# Headless Linux (requires xvfb and xauth):
xvfb-run -a -s '-screen 0 1280x1024x24' make test BMK=/path/to/BlitzMax/bin/bmk
```

Release and debug builds are checked under Xvfb with Mesa llvmpipe software OpenGL. Hardware acceleration, audible output, physical controllers, the Steam client and a real Wayland desktop require separate validation.

## Historical Raspberry Pi cross-compilation notes

The following instructions describe the old Raspberry Pi toolchain and `/opt/vc` graphics stack. They have not been validated on current Raspberry Pi OS and are not part of the tested desktop Linux build above.

At the time of writing the build system, unfortunately, doesn't respect `CC` and `CXX`, and always calls the native compiler. You'll have to do some manual hacking.

- Make sure you have a C++ cross compiler installed (eg. `arm-linux-gnueabihf-g++`)
- Copy the OpenGL/GLES libraries from the Raspberry Pi to your system. You have to copy `/opt/vc/` from the Pi (or from a Pi disk image) to the same place on your native system. If this path is not good for you, you can change it in `BlitzMax/mod/sdl.mod/sdlgraphics.mod/sdlgraphics.bmx`
- Create a new directory that will hold symlinks to the cross compilers, eg. `armcc`, and enter into it
- `for f in /usr/bin/arm-linux-gnueabihf-*; do f2=$(basename $f); ln -s $f ./${f2/arm-linux-gnueabihf-/}; done`
- Install the dependencies of the BMX-NG compiler: `sudo apt-get install libasound2-dev libpulse-dev libxft-dev libxxf86vm-dev`
- Get the BMX-NG compiler for Linux from here: https://github.com/bmx-ng/bmx-ng/releases
- Extract it to somewhere
- `cd` into the cloned game repository
- Build the game like this: `PATH=/path/to/armcc:/path/to/BlitzMax/bin:$PATH bmk makeapp -t gui -l raspberrypi -g arm -r -w -v gridwars.bmx`
- At the very end, you will get a compile error about an unexpected `-m32` flag, or undefined EGL symbols. To fix it, copy the failing `g++` command, replace `g++` with `arm-linux-gnueabihf-g++`, remove `-m32` and also append `-lEGL` to the end
