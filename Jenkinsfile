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
                bat 'npm install'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                bat "docker build -t %DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER% -t %DOCKER_HUB_USER%/%IMAGE_NAME%:latest ."
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
                    bat 'echo %DOCKER_PASS%| docker login -u %DOCKER_USER% --password-stdin'
                    bat 'docker push %DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER%'
                    bat 'docker push %DOCKER_HUB_USER%/%IMAGE_NAME%:latest'
                    bat 'docker logout'
                }
            }
        }

        stage('Terraform: Provision EC2') {
            steps {
                echo 'Provisioning EC2 with Terraform...'
                withCredentials([
                    string(credentialsId: 'aws-access-key',    variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key',    variable: 'AWS_SECRET_ACCESS_KEY'),
                    string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                ]) {
                    dir('terraform') {
                        bat 'terraform init'
                        bat 'terraform validate'
                        bat 'terraform apply -auto-approve -var="docker_image=sokhadomkhorn/foodexpress-api:latest"'
                        script {
                            env.EC2_PUBLIC_IP = bat(
                                script: '@terraform output -raw public_ip',
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
                    bat "timeout /t 30 /nobreak"
                    bat """
                        ssh -o StrictHostKeyChecking=no -i "%SSH_KEY%" %SSH_USER%@%EC2_PUBLIC_IP% "docker stop foodexpress || true && docker rm foodexpress || true && docker pull %DOCKER_HUB_USER%/%IMAGE_NAME%:latest && docker run -d --name foodexpress --restart always -p 80:%APP_PORT% %DOCKER_HUB_USER%/%IMAGE_NAME%:latest"
                    """
                }
            }
        }

        stage('Smoke Test') {
            steps {
                echo 'Running smoke test...'
                bat "timeout /t 15 /nobreak"
                bat "curl -f http://%EC2_PUBLIC_IP%/"
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
            bat "docker rmi %DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER% 2>nul || exit /b 0"
        }
    }
}