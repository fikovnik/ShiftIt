<h1><img src="artwork/ShiftIt.png" width="72" height="72" valign="middle"/>ShiftIt</h1>

*Managing window size and position in macOS*

# About

This is a fork of [fikovnik/ShiftIt](https://github.com/fikovnik/ShiftIt) that
builds **natively for Apple Silicon (arm64)**. The upstream project is no
longer maintained and its latest release is Intel-only; this fork updates the
build and code so ShiftIt keeps working on modern macOS.

ShiftIt is an application for macOS that allows you to quickly manipulate
window position and size using keyboard shortcuts. It is a complete rewrite of
the original [ShiftIt](http://code.google.com/p/shiftit/) by Aravindkumar
Rajendiran which is no longer under development.

License: [GNU General Public License v3](http://www.gnu.org/licenses/gpl.html)

## Download

Build it yourself (see [Local build](#local-build)) — the result is a single
arch `arm64` app. There is no signed release, so no pre-built download is
offered.

## Installation

1. Copy `ShiftIt.app` to `/Applications`.
2. Launch it (unsigned app: right-click → *Open* → *Open* the first time).
3. **Grant accessibility access** — ShiftIt shows a dialog; click
   *Open System Preferences* and turn ON the switch next to ShiftIt under
   *System Settings → Privacy & Security → Accessibility*, then click
   *Recheck* in the dialog.

ShiftIt only needs this once. Note that the app is ad-hoc signed, so if you
**rebuild** it, macOS treats it as a different app and authorization must be
repeated (see the [FAQ](#i-rebuilt-shiftit-and-accessibility-stopped-working-why)).

## User guide

ShiftIt installs itself in the menu bar (optionally it can be completely
hidden). It provides a set of actions that manipulate window positions and
sizes:

![Screenshot Menu](docs/schreenshot-menu.png)

Normally, all Cocoa windows and X11 windows are supported (X11 requires
[XQuartz](https://www.xquartz.org/) to be installed). Some applications might
not work correctly or not at all; there is a
[list of known problems](https://github.com/fikovnik/ShiftIt/wiki/Application-Compatibility-Issues)
in the upstream wiki.

## Requirements

* macOS 10.13+, Apple Silicon (arm64)

## FAQ

##### How do I turn on/off windows cycling sizes with multiple hotkey presses?

If this feature is on, snapping to the left side of the screen (and top, bottom, and right sides) will resize the window to half of the screen.  If window is then snapped to the same side of the screen, it will resize to one third of the screen, and then two thirds of the screen.

If the feature is off, additional snappings will have no effect and the window will remain at half of the screen.

Currently, the only way to accomplish this is by running commands on the command line.  To turn the feature on, run:
```
defaults write org.shiftitapp.ShiftIt multipleActionsCycleWindowSizes YES
```
To turn it off, run:
```
defaults write org.shiftitapp.ShiftIt multipleActionsCycleWindowSizes NO
```

##### I disabled the _Show Icon in Menu Bar_ in the preferences, how can I get it back?

Launch the application again. It will open the preference dialog.

##### I pressed a shortcut, but nothing has happened, why?

Check that accessibility access is granted: *System Settings → Privacy &
Security → Accessibility* → switch ON next to ShiftIt. If the switch is ON and
shortcuts still do not work, turn it OFF and ON again.

While most application windows work well with ShiftIt, there are some
exceptions (like the GTK+ OSX applications); see the
[list of known problems](https://github.com/fikovnik/ShiftIt/wiki/Application-Compatibility-Issues).

##### I rebuilt ShiftIt and accessibility stopped working, why?

macOS ties accessibility authorization to the app's code signature. ShiftIt is
ad-hoc signed, so every rebuild produces a different signature and macOS treats
it as a different app. Reset the stale record and authorize again:

```sh
$ tccutil reset Accessibility org.shiftitapp.ShiftIt
```

then relaunch ShiftIt and turn the switch ON once more. Day-to-day use (without
rebuilding) is unaffected — authorization persists.

## Development

This fork commits directly to `master`.

### Local build

Requirements: Xcode with the macOS 10.13+ SDK (deployment target is 10.13).
Sparkle auto-update was removed; the bundled `ShortcutRecorder.framework` is an
arm64 build of [ShortcutRecorder](https://github.com/Kentzo/ShortcutRecorder).

To build ShiftIt locally just clone the repository and execute the following
command in the `ShiftIt` directory:

```sh
$ xcodebuild -target "ShiftIt NoX11" -configuration Release
```

The `ShiftIt NoX11` target is the recommended one: it is pure Cocoa and needs
no extra dependencies. The `ShiftIt` target additionally builds the X11
driver, which requires XQuartz headers (`/opt/X11/include`) and is loaded via
`dlopen` at runtime:

```sh
$ xcodebuild -target ShiftIt -configuration Release
```

The build lands in the `SYMROOT` you pass (e.g. `SYMROOT=../build`); verify
with `lipo -info` that the binary is arm64.

### Brew Cask

`brew install --cask shiftit` installs the **upstream Intel build**, which runs
under Rosetta only. If you want the native arm64 build, use the local build
above instead.

### Making a release

The old Python 2 / fabric release pipeline (DSA-signed appcast, Travis CI) was
removed along with the Sparkle auto-update it served. To cut a release
manually:

1. Update the version in [ShiftIt/ShiftIt-Info.plist](ShiftIt/ShiftIt-Info.plist)
   — it appears twice: `CFBundleShortVersionString` and `CFBundleVersion`.
2. Build: `xcodebuild -target "ShiftIt NoX11" -configuration Release SYMROOT=build/Release`
3. Package: `ditto -ck --keepParent build/Release/ShiftIt.app ShiftIt-<version>-arm64.zip`
4. Create a GitHub release in your fork and upload the zip.
