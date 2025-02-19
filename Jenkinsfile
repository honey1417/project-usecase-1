pipeline {
    agent any
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'stage', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Rollback to Previous Version?')
        booleanParam(name: 'CREATE_CLUSTER', defaultValue: false, description: 'Create GCP Kubernetes Cluster?')
    } 

    environment {
        GITHUB_TOKEN = credentials('github-pat')
        PROJECT_ID = "harshini-450807"
        GKE_CLUSTER = "usecase-1-cluster"
        GKE_REGION = "us-central1"
        //IMAGE_NAME = "usecase-1"
        IMAGE_TAG = "${BUILD_NUMBER}"
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-creds')
        DOCKER_HUB_USR = "harshini1402"
        DOCKER_HUB_PSW = credentials('docker-creds')
    }
    
    tools {
        jdk 'jdk-17'
        maven 'maven-3.8.8'
        git 'Git'
    }

    stages {
        stage('Test Git Command') {
            steps {
                script {
                    sh 'git --version'
                }
            }
        }

        stage('Cloning the Git Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/honey1417/project-usecases.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

            // stage('Docker Build') {
            //     steps {
            //         sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'  
            //     }
            // }

        stage('Docker Build & Push') {
            steps {
                script {
                    //echo "Building Docker Image: ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker build -t csk ."

                    echo "Listing Docker Images..."
                    sh "docker images"

                    // Verify if the image exists before tagging
                    sh '''
                        docker images | grep "${IMAGE_NAME}" || { echo "Error: Docker image not found!"; exit 1; }
                    '''

                    echo "Logging into Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: 'docker-creds', usernameVariable: 'DOCKER_HUB_USR', passwordVariable: 'DOCKER_HUB_PSW')]) {
                        sh '''
                            echo $DOCKER_HUB_PSW | docker login -u $DOCKER_HUB_USR --password-stdin
                        '''
                        
                        echo "Tagging Image..."
                        sh "docker tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} ${env.DOCKER_HUB_USR}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"

                        echo "Pushing Image to Docker Hub..."
                        sh "docker push ${env.DOCKER_HUB_USR}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    }

                    echo "Docker Push Completed Successfully!"
                }
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
                    withCredentials([file(credentialsId: 'gcp-creds', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
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
                    sed -i 's|image: .*|image: ${DOCKER_HUB_USR}/${IMAGE_NAME}:${IMAGE_TAG}|' deploy.yml
                    """
                }
            }
        }

        stage('Deploy Application') {
            steps {
                withCredentials([file(credentialsId: 'gcp-creds', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    script {
                        echo 'Authenticating with GCP...'
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'

                        // Get Kubernetes credentials
                        sh """
                        gcloud container clusters get-credentials ${GKE_CLUSTER} --region ${GKE_REGION} --project ${PROJECT_ID}
                        """

                        // Deploy to Kubernetes
                        sh 'kubectl apply -f deploy.yml'
                        sh 'kubectl set image deployment/project-uc1-deployment  project-uc1-deployment=${DOCKER_HUB_USR}/${IMAGE_NAME}:${IMAGE_TAG}'
                        sh 'kubectl rollout status deployment' 
                        sh 'sleep 15'
                        sh 'kubectl get deployments'
                        sh 'kubectl describe deployment project-uc1-deployment'
                        sh 'kubectl get pods'
                        sh 'kubectl get svc'
                        echo 'Deployment and service details retrieved'
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
                    sh 'kubectl rollout undo deployment project-uc1-deployment --to-revision=1'
                } else {
                    echo "Deployment failed! No rollback triggered."
                }
            }
        }
    }
}
