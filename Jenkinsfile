pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:cli
    command:
    - cat
    tty: true
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: docker-sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }

    environment {
        DOCKER_TAG = "build-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        echo "Building Docker Image..."
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh "docker build -t \$DOCKER_USER/my-app:${env.DOCKER_TAG} ."
                            sh "docker tag \$DOCKER_USER/my-app:${env.DOCKER_TAG} \$DOCKER_USER/my-app:latest"
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                container('docker') {
                    script {
                        echo "Pushing Docker Image..."
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                            sh "docker push \$DOCKER_USER/my-app:${env.DOCKER_TAG}"
                            sh "docker push \$DOCKER_USER/my-app:latest"
                        }
                    }
                }
            }
        }

        stage('Update GitOps Manifests') {
            steps {
                script {
                    echo "Updating Kubernetes Manifests for ArgoCD..."
                    withCredentials([
                        string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN'),
                        usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
                    ]) {
                        sh """
                        git config user.email "jenkins@devops.com"
                        git config user.name "Jenkins CI"
                        sed -i "s|image: .*|image: \$DOCKER_USER/my-app:${env.DOCKER_TAG}|g" devops-system/k8s/app/deployment.yaml
                        git add devops-system/k8s/app/deployment.yaml
                        git commit -m "Deploy ${env.DOCKER_TAG} via CI [ci skip]"
                        git push https://${GITHUB_TOKEN}@github.com/mohammedmusa1/intern-devops.git HEAD:main
                        """
                    }
                }
            }
        }
    }
}
