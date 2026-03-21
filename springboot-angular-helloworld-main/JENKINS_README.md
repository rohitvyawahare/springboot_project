# Jenkins CI/CD Pipeline Configuration

Complete Jenkins setup and configuration for Spring Boot (backend) + Angular (frontend) application.

## 📋 Overview

This project includes a complete Declarative Pipeline (Jenkinsfile) with automated:
- **Build**: Maven for backend, npm for frontend
- **Test**: Unit tests for both components
- **Quality**: SonarQube code analysis
- **Containerize**: Multi-stage Docker builds
- **Scan**: Trivy vulnerability scanning
- **Deploy**: Automated Kubernetes deployment (main branch only)
- **Monitor**: Health checks and smoke tests

## 📁 Files Included

```
├── Jenkinsfile                      # Main pipeline definition
├── JENKINS_SETUP.md                # Comprehensive setup guide
├── JENKINS_QUICKSTART.md           # 5-minute quick start
├── scripts/
│   ├── setup-jenkins-agent.sh      # Linux/macOS agent setup
│   └── setup-jenkins-agent.ps1     # Windows agent setup
└── vars/
    └── PipelineUtils.groovy        # Shared pipeline utilities
```

## 🚀 Quick Start (5 minutes)

### Prerequisites

```bash
# Verify these are installed
java -version          # Java 17+
mvn --version          # Maven 3.9+
node --version         # Node.js 20+
npm --version          # npm 9+
docker --version       # Docker 20+
kubectl version        # Kubernetes CLI
```

### 1. Jenkins Setup

```bash
# Install Jenkins (Docker recommended)
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

# Access at http://localhost:8080
```

### 2. Install Plugins

Navigate to **Manage Jenkins** → **Manage Plugins** → **Available**

Essential:
- Pipeline
- Git
- Docker Pipeline
- Kubernetes
- Email Extension
- HTML Publisher

### 3. Add Credentials

**Manage Jenkins** → **Manage Credentials** → **System** → **Global Credentials**

Create three credentials:

```
1) docker-registry-credentials (Username/Password)
   Username: your-docker-username
   Password: docker-token-or-password

2) docker-registry-url (Secret text)
   Secret: docker.io (or your registry URL)

3) kubeconfig (Secret file)
   File: your ~/.kube/config
```

### 4. Create Pipeline Job

1. **New Item** → `helloworld-pipeline` → **Pipeline** → **OK**
2. **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository: `https://github.com/your-org/springboot-angular-helloworld.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
3. **Save** → **Build Now**

### 5. GitHub Webhook (Optional)

**Repository Settings** → **Webhooks** → **Add webhook**
- Payload URL: `http://jenkins-url/github-webhook/`
- Content type: `application/json`
- Events: Push, Pull requests

## 🔧 Setup Agent (Linux/macOS)

### Automated Setup

```bash
# Download and run setup script
curl -o setup-jenkins-agent.sh \
  https://raw.githubusercontent.com/your-org/springboot-angular-helloworld/main/scripts/setup-jenkins-agent.sh

chmod +x setup-jenkins-agent.sh
./setup-jenkins-agent.sh
```

### Manual Setup

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y \
  openjdk-17-jdk-headless \
  maven \
  nodejs \
  npm \
  docker.io \
  kubectl

# Add user to Docker group
sudo usermod -aG docker $USER
newgrp docker

# Create Jenkins workspace
mkdir -p $HOME/jenkins-workspace
```

## 🔧 Setup Agent (Windows)

### Automated Setup (as Administrator)

```powershell
# Run in PowerShell as Administrator
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$setupUrl = "https://raw.githubusercontent.com/your-org/springboot-angular-helloworld/main/scripts/setup-jenkins-agent.ps1"
$setupScript = "$env:TEMP\setup-jenkins-agent.ps1"

(New-Object System.Net.WebClient).DownloadFile($setupUrl, $setupScript)
& $setupScript
```

### Manual Setup

```powershell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install -y openjdk17 maven nodejs docker-desktop kubernetes-cli

