<h1><img src="https://raw.github.com/fikovnik/ShiftIt/develop/artwork/ShiftIt.png" width="72" height="72" valign="middle"/>ShiftIt <a href="https://travis-ci.org/fikovnik/ShiftIt"><img src="https://travis-ci.org/fikovnik/ShiftIt.svg" valign="middle" alt="Build Status"/></a></h1>

*Managing window size and position in OSX*

# About

ShiftIt is an application for OSX that allows you to quickly manipulate window position and size using keyboard shortcuts.
It intends to become a full featured window organizer for OSX.
It is a complete rewrite of the original [ShiftIt](http://code.google.com/p/shiftit/) by Aravindkumar Rajendiran which is not longer under development.
For discussing any sort of stuff about this app, please create a [new issue](https://github.com/fikovnik/ShiftIt/issues).

License: [GNU General Public License v3](http://www.gnu.org/licenses/gpl.html)

Change logs: change logs are versioned in the [repository](https://github.com/fikovnik/ShiftIt/tree/develop/release) as well.

## Download

A binary build for OSX 10.7+ is available in [releases](https://github.com/fikovnik/ShiftIt/releases).

## User guide

ShiftIt installs itself in the menu bar (optionally it can be completely hidden).
It provides a set of actions that manipulates windows positions and sizes.
Following is an example of list of actions available:

![Screenshot Menu](https://raw.github.com/fikovnik/ShiftIt/develop/docs/schreenshot-menu.png)

Normally, all Cocoa windows and X11 windows are supported.
Some applications might not work correctly or not at all.
There is a [list of known problems](https://github.com/fikovnik/ShiftIt/wiki/Application-Compatibility-Issues).
If you find any problem not mentioned there, please submit an issue.

## Requirements

* OSX 10.7+, 64-bit

The primary development is done on OSX 10.10, but it should be running under OSX 10.7 as well.

## FAQ

##### I disabled the _Show Icon in Menu Bar_ in the preferences, how can I get it back?

Launch the application again. It will open the preference dialog.

##### I pressed a shortcut, but nothing has happened, why?

While most of application windows should work well with ShiftIt, there are some exceptions (like the GTK+ OSX applications). There is a [list of known problems](https://github.com/fikovnik/ShiftIt/wiki/Application-Compatibility-Issues). If you find any problem not mentioned in the list, please raise an issue.

##### I pressed a shortcut, something happened, but not what I expected, why?

ShiftIt is based on a Cocoa Accessibility API and sometimes this API can be a bit [fragile](http://lists.apple.com/archives/accessibility-dev/2011/Aug/msg00031.html) and not do exactly what it should. In order to help to improve ShiftIt, please submit an issue every time you find some weird behavior. Before you do please consult the [list of known problems](https://github.com/fikovnik/ShiftIt/wiki/Application-Compatibility-Issues). Thanks!

##### ShiftIt wants accessibility access on my Mac but my system preferences don't match the instruction, why?

For instructions on accessibility in Mac OS X 10.9.x, see [this comment](https://github.com/fikovnik/ShiftIt/issues/110#issuecomment-20834932).

##### How to repair Accessibility API permissions?

This can be done either using  the GUI in _System Preferences_ -> _Security & Privacy_ -> _Privacy_ -> _Accessibility_ where it is necessary to check and uncheck the checkbox which is next to ShiftIt in the _Allow the apps below to control your computer_.
If ShiftIt is not in the list, just drag and drop it there from the `Applications` folder.

![ShiftIt permissions](https://github.com/fikovnik/ShiftIt/blob/master/ShiftIt/AccessibilitySettingsMaverick.png)

Alternatively, this can be also done in a command line, however, this is rather a hack with all potential issues hacks come with.

```sh
$ sudo sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' 'update access set allowed=1 where client like "%org.shiftitapp.ShiftIt%"'
``` 

For instructions on accessibility in Mac OS X 10.9.x, see [this comment](https://github.com/fikovnik/ShiftIt/issues/110#issuecomment-20834932).
If you've upgraded to 10.10, just uncheck and recheck the box to make things work again.

## Development

The repository is based on the git flow model. The development therefore happens in the `develop` branch. Any contribution is welcomed!

### Local build

To build ShiftIt locally just clone the repository or get the latest snapshot and execute following command in the `ShiftIt` directory:

```sh
$ xcodebuild -target ShiftIt -configuration Release
```

To make a build without X11 support execute following:

```sh
$ xcodebuild -target "ShiftIt NoX11" -configuration Release
```

### Brew Cask
To install  ShiftIt using brew you can use the cask.

```
$ brew cask install shiftit
```

### Making a release

Releases are handled using [fabric](http://docs.fabfile.org/en/1.5/). There are some dependencies that can be easily obtained using `pip`:

* [fabric](http://docs.fabfile.org/en/1.5/) - the build system itself
* [github3](https://github.com/sigmavirus24/github3.py) - library for GitHub 3 API
* [pystache](https://github.com/defunkt/pystache) - templates 

The releases are fully automatic which hopefully will help to release more often.

**Available commands**

* `archive` - Archives build
* `build` - Makes a build by executing xcodebuild
* `info` - Output all the build properties
* `release` - Prepare the release: sign the build, generate appcast, generate release notes
* `release_notes` - Generate release notes

After `fab release` instructions about how to create the actual release at github are printed.

Thanks [JetBrains](http://www.jetbrains.com/) for kindly supporting this open source project by providing [AppCode](http://www.jetbrains.com/objc/) IDE.
