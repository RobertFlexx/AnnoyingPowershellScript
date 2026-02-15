$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.Screen]::PrimaryScreen

if (-not $screen) { exit 0 }

$nativeWidth = $screen.Bounds.Width
$nativeHeight = $screen.Bounds.Height
$native_mode = "${nativeWidth}x${nativeHeight}"

$modes_pool = @(
    $native_mode,
    "3840x2160",
    "2560x1440",
    "1920x1080",
    "1280x1024",
    "1024x768"
)

$mode = $modes_pool | Get-Random

$scale_pool = @(
    "1x1", "2x2", "3x3", "16x16", "32x18", "64x36",
    "80x25", "100x56", "160x90", "320x180", "640x360", "800x600",
    $mode
)

$sf = $scale_pool | Get-Random

$rot_pool = @(0, 1, 2, 3)  # 0=normal, 1=90deg, 2=180deg, 3=270deg
$rot = $rot_pool | Get-Random

if ($mode -match '(\d+)x(\d+)') {
    $mw = [int]$Matches[1]
    $mh = [int]$Matches[2]
} else {
    $mw = $nativeWidth
    $mh = $nativeHeight
    $mode = $native_mode
}

if ($sf -match '(\d+)x(\d+)') {
    $fw = [int]$Matches[1]
    $fh = [int]$Matches[2]
} else {
    $fw = $mw
    $fh = $mh
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DisplaySettings {
    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    public const int DMDO_DEFAULT = 0;
    public const int DMDO_90 = 1;
    public const int DMDO_180 = 2;
    public const int DMDO_270 = 3;
    public const int DM_PELSWIDTH = 0x80000;
    public const int DM_PELSHEIGHT = 0x100000;
    public const int DM_DISPLAYORIENTATION = 0x00000080;
}
"@

try {
    $devMode = New-Object DisplaySettings+DEVMODE
    $devMode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devMode)

    [DisplaySettings]::EnumDisplaySettings($null, -1, [ref]$devMode) | Out-Null

    $devMode.dmPelsWidth = $mw
    $devMode.dmPelsHeight = $mh
    $devMode.dmDisplayOrientation = $rot
    $devMode.dmFields = [DisplaySettings]::DM_PELSWIDTH -bor [DisplaySettings]::DM_PELSHEIGHT -bor [DisplaySettings]::DM_DISPLAYORIENTATION

    [DisplaySettings]::ChangeDisplaySettings([ref]$devMode, 0) | Out-Null
} catch {
    # silently continue on error
}

if ((Get-Random -Minimum 0 -Maximum 5) -eq 0) {
    # Bindoj doesnt have direct panning equivalent so immaskip
}

if ((Get-Random -Minimum 0 -Maximum 10) -eq 0) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Cursor {
    [DllImport("user32.dll")]
    public static extern bool ShowCursor(bool bShow);
}
"@
    [Cursor]::ShowCursor($false) | Out-Null
}
