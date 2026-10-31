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
using System.Collections.Generic;
using System.IO;

namespace ShiftIt.Windows
{
    /// <summary>
    /// Persistent user settings, stored as a plain INI file under
    /// %APPDATA%\ShiftIt\settings.ini (analogous to NSUserDefaults on macOS).
    /// </summary>
    internal static class Settings
    {
        private const string FileName = "settings.ini";

        private static readonly object Gate = new object();
        private static Dictionary<string, string> values;
        private static string filePath;

        /// <summary>
        /// Port of the macOS kMutipleActionsCycleWindowSizes default: when on,
        /// snapping repeatedly to the same edge cycles the window between 1/2,
        /// 1/3 and 2/3 of the screen. Defaults to ON here because the Windows
        /// port exposes no thirds-specific shortcuts; it can be turned off from
        /// the tray menu.
        /// </summary>
        public static bool CycleWindowSizes
        {
            get { return ReadBool("cycleWindowSizes", true); }
            set { WriteBool("cycleWindowSizes", value); }
        }

        private static string FilePath()
        {
            if (filePath == null)
            {
                string dir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                    "ShiftIt");
                Directory.CreateDirectory(dir);
                filePath = Path.Combine(dir, FileName);
            }
            return filePath;
        }

        private static Dictionary<string, string> Load()
        {
            if (values != null)
            {
                return values;
            }
            values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            try
            {
                if (File.Exists(FilePath()))
                {
                    foreach (string raw in File.ReadAllLines(FilePath()))
                    {
                        string line = raw.Trim();
                        if (line.Length == 0 || line.StartsWith(";") || line.StartsWith("["))
                        {
                            continue;
                        }
                        int eq = line.IndexOf('=');
                        if (eq > 0)
                        {
                            values[line.Substring(0, eq).Trim()] = line.Substring(eq + 1).Trim();
                        }
                    }
                }
            }
            catch (Exception)
            {
                // unreadable settings file: fall back to defaults
            }
            return values;
        }

        private static bool ReadBool(string key, bool def)
        {
            lock (Gate)
            {
                string v;
                return Load().TryGetValue(key, out v) ? v == "1" || v.Equals("true", StringComparison.OrdinalIgnoreCase) : def;
            }
        }

        private static void WriteBool(string key, bool value)
        {
            lock (Gate)
            {
                Load()[key] = value ? "1" : "0";
                try
                {
                    List<string> lines = new List<string>();
                    lines.Add("; ShiftIt (Windows) settings");
                    foreach (KeyValuePair<string, string> kv in values)
                    {
                        lines.Add(kv.Key + "=" + kv.Value);
                    }
                    File.WriteAllLines(FilePath(), lines.ToArray());
                }
                catch (Exception)
                {
                    // best effort: settings just won't persist
                }
            }
        }
    }
}
