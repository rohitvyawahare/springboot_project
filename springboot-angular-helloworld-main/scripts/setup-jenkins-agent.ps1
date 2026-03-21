# setup-jenkins-agent.ps1 - Initialize Jenkins agent for helloworld project (Windows)
# Run as Administrator

param(
    [switch]$SkipJava = $false,
    [switch]$SkipMaven = $false,
    [switch]$SkipNode = $false,
    [switch]$SkipDocker = $false,
    [switch]$SkipKubectl = $false,
    [switch]$SkipTrivy = $false
)

# Ensure script runs as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "================================================" -ForegroundColor Green
Write-Host "Jenkins Agent Setup for Helloworld Project (Windows)" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Helper functions
function Write-Info {
    Write-Host "[INFO] $args" -ForegroundColor Green
}

function Write-Warn {
    Write-Host "[WARN] $args" -ForegroundColor Yellow
}

function Write-Error {
    Write-Host "[ERROR] $args" -ForegroundColor Red
}

function Check-Command {
    param([string]$Command)
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    if ($exists) {
        Write-Host "✓ $Command is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $Command is NOT installed" -ForegroundColor Red
    }
    return $exists
}

function Install-Chocolatey {
    if (-NOT (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Info "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path += ";C:\ProgramData\chocolatey\bin"
    }
}

# ====================================
# 1. Install Chocolatey
# ====================================
Write-Info "Installing Chocolatey package manager..."
Install-Chocolatey

# ====================================
# 2. Check and install Java
# ====================================
if (-NOT $SkipJava) {
    Write-Info "Checking Java installation..."
    if (-NOT (Check-Command java)) {
        Write-Warn "Installing Java 17..."
        choco install -y openjdk17
        $env:JAVA_HOME = "C:\Program Files\OpenJDK\openjdk-17*"
    }
    java -version
}

# ====================================
# 3. Check and install Maven
# ====================================
if (-NOT $SkipMaven) {
    Write-Info "Checking Maven installation..."
    if (-NOT (Check-Command mvn)) {
        Write-Warn "Installing Maven..."
        choco install -y maven
    }
    mvn --version
}

# ====================================
# 4. Check and install Node.js
# ====================================
if (-NOT $SkipNode) {
    Write-Info "Checking Node.js installation..."
    if (-NOT (Check-Command node)) {
        Write-Warn "Installing Node.js 20..."
        choco install -y nodejs --version 20
    }
    node --version
    npm --version
}

# ====================================
# 5. Check and install Docker
# ====================================
if (-NOT $SkipDocker) {
    Write-Info "Checking Docker installation..."
    if (-NOT (Check-Command docker)) {
        Write-Warn "Installing Docker Desktop..."
        choco install -y docker-desktop
        Write-Warn "Please restart your computer for Docker installation to complete"
    } else {
        docker --version
    }
}

# ====================================
# 6. Check and install kubectl
# ====================================
if (-NOT $SkipKubectl) {
    Write-Info "Checking kubectl installation..."
    if (-NOT (Check-Command kubectl)) {
        Write-Warn "Installing kubectl..."
        choco install -y kubernetes-cli
    }
    kubectl version --client
}

# ====================================
# 7. Check and install Trivy
# ====================================
if (-NOT $SkipTrivy) {
    Write-Info "Checking Trivy installation..."
    if (-NOT (Check-Command trivy)) {
        Write-Warn "Installing Trivy..."
        choco install -y trivy
    }
    trivy version
}

# ====================================
# 8. Create necessary directories
# ====================================
Write-Info "Creating necessary directories..."

$kubeDir = "$env:USERPROFILE\.kube"
$dockerDir = "$env:USERPROFILE\.docker"
$jenkinsDir = "$env:USERPROFILE\jenkins-workspace"

New-Item -ItemType Directory -Force -Path $kubeDir | Out-Null
New-Item -ItemType Directory -Force -Path $dockerDir | Out-Null
New-Item -ItemType Directory -Force -Path $jenkinsDir | Out-Null

Write-Info "Created directories:"
Write-Host "  - $kubeDir (for kubeconfig)"
Write-Host "  - $dockerDir (for Docker credentials)"
Write-Host "  - $jenkinsDir (for Jenkins work)"

# ====================================
# 9. Create environment variable setup script
# ====================================
$setupScript = @"
# Environment setup for Jenkins
`$env:JAVA_HOME = 'C:\Program Files\OpenJDK\openjdk-17*'
`$env:MAVEN_HOME = 'C:\ProgramData\chocolatey\lib\maven\tools\apache-maven-*'
`$env:NODEJS_HOME = 'C:\Program Files\nodejs'

# Add to PATH if not already present
`$paths = `$env:Path -split ';'
if (`$paths -notcontains `$env:JAVA_HOME) {
    `$env:Path = `$env:JAVA_HOME + `;` + `$env:Path
}
"@

$setupScriptPath = "$env:USERPROFILE\jenkins-env-setup.ps1"
Set-Content -Path $setupScriptPath -Value $setupScript
Write-Info "Created environment setup script: $setupScriptPath"

# ====================================
# 10. Verify installations
# ====================================
Write-Info "Verifying all installations..."

Check-Command java
Check-Command mvn
Check-Command node
Check-Command npm
Check-Command docker
Check-Command kubectl
Check-Command trivy

# ====================================
# 11. Print summary
# ====================================
Write-Host ""
Write-Info "Setup complete! Summary:"
Write-Host "================================================"

try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "Java: $javaVersion"
} catch {}

try {
    $mavenVersion = mvn --version 2>&1 | Select-Object -First 1
    Write-Host "Maven: $mavenVersion"
} catch {}

try { Write-Host "Node: $(node --version)" } catch {}
try { Write-Host "NPM: $(npm --version)" } catch {}
try { Write-Host "Docker: $(docker --version)" } catch {}
try { Write-Host "Kubectl: $(kubectl version --client 2>&1 | Select-String 'Client')" } catch {}
try { Write-Host "Trivy: $(trivy version 2>&1 | Select-Object -First 1)" } catch {}

Write-Host "================================================"

Write-Info "Next steps:"
Write-Host "1. Configure kubeconfig:"
Write-Host "   Copy your kubeconfig file to: $env:USERPROFILE\.kube\config"
Write-Host ""
Write-Host "2. Connect Jenkins agent:"
Write-Host "   - Add agent node in Jenkins UI"
Write-Host "   - Configure remote root directory: $jenkinsDir"
Write-Host ""
Write-Host "3. Set environment variables:"
Write-Host "   Run: $setupScriptPath"
Write-Host ""
Write-Host "4. Test Docker access (in PowerShell as Administrator):"
Write-Host "   docker ps"
Write-Host ""
Write-Host "5. Test Kubernetes access:"
Write-Host "   kubectl get nodes"
Write-Host ""

if (-NOT $SkipDocker) {
    Write-Warn "Docker Desktop requires a system restart to complete installation"
    Write-Warn "Please restart your computer when ready"
}

Write-Info "Jenkins agent setup finished successfully!"
Write-Host "Please run: & '$setupScriptPath' to setup environment variables in future sessions"
