// vars/PipelineUtils.groovy
// Shared library utilities for helloworld pipeline

def buildDockerImage(String imageName, String dockerfilePath, String tag) {
    echo "Building Docker image: ${imageName}:${tag}"
    sh """
        docker build \
            -f ${dockerfilePath} \
            -t ${imageName}:${tag} \
            -t ${imageName}:latest \
            .
        docker images | grep ${imageName.split('/')[1]}
    """
}

def pushDockerImage(String imageName, String tag) {
    echo "Pushing Docker image: ${imageName}:${tag}"
    sh """
        docker push ${imageName}:${tag}
        docker push ${imageName}:latest
    """
}

def scanDockerImage(String imageName, String tag) {
    echo "Scanning Docker image for vulnerabilities: ${imageName}:${tag}"
    sh """
        which trivy || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
        trivy image --severity HIGH,CRITICAL ${imageName}:${tag} || true
    """
}

def deployToKubernetes(String manifestPath, String kubeconfig) {
    echo "Deploying to Kubernetes from: ${manifestPath}"
    sh """
        export KUBECONFIG=${kubeconfig}
        kubectl apply -f ${manifestPath}
        kubectl get deployments
    """
}

def waitForRollout(String deploymentName, String timeout = '5m') {
    echo "Waiting for rollout of deployment: ${deploymentName}"
    sh """
        export KUBECONFIG=\${KUBE_CONFIG}
        kubectl rollout status deployment/${deploymentName} -n default --timeout=${timeout}
    """
}

def runHealthCheck() {
    echo "Running health checks..."
    sh """
        export KUBECONFIG=\${KUBE_CONFIG}
        
        echo "=== Service Status ==="
        kubectl get svc -l app=helloworld
        
        echo "=== Pod Status ==="
        kubectl get pods -l app=helloworld
        
        echo "=== Recent Logs ==="
        kubectl logs -l app=helloworld --tail=20 --all-containers=true || true
    """
}

def notifySlack(String message, String status) {
    echo "Sending Slack notification: ${status}"
    // This would require Slack plugin and webhook configuration
    // sh "curl -X POST ${SLACK_WEBHOOK_URL} -d '{\"text\":\"${message}\"}'"
}

def archiveArtifacts(List<String> patterns) {
    echo "Archiving artifacts: ${patterns.join(', ')}"
    patterns.each { pattern ->
        archiveArtifacts artifacts: pattern, allowEmptyArchive: true
    }
}

return this
