pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    environment {
        DOCKER_HUB_USER     = 'sokhadomkhorn'
        IMAGE_NAME          = 'foodexpress-api'
        DOCKER_IMAGE_FULL   = "${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}"
        DOCKER_IMAGE_LATEST = "${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
        APP_PORT            = '5000'
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh """
                docker build -t $DOCKER_IMAGE_FULL -t $DOCKER_IMAGE_LATEST .
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push $DOCKER_IMAGE_FULL
                    docker push $DOCKER_IMAGE_LATEST
                    docker logout
                    """
                }
            }
        }

        stage('Terraform: Provision EC2') {
            steps {
                echo 'Provisioning EC2 with Terraform...'
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                ]) {
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform apply -auto-approve -var="docker_image=sokhadomkhorn/foodexpress-api:latest"'

                        script {
                            env.EC2_PUBLIC_IP = sh(
                                script: 'terraform output -raw public_ip',
                                returnStdout: true
                            ).trim()
                        }
                    }
                }
                echo "EC2 instance ready at: ${EC2_PUBLIC_IP}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo 'Deploying container to EC2...'
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh """
                    sleep 30
                    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" $SSH_USER@$EC2_PUBLIC_IP "
                        docker stop foodexpress || true &&
                        docker rm foodexpress || true &&
                        docker pull $DOCKER_IMAGE_LATEST &&
                        docker run -d --name foodexpress --restart always -p 80:$APP_PORT $DOCKER_IMAGE_LATEST
                    "
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                echo 'Running smoke test...'
                sh """
                sleep 15
                curl -f http://$EC2_PUBLIC_IP/
                """
            }
        }
    }

    post {
        success {
            echo "DEPLOYMENT SUCCESSFUL - App live at: http://${EC2_PUBLIC_IP}"
        }
        failure {
            echo 'Pipeline FAILED. Check the logs above.'
        }
        always {
            sh "docker rmi $DOCKER_IMAGE_FULL || true"
        }
    }
}
