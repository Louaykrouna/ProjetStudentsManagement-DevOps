pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "louaykrouna/students-management"
        DOCKER_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                echo '===== Checkout du code ====='
                git branch: 'master', url: 'https://github.com/Louaykrouna/ProjetStudentsManagement-DevOps.git'
            }
        }

        stage('Build Backend') {
            steps {
                echo "===== Build Backend ====="
                sh 'mvn clean install -DskipTests'
            }
        }

        stage('Package App') {
            steps {
                echo "===== Packaging JAR ====="
                sh 'mvn package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "===== 🚧 Construction image Docker ====="
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "===== 🚀 Push image vers Docker Hub ====="
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-cred',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline exécutée avec succès !'
        }
        always {
            echo '🧹 Nettoyage image docker locale'
            sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
        }
    }
}
