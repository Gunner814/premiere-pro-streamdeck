<#
.SYNOPSIS
  Generates a "Premiere Pro" profile for the Stream Deck + XL (9x4 keys, 6 dials)
  and optionally installs it together with the Premiere Pro Stream Deck plugin.

.DESCRIPTION
  Keys use Stream Deck's built-in Hotkey / Page actions with a flat colour background and
  text only. Each ROW is one category with its own colour. Dials use this repo's
  "Timeline Dial" plugin action (build it first: npm run build).

  Coordinates in the profile format are "col,row": keys 0..8 x 0..3, dials 0..5 x 0.
  Shortcuts are Premiere Pro's DEFAULT Windows shortcuts.

  Without -Install the profile is only written to ..\dist.
  With -Install (Stream Deck must be CLOSED) the script:
    1. backs up ProfilesV3 to Documents,
    2. removes any previous profile named "Premiere Pro" that this script made,
    3. copies the new profile into ProfilesV3 (your other profiles are untouched),
    4. copies the plugin into the Stream Deck Plugins folder.
#>
param(
  [switch]$Install,
  [string]$PremiereExe = "C:\Program Files\Adobe\Adobe Premiere Pro 2026\Adobe Premiere Pro.exe"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repo    = Split-Path $PSScriptRoot -Parent
$sdRoot  = "$env:APPDATA\Elgato\StreamDeck"
$root    = "$sdRoot\ProfilesV3"
$out     = Join-Path $repo 'dist'
$plugSrc = Join-Path $repo 'com.gunner814.premiere-pro.sdPlugin'
$PLUGIN  = 'com.gunner814.premiere-pro'

# Reuse the Stream Deck + XL device model/UUID from an existing profile on this machine.
$dev = Get-ChildItem $root -Directory -Filter *.sdProfile |
  ForEach-Object { (Get-Content "$($_.FullName)\manifest.json" -Raw | ConvertFrom-Json).Device } |
  Where-Object { $_.Model -eq '20GBX9901' } | Select-Object -First 1   # 20GBX9901 = Stream Deck + XL
if (-not $dev) { throw "No Stream Deck + XL profile found under $root to copy the device ID from." }

# Row colours (one category per row). Key = image id, value = background colour.
$colors = [ordered]@{
  PLAYBACK = '#1B4F9C'   # blue
  PLAYNOW  = '#2F7BFF'   # bright blue (Play / Pause)
  CUT      = '#A12D2D'   # red
  TOOLS    = '#2A7A4B'   # green
  MARK     = '#B0690A'   # amber
  VIEW     = '#1B4F9C'   # blue
  CLIP     = '#6B3FA0'   # purple
  CLIPBRD  = '#4B4F56'   # grey
  PROJECT  = '#B0690A'   # amber
  NAV      = '#2B2B2B'   # dark = page button
}

# mods bitmask: Shift=1, Ctrl=2, Alt=4
function New-State($title,$img) {
  @{ Title=$title; Image="Images/$img.png"; ShowTitle=$true; TitleAlignment='middle'; TitleColor='#ffffff'; FontSize=12 }
}
function New-Hotkey($title,$vk,$qt,$mods,$img) {
  $h = @{ KeyCmd=$false; KeyCtrl=[bool]($mods -band 2); KeyShift=[bool]($mods -band 1); KeyOption=[bool]($mods -band 4)
          KeyModifiers=$mods; NativeCode=$vk; QTKeyCode=$qt; VKeyCode=$vk }
  @{ ActionID=[guid]::NewGuid().ToString(); LinkedTitle=$true; Name='Hotkey'
     Plugin=@{ Name='Activate a Key Command'; UUID='com.elgato.streamdeck.system.hotkey'; Version='1.0' }
     Resources=$null; Settings=@{ Coalesce=$true; Hotkeys=@($h) }; State=0
     States=@(New-State $title $img); UUID='com.elgato.streamdeck.system.hotkey' }
}
function New-Nav($kind,$title) {
  @{ ActionID=[guid]::NewGuid().ToString(); LinkedTitle=$true; Name=$title
     Plugin=@{ Name='Pages'; UUID='com.elgato.streamdeck.page'; Version='1.0' }
     Resources=$null; Settings=@{}; State=0
     States=@(New-State $title 'NAV'); UUID="com.elgato.streamdeck.page.$kind" }
}
function New-Dial($mode) {
  @{ ActionID=[guid]::NewGuid().ToString(); LinkedTitle=$true; Name='Timeline Dial'
     Plugin=@{ Name='Premiere Pro'; UUID=$PLUGIN; Version='0.1.0.0' }
     Resources=$null; Settings=@{ mode=$mode }; State=0
     States=@(@{ FontFamily=''; FontSize=12; FontStyle=''; FontUnderline=$false; OutlineThickness=2; ShowTitle=$true; TitleAlignment='middle'; TitleColor='#ffffff' })
     UUID="$PLUGIN.timeline-dial" }
}
# Shorthand per row: H title vk qt mods
$DEL=16777223; $RET=16777220; $LEFT=16777234; $RIGHT=16777236; $UPQ=16777235; $DOWNQ=16777237
function PB($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'PLAYBACK' }
function CU($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'CUT' }
function TL($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'TOOLS' }
function MK($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'MARK' }
function VW($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'VIEW' }
function CL($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'CLIP' }
function CB($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'CLIPBRD' }
function PJ($t,$vk,$qt,$m)  { New-Hotkey $t $vk $qt $m 'PROJECT' }

# ===== PAGE 1: EDIT.  Rows = categories; keys are "col,row" (9 x 4). =====
# Most-used keys sit on the LEFT. Bottom row = playback (closest to the hand), PLAY / PAUSE bottom-left.
$page1 = [ordered]@{
  # Row 0 - CUT (red)
  '0,0'=CU "Cut at`nPlayhead" 75 75 2;      '1,0'=CU "Cut All`nTracks" 75 75 3
  '2,0'=CU "Delete +`nClose Gap" 46 $DEL 1; '3,0'=CU "Delete`nKeep Gap" 46 $DEL 0
  '4,0'=CU "Trim`nBack" 81 81 0; '5,0'=CU "Trim`nFwd" 87 87 0
  '6,0'=CU "Extend`nEdit" 69 69 0; '7,0'=CU "Lift" 186 59 0
  '8,0'=CU "Extract" 222 39 0
  # Row 1 - TOOLS (green)
  '0,1'=TL "Select" 86 86 0;                '1,1'=TL "Razor" 67 67 0
  '2,1'=TL "Ripple`nEdit" 66 66 0;          '3,1'=TL "Rate`nStretch" 82 82 0
  '4,1'=TL "Slip" 89 89 0;                  '5,1'=TL "Slide" 85 85 0
  '6,1'=TL "Pen" 80 80 0;                   '7,1'=TL "Hand" 72 72 0
  '8,1'=TL "Zoom`nTool" 90 90 0
  # Row 2 - UNDO, MARKS, SAVE (amber). Undo / Redo first.
  '0,2'=MK "Undo" 90 90 2;                  '1,2'=MK "Redo" 90 90 3
  '2,2'=MK "Mark In" 73 73 0;               '3,2'=MK "Mark Out" 79 79 0
  '4,2'=MK "Clear`nIn / Out" 88 88 3;       '5,2'=MK "Add`nMarker" 77 77 0
  '6,2'=MK "Snap`nOn / Off" 83 83 0;        '7,2'=MK "Save" 83 83 2
  '8,2'=New-Nav 'next' 'MORE >'
  # Row 3 - PLAYBACK (blue). Play / Pause bottom-left.
  '0,3'=New-Hotkey "PLAY /`nPAUSE" 32 32 0 'PLAYNOW'
  '1,3'=PB "Back`n1 Frame" 37 $LEFT 0;      '2,3'=PB "Forward`n1 Frame" 39 $RIGHT 0
  '3,3'=PB "Back`n5 Frames" 37 $LEFT 1;     '4,3'=PB "Forward`n5 Frames" 39 $RIGHT 1
  '5,3'=PB "Previous`nEdit" 38 $UPQ 0;      '6,3'=PB "Next`nEdit" 40 $DOWNQ 0
  '7,3'=PB "Play`nReverse" 74 74 0;        '8,3'=PB "Play`nForward" 76 76 0
}
# ===== PAGE 2: MORE (same row order: blue view/navigate on the bottom row, amber third) =====
$page2 = [ordered]@{
  # Row 0 - CLIP (purple)
  '0,0'=CL "Speed /`nDuration" 82 82 2;     '1,0'=CL "Link /`nUnlink" 76 76 2
  '2,0'=CL "Group" 71 71 2;                 '3,0'=CL "Ungroup" 71 71 3
  '4,0'=CL "Default`nTransition" 68 68 2;   '5,0'=CL "Enable /`nDisable" 69 69 1
  '6,0'=CL "Render`nIn to Out" 13 $RET 0
  # Row 1 - CLIPBOARD (grey)
  '0,1'=CB "Copy" 67 67 2;                  '1,1'=CB "Cut" 88 88 2
  '2,1'=CB "Paste" 86 86 2;                 '3,1'=CB "Paste`nInsert" 86 86 3
  '4,1'=CB "Paste`nAttributes" 86 86 6;     '5,1'=CB "Select`nAll" 65 65 2
  '6,1'=CB "Deselect`nAll" 65 65 3
  # Row 2 - PROJECT (amber)
  '0,2'=PJ "Import" 73 73 2;                '1,2'=PJ "Export" 77 77 2
  '2,2'=PJ "Save As" 83 83 3;               '3,2'=PJ "New Bin" 66 66 2
  '8,2'=New-Nav 'previous' '< BACK'
  # Row 3 - VIEW / NAVIGATE (blue)
  '0,3'=VW "Go to`nIn" 73 73 1;             '1,3'=VW "Go to`nOut" 79 79 1
  '2,3'=VW "Match`nFrame" 70 70 0;          '3,3'=VW "Reverse`nMatch" 82 82 1
  '4,3'=VW "Timeline`nZoom In" 187 61 0;    '5,3'=VW "Timeline`nZoom Out" 189 45 0
  '6,3'=VW "Fit`nSequence" 220 92 0;        '7,3'=VW "Maximize`nPanel" 192 96 0
}
$pages = @(@{Name='Edit';Keys=$page1}, @{Name='More';Keys=$page2})

# 6 dials, one per column across the top ("col,0"). Same on every page.
$dials = [ordered]@{
  '0,0'=New-Dial 'frame'; '1,0'=New-Dial 'frame5'; '2,0'=New-Dial 'edit'
  '3,0'=New-Dial 'zoom';  '4,0'=New-Dial 'shuttle'; '5,0'=New-Dial 'undo'
}

# ---- write profile ----
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory $out | Out-Null
$profId = [guid]::NewGuid().ToString().ToUpper()
$pdir   = "$out\$profId.sdProfile"
$ids    = @($pages | ForEach-Object { [guid]::NewGuid().ToString() })
$defId  = [guid]::NewGuid().ToString()
foreach ($g in @($defId) + $ids) { New-Item -ItemType Directory -Force "$pdir\Profiles\$($g.ToUpper())\Images" | Out-Null }
New-Item -ItemType Directory -Force "$pdir\Images" | Out-Null

function New-ColorPng($path,$hex) {
  $bmp = New-Object Drawing.Bitmap 144,144
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.Clear([Drawing.ColorTranslator]::FromHtml($hex))
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(70,255,255,255)), 4
  $g.DrawRectangle($pen, 2, 2, 139, 139)
  $g.Dispose(); $pen.Dispose()
  $bmp.Save($path, [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
foreach ($g in $ids) { foreach ($c in $colors.Keys) { New-ColorPng "$pdir\Profiles\$($g.ToUpper())\Images\$c.png" $colors[$c] } }

$utf8 = New-Object Text.UTF8Encoding $false
function Save-Json($obj,$path) { [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 20 -Compress), $utf8) }

Save-Json @{ Controllers=@(@{Actions=$null;Type='Keypad'},@{Actions=$null;Type='Encoder'}); Icon=''; Name='' } "$pdir\Profiles\$($defId.ToUpper())\manifest.json"
for ($i=0; $i -lt $pages.Count; $i++) {
  Save-Json @{ Controllers=@(@{Actions=$pages[$i].Keys;Type='Keypad'},@{Actions=$dials;Type='Encoder'}); Icon=''; Name=$pages[$i].Name } `
            "$pdir\Profiles\$($ids[$i].ToUpper())\manifest.json"
}
Save-Json ([ordered]@{ AppIdentifier=$PremiereExe; Device=@{Model=$dev.Model;UUID=$dev.UUID}; Name='Premiere Pro'
          Pages=@{ Current=$ids[0]; Default=$defId; Pages=@($ids) }; Version='3.0' }) "$pdir\manifest.json"
"Profile generated: $pdir"

# ---- install ----
if ($Install) {
  if (Get-Process StreamDeck -ErrorAction SilentlyContinue) { throw "Quit Stream Deck first (tray icon > Quit), then re-run with -Install." }
  if (-not (Test-Path "$plugSrc\bin\plugin.js")) { throw "Plugin not built. Run: npm install; npm run build" }

  $bak = "$env:USERPROFILE\Documents\StreamDeck-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $root "$bak\ProfilesV3" -Recurse
  "Backup: $bak"

  # Remove only previous profiles of ours: named "Premiere Pro" and bound to a Premiere executable.
  Get-ChildItem $root -Directory -Filter *.sdProfile | ForEach-Object {
    $m = Get-Content "$($_.FullName)\manifest.json" -Raw | ConvertFrom-Json
    if ($m.Name -eq 'Premiere Pro' -and $m.AppIdentifier -like '*Premiere*') { Remove-Item $_.FullName -Recurse -Force; "Removed old profile $($_.Name)" }
  }
  Copy-Item $pdir $root -Recurse
  "Profile installed (existing profiles untouched)."

  $dest = "$sdRoot\Plugins\$PLUGIN.sdPlugin"
  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  Copy-Item $plugSrc $dest -Recurse
  "Plugin installed: $dest"
  "Now start Stream Deck."
}
