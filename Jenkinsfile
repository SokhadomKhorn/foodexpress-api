pipeline {
    agent any

    environment {
        EC2_IP = "98.89.47.255"
    }

    stages {

        stage('Clone Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/SokhadomKhorn/foodexpress-api.git'
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                        cd foodexpress-api &&
                        git pull &&
                        docker stop \$(docker ps -q) || true &&
                        docker rm \$(docker ps -aq) || true &&
                        docker build -t foodexpress . &&
                        docker run -d -p 80:5000 foodexpress
                    '
                    """
                }
            }
        }
    }
}
