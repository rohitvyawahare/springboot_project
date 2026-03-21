# Quick Start: Jenkins Pipeline for Helloworld

This document provides quick-start instructions to get the Jenkinsfile running.

## Prerequisites Checklist

- [ ] Jenkins server installed (v2.440+)
- [ ] Docker installed on Jenkins agent
- [ ] Kubernetes cluster configured and accessible
- [ ] Git repository URL handy
- [ ] Docker registry credentials (Docker Hub, Harbor, etc.)
- [ ] Kubeconfig file for Kubernetes
- [ ] Email SMTP configured (optional but recommended)

## 5-Minute Setup

### 1. Install Required Plugins (1 min)

In Jenkins UI:
1. **Manage Jenkins** → **Manage Plugins** → **Available**
2. Search and install:
   - `Pipeline`
   - `Git`
   - `Docker Pipeline`
   - `Kubernetes`
   - `Email Extension Plugin`
   - `HTML Publisher`

### 2. Add Credentials (2 min)

**Manage Jenkins** → **Manage Credentials** → **System** → **Global Credentials**

```
Add these three:

1. Docker Registry (Username/Password)
   ID: docker-registry-credentials
   Username: your-docker-username
   Password: your-docker-token

2. Docker Registry URL (Secret text)
   ID: docker-registry-url
   Secret: docker.io (or your registry)

3. Kubeconfig (Secret file)
   ID: kubeconfig
   File: ~/.kube/config
```

### 3. Create Pipeline Job (1 min)

1. **New Item** → Enter: `helloworld-pipeline` → Select: **Pipeline** → **OK**
2. Scroll to **Pipeline** section
3. Select: **Pipeline script from SCM**
4. Choose: **Git**
5. Enter Repository URL: `https://github.com/your-org/springboot-angular-helloworld.git`
6. Branch: `*/main`
7. Script Path: `Jenkinsfile`
8. Click **Save**

### 4. Configure Build Triggers (1 min)

1. **Build Triggers** section
2. Check: ✓ **GitHub hook trigger for GITScm polling**
3. Check: ✓ **Poll SCM** (Schedule: `H/15 * * * *`)
4. Click **Save**

### 5. Run First Build

1. Click **Build Now**
2. Watch the build progress: Click build number → **Console Output**
3. Fix any errors (see **Troubleshooting** below)

---

## Pipeline Stages Explained

```
Checkout               → Clone repository
├─ Validate            → Check project structure
│  ├─ Backend Validation
│  └─ Frontend Validation
├─ Build Backend       → Maven package
├─ Build Frontend      → npm build
├─ Unit Tests          → Run test suites
│  ├─ Backend Tests
│  └─ Frontend Tests
├─ SonarQube Analysis  → Code quality (main branch only)
├─ Build Docker Images → docker build
├─ Scan Images         → Trivy vulnerability scan
├─ Push Images         → Push to registry (main only)
├─ Deploy to K8s       → kubectl apply (main only)
├─ Health Check        → Verify deployments
└─ Smoke Tests         → Basic endpoint tests
```

---

## Environment Variables

The Jenkinsfile automatically sets:

```groovy
REGISTRY                    // Docker registry (from credentials)
DOCKER_BACKEND_IMAGE        // backend image name
DOCKER_FRONTEND_IMAGE       // frontend image name
BUILD_TAG                   // unique tag: ${BUILD_NUMBER}-${GIT_COMMIT.take(7)}
```

---

## Running Only on Main Branch

Deployment stages only run on `main` branch. For other branches:
- ✓ Code builds and tests run
- ✓ Docker images are built and scanned
- ✗ Images are NOT pushed to registry
- ✗ NOT deployed to Kubernetes

---

## Webhook Setup (GitHub)

1. Go to repository → **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `http://your-jenkins-url/github-webhook/`
3. **Content type**: `application/json`
4. **Which events would you like to trigger this webhook?**: Select **Push events** and **Pull requests**
5. Click **Add webhook**

Jenkins will automatically trigger builds on push and PRs.

---

## Troubleshooting

