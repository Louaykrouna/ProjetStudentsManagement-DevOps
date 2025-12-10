pipeline {
    agent any
    
    environment {
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        DOCKER_IMAGE = "louaykrouna/students-management"
        DOCKER_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '===== Récupération du code source ====='
                checkout scm
            }
        }
        
        stage('Build Backend') {
            steps {
                echo '===== Compilation du backend Spring Boot ====='
                sh 'mvn clean compile -DskipTests'
            }
        }
        
        stage('Test Backend') {
            steps {
                echo '===== Exécution des tests ====='
                sh 'mvn test'
            }
        }
        
        stage('Package Backend') {
            steps {
                echo '===== Création du JAR ====='
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '===== Construction de l\'image Docker ====='
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo '===== Push de l\'image sur Docker Hub ====='
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', 
                                                      usernameVariable: 'DOCKER_USER', 
                                                      passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        sh "docker push ${DOCKER_IMAGE}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo '===== Déploiement sur Kubernetes ====='
                script {
                    sh "kubectl apply -f k8s/mysql-deployment.yaml"
                    sh "kubectl apply -f k8s/backend-deployment.yaml"
                    sh "kubectl get pods -n devops"
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline exécuté avec succès !'
        }
        failure {
            echo '❌ Le pipeline a échoué !'
        }
        always {
            echo '===== Nettoyage des images Docker locales ====='
            sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
        }
    }
}
