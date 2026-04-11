pipeline {
    agent any

    stages {

        stage('Clone') {
            steps {
                git 'https://github.com/SokhadomKhorn/foodexpress-api.git'
            }
        }

        stage('Build Docker') {
            steps {
                sh 'docker build -t foodexpress .'
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Run App') {
            steps {
                sh 'docker run -d -p 80:3000 foodexpress'
            }
        }
    }
}
