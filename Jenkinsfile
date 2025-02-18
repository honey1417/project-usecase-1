pipeline {
    agent any
    parameters {
        string(name: 'GIT_REPO', defaultValue: 'https://github.com/honey1417/project-usecases.git', description: 'Git repository URL')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'stage', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Rollback to Previous Version?' )
        booleanParam(name: 'CREATE_CLUSTER', defaultValue: false, description: 'Create a new cluster?' )
    } 

    environment {
        GITHUB_TOKEN = credentials('github-pat')
        PROJECT_ID = "harshini-450807"
        GKE_CLUSTER = "usecase-1-cluster"
        GKE_REGION = "us-central1"
        IMAGE_NAME = "my-project-uc-1"
        IMAGE_TAG = "${BUILD_NUMBER}"
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-svc-acc-key')
        DOCKER_HUB_USERNAME = "harshini1402"
        DOCKER_HUB_PASSWORD = credentials('harshini-docker-hub-creds')
    }
    tools {
        jdk 'jdk-17'
        maven 'maven-3.8.8'
    }
    stages {
        stage('Cloning the Git Repository') {
            steps {
                git branch: 'main', credentialsId: '${GITHUB_TOKEN}', url: "${params.GIT_REPO}"
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    sh "echo $DOCKER_HUB_PASSWORD | docker login -u ${DOCKER_HUB_USERNAME} --password-stdin"
                }  
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'  
                sh 'docker push ${IMAGE_NAME}:${IMAGE_TAG}'
            }
        }

        stage('Terraform: Initialize') {
            steps {
                echo 'Initializing Terraform'
                sh 'terraform init'
            }
        }

        stage('Terraform: Plan') {
            steps {
                echo 'Planning Terraform'
                sh 'terraform plan'
            }
        }

        stage('Terraform: Apply') {
            when {
                expression { params.CREATE_CLUSTER }
            }
            steps {
                script {
                    echo 'Applying Terraform config to Create GCP Resources'
                    withCredentials([file(credentialsId: 'gcp-svc-acc-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh '''
                        gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}
                        export GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}
                        terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Update Deployment File') {
            steps {
                script {
                    echo 'Updating Deployment YAML with latest Docker image...'
                    sh """
                    sed -i 's|image: .*|image: ${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}|' deploy.yml
                    """
                }
            }
        }

        stage('Deploy Application') {
            steps {
                withCredentials([file(credentialsId: 'gcp-svc-acc-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        echo 'Authenticating with GCP...'
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'

                        // Get Kubernetes credentials
                        sh """
                        gcloud container clusters get-credentials ${GKE_CLUSTER} --region ${GKE_REGION} --project ${PROJECT_ID}
                        """

                        // Deploy to Kubernetes
                        sh 'kubectl apply -f deploy.yml'
                        sh 'kubectl set image deployment/demo-app demo-app=${IMAGE_NAME}:${IMAGE_TAG}'
                        sh 'kubectl rollout status deployment demo-app'
                        sh 'sleep 15'
                        sh 'kubectl get deployments'
                        sh 'kubectl describe deployment demo-app'
                        sh 'kubectl get pods'
                        sh 'kubectl get svc'
                        echo 'Deployment and service details retrieved.'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build, Docker image creation, Terraform infra creation, and Kubernetes deployment successful!"
        }
        failure {
            script {
                if (params.ROLLBACK) {
                    echo "Rolling back to Previous Version"
                    sh 'kubectl rollout undo deployment demo-app --to-revision=1'
                } else {
                    echo "Deployment failed! No rollback triggered."
                }
            }
        }
    }
}
