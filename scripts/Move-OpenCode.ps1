# =====================================================
#  Move-OpenCode.ps1  (ASCII only - no Chinese text)
#  Migrate OpenCode data on C: to G:\opencode\.opencode
#  and create NTFS junctions at the original locations.
#  Run as Administrator in Windows PowerShell.
#  Close OpenCode before running this script.
# =====================================================

# --- 0) Check administrator rights ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning 'Please run this script as Administrator.'
    Read-Host 'Press ENTER to exit'
    exit 1
}

$BaseG = 'G:\opencode\.opencode'
Write-Host '=========================================='
Write-Host 'OpenCode C -> G migration started'
Write-Host "Target base: $BaseG"
Write-Host '=========================================='

if (-not (Test-Path -LiteralPath $BaseG)) {
    New-Item -ItemType Directory -Path $BaseG -Force | Out-Null
}

# Mapping: source folder -> sub folder name under $BaseG
$Sources = @(
    @{ Src = Join-Path $env:USERPROFILE '.config\opencode';                  Tgt = 'config'  },
    @{ Src = Join-Path $env:APPDATA 'opencode';                              Tgt = 'roaming' },
    @{ Src = Join-Path $env:USERPROFILE '.cache\opencode';                   Tgt = 'cache'   },
    @{ Src = Join-Path $env:USERPROFILE '.codearts\kernel\.opencode\agents'; Tgt = 'agents'  }
)

function Is-Junction([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $false }
    return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Clear-TopLevel([string]$Folder) {
    Get-ChildItem -LiteralPath $Folder -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) { $_.IsReadOnly = $false }
            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        } catch { }
    }
}

# --- 1) Migrate each folder ---
foreach ($m in $Sources) {
    $src = $m.Src
    $tgt = Join-Path $BaseG $m.Tgt

    # 1a) Make sure target folder exists
    if (-not (Test-Path -LiteralPath $tgt)) {
        New-Item -ItemType Directory -Path $tgt -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $src)) {
        # Source missing: if its parent exists, still create the junction
        # so that any future writes go to G: instead of C:.
        $parent = Split-Path $src -Parent
        if (Test-Path -LiteralPath $parent) {
            cmd /c mklink /J "$src" "$tgt" | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK]   Source missing -> junction created: $src -> $tgt"
            } else {
                Write-Host "[SKIP] Source missing and mklink failed: $src"
            }
        } else {
            Write-Host "[SKIP] Source and parent not found: $src"
        }
        continue
    }

    if (Is-Junction $src) {
        Write-Host "[SKIP] Already a junction: $src"
        continue
    }

    Write-Host ''
    Write-Host "--- Processing: $src"
    Write-Host "      Target: $tgt"

    # 1b) Mirror source -> target with robocopy (exit codes 0-7 mean OK)
    Write-Host '      [1/3] robocopy mirroring ...'
    robocopy $src $tgt /MIR /XA:SH /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -ge 8) {
        Write-Warning "robocopy failed with code $rc for: $src  (junction NOT created)"
        continue
    }
    Write-Host "      robocopy finished (code $rc)."

    # 1c) Remove ALL contents inside source folder (keep the folder itself)
    Write-Host '      [2/3] cleaning source folder ...'
    Clear-TopLevel $src

    # 1d) Create junction at original path -> target
    Write-Host '      [3/3] creating junction ...'
    cmd /c mklink /J "$src" "$tgt" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Junction created: $src -> $tgt"
    } else {
        Write-Warning "      [FAIL] mklink returned code $LASTEXITCODE for: $src"
    }
}

# --- 2) Verify ---
Write-Host ''
Write-Host '=== VERIFY ==='
$allOk = $true
foreach ($m in $Sources) {
    $src = $m.Src
    if (Test-Path -LiteralPath $src) {
        if (Is-Junction $src) {
            $item   = Get-Item -LiteralPath $src -Force
            $target = $item.Target
            if (-not $target) { $target = $item.LinkTarget }
            Write-Host "[OK]   $src -> $target"
        } else {
            Write-Host "[WARN] Still real files (not junction): $src"
            $allOk = $false
        }
    } else {
        Write-Host "[INFO] Not found (never existed or parent missing): $src"
    }
}

Write-Host ''
if ($allOk) {
    Write-Host 'RESULT: Migration finished. All folders are junctions to G:.' -ForegroundColor Green
} else {
    Write-Host 'RESULT: Some folders need attention. Check lines marked [WARN] / [FAIL].' -ForegroundColor Yellow
}

Write-Host ''
Read-Host 'Finished. Press ENTER to close this window'