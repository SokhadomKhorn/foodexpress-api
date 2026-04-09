pipeline {
agent any

```
tools {
    nodejs 'NodeJS'
}

environment {
    DOCKER_HUB_USER     = 'sokhadomkhorn'
    IMAGE_NAME          = 'foodexpress-api'
    IMAGE_TAG           = "%BUILD_NUMBER%"
    DOCKER_IMAGE_FULL   = "%DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER%"
    DOCKER_IMAGE_LATEST = "%DOCKER_HUB_USER%/%IMAGE_NAME%:latest"
    APP_PORT            = '5000'
}

triggers {
    githubPush()
}

stages {

    stage('Clone Repository') {
        steps {
            echo 'Cloning repository...'
            checkout scm
            bat 'echo Branch: %GIT_BRANCH% Commit: %GIT_COMMIT%'
        }
    }

    stage('Install Dependencies') {
        steps {
            bat 'npm install'
        }
    }

    stage('Build Docker Image') {
        steps {
            bat '''
            docker build ^
              -t %DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER% ^
              -t %DOCKER_HUB_USER%/%IMAGE_NAME%:latest ^
              .
            '''
        }
    }

    stage('Push to Docker Hub') {
        steps {
            withCredentials([usernamePassword(
                credentialsId: 'dockerhub-credentials',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )]) {
                bat '''
                echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                docker push %DOCKER_HUB_USER%/%IMAGE_NAME%:%BUILD_NUMBER%
                docker push %DOCKER_HUB_USER%/%IMAGE_NAME%:latest
                docker logout
                '''
            }
        }
    }

    stage('Terraform: Provision EC2') {
        steps {
            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'aws-credentials',
                accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                dir('terraform') {
                    bat 'terraform init'
                    bat 'terraform validate'
                    bat 'terraform apply -auto-approve'
                    
                    script {
                        env.EC2_PUBLIC_IP = bat(
                            script: 'terraform output -raw public_ip',
                            returnStdout: true
                        ).trim()
                    }
                }
            }
            echo "EC2 IP: ${EC2_PUBLIC_IP}"
        }
    }

    stage('Deploy to EC2') {
        steps {
            withCredentials([sshUserPrivateKey(
                credentialsId: 'ec2-ssh-key',
                keyFileVariable: 'SSH_KEY',
                usernameVariable: 'SSH_USER'
            )]) {
                bat """
                timeout /t 30

                ssh -o StrictHostKeyChecking=no -i "%SSH_KEY%" %SSH_USER%@%EC2_PUBLIC_IP% ^
                "docker stop foodexpress || true && ^
                 docker rm foodexpress || true && ^
                 docker pull %DOCKER_HUB_USER%/%IMAGE_NAME%:latest && ^
                 docker run -d --name foodexpress --restart always -p 80:5000 %DOCKER_HUB_USER%/%IMAGE_NAME%:latest"
                """
            }
        }
    }

    stage('Smoke Test') {
        steps {
            bat """
            timeout /t 15
            curl http://%EC2_PUBLIC_IP%
            """
        }
    }
}

post {
    success {
        echo "App deployed at: http://${EC2_PUBLIC_IP}"
    }
    failure {
        echo "Pipeline failed."
    }
}
```

}

