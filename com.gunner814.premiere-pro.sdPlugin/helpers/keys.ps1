# Keystroke helper for the Premiere Pro Stream Deck plugin.
# Long-running: reads lines "<vk> <mods> <count>" from stdin and taps that key <count> times,
# but ONLY while Adobe Premiere Pro is the foreground window.
#   mods bitmask: 1 = Shift, 2 = Ctrl, 4 = Alt
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Kbd {
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  public static void Tap(byte vk, int mods, int count) {
    // Arrow / navigation / Delete keys must carry the EXTENDED flag so they aren't read as numpad keys.
    uint ext = (vk >= 33 && vk <= 46) ? 1u : 0u;
    for (int i = 0; i < count; i++) {
      if ((mods & 2) != 0) keybd_event(0x11, 0, 0, UIntPtr.Zero);
      if ((mods & 1) != 0) keybd_event(0x10, 0, 0, UIntPtr.Zero);
      if ((mods & 4) != 0) keybd_event(0x12, 0, 0, UIntPtr.Zero);
      keybd_event(vk, 0, ext, UIntPtr.Zero);
      keybd_event(vk, 0, ext | 2u, UIntPtr.Zero);
      if ((mods & 4) != 0) keybd_event(0x12, 0, 2, UIntPtr.Zero);
      if ((mods & 1) != 0) keybd_event(0x10, 0, 2, UIntPtr.Zero);
      if ((mods & 2) != 0) keybd_event(0x11, 0, 2, UIntPtr.Zero);
    }
  }
}
"@

function Test-PremiereFocused {
  $h = [Kbd]::GetForegroundWindow()
  if ($h -eq [IntPtr]::Zero) { return $false }
  $procId = 0
  [void][Kbd]::GetWindowThreadProcessId($h, [ref]$procId)
  $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
  return ($p -and $p.ProcessName -like 'Adobe Premiere Pro*')
}

[Console]::Out.WriteLine('ready'); [Console]::Out.Flush()
while ($true) {
  $line = [Console]::In.ReadLine()
  if ($null -eq $line) { break }
  $parts = $line.Trim() -split '\s+'
  if ($parts.Count -lt 3) { continue }
  if (-not (Test-PremiereFocused)) { continue }
  [Kbd]::Tap([byte][int]$parts[0], [int]$parts[1], [int]$parts[2])
}
