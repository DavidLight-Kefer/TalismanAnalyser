# File: update.ps1

# Exit on error
$ErrorActionPreference = 'Stop'

# Load environment variables from .env file if it exists
if (Test-Path '.env') {
    Get-Content '.env' | Where-Object { $_ -match '^\w+=' } | ForEach-Object {
        $name, $value = $_ -split '=', 2
        Set-Item -Path Env:$name -Value $value
    }
}

# Change directory to src
Push-Location -Path 'src'
try {
    # Run the Lua compiler
    & lua compiler.lua

    # Move the output.lua to the target directory, overwriting if it exists
    Move-Item -Path 'output.lua' -Destination "${env:WILDS_DIR}\reframework\autorun\talisman_analyser_dev.lua" -Force
} finally {
    # Change back to the original directory
    Pop-Location
}

# Define the target directory
$TARGET_DIR = "${env:WILDS_DIR}\reframework\images\talisman_analyser"

# Create the target directory if it doesn't exist
if (-Not (Test-Path -Path $TARGET_DIR)) {
    New-Item -ItemType Directory -Path $TARGET_DIR
}

# Copy all files from ./assets/images to the target directory, overwriting if they exist
Copy-Item -Path '.\assets\images\*' -Destination $TARGET_DIR -Recurse -Force
