# Smoke test for the ShiftIt Windows port.
#
# Starts Notepad, runs ShiftIt.exe --once <action> <hwnd> against it and
# verifies the resulting window rectangle against the expected geometry.
# Run from an interactive session:
#   powershell -ExecutionPolicy Bypass -File windows\test\smoke-test.ps1
#
# Requires: windows\ShiftIt.exe (build with build.cmd).

param(
    [string]$ShiftItExe = (Join-Path $PSScriptRoot "..\ShiftIt.exe")
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $ShiftItExe)) {
    Write-Host "FAIL: $ShiftItExe not found - run windows\build.cmd first"
    exit 1
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public struct RECT { public int Left, Top, Right, Bottom; }
public static class TestNative {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out RECT r, int cb);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr v);
    public static readonly IntPtr PMv2 = new IntPtr(-4);
    public static RECT Visible(IntPtr h) {
        RECT r;
        if (DwmGetWindowAttribute(h, 9, out r, 16) != 0) GetWindowRect(h, out r);
        return r;
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms
[TestNative]::SetProcessDpiAwarenessContext([TestNative]::PMv2) | Out-Null

$script:Failures = 0

function Get-VisibleRect([IntPtr]$hwnd) {
    $r = [TestNative]::Visible($hwnd)
    return @{ X = $r.Left; Y = $r.Top; W = ($r.Right - $r.Left); H = ($r.Bottom - $r.Top) }
}

function Invoke-ShiftIt([string]$action, [IntPtr]$hwnd) {
    Start-Process -FilePath $ShiftItExe -ArgumentList @("--once", $action, "$hwnd") -Wait
    Start-Sleep -Milliseconds 250
}

function Assert-Rect([string]$name, $expected) {
    $actual = Get-VisibleRect $script:NotepadHwnd
    $ok = $true
    foreach ($key in @("X", "Y", "W", "H")) {
        $diff = [Math]::Abs($expected[$key] - $actual[$key])
        if ($diff -gt 30) { $ok = $false }
    }
    if ($ok) {
        Write-Host ("PASS  {0}  -> ({1},{2}) {3}x{4}" -f $name, $actual.X, $actual.Y, $actual.W, $actual.H)
    } else {
        $script:Failures++
        Write-Host ("FAIL  {0}`n        expected X={1} Y={2} W={3} H={4}`n        actual   X={5} Y={6} W={7} H={8}" -f `
            $name, $expected.X, $expected.Y, $expected.W, $expected.H, $actual.X, $actual.Y, $actual.W, $actual.H)
    }
}

# --- launch a throwaway notepad window --------------------------------------
# Win11 Notepad is a store app: the launcher stub exits immediately, so find
# the real process by comparing Notepad processes before/after launch.
$existingIds = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
Start-Process notepad.exe

$proc = $null
$deadline = (Get-Date).AddSeconds(15)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 200
    $candidates = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue |
        Where-Object { $existingIds -notcontains $_.Id -and $_.MainWindowHandle -ne 0 })
    if ($candidates.Count -gt 0) { $proc = $candidates[0]; break }
}
if ($null -eq $proc) {
    Write-Host "FAIL: could not get a notepad window handle"
    exit 1
}
$procId = $proc.Id
$script:NotepadHwnd = $proc.MainWindowHandle
Write-Host ("Testing against notepad HWND {0} (PID {1})" -f $script:NotepadHwnd, $procId)

try {
    $work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $wx = $work.X; $wy = $work.Y; $ww = $work.Width; $wh = $work.Height
    Write-Host ("Primary work area: ({0},{1}) {2}x{3}" -f $wx, $wy, $ww, $wh)

    # halves
    Invoke-ShiftIt "left" $script:NotepadHwnd
    Assert-Rect "left half" @{ X = $wx; Y = $wy; W = [int]($ww / 2); H = $wh }

    Invoke-ShiftIt "right" $script:NotepadHwnd
    Assert-Rect "right half" @{ X = $wx + $ww - [int]($ww / 2); Y = $wy; W = [int]($ww / 2); H = $wh }

    # cycling: left -> 1/3 -> 2/3 (cycleWindowSizes defaults to on)
    Invoke-ShiftIt "left" $script:NotepadHwnd
    Assert-Rect "left half (cycle reset)" @{ X = $wx; Y = $wy; W = [int]($ww / 2); H = $wh }
    Invoke-ShiftIt "left" $script:NotepadHwnd
    Assert-Rect "left third" @{ X = $wx; Y = $wy; W = [int]($ww / 3); H = $wh }
    Invoke-ShiftIt "left" $script:NotepadHwnd
    Assert-Rect "left two thirds" @{ X = $wx; Y = $wy; W = [int]($ww * 2 / 3); H = $wh }

    # corners
    Invoke-ShiftIt "top" $script:NotepadHwnd
    Assert-Rect "top half" @{ X = $wx; Y = $wy; W = $ww; H = [int]($wh / 2) }

    Invoke-ShiftIt "top-left" $script:NotepadHwnd
    Assert-Rect "top-left quarter" @{ X = $wx; Y = $wy; W = [int]($ww / 2); H = [int]($wh / 2) }

    Invoke-ShiftIt "bottom-right" $script:NotepadHwnd
    Assert-Rect "bottom-right quarter" @{ X = $wx + [int]($ww / 2); Y = $wy + [int]($wh / 2); W = $ww - [int]($ww / 2); H = $wh - [int]($wh / 2) }

    # center keeps the current size
    $before = Get-VisibleRect $script:NotepadHwnd
    Invoke-ShiftIt "center" $script:NotepadHwnd
    Assert-Rect "center (size preserved)" @{
        X = $wx + [int](($ww - $before.W) / 2); Y = $wy + [int](($wh - $before.H) / 2);
        W = $before.W; H = $before.H }

    # maximize fills the work area
    Invoke-ShiftIt "maximize" $script:NotepadHwnd
    Assert-Rect "maximize" @{ X = $wx; Y = $wy; W = $ww; H = $wh }

    # toggle-maximize uses the native zoomed state
    Invoke-ShiftIt "toggle-maximize" $script:NotepadHwnd
    if ([TestNative]::IsZoomed($script:NotepadHwnd)) {
        Write-Host "PASS  toggle-maximize (IsZoomed)"
    } else {
        $script:Failures++
        Write-Host "FAIL  toggle-maximize: window not zoomed"
    }

    # screen change: no-op on a single monitor, must not crash either way
    Invoke-ShiftIt "next-screen" $script:NotepadHwnd
    Invoke-ShiftIt "previous-screen" $script:NotepadHwnd
    Write-Host "PASS  next/previous screen executed without error"
}
finally {
    $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($null -ne $p) {
        $p.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 500
        Stop-Process -Id $procId -ErrorAction SilentlyContinue
    }
}

if ($script:Failures -gt 0) {
    Write-Host ("`n{0} assertion(s) FAILED" -f $script:Failures)
    exit 1
}
Write-Host "`nAll assertions passed."
exit 0
