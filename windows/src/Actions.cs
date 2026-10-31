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
using System.Windows.Forms;

namespace ShiftIt.Windows
{
    internal enum SpecialAction
    {
        None,
        ToggleMaximize,
        NextScreen,
        PreviousScreen
    }

    /// <summary>
    /// Computes the new window rectangle, expressed in work-area-relative
    /// coordinates (origin at the top-left of the screen's work area), from
    /// the current window rectangle and the work-area size. This is the port
    /// of the macOS SimpleWindowGeometryChangeBlock.
    /// </summary>
    internal delegate Rectangle GeometryChange(Rectangle windowRect, Size screenSize);

    internal sealed class ShiftItAction
    {
        public readonly string Id;
        public readonly string Label;
        public readonly Keys Shortcut;
        public readonly GeometryChange Change;
        public readonly SpecialAction Special;

        public ShiftItAction(string id, string label, Keys shortcut, GeometryChange change)
        {
            Id = id;
            Label = label;
            Shortcut = shortcut;
            Change = change;
            Special = SpecialAction.None;
        }

        public ShiftItAction(string id, string label, Keys shortcut, SpecialAction special)
        {
            Id = id;
            Label = label;
            Shortcut = shortcut;
            Change = null;
            Special = special;
        }
    }

    /// <summary>
    /// The default ShiftIt actions, ported from DefaultShiftItActions.m.
    /// All rectangles are work-area-relative; cycling behaviour (1/2 -> 1/3
    /// -> 2/3 on repeated snaps to the same edge) is detected statelessly by
    /// comparing the current rectangle to the cycle candidates with a 20px
    /// tolerance, exactly like rectCloseTo() in the original.
    /// </summary>
    internal static class Actions
    {
        private static bool CloseTo(int a, int b)
        {
            return Math.Abs(a - b) < 20;
        }

        private static bool RectCloseTo(Rectangle a, Rectangle b)
        {
            return CloseTo(a.X, b.X) && CloseTo(a.Y, b.Y)
                && CloseTo(a.Width, b.Width) && CloseTo(a.Height, b.Height);
        }

        public static readonly ShiftItAction[] All = new ShiftItAction[]
        {
            new ShiftItAction("left", "Snap Left",
                Keys.Control | Keys.Alt | Keys.Left,
                delegate(Rectangle w, Size s)
                {
                    Rectangle half = new Rectangle(0, 0, s.Width / 2, s.Height);
                    if (!Settings.CycleWindowSizes)
                    {
                        return half;
                    }
                    Rectangle third = new Rectangle(0, 0, s.Width / 3, s.Height);
                    if (RectCloseTo(w, half))
                    {
                        return third;
                    }
                    if (RectCloseTo(w, third))
                    {
                        return new Rectangle(0, 0, s.Width * 2 / 3, s.Height);
                    }
                    return half;
                }),
            new ShiftItAction("right", "Snap Right",
                Keys.Control | Keys.Alt | Keys.Right,
                delegate(Rectangle w, Size s)
                {
                    Rectangle half = new Rectangle(s.Width / 2, 0, s.Width - s.Width / 2, s.Height);
                    if (!Settings.CycleWindowSizes)
                    {
                        return half;
                    }
                    Rectangle third = new Rectangle(s.Width - s.Width / 3, 0, s.Width / 3, s.Height);
                    if (RectCloseTo(w, half))
                    {
                        return third;
                    }
                    Rectangle twoThirds = new Rectangle(s.Width - s.Width * 2 / 3, 0, s.Width * 2 / 3, s.Height);
                    if (RectCloseTo(w, third))
                    {
                        return twoThirds;
                    }
                    return half;
                }),
            new ShiftItAction("top", "Snap Top",
                Keys.Control | Keys.Alt | Keys.Up,
                delegate(Rectangle w, Size s)
                {
                    Rectangle half = new Rectangle(0, 0, s.Width, s.Height / 2);
                    if (!Settings.CycleWindowSizes)
                    {
                        return half;
                    }
                    Rectangle third = new Rectangle(0, 0, s.Width, s.Height / 3);
                    if (RectCloseTo(w, half))
                    {
                        return third;
                    }
                    if (RectCloseTo(w, third))
                    {
                        return new Rectangle(0, 0, s.Width, s.Height * 2 / 3);
                    }
                    return half;
                }),
            new ShiftItAction("bottom", "Snap Bottom",
                Keys.Control | Keys.Alt | Keys.Down,
                delegate(Rectangle w, Size s)
                {
                    Rectangle half = new Rectangle(0, s.Height / 2, s.Width, s.Height - s.Height / 2);
                    if (!Settings.CycleWindowSizes)
                    {
                        return half;
                    }
                    Rectangle third = new Rectangle(0, s.Height - s.Height / 3, s.Width, s.Height / 3);
                    if (RectCloseTo(w, half))
                    {
                        return third;
                    }
                    if (RectCloseTo(w, third))
                    {
                        return new Rectangle(0, s.Height - s.Height * 2 / 3, s.Width, s.Height * 2 / 3);
                    }
                    return half;
                }),
            new ShiftItAction("top-left", "Snap Top Left",
                Keys.Control | Keys.Alt | Keys.Home,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle(0, 0, s.Width / 2, s.Height / 2);
                }),
            new ShiftItAction("top-right", "Snap Top Right",
                Keys.Control | Keys.Alt | Keys.PageUp,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle(s.Width / 2, 0, s.Width - s.Width / 2, s.Height / 2);
                }),
            new ShiftItAction("bottom-left", "Snap Bottom Left",
                Keys.Control | Keys.Alt | Keys.End,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle(0, s.Height / 2, s.Width / 2, s.Height - s.Height / 2);
                }),
            new ShiftItAction("bottom-right", "Snap Bottom Right",
                Keys.Control | Keys.Alt | Keys.PageDown,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle(s.Width / 2, s.Height / 2, s.Width - s.Width / 2, s.Height - s.Height / 2);
                }),
            new ShiftItAction("maximize", "Maximize",
                Keys.Control | Keys.Alt | Keys.M,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle(0, 0, s.Width, s.Height);
                }),
            new ShiftItAction("center", "Center",
                Keys.Control | Keys.Alt | Keys.C,
                delegate(Rectangle w, Size s)
                {
                    return new Rectangle((s.Width - w.Width) / 2, (s.Height - w.Height) / 2, w.Width, w.Height);
                }),
            new ShiftItAction("toggle-maximize", "Toggle Maximize",
                Keys.Control | Keys.Alt | Keys.Shift | Keys.M,
                SpecialAction.ToggleMaximize),
            new ShiftItAction("next-screen", "Next Screen",
                Keys.Control | Keys.Alt | Keys.Shift | Keys.Right,
                SpecialAction.NextScreen),
            new ShiftItAction("previous-screen", "Previous Screen",
                Keys.Control | Keys.Alt | Keys.Shift | Keys.Left,
                SpecialAction.PreviousScreen),
        };

        public static ShiftItAction Find(string id)
        {
            foreach (ShiftItAction a in All)
            {
                if (a.Id == id)
                {
                    return a;
                }
            }
            return null;
        }
    }
}
