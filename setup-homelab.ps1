# HomeLab Repository Setup Script (PowerShell)
# This script clones the HomeLab repository and sets up the environment on a fresh Windows VM

param(
    [string]$InstallPath = "$env:USERPROFILE\HomeLab"
)

# Repository details
$RepoUrl = "https://github.com/cousmax/HomeLab.git"
$Branch = "Dynamic-Servarr"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Status {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Check if Git is installed
function Test-GitInstallation {
    Write-Status "Checking Git installation..."
    try {
        $null = git --version
        Write-Success "Git is already installed"
        return $true
    }
    catch {
        Write-Error "Git is not installed. Please install Git for Windows from: https://git-scm.com/download/win"
        return $false
    }
}

# Check if Python is installed
function Test-PythonInstallation {
    Write-Status "Checking Python installation..."
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) {
            Write-Success "Python is installed: $pythonVersion"
            return $true
        }
    }
    catch {
        Write-Warning "Python is not installed. Consider installing Python from: https://www.python.org/downloads/"
        return $false
    }
}

# Clone or update repository
function Setup-Repository {
    Write-Status "Setting up HomeLab repository..."
    
    $parentDir = Split-Path -Parent $InstallPath
    $repoName = Split-Path -Leaf $InstallPath
    
    # Create parent directory if it doesn't exist
    if (!(Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    Set-Location $parentDir
    
    if (Test-Path $InstallPath) {
        Write-Warning "Repository directory already exists. Updating..."
        Set-Location $InstallPath
        git fetch origin
        git checkout $Branch
        git pull origin $Branch
        Write-Success "Repository updated successfully"
    }
    else {
        Write-Status "Cloning repository from GitHub..."
        git clone -b $Branch $RepoUrl $repoName
        Set-Location $InstallPath
        Write-Success "Repository cloned successfully to: $InstallPath"
    }
}

# Install Python requirements
function Install-PythonRequirements {
    $requirementsPath = Join-Path $InstallPath "MediaManagement\scripts\requirements.txt"
    
    if (Test-Path $requirementsPath) {
        Write-Status "Installing Python requirements..."
        try {
            python -m pip install -r $requirementsPath
            Write-Success "Python requirements installed"
        }
        catch {
            Write-Warning "Failed to install Python requirements. Make sure Python and pip are installed."
        }
    }
    else {
        Write-Warning "No requirements.txt found"
    }
}

# Display next steps
function Show-NextSteps {
    Write-Host ""
    Write-Success "HomeLab repository setup complete!"
    Write-Host ""
    Write-ColorOutput "Repository location: $InstallPath" "Cyan"
    Write-Host ""
    Write-ColorOutput "Next steps:" "Cyan"
    Write-Host "1. Navigate to the repository: cd `"$InstallPath`""
    Write-Host "2. For MediaManagement setup: cd MediaManagement"
    Write-Host "3. For NextCloud setup: cd NextCloud"
    Write-Host ""
    Write-ColorOutput "Available scripts:" "Cyan"
    Write-Host "📦 MediaManagement:"
    Write-Host "   - .\scripts\install-docker-and-update-os.sh"
    Write-Host "   - .\scripts\generate-compose.py"
    Write-Host "   - .\scripts\test-compose.sh"
    Write-Host ""
    Write-Host "☁️  NextCloud:"
    Write-Host "   - .\install.sh"
    Write-Host "   - .\quick-install.sh"
    Write-Host "   - .\scripts\install-nextcloud-aio.sh"
    Write-Host ""
}

# Main execution
function Main {
    Write-Status "Starting HomeLab setup on fresh Windows VM..."
    Write-Host ""
    
    # Check prerequisites
    if (!(Test-GitInstallation)) {
        exit 1
    }
    
    $pythonAvailable = Test-PythonInstallation
    
    # Setup repository
    Setup-Repository
    
    # Install Python requirements if Python is available
    if ($pythonAvailable) {
        Install-PythonRequirements
    }
    
    Show-NextSteps
}

# Run main function
Main