### Build fails at "Validate" stage

**Problem**: Maven or npm command not found

**Solution**:
```bash
# Check if Java is installed
java -version

# Check Node.js
node --version
npm --version

# If missing, install tools on Jenkins agent
```

### Docker build fails

**Problem**: "permission denied" or "Cannot connect to Docker daemon"

**Solution**:
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Kubernetes deployment fails

**Problem**: "kubeconfig not found" or "unauthorized"

**Solution**:
```bash
# Verify credential ID matches
# Update JENKINS_SETUP.md step 3

# Test locally:
export KUBECONFIG=/path/to/config
kubectl get nodes
```

### SonarQube analysis fails

**Problem**: "SonarQube server not configured"

**Solution**:
1. Configure SonarQube in **Manage Jenkins** → **Configure System**
2. Name: `SonarQube`
3. URL: `http://sonarqube-server:9000`
4. Token: Create in SonarQube UI

### Pipeline sometimes skips stages

**Problem**: Branch protection or conditional stages

**Explanation**: Stages like `Push Images` and `Deploy to K8s` only run on `main` branch.

**Solution**: Merge to main branch to trigger full pipeline.

---

## Debugging Tips

### View Build Variables

Add this to any stage:
```groovy
sh '''
    echo "Build: ${BUILD_NUMBER}"
    echo "Commit: ${GIT_COMMIT}"
    echo "Branch: ${GIT_BRANCH}"
    echo "Image: ${DOCKER_BACKEND_IMAGE}:${BUILD_TAG}"
'''
```

### Check Plugin Versions

**Manage Jenkins** → **Manage Plugins** → **Installed**

Ensure plugins are recent versions.

### View Pipeline Graph

**Blue Ocean** plugin provides visual pipeline execution:
- Install "Blue Ocean" plugin
- Click **Open Blue Ocean** on any job

### Verbose Logging

Add to pipeline:
```groovy
properties([
    pipelineJob.getProperties().add(
        new StringParametersDefinitionProperty(
            new StringParameterDefinition('DEBUG', 'false', 'Enable debug mode')
        )
    )
])
```

---

## Next Steps

1. ✓ Complete prerequisites checklist
2. ✓ Follow 5-minute setup
3. ✓ Run first build and verify
4. ✓ Set up webhooks
5. → Customize stages as needed (see **JENKINS_SETUP.md**)
6. → Set up SonarQube analysis (optional)
7. → Configure Slack notifications (optional)
8. → Set up monitoring and alerts

---

## Common Customizations

### Change trigger schedule
Edit Job → **Build Triggers** → **Poll SCM**
```
H/15 * * * *    # Every 15 minutes
H 2 * * *       # Daily at 2 AM
H 9 * * MON-FRI # Weekdays at 9 AM
```

### Add Slack notifications

Edit Job → **Post-build Actions** → **Slack Notifications**

Install **Slack Notification Plugin** first.

### Exclude SonarQube for certain branches

In Jenkinsfile, change:
```groovy
when {
    branch 'main'
}
```

To include multiple branches:
```groovy
when {
    branch pattern: "main|develop|release.*", comparator: "REGEXP"
}
```

### Modify retention policy

Edit Job → **Discard old builds**:
```
Max # of builds to keep: 20
Max # of days to keep: 60
Artifact retention: 5 builds / 30 days
```

---

## Performance Optimization

### Parallel Stages

The Jenkinsfile already parallelizes:
- Backend validation + Frontend validation
- Backend unit tests + Frontend unit tests

### Caching

Add Maven cache to agent:
```groovy
options {
    timestamps()
    timeout(time: 1, unit: 'HOURS')
    
    // Disable to save disk
    buildDiscarder(logRotator(numToKeepStr: '10'))
}
```

### Docker Image Layers

Multi-stage builds cache dependencies:
```dockerfile
# Backend uses maven cache
# Frontend uses npm cache from package-lock.json
```

---

## Support & Documentation

- Jenkins: https://www.jenkins.io/doc/
- Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- SonarQube: https://docs.sonarqube.org/
