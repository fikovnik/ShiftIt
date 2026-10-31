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
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace ShiftIt.Windows
{
    /// <summary>
    /// Win32 equivalent of the macOS AXWindowDriver: finds the focused
    /// window, computes the target geometry (delegated to ShiftItAction)
    /// and applies it. All geometry handled here is the *visible* window
    /// bounds (DWM extended frame bounds), so snapped windows visually
    /// align with the screen edges even though SetWindowPos addresses the
    /// outer frame that includes Win10+ invisible resize borders.
    /// </summary>
    internal sealed class WindowManager
    {
        private readonly uint ownProcessId;

        /// <summary>
        /// Human-readable reason of the last failed Execute (null when the
        /// last execute succeeded). Surfaced as a balloon tip by the tray
        /// app so a no-op hotkey press is never silent.
        /// </summary>
        public string LastError
        {
            get;
            private set;
        }

        public WindowManager()
        {
            ownProcessId = (uint)System.Diagnostics.Process.GetCurrentProcess().Id;
        }

        public bool Execute(ShiftItAction action)
        {
            if (action == null)
            {
                LastError = null;
                return false;
            }
            IntPtr hwnd = ManagedForegroundWindow();
            if (hwnd == IntPtr.Zero)
            {
                LastError = "The focused window cannot be managed by ShiftIt "
                    + "(desktop, taskbar or a window of an elevated application).";
                return false;
            }
            return Execute(action, hwnd);
        }

        /// <summary>
        /// Runs an action against a specific window (used by the --once CLI
        /// mode and tests; the no-hwnd overload targets the focused window).
        /// </summary>
        public bool Execute(ShiftItAction action, IntPtr hwnd)
        {
            LastError = null;
            if (action == null || hwnd == IntPtr.Zero)
            {
                return false;
            }

            Rectangle visible = GetVisibleBounds(hwnd);
            if (visible.Width <= 0 || visible.Height <= 0)
            {
                return false;
            }

            if (action.Special == SpecialAction.ToggleMaximize)
            {
                Native.ShowWindow(hwnd, Native.IsZoomed(hwnd) ? Native.SW_RESTORE : Native.SW_MAXIMIZE);
                return true;
            }

            if (action.Special == SpecialAction.NextScreen || action.Special == SpecialAction.PreviousScreen)
            {
                return MoveToAdjacentScreen(hwnd, visible, action.Special == SpecialAction.NextScreen);
            }

            Screen screen = BestFitScreen(visible);
            if (screen == null)
            {
                return false;
            }

            // Parity with macOS ShiftIt: fullscreen windows are left alone
            // (deliberate no-op, not an error).
            if (IsFullScreen(visible, screen))
            {
                return true;
            }

            Rectangle work = screen.WorkingArea;
            Rectangle relative = new Rectangle(visible.X - work.X, visible.Y - work.Y,
                visible.Width, visible.Height);
            Rectangle target = action.Change(relative, work.Size);
            Rectangle absolute = new Rectangle(work.X + target.X, work.Y + target.Y,
                target.Width, target.Height);
            bool applied = ApplyGeometry(hwnd, absolute);
            if (!applied)
            {
                LastError = "\"" + GetWindowTitle(hwnd) + "\" did not accept the new geometry. "
                    + "Windows of elevated (administrator) applications cannot be moved by a "
                    + "non-elevated ShiftIt.";
            }
            return applied;
        }

        internal static string GetWindowTitle(IntPtr hwnd)
        {
            StringBuilder sb = new StringBuilder(256);
            Native.GetWindowText(hwnd, sb, sb.Capacity);
            return sb.ToString();
        }

        /// <summary>
        /// The focused window, excluding windows we should not manage
        /// (our own process, invisible/shell windows). Port of
        /// AXWindowDriver findFocusedWindow.
        /// </summary>
        private IntPtr ManagedForegroundWindow()
        {
            IntPtr hwnd = Native.GetForegroundWindow();
            if (hwnd == IntPtr.Zero)
            {
                return IntPtr.Zero;
            }

            uint pid;
            Native.GetWindowThreadProcessId(hwnd, out pid);
            if (pid == ownProcessId)
            {
                return IntPtr.Zero;
            }

            if ((Native.GetWindowLong(hwnd, Native.GWL_STYLE) & Native.WS_VISIBLE) == 0)
            {
                return IntPtr.Zero;
            }

            string className = GetWindowClassName(hwnd);
            if (className == "Shell_TrayWnd" || className == "Shell_SecondaryTrayWnd"
                || className == "Progman" || className == "WorkerW")
            {
                return IntPtr.Zero;
            }

            return hwnd;
        }

        private static string GetWindowClassName(IntPtr hwnd)
        {
            StringBuilder sb = new StringBuilder(256);
            Native.GetClassName(hwnd, sb, sb.Capacity);
            return sb.ToString();
        }

        /// <summary>
        /// The visible bounds of the window. Prefers the DWM extended frame
        /// bounds (what the user actually sees); falls back to GetWindowRect
        /// on older systems or when DWM is unavailable.
        /// </summary>
        public Rectangle GetVisibleBounds(IntPtr hwnd)
        {
            RECT rect;
            int hr = Native.DwmGetWindowAttribute(hwnd, Native.DWMWA_EXTENDED_FRAME_BOUNDS,
                out rect, System.Runtime.InteropServices.Marshal.SizeOf(typeof(RECT)));
            if (hr == 0)
            {
                return rect.ToRectangle();
            }
            RECT outer;
            Native.GetWindowRect(hwnd, out outer);
            return outer.ToRectangle();
        }

        /// <summary>
        /// Port of SIScreen screenForWindowGeometry: the screen on which the
        /// largest part of the window rectangle lies.
        /// </summary>
        public Screen BestFitScreen(Rectangle windowRect)
        {
            Screen best = null;
            long bestArea = 0;
            foreach (Screen screen in Screen.AllScreens)
            {
                Rectangle intersect = Rectangle.Intersect(windowRect, screen.Bounds);
                long area = (long)intersect.Width * intersect.Height;
                if (area > bestArea)
                {
                    best = screen;
                    bestArea = area;
                }
            }
            return best;
        }

        private static bool IsFullScreen(Rectangle visible, Screen screen)
        {
            Rectangle bounds = screen.Bounds;
            return visible.Width >= bounds.Width - 4 && visible.Height >= bounds.Height - 4;
        }

        /// <summary>
        /// Moves the window so that its *visible* frame covers
        /// targetVisible. The invisible resize borders (the difference
        /// between GetWindowRect and the DWM extended frame bounds) are
        /// added on top of the target so the result lines up exactly with
        /// the screen edge. Maximized/minimized windows are restored first.
        /// Returns false when the window did not end up at the target
        /// (e.g. elevated applications refuse to be moved).
        /// </summary>
        private bool ApplyGeometry(IntPtr hwnd, Rectangle targetVisible)
        {
            if (Native.IsZoomed(hwnd) || Native.IsIconic(hwnd))
            {
                Native.ShowWindow(hwnd, Native.SW_RESTORE);
            }

            RECT outer;
            Native.GetWindowRect(hwnd, out outer);
            RECT visible;
            int hr = Native.DwmGetWindowAttribute(hwnd, Native.DWMWA_EXTENDED_FRAME_BOUNDS,
                out visible, System.Runtime.InteropServices.Marshal.SizeOf(typeof(RECT)));
            if (hr != 0)
            {
                visible = outer;
            }

            int padLeft = visible.Left - outer.Left;
            int padTop = visible.Top - outer.Top;
            int padRight = outer.Right - visible.Right;
            int padBottom = outer.Bottom - visible.Bottom;

            Native.SetWindowPos(hwnd, IntPtr.Zero,
                targetVisible.X - padLeft,
                targetVisible.Y - padTop,
                targetVisible.Width + padLeft + padRight,
                targetVisible.Height + padTop + padBottom,
                Native.SWP_NOZORDER);

            // The window may clamp the size it accepts (min/max tracking
            // limits, fixed-size dialogs), so allow a generous tolerance
            // when checking whether the geometry was applied.
            const int tolerance = 60;
            Rectangle now = GetVisibleBounds(hwnd);
            return Math.Abs(now.X - targetVisible.X) <= tolerance
                && Math.Abs(now.Y - targetVisible.Y) <= tolerance
                && Math.Abs(now.Width - targetVisible.Width) <= tolerance
                && Math.Abs(now.Height - targetVisible.Height) <= tolerance;
        }

        /// <summary>
        /// Port of ScreenChangeShiftItAction: moves the window to the
        /// next/previous screen (ordered left-to-right, top-to-bottom, with
        /// wrap-around) and rescales its geometry proportionally to the
        /// target screen's work area, like the macOS original.
        /// </summary>
        private bool MoveToAdjacentScreen(IntPtr hwnd, Rectangle visible, bool next)
        {
            Screen[] screens = Screen.AllScreens;
            Array.Sort(screens, delegate(Screen a, Screen b)
            {
                int byX = a.Bounds.X.CompareTo(b.Bounds.X);
                return byX != 0 ? byX : a.Bounds.Y.CompareTo(b.Bounds.Y);
            });
            if (screens.Length < 2)
            {
                return true; // deliberate no-op on a single monitor
            }

            Screen current = BestFitScreen(visible);
            int index = 0;
            for (int i = 0; i < screens.Length; i++)
            {
                if (current != null && screens[i].DeviceName == current.DeviceName)
                {
                    index = i;
                    break;
                }
            }
            int targetIndex = ((index + (next ? 1 : -1)) % screens.Length + screens.Length) % screens.Length;
            Screen targetScreen = screens[targetIndex];

            Rectangle from = current != null ? current.WorkingArea : screens[index].WorkingArea;
            Rectangle to = targetScreen.WorkingArea;
            double kw = (double)to.Width / from.Width;
            double kh = (double)to.Height / from.Height;

            int x = to.X + (int)Math.Round((visible.X - from.X) * kw);
            int y = to.Y + (int)Math.Round((visible.Y - from.Y) * kh);
            int w = Math.Max(200, (int)Math.Round(visible.Width * kw));
            int h = Math.Max(120, (int)Math.Round(visible.Height * kh));

            // keep the window inside the target work area
            if (w > to.Width) w = to.Width;
            if (h > to.Height) h = to.Height;
            if (x < to.X) x = to.X;
            if (y < to.Y) y = to.Y;
            if (x + w > to.X + to.Width) x = to.X + to.Width - w;
            if (y + h > to.Y + to.Height) y = to.Y + to.Height - h;

            bool applied = ApplyGeometry(hwnd, new Rectangle(x, y, w, h));
            if (!applied)
            {
                LastError = "\"" + GetWindowTitle(hwnd) + "\" did not accept the new geometry. "
                    + "Windows of elevated (administrator) applications cannot be moved by a "
                    + "non-elevated ShiftIt.";
            }
            return applied;
        }
    }
}
