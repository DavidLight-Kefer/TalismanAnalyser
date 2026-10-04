# File: archive.ps1

# Exit on any error
$ErrorActionPreference = "Stop"

# Load environment variables if .env file exists
if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$') {
            Set-Item -Path Env:$($matches[1]) -Value $matches[2]
        }
    }
}

$start_dir = Get-Location

# Check if version argument is provided
if ($args.Count -lt 1) {
    Write-Error "Usage: .\archive.ps1 <version>"
    exit 1
}

# Go to script directory
Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

$VERSION = $args[0]
$FOLDER_NAME = "talisman_analyser_v$VERSION"

# Generate single .lua file
Set-Location -Path "src"
& lua compiler.lua
Set-Location -Path ".."

if (-Not (Test-Path "artefacts")) {
    New-Item -ItemType Directory "artefacts"
}

Set-Location -Path "artefacts"

New-Item -ItemType Directory -Path "tmp\reframework\autorun" -Force
Move-Item -Path "..\src\output.lua" -Destination "tmp\reframework\autorun\talisman_analyser.lua"

Set-Content -Path "tmp\modinfo.ini" -Value @"
name=Talisman Analyser
version=$VERSION
description=Analyse your Appraised Talismans to find Duplicates and Obsoletes.
screenshot=screenshot.png
author=DavidLight
"@

# Shrink image if possible
if (Get-Command "magick" -ErrorAction SilentlyContinue) {
    & magick "../images/screenshot.png" -resize 25% "tmp\screenshot.png"
} else {
    Copy-Item -Path "../images/screenshot.png" -Destination "tmp"
}

Move-Item -Path "tmp" -Destination $FOLDER_NAME

if (Test-Path "talisman_analyser.zip") {
    Remove-Item "talisman_analyser.zip"
}

Compress-Archive -Path $FOLDER_NAME -DestinationPath "talisman_analyser.zip" -Force
Remove-Item -Recurse -Force $FOLDER_NAME

Set-Location -Path $start_dir
