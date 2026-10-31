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
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using Microsoft.Win32;

namespace ShiftIt.Windows
{
    /// <summary>
    /// Message-only window that receives WM_HOTKEY from RegisterHotKey,
    /// the Windows equivalent of the Carbon event hot keys used on macOS.
    /// </summary>
    internal sealed class HotKeyWindow : NativeWindow
    {
        public delegate void HotKeyDelegate(int id);

        public event HotKeyDelegate HotKey;

        private const int HWND_MESSAGE = -3;

        public HotKeyWindow()
        {
            CreateParams cp = new CreateParams();
            cp.Caption = "ShiftIt_HotKeyWindow";
            cp.Parent = new IntPtr(HWND_MESSAGE);
            CreateHandle(cp);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == Native.WM_HOTKEY && HotKey != null)
            {
                HotKey(m.WParam.ToInt32());
            }
            base.WndProc(ref m);
        }
    }

    /// <summary>
    /// The tray application: menu bar icon equivalent on Windows is a
    /// notification-area icon with a context menu exposing all ShiftIt
    /// actions plus settings.
    /// </summary>
    internal sealed class TrayApp : ApplicationContext
    {
        private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
        private const string RunValueName = "ShiftIt";

        /// <summary>
        /// Cross-process event used by a second launch attempt to ask the
        /// running instance to show its "already running" balloon tip
        /// instead of exiting silently (which reads like a crash).
        /// </summary>
        public const string ShowBalloonEventName = "ShiftIt_ShowBalloon";

        private readonly WindowManager windows = new WindowManager();
        private readonly HotKeyWindow hotKeyWindow = new HotKeyWindow();
        private readonly System.Threading.ManualResetEvent shutDown =
            new System.Threading.ManualResetEvent(false);
        private NotifyIcon trayIcon;
        private ToolStripMenuItem cycleItem;
        private ToolStripMenuItem startupItem;
        private System.Threading.SynchronizationContext uiContext;
        private System.Threading.EventWaitHandle showBalloonEvent;
        private System.Collections.Generic.List<string> hotKeyConflicts;

        public TrayApp()
        {
            uiContext = new System.Windows.Forms.WindowsFormsSynchronizationContext();
            BuildMenu();
            hotKeyConflicts = RegisterHotKeys();
            ListenForShowRequests();
            ShowStartupBalloon();
            Application.ApplicationExit += new EventHandler(OnApplicationExit);
        }

        private void BuildMenu()
        {
            ContextMenuStrip menu = new ContextMenuStrip();

            foreach (ShiftItAction action in Actions.All)
            {
                ToolStripMenuItem item = new ToolStripMenuItem(action.Label);
                item.ShortcutKeys = action.Shortcut;
                item.ShowShortcutKeys = true;
                ShiftItAction captured = action;
                item.Click += delegate(object sender, EventArgs e) { RunAction(captured); };
                menu.Items.Add(item);
            }

            menu.Items.Add(new ToolStripSeparator());

            cycleItem = new ToolStripMenuItem("Cycle window sizes (1/2 \u2192 1/3 \u2192 2/3)");
            cycleItem.Checked = Settings.CycleWindowSizes;
            cycleItem.Click += delegate(object sender, EventArgs e)
            {
                cycleItem.Checked = !cycleItem.Checked;
                Settings.CycleWindowSizes = cycleItem.Checked;
            };
            menu.Items.Add(cycleItem);

            startupItem = new ToolStripMenuItem("Run at startup");
            startupItem.Checked = IsRunAtStartupEnabled();
            startupItem.Click += delegate(object sender, EventArgs e)
            {
                startupItem.Checked = !startupItem.Checked;
                SetRunAtStartup(startupItem.Checked);
            };
            menu.Items.Add(startupItem);

            menu.Items.Add(new ToolStripSeparator());

            ToolStripMenuItem aboutItem = new ToolStripMenuItem("About ShiftIt\u2026");
            aboutItem.Click += delegate(object sender, EventArgs e)
            {
                MessageBox.Show(
                    "ShiftIt " + Application.ProductVersion + " (Windows port)\n\n"
                    + "Manage window size and position with keyboard shortcuts.\n"
                    + "Port of https://github.com/fikovnik/ShiftIt (GPLv3).",
                    "About ShiftIt", MessageBoxButtons.OK, MessageBoxIcon.Information);
            };
            menu.Items.Add(aboutItem);

            ToolStripMenuItem exitItem = new ToolStripMenuItem("Exit");
            exitItem.Click += delegate(object sender, EventArgs e) { Application.Exit(); };
            menu.Items.Add(exitItem);

            trayIcon = new NotifyIcon();
            trayIcon.Text = "ShiftIt (Ctrl+Alt+Arrows to snap)";
            trayIcon.Icon = CreateIcon();
            trayIcon.ContextMenuStrip = menu;
            trayIcon.Visible = true;
        }

        private System.Collections.Generic.List<string> RegisterHotKeys()
        {
            System.Collections.Generic.List<string> conflicts =
                new System.Collections.Generic.List<string>();
            hotKeyWindow.HotKey += new HotKeyWindow.HotKeyDelegate(OnHotKey);
            for (int i = 0; i < Actions.All.Length; i++)
            {
                Keys k = Actions.All[i].Shortcut;
                uint modifiers = 0;
                if ((k & Keys.Control) != 0) modifiers |= Native.MOD_CONTROL;
                if ((k & Keys.Alt) != 0) modifiers |= Native.MOD_ALT;
                if ((k & Keys.Shift) != 0) modifiers |= Native.MOD_SHIFT;
                uint vk = (uint)(k & Keys.KeyCode);
                if (!Native.RegisterHotKey(hotKeyWindow.Handle, i, modifiers, vk))
                {
                    // A hot key may already be taken by another application
                    // (e.g. Intel display drivers use Ctrl+Alt+Arrows); the
                    // action stays available from the tray menu.
                    string label = Actions.All[i].Label + " (" +
                        TypeDescriptor.GetConverter(typeof(Keys)).ConvertToString(k) + ")";
                    conflicts.Add(label);
                    System.Diagnostics.Debug.WriteLine("ShiftIt: hot key registration failed for " + Actions.All[i].Id);
                }
            }
            return conflicts;
        }

        /// <summary>
        /// Balloon shown on every start and when a second launch attempt is
        /// made, so a tray-only application without any window never looks
        /// like it failed to start.
        /// </summary>
        private void ShowStartupBalloon()
        {
            string text = "Snap windows: Ctrl+Alt+Arrows (halves), " +
                "Ctrl+Alt+Home/PgUp/End/PgDn (corners), Ctrl+Alt+M (maximize).\n" +
                "Right-click the ShiftIt tray icon for all actions.";
            if (hotKeyConflicts.Count > 0)
            {
                string taken = string.Join(", ", hotKeyConflicts.ToArray());
                if (taken.Length > 120)
                {
                    taken = taken.Substring(0, 120) + "\u2026";
                }
                text += "\n\nTaken by other apps (use tray menu): " + taken;
            }
            trayIcon.BalloonTipTitle = "ShiftIt is running";
            trayIcon.BalloonTipText = text;
            trayIcon.BalloonTipIcon = ToolTipIcon.Info;
            trayIcon.ShowBalloonTip(5000);
        }

        private void ListenForShowRequests()
        {
            showBalloonEvent = new System.Threading.EventWaitHandle(
                false, System.Threading.EventResetMode.AutoReset, ShowBalloonEventName);
            System.Threading.ThreadPool.QueueUserWorkItem(delegate(object state)
            {
                while (true)
                {
                    int hit = System.Threading.WaitHandle.WaitAny(
                        new System.Threading.WaitHandle[] { showBalloonEvent, shutDown });
                    if (hit == 1)
                    {
                        return;
                    }
                    try
                    {
                        uiContext.Post(delegate(object o) { ShowStartupBalloon(); }, null);
                    }
                    catch (Exception)
                    {
                        return; // UI thread already gone
                    }
                }
            });
        }

        private void OnHotKey(int id)
        {
            if (id >= 0 && id < Actions.All.Length)
            {
                RunAction(Actions.All[id]);
            }
        }

        private void RunAction(ShiftItAction action)
        {
            try
            {
                if (!windows.Execute(action) && windows.LastError != null)
                {
                    ShowFailureBalloon(windows.LastError);
                }
            }
            catch (Exception ex)
            {
                // Actions must never take the process down; a failing window
                // (e.g. an elevated app refusing to be moved) is ignored.
                System.Diagnostics.Debug.WriteLine("ShiftIt: action " + action.Id + " failed: " + ex.Message);
            }
        }

        private DateTime lastFailureBalloon = DateTime.MinValue;

        /// <summary>
        /// A hot key press that does nothing must never be silent: say which
        /// window refused to move and why. Rate-limited so a repeated press
        /// cannot flood the user with balloons.
        /// </summary>
        private void ShowFailureBalloon(string reason)
        {
            if ((DateTime.UtcNow - lastFailureBalloon).TotalSeconds < 5)
            {
                return;
            }
            lastFailureBalloon = DateTime.UtcNow;
            trayIcon.BalloonTipTitle = "ShiftIt could not move the window";
            trayIcon.BalloonTipText = reason;
            trayIcon.BalloonTipIcon = ToolTipIcon.Warning;
            trayIcon.ShowBalloonTip(5000);
        }

        private static bool IsRunAtStartupEnabled()
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(RunKey))
                {
                    return key != null && key.GetValue(RunValueName) != null;
                }
            }
            catch (Exception)
            {
                return false;
            }
        }

        private static void SetRunAtStartup(bool enable)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.CreateSubKey(RunKey))
                {
                    if (enable)
                    {
                        key.SetValue(RunValueName, "\"" + Application.ExecutablePath + "\"");
                    }
                    else if (key.GetValue(RunValueName) != null)
                    {
                        key.DeleteValue(RunValueName);
                    }
                }
            }
            catch (Exception)
            {
                // best effort
            }
        }

        /// <summary>
        /// Draws the tray icon (a cross of arrows) instead of shipping a
        /// binary resource.
        /// </summary>
        private static Icon CreateIcon()
        {
            Bitmap bmp = new Bitmap(32, 32);
            using (Graphics g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);
                using (SolidBrush bg = new SolidBrush(Color.FromArgb(45, 45, 50)))
                {
                    g.FillEllipse(bg, 1, 1, 30, 30);
                }
                using (Pen pen = new Pen(Color.White, 2.5f))
                {
                    pen.CustomStartCap = new AdjustableArrowCap(3.5f, 3.5f);
                    pen.CustomEndCap = new AdjustableArrowCap(3.5f, 3.5f);
                    g.DrawLine(pen, 16, 8, 16, 24);
                    g.DrawLine(pen, 8, 16, 24, 16);
                }
            }
            return Icon.FromHandle(bmp.GetHicon());
        }

        private void OnApplicationExit(object sender, EventArgs e)
        {
            shutDown.Set();
            if (showBalloonEvent != null)
            {
                showBalloonEvent.Close();
            }
            for (int i = 0; i < Actions.All.Length; i++)
            {
                Native.UnregisterHotKey(hotKeyWindow.Handle, i);
            }
            if (trayIcon != null)
            {
                trayIcon.Visible = false;
                if (trayIcon.Icon != null)
                {
                    Native.DestroyIcon(trayIcon.Icon.Handle);
                }
                trayIcon.Dispose();
            }
            hotKeyWindow.DestroyHandle();
        }
    }
}
