/*
 ShiftIt: Window Organizer — Windows port
 Copyright (c) 2010-2011 Filip Krikova (original macOS application)

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using System;
using System.Threading;
using System.Windows.Forms;

namespace ShiftIt.Windows
{
    internal static class Program
    {
        private static Mutex singleInstanceMutex;

        [STAThread]
        private static int Main(string[] args)
        {
            // Hidden helper mode: ShiftIt.exe --once <action-id> [hwnd] runs a
            // single action on the focused window (or the given window) and
            // exits (handy for scripting and testing). Exit code 1 means the
            // action could not be applied.
            if (args.Length >= 2 && args[0] == "--once")
            {
                EnablePerMonitorDpi();
                long handle = 0;
                if (args.Length >= 3)
                {
                    long.TryParse(args[2], out handle);
                }
                WindowManager wm = new WindowManager();
                bool ok = wm.Execute(Actions.Find(args[1]), new IntPtr(handle));
                if (!ok && wm.LastError != null)
                {
                    Console.Error.WriteLine(wm.LastError);
                }
                return ok ? 0 : 1;
            }

            if (args.Length == 1 && (args[0] == "--help" || args[0] == "-h" || args[0] == "/?"))
            {
                Console.Out.WriteLine("ShiftIt (Windows port) - manage window size and position");
                Console.Out.WriteLine();
                Console.Out.WriteLine("Usage:");
                Console.Out.WriteLine("  ShiftIt.exe              run as a tray application");
                Console.Out.WriteLine("  ShiftIt.exe --once <id>  run one action on the focused window and exit");
                Console.Out.WriteLine();
                Console.Out.WriteLine("Available actions:");
                foreach (ShiftItAction a in Actions.All)
                {
                    Console.Out.WriteLine("  " + a.Id.PadRight(16) + a.Label);
                }
                return 0;
            }

            bool createdNew;
            singleInstanceMutex = new Mutex(true, "ShiftIt_Windows_SingleInstance", out createdNew);
            if (!createdNew)
            {
                // Already running: ask the existing instance to show its
                // balloon tip so this launch attempt produces visible
                // feedback instead of a silent (crash-looking) exit.
                try
                {
                    System.Threading.EventWaitHandle existing;
                    if (System.Threading.EventWaitHandle.TryOpenExisting(
                        TrayApp.ShowBalloonEventName, out existing))
                    {
                        existing.Set();
                    }
                }
                catch (Exception)
                {
                    // no signaling possible: just exit
                }
                return 0;
            }

            EnablePerMonitorDpi();
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new TrayApp());

            GC.KeepAlive(singleInstanceMutex);
            return 0;
        }

        /// <summary>
        /// Per-monitor-v2 DPI awareness keeps WinForms Screen coordinates and
        /// Win32 window coordinates in the same physical-pixel space. On
        /// systems older than Windows 10 1703 the call fails harmlessly and
        /// the process runs system-DPI aware.
        /// </summary>
        private static void EnablePerMonitorDpi()
        {
            try
            {
                Native.SetProcessDpiAwarenessContext(Native.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
            }
            catch (Exception)
            {
                // old OS or entry point missing: stay at default awareness
            }
        }
    }
}
