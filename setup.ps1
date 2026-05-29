# setup-obs-overlay.ps1
#
# OBS Keyshot Overlay Auto Setup
#
# WHAT THIS DOES:
# - Detects OBS config directory
# - Creates OBS scripts folder if missing
# - Copies overlay script automatically
# - Installs pynput into OBS Python
# - Prints helpful status messages
#
# USAGE:
#
# Open PowerShell as Administrator:
#
# powershell -ExecutionPolicy Bypass -File .\setup.ps1
#
# ------------------------------------------------------------

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================="
Write-Host " OBS Keyshot Overlay Setup"
Write-Host "========================================="
Write-Host ""

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

$SCRIPT_NAME = "obs-keyshot.py"

# current folder
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$SCRIPT_SOURCE = Join-Path $PROJECT_DIR $SCRIPT_NAME

# ------------------------------------------------------------
# VERIFY SCRIPT EXISTS
# ------------------------------------------------------------

if (!(Test-Path $SCRIPT_SOURCE)) {
    Write-Host ""
    Write-Host "[ERROR] Could not find:" -ForegroundColor Red
    Write-Host $SCRIPT_SOURCE -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "[OK] Found overlay script"

# ------------------------------------------------------------
# FIND OBS DIRECTORY
# ------------------------------------------------------------

$OBS_DIR = Join-Path $env:APPDATA "obs-studio"

if (!(Test-Path $OBS_DIR)) {
    Write-Host ""
    Write-Host "[ERROR] OBS config directory not found." -ForegroundColor Red
    Write-Host "Launch OBS once before running setup."
    Write-Host ""
    exit 1
}

Write-Host "[OK] OBS config found"

# ------------------------------------------------------------
# CREATE SCRIPTS DIRECTORY
# ------------------------------------------------------------

$OBS_SCRIPT_DIR = Join-Path $OBS_DIR "scripts"

if (!(Test-Path $OBS_SCRIPT_DIR)) {
    New-Item -ItemType Directory -Path $OBS_SCRIPT_DIR | Out-Null
}

Write-Host "[OK] OBS scripts folder ready"

# ------------------------------------------------------------
# COPY SCRIPT
# ------------------------------------------------------------

$DEST_SCRIPT = Join-Path $OBS_SCRIPT_DIR $SCRIPT_NAME

Copy-Item $SCRIPT_SOURCE $DEST_SCRIPT -Force

Write-Host "[OK] Script copied:"
Write-Host "     $DEST_SCRIPT"

# ------------------------------------------------------------
# DETECT PYTHON
# ------------------------------------------------------------

Write-Host ""
Write-Host "Searching for Python..."

$PYTHON = $null

try {
    $PYTHON = pyenv which python
}
catch {
}

if (!$PYTHON) {
    try {
        $PYTHON = (Get-Command python).Source
    }
    catch {
    }
}

if (!$PYTHON) {
    Write-Host ""
    Write-Host "[ERROR] Could not detect Python." -ForegroundColor Red
    Write-Host ""
    exit 1
}

$PYTHON = $PYTHON.Trim()

Write-Host "[OK] Python found:"
Write-Host "     $PYTHON"

# ------------------------------------------------------------
# INSTALL PYNPUT
# ------------------------------------------------------------

Write-Host ""
Write-Host "Installing pynput..."

& $PYTHON -m pip install pynput

Write-Host ""
Write-Host "[OK] pynput installed"

# ------------------------------------------------------------
# FINAL OBS INSTRUCTIONS
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================="
Write-Host " SETUP COMPLETE"
Write-Host "========================================="
Write-Host ""

Write-Host "NEXT STEPS:"
Write-Host ""

Write-Host "1. Open OBS"
Write-Host "2. Tools -> Scripts"
Write-Host "3. Python Settings"
Write-Host "4. Set Python path to:"

$PYTHON_DIR = Split-Path $PYTHON -Parent

Write-Host ""
Write-Host "   $PYTHON_DIR" -ForegroundColor Cyan
Write-Host ""

Write-Host "5. Restart OBS"
Write-Host "6. Add script:"
Write-Host ""
Write-Host "   $DEST_SCRIPT" -ForegroundColor Cyan
Write-Host ""

Write-Host "7. Create OBS Text Source named:"
Write-Host ""
Write-Host "   keyshot" -ForegroundColor Cyan
Write-Host ""

Write-Host "DONE!"
Write-Host ""