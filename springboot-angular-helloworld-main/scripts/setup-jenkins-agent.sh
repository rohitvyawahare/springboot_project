#!/bin/bash
# setup-jenkins-agent.sh - Initialize Jenkins agent for helloworld project

set -e

echo "================================================"
echo "Jenkins Agent Setup for Helloworld Project"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        return 1
    fi
}

print_info "Starting Jenkins agent setup..."

# Check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    print_error "Unsupported OS: $OSTYPE"
    exit 1
fi

print_info "Detected OS: $OS"

# ====================================
# 1. Check and install Java
# ====================================
print_info "Checking Java installation..."
if ! check_command java; then
    print_warn "Installing Java 17..."
    if [ "$OS" == "linux" ]; then
        sudo apt-get update
        sudo apt-get install -y openjdk-17-jdk-headless
    elif [ "$OS" == "macos" ]; then
        brew install openjdk@17
        sudo ln -sfn /usr/local/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
    fi
fi

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
print_info "JAVA_HOME: $JAVA_HOME"

# ====================================
# 2. Check and install Maven
# ====================================
print_info "Checking Maven installation..."
if ! check_command mvn; then
    print_warn "Installing Maven..."
    if [ "$OS" == "linux" ]; then
        sudo apt-get install -y maven
    elif [ "$OS" == "macos" ]; then
        brew install maven
    fi
fi

mvn --version

# ====================================
# 3. Check and install Node.js
# ====================================
print_info "Checking Node.js installation..."
if ! check_command node; then
    print_warn "Installing Node.js 20..."
    if [ "$OS" == "linux" ]; then
        curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ "$OS" == "macos" ]; then
        brew install node@20
        brew link node@20
    fi
fi

node --version
npm --version

# ====================================
# 4. Check and install Docker
# ====================================
print_info "Checking Docker installation..."
if ! check_command docker; then
    print_warn "Installing Docker..."
    if [ "$OS" == "linux" ]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
    elif [ "$OS" == "macos" ]; then
        brew install --cask docker
    fi
fi

# Add current user to docker group (Linux only)
if [ "$OS" == "linux" ]; then
    print_info "Adding current user to docker group..."
    sudo usermod -aG docker $USER
    print_warn "Please log out and back in for group changes to take effect"
fi

docker --version

# ====================================
# 5. Check and install kubectl
# ====================================
print_info "Checking kubectl installation..."
if ! check_command kubectl; then
    print_warn "Installing kubectl..."
    if [ "$OS" == "linux" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    elif [ "$OS" == "macos" ]; then
        brew install kubectl
    fi
fi

kubectl version --client

# ====================================
# 6. Install Trivy (vulnerability scanner)
# ====================================
print_info "Checking Trivy installation..."
if ! check_command trivy; then
    print_warn "Installing Trivy..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

trivy version

# ====================================
# 7. Create necessary directories
# ====================================
print_info "Creating necessary directories..."
mkdir -p $HOME/.kube
mkdir -p $HOME/.docker
mkdir -p $HOME/jenkins-workspace

print_info "Created directories:"
echo "  - $HOME/.kube (for kubeconfig)"
echo "  - $HOME/.docker (for Docker credentials)"
echo "  - $HOME/jenkins-workspace (for Jenkins work)"

# ====================================
# 8. Verify installations
# ====================================
print_info "Verifying all installations..."

check_command java
check_command mvn
check_command node
check_command npm
check_command docker
check_command kubectl
check_command trivy

# ====================================
# 9. Print summary
# ====================================
echo ""
print_info "Setup complete! Summary:"
echo "================================================"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn --version | head -n 1)"
echo "Node: $(node --version)"
echo "NPM: $(npm --version)"
echo "Docker: $(docker --version)"
echo "Kubectl: $(kubectl version --client 2>&1 | grep 'Client Version' | head -n 1)"
echo "Trivy: $(trivy version | head -n 1)"
echo "================================================"

print_info "Next steps:"
echo "1. Configure kubeconfig:"
echo "   scp user@k8s-master:~/.kube/config $HOME/.kube/config"
echo ""
echo "2. Connect Jenkins agent:"
echo "   - Add agent node in Jenkins UI"
echo "   - Configure remote root directory: $HOME/jenkins-workspace"
echo ""
echo "3. Test Docker access:"
echo "   docker ps"
echo ""
echo "4. Test Kubernetes access:"
echo "   kubectl get nodes"
echo ""

print_info "Jenkins agent setup finished successfully!"
