pipeline {
    agent any

    tools {
        nodejs 'NodeJS'
    }

    // ── Environment variables ─────────────────────────────────────────
    environment {
        DOCKER_HUB_USER     = 'sokhadomkhorn'               // Your Docker Hub username
        IMAGE_NAME          = 'foodexpress-api'
        IMAGE_TAG           = "${env.BUILD_NUMBER}"
        DOCKER_IMAGE_FULL   = "${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
        DOCKER_IMAGE_LATEST = "${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
        APP_PORT            = '5000'
    }

    // ── Trigger on every GitHub push ─────────────────────────────────
    triggers {
        githubPush()
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        // ── Stage 1: Clone Repository ─────────────────────────────────
        stage('Clone Repository') {
            steps {
                echo 'Cloning repository...'
                checkout scm
                sh 'echo "Branch: ${GIT_BRANCH} | Commit: ${GIT_COMMIT}"'
            }
        }

        // ── Stage 2: Install Dependencies ────────────────────────────
        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }

        // ── Stage 3: Build Docker Image ──────────────────────────────
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE_FULL}"
                sh """
                    docker build \
                      -t ${DOCKER_IMAGE_FULL} \
                      -t ${DOCKER_IMAGE_LATEST} \
                      .
                """
                sh "docker images | grep ${IMAGE_NAME}"
            }
        }

        // ── Stage 4: Push to Docker Hub ──────────────────────────────
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE_FULL}
                        docker push ${DOCKER_IMAGE_LATEST}
                        docker logout
                    """
                }
            }
        }

        // ── Stage 5: Terraform — Provision EC2 ───────────────────────
        stage('Terraform: Provision EC2') {
            steps {
                echo 'Provisioning AWS EC2 instance with Terraform...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('terraform') {
                        sh """
                            terraform init
                            terraform validate
                            terraform plan \
                              -var="docker_image=${DOCKER_IMAGE_LATEST}" \
                              -out=tfplan
                            terraform apply -auto-approve tfplan
                        """
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

        // ── Stage 6: Deploy Container to EC2 ─────────────────────────
        stage('Deploy Container') {
            steps {
                echo "Deploying container to EC2 at ${EC2_PUBLIC_IP}..."
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ec2-ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh """
                        # Wait for EC2 SSH to become available
                        sleep 30

                        ssh -o StrictHostKeyChecking=no \
                            -i "${SSH_KEY}" \
                            ${SSH_USER}@${EC2_PUBLIC_IP} << 'REMOTE'
                            docker stop foodexpress 2>/dev/null || true
                            docker rm   foodexpress 2>/dev/null || true
                            docker pull ${DOCKER_IMAGE_LATEST}
                            docker run -d \
                              --name foodexpress \
                              --restart always \
                              -p 80:${APP_PORT} \
                              ${DOCKER_IMAGE_LATEST}
                            echo "Running containers:"
                            docker ps | grep foodexpress
REMOTE
                    """
                }
            }
        }

        // ── Stage 7: Smoke Test ───────────────────────────────────────
        stage('Smoke Test') {
            steps {
                echo 'Verifying application is live...'
                sh """
                    sleep 15
                    HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${EC2_PUBLIC_IP}/ || echo "000")
                    echo "HTTP status: \$HTTP_STATUS"
                    if [ "\$HTTP_STATUS" != "200" ]; then
                        echo "SMOKE TEST FAILED — expected 200, got \$HTTP_STATUS"
                        exit 1
                    fi
                    echo "SMOKE TEST PASSED — app is live at http://${EC2_PUBLIC_IP}"
                """
            }
        }
    }

    // ── Post-build ────────────────────────────────────────────────────
    post {
        success {
            echo """
            ================================================
            DEPLOYMENT SUCCESSFUL
            App URL : http://${EC2_PUBLIC_IP}
            Image   : ${DOCKER_IMAGE_FULL}
            Build   : #${env.BUILD_NUMBER}
            ================================================
            """
        }
        failure {
            echo 'Pipeline FAILED. Review logs above.'
        }
        always {
            sh "docker rmi ${DOCKER_IMAGE_FULL} ${DOCKER_IMAGE_LATEST} 2>/dev/null || true"
        }
    }
}
