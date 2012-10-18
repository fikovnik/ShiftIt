<h1><img src="https://github.com/fikovnik/ShiftIt/raw/master/artwork/ShiftIt.png" width="72" height="72" valign="middle"/>ShiftIt </h1>

*Managing window size and position in OSX*

**Note: The master branch is highly outdated, please have a look at the `shiftit16` branch.**

About
--------

ShiftIt is an application for OSX that allows you to quickly manipulate window position and size using keyboard shortcuts. It intends to become a full featured window organizer for OSX.
It is a fork from the original [ShiftIt][1] by [Aravindkumar Rajendiran][2] which is not longer under development. For discussing any sort of stuff about this app, please create a new issue [right here][3] in github. There is also quite a quiet [google group][4], but it's better to post stuff directly here.

License: [GNU General Public License v3][5]

Requirements
------------

The primary development is done on OSX 10.6 Snow Leopard, but it should be running under OSX 10.5 Leopard as well.

Compiling
---------

After cloning or download a snapshot of the repository (*master branch
is recommended*):

  * on OSX 10.6 Snow Leopard
       1. Compile in XCode by clicking build, or use the
        `scripts/release.sh` (*With the script option, please ignore any errors related to the signing the release. Just check if you see the `** BUILD SUCCEEDED **` message in the output and grab the app from `ShiftIt/build/Release/ShiftIt.app` directory.*)
       1. That's it
  * on OSX 10.5 Leopard
       1. Go to `Project` menu and click `Edit Project Settings` item
       1. Select `Build` tab
       1. Set `Architectures` to be `32-bit Universal`
       1. Select `C/C++ Compiler Version` to be `GCC 4.2`
       1. Check `Build Active Architecture Only`
	
The reason for this is that the Interface Builder frameworks on OS X Leopard 10.5 do not have 64-Bit capabilities. 

Note: If you have a problem with the build - xcode complaining about the ShortcutRecorder IB plugin then download (from [here][7]) and build it yourself. Once done load it into the Interface Builder (double click on the just built ShortcutRecorder.ibplugin).

FAQ
---

**I disabled the `Show Icon in Menu Bar` in the preferences, how can I get it back?how can I get it back?**

Launch the application again. It will open the preference dialog.

3rd Party Frameworks
--------------------

 * [ShortcutRecorder][7] framework (*New BSD license*) for capturing key bindings during hotkey reconfiguration. (*from version 1.4*)
 * [FMT][8] framework (*MIT license*) for some utility functions like handling login items, hot keys, etc. (*from version 1.5*)

Change Log:
---------------------------

  - [1.5][9]
  - [1.4.1][10]
  - [1.4][11]
  - [1.3][12]


  [1]: http://code.google.com/p/shiftit/
  [2]: http://ca.linkedin.com/in/aravind88
  [3]: https://github.com/fikovnik/ShiftIt/issues
  [4]: http://groups.google.com/group/shiftitapp
  [5]: http://www.gnu.org/licenses/gpl.html
  [7]: http://code.google.com/p/shortcutrecorder/
  [8]: https://github.com/fikovnik/FMT
  [9]: http://nkuyu.net/apps/shiftit/release-notes-1.5.html
  [10]: http://nkuyu.net/apps/shiftit/release-notes-1.4.1.html
  [11]: http://nkuyu.net/apps/shiftit/release-notes-1.4.html
  [12]: http://nkuyu.net/apps/shiftit/release-notes-1.3.html
