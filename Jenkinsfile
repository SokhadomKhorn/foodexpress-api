pipeline {
    agent any
    tools {
        nodejs 'NodeJS'
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
                sh 'docker build -t foodexpress-api .'
            }
        }
        stage('Deploy Container') {
            steps {
                echo 'Deploying container...'
                sh 'docker stop foodexpress || true'
                sh 'docker rm foodexpress || true'
                sh 'docker run -d -p 3000:3000 --name foodexpress foodexpress-api'
            }
        }
    }
}