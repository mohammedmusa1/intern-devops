pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "${env.dockerhub_username}/my-app"
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
                script {
                    echo "Building Docker Image..."
                    // sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    // sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    echo "Pushing Docker Image..."
                    /*
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                    */
                }
            }
        }

        stage('Update GitOps Manifests') {
            steps {
                script {
                    echo "Updating Kubernetes Manifests for ArgoCD..."
                    /*
                    withCredentials([string(credentialsId: 'github-pat', variable: 'GITHUB_TOKEN')]) {
                        sh """
                        git config user.email "jenkins@devops.com"
                        git config user.name "Jenkins CI"
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g' k8s/app/deployment.yaml
                        git add k8s/app/deployment.yaml
                        git commit -m "Deploy ${DOCKER_TAG} via CI"
                        git push https://${GITHUB_TOKEN}@github.com/mohammedmusa1/internshiproject.git HEAD:main
                        """
                    }
                    */
                }
            }
        }
    }
}