# Create workspace
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\jenkins-workspace"
```

## 📊 Pipeline Stages

```
1. Checkout           - Clone code from Git
2. Validate           - Verify Maven/npm project structure
3. Build Backend      - Compile Spring Boot with Maven
4. Build Frontend     - Build Angular with npm
5. Unit Tests         - Run test suites
6. SonarQube Analysis - Code quality scan (main branch only)
7. Build Images       - Create Docker images
8. Scan Images        - Security vulnerability scan with Trivy
9. Push Images        - Push to Docker registry (main branch only)
10. Deploy to K8s     - Apply Kubernetes manifests (main branch only)
11. Health Check      - Verify deployment health
12. Smoke Tests       - Basic endpoint testing
```

## 🌳 Branch Strategy

| Branch | Build | Test | Deploy |
|--------|-------|------|--------|
| main   | ✓     | ✓    | ✓      |
| dev    | ✓     | ✓    | ✗      |
| feature/* | ✓ | ✓    | ✗      |

Only `main` branch deploys to production Kubernetes cluster.

## 📝 Environment Variables

Automatically set by pipeline:

```groovy
BUILD_NUMBER        // Jenkins build number
GIT_COMMIT          // Full commit SHA
GIT_BRANCH          // Current branch
BUILD_TAG           // ${BUILD_NUMBER}-${GIT_COMMIT:0:7}
DOCKER_BACKEND_IMAGE // docker.io/helloworld-backend
DOCKER_FRONTEND_IMAGE // docker.io/helloworld-frontend
```

## 🔐 Security

### Docker Registry

```groovy
// Jenkinsfile uses credentials
withCredentials([
    usernamePassword(credentialsId: 'docker-registry-credentials', 
                     usernameVariable: 'REGISTRY_USR', 
                     passwordVariable: 'REGISTRY_PSW')
]) {
    sh 'echo $REGISTRY_PSW | docker login -u $REGISTRY_USR --password-stdin'
}
```

### Kubernetes

```groovy
// Uses kubeconfig credential securely
sh '''
    export KUBECONFIG=${KUBE_CONFIG}
    kubectl apply -f k8s/helloworld-deployment.yaml
'''
```

### Image Scanning

```groovy
// Trivy scans for HIGH and CRITICAL vulnerabilities
trivy image --severity HIGH,CRITICAL myregistry/image:tag
```

## 🐛 Troubleshooting

### Build Fails at "Validate"

**Problem**: Maven/npm command not found

**Solution**:
```bash
# Verify tools on agent
java -version
mvn --version
node --version

# If missing, run setup script
./setup-jenkins-agent.sh
```

### Docker Build Fails

**Problem**: Permission denied / Cannot connect to daemon

**Solution**:
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# On macOS, ensure Docker Desktop is running
```

### K8s Deployment Fails

**Problem**: kubeconfig not found / unauthorized

**Solution**:
1. Verify credentials ID: `kubeconfig`
2. Test locally:
   ```bash
   export KUBECONFIG=/path/to/config
   kubectl get nodes
   ```
3. Ensure kubeconfig RBAC permissions are set

### Pipeline Unstable

**Problem**: Random stage failures

**Trigger**: Check logs
```bash
docker logs -f jenkins
```

**Fix**: Review specific stage error in Jenkins console output

## 📚 Extended Reading

- **[JENKINS_SETUP.md](JENKINS_SETUP.md)** - Complete detailed setup guide
- **[JENKINS_QUICKSTART.md](JENKINS_QUICKSTART.md)** - 5-minute quick reference
- **[Jenkinsfile](Jenkinsfile)** - Pipeline source code with inline documentation

## 🛠️ Advanced Customizations

### Modify trigger schedule

Edit job → **Build Triggers** → **Poll SCM**:
```
H/15 * * * *    # Every 15 minutes
H 2 * * *       # Daily at 2 AM
H 9 * * MON-FRI # Weekdays at 9 AM
```

### Add Slack notifications

1. Install **Slack Notification Plugin**
2. Edit job → **Post-build Actions** → **Slack Notifications**

### Parallel stages

Jenkinsfile already uses parallel:
```groovy
parallel {
    stage('Backend Tests') { ... }
    stage('Frontend Tests') { ... }
}
```

### Custom stage for your needs

Add to Jenkinsfile:
```groovy
stage('Custom') {
    steps {
        script {
            echo "Custom stage"
        }
    }
}
```

## 📈 Monitoring

### View Build Metrics

- **Failed builds**: Jenkins dashboard summary
- **Build duration**: Each stage logs time
- **Test results**: Reports → Test Result Trend
- **Code coverage**: Reports → Coverage

### Log Analysis

```bash
# Stream Jenkins logs
docker logs -f jenkins

# Check specific build
curl http://localhost:8080/job/helloworld-pipeline/123/consoleText
```

## 📦 Deployment Verification

After deployment, check:

```bash
# Verify pods
kubectl get pods -l app=helloworld

# Check services
kubectl get svc helloworld-backend-svc helloworld-frontend-svc

# View logs
kubectl logs -l app=helloworld,tier=backend

# Test endpoints
curl http://backend-service/hello
curl http://frontend-service/index.html
```

## 🔄 CI/CD Best Practices

1. ✅ Keep Jenkinsfile in repository
2. ✅ Use declarative pipeline syntax
3. ✅ Parallel stages for faster builds
4. ✅ Environment variables for configuration
5. ✅ Credentials for sensitive data
6. ✅ Automated tests before deployment
7. ✅ Approval gates for production
8. ✅ Health checks post-deployment

## 📞 Support

For issues:
1. Check [JENKINS_SETUP.md](JENKINS_SETUP.md) troubleshooting section
2. Review Jenkins logs: `docker logs jenkins`
3. Check build console output for specific errors
4. Verify credentials and webhook configuration

## 📚 References

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Deployment Guide](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [SonarQube Analysis](https://docs.sonarqube.org/)

---

**Last Updated**: March 2024  
**Version**: 1.0  
**Status**: Production Ready
