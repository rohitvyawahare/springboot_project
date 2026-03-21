# Jenkins Configuration Guide for Helloworld Project

This guide contains all necessary steps to set up Jenkins for the Helloworld Spring Boot + Angular project.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Jenkins Installation](#jenkins-installation)
3. [Plugin Installation](#plugin-installation)
4. [Credentials Setup](#credentials-setup)
5. [Pipeline Job Creation](#pipeline-job-creation)
6. [Webhook Configuration](#webhook-configuration)
7. [Build Configuration](#build-configuration)
8. [Post-Build Actions](#post-build-actions)

---

## Prerequisites

- Jenkins server running (v2.440+)
- Docker installed and running on Jenkins agent/master
- Kubernetes cluster accessible
- Git repository access
- Docker Registry (Docker Hub, Harbor, or private registry)

---

## Jenkins Installation

### Using Docker (Recommended)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  jenkins/jenkins:lts-jdk17
```

### Traditional Installation (Ubuntu/Debian)

```bash
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins java-17-openjdk-headless
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

Access Jenkins at `http://localhost:8080`

---

## Plugin Installation

Navigate to **Manage Jenkins** → **Manage Plugins** → **Available Plugins**

Install the following plugins:

### Essential Plugins
- **Pipeline** - Pipeline plugin
- **Pipeline: Stage View** - Stage view for pipelines
- **Pipeline: GitHub Integration** - GitHub integration
- **Git** - Git plugin
- **GitHub** - GitHub plugin

### Build & Testing Plugins
- **SonarQube Scanner** - Code quality analysis
- **JUnit Plugin** - Test result reporting
- **Email Extension Plugin** - Email notifications
- **HTML Publisher** - HTML reports (code coverage)

### Container & Kubernetes Plugins
- **Docker Pipeline** - Docker integration in Pipeline
- **Kubernetes** - Kubernetes cloud integration
- **Kubernetes CLI** - kubectl commands

### Quality & Security
- **Trivy Scanner** - Container vulnerability scanning
- **OWASP Dependency-Check** - Dependency scanning

**Installation Command (via CLI):**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
  pipeline \
  pipeline-stage-view \
  pipeline-github \
  git \
  github \
  sonar \
  junit \
  email-ext \
  htmlpublisher \
  docker-workflow \
  kubernetes \
  kubernetes-client \
  dependency-check-jenkins-plugin
```

---

## Credentials Setup

### 1. Docker Registry Credentials

**Path:** Manage Jenkins → Manage Credentials → System → Global Credentials → Add Credentials

- **Kind**: Username with password
- **Username**: Your Docker registry username
- **Password**: Your Docker registry password/token
- **ID**: `docker-registry-credentials`
- **Description**: Docker Registry Credentials

### 2. Docker Registry URL

- **Kind**: Secret text
- **Secret**: `docker.io` (for Docker Hub) or your registry URL
- **ID**: `docker-registry-url`
- **Description**: Docker Registry URL

### 3. Kubernetes Config

- **Kind**: Secret file
- **File**: Your kubeconfig file (typically `~/.kube/config`)
- **ID**: `kubeconfig`
- **Description**: Kubernetes Config File

### 4. GitHub (Optional)

- **Kind**: SSH Key or Personal Access Token
- **ID**: `github-credentials`
- **Description**: GitHub Access Token

### 5. Email Credentials (Optional)

For email notifications, set up SMTP credentials:
- **Path:** Manage Jenkins → Configure System → E-mail Notification
- Configure SMTP server details

---

## Pipeline Job Creation

### Step 1: Create New Job

1. Click **New Item**
2. Enter job name: `helloworld-pipeline`
3. Select **Pipeline**
4. Click **OK**

### Step 2: Pipeline Configuration

**General**
- Enable: **Discard old builds**
  - Max # of builds to keep: `10`
  - Max # of days to keep builds: `30`

**Build Triggers**
- Check: **GitHub hook trigger for GITScm polling**
- Check: **Poll SCM** (optional fallback)
  - Schedule: `H/15 * * * *` (every 15 minutes)

**Pipeline**

Choose one of the following:

#### Option A: Pipeline script from SCM (Recommended)

- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/your-org/springboot-angular-helloworld.git`
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`
- **Lightweight checkout**: Check

#### Option B: Pipeline script

- **Definition**: Pipeline script
- **Script**: Copy the entire Jenkinsfile content into this field

### Step 3: Save and Build

Click **Save** → Click **Build Now** to test the pipeline

---

## Webhook Configuration

### GitHub Webhook Setup

1. Go to GitHub Repository → **Settings** → **Webhooks** → **Add webhook**

2. **Payload URL**: `http://your-jenkins-url/github-webhook/`

3. **Content type**: `application/json`

4. **Events**: Select:
   - Push events
   - Pull request events

5. Click **Add webhook**

6. Test webhook (GitHub will show delivery status)

### GitLab Webhook Setup

1. Go to GitLab Project → **Settings** → **Integrations** → **Jenkins**

2. **Jenkins server URL**: `http://your-jenkins-url/`

3. **Project name**: `helloworld-pipeline`

4. Click **Save**

---

## Build Configuration

### SonarQube Integration

1. **Manage Jenkins** → **Configure System** → **SonarQube servers**

2. Click **Add SonarQube**
   - **Name**: `SonarQube`
   - **Server URL**: `http://sonarqube-server:9000`
   - **Server authentication token**: Create token in SonarQube

3. Save configuration

### Docker Configuration

1. **Manage Jenkins** → **Configure System** → **Cloud** → **Docker**

2. **Docker Host URI**: `unix:///var/run/docker.sock` (or your Docker daemon URL)

3. Enable **Docker API version override** if needed

### Kubernetes Configuration

1. **Manage Jenkins** → **Configure System** → **Cloud** → **Kubernetes**

2. **Kubernetes URL**: Your cluster API endpoint

3. **Kubernetes Namespace**: `default` (or your namespace)

4. **Jenkins URL**: `http://jenkins-service:8080` (internal service name)

5. Configure pod templates for build agents

---

## Environment Variables

Set the following environment variables in Jenkins job configuration:

**Build Variables** (optional, already in Jenkinsfile):

```
BUILD_TAG=${BUILD_NUMBER}-${GIT_COMMIT.take(7)}
DOCKER_BACKEND_IMAGE=your-registry/helloworld-backend
DOCKER_FRONTEND_IMAGE=your-registry/helloworld-frontend
```

---

## Post-Build Actions

### Email Notifications

**Path:** Job Configuration → Post-build Actions → Add post-build action → **Editable Email Notification**

**Triggers:**
- Before Build
- Build Unstable
- Build Failure
- Build Fixed

**Default Recipients**: `devops-team@example.com`

**Advanced Settings:**
- Enable: **Send to individuals who broke the build**
- Enable: **Send individual email notifications**

### Performance Graph

**Path:** Post-build Actions → Add → **Plot build data**

- **Plot group**: `Metrics`
- **Plot title**: `Build Duration`
- **Data series file**: `**/build-metrics.csv`

### Slack Notifications (Optional)

Install **Slack Notification Plugin**

**Post-build Action** → Add → **Slack Notifications**

- **Workspace**: Your Slack workspace
- **Channel**: `#builds` or `#deployments`
- **Team Domain**: Your Slack team

---

## Advanced Configuration

### Blue Ocean Setup (Optional)

1. Install **Blue Ocean** plugin
2. Click **Jenkins** logo → **Open Blue Ocean**
3. Create new pipeline or link existing
4. Better UI for viewing pipeline execution

### Matrix Builds (Multi-version Testing)

Add to Pipeline stage:

```groovy
stage('Multi-Version Build') {
    matrix {
        agent any
        axes {
            axis {
                name 'DOCKER_TAG'
                values 'latest', 'stable', 'dev'
            }
        }
        stages {
            stage('Build') {
                steps {
                    echo "Building with tag: ${DOCKER_TAG}"
                }
            }
        }
    }
}
```

### Shared Library Usage

Create a shared library for reusable pipeline code:

1. **Manage Jenkins** → **System Configuration** → **Global Pipeline Libraries**

2. **Name**: `helloworld-lib`

3. **Modern SCM** → Select Git

4. **Library path**: `vars/`

---

## Troubleshooting

### Pipeline Won't Trigger

- Verify webhook is working: GitHub/GitLab → webhook events
- Check Jenkins logs: `/var/log/jenkins/jenkins.log`
- Ensure GitHub hook trigger is enabled in job configuration

### Docker Build Fails

```bash
# Check Docker daemon
docker ps

# Verify Jenkins can access Docker socket
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Kubernetes Deployment Fails

```bash
# Verify kubeconfig
export KUBECONFIG=/path/to/kubeconfig
kubectl get nodes

# Check pod logs
kubectl logs -l app=helloworld --all-namespaces
```

### SonarQube Analysis Fails

- Verify SonarQube server is running
- Check SonarQube authentication token validity
- Ensure firewall allows Jenkins → SonarQube communication

---

## Monitoring and Logging

### Jenkins Logs

```bash
# Docker
docker logs -f jenkins

# System
tail -f /var/log/jenkins/jenkins.log
```

### Build Logs

Access via Jenkins UI:
- Click build number
- Click **Console Output**

### Export Build Artifacts

```bash
# Access build artifacts
http://your-jenkins-url/job/helloworld-pipeline/lastSuccessfulBuild/artifact/
```

---

## Security Best Practices

1. **Enable Security Realm**: Manage Jenkins → Configure Global Security
   - Use LDAP, GitHub OAuth, or local user database

2. **Set Authorization Strategy**: Project-based Matrix Authorization

3. **Enable CSRF Protection**: Check "Enable proxy compatibility"

4. **Manage Credentials**: Use Jenkins Credential System, never hardcode

5. **Regular Backups**: Backup `/var/jenkins_home`

6. **Keep Jenkins Updated**: Run latest LTS version

7. **Plugin Updates**: Regularly update plugins for security patches

---

## Maintenance

### Regular Tasks

```bash
# Weekly: Check disk space
df -h /var/jenkins_home

# Monthly: Clean old builds
# Configure in job: Discard old builds

# Quarterly: Update plugins and core
# Manage Jenkins → Manage Plugins → Updates available
```

### Backup Strategy

```bash
# Backup Jenkins home
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/jenkins_home

# Store in S3 or similar
aws s3 cp jenkins-backup-*.tar.gz s3://backup-bucket/jenkins/
```

---

## Next Steps

1. Install plugins from **Plugin Installation** section
2. Set up credentials as per **Credentials Setup**
3. Create pipeline job following **Pipeline Job Creation**
4. Configure webhooks for your Git provider
5. Run first build and verify all stages pass
6. Monitor logs and adjust as needed

For issues, consult Jenkins documentation: https://www.jenkins.io/doc/
