pipeline {
    agent any

    environment {
        // NE PAS mettre le token ici! Utiliser Jenkins Credentials
        DOCKER_HUB_USERNAME = 'louaykrouna'  // OK - c'est public
        DOCKER_HUB_REPO = "${DOCKER_HUB_USERNAME}/students-management"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
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

        stage('Test Backend') {
            steps {
                echo "===== Tests Backend ====="
                sh 'mvn test'
            }
        }

        stage('Packaging') {
            steps {
                echo "===== Packaging (JAR) ====="
                sh 'mvn package -DskipTests'
                
                // Vérifier que le JAR a été créé
                sh 'ls -la target/*.jar'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "===== Construction de l\'image Docker ====="
                script {
                    // Construire l'image avec votre Dockerfile existant
                    sh "docker build -t ${DOCKER_HUB_REPO}:${IMAGE_TAG} ."
                    
                    // Ajouter le tag "latest"
                    sh "docker tag ${DOCKER_HUB_REPO}:${IMAGE_TAG} ${DOCKER_HUB_REPO}:latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "===== Push vers Docker Hub avec PAT ====="
                script {
                    // Utiliser withCredentials pour sécuriser le token
                    withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_TOKEN')]) {
                        sh """
                            # Se connecter à Docker Hub avec le PAT depuis Jenkins Credentials
                            echo "\$DOCKER_TOKEN" | docker login \
                                --username ${DOCKER_HUB_USERNAME} \
                                --password-stdin
                            
                            # Pousser les images
                            docker push ${DOCKER_HUB_REPO}:${IMAGE_TAG}
                            docker push ${DOCKER_HUB_REPO}:latest
                            
                            # Déconnexion
                            docker logout
                            
                            echo "✅ Push réussi vers Docker Hub!"
                        """
                    }
                    
                    echo "📦 Repository: ${DOCKER_HUB_REPO}"
                    echo "🏷️  Tags: ${IMAGE_TAG} et latest"
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "===== Nettoyage ====="
                script {
                    sh """
                        docker rmi ${DOCKER_HUB_REPO}:${IMAGE_TAG} 2>/dev/null || true
                        docker rmi ${DOCKER_HUB_REPO}:latest 2>/dev/null || true
                    """
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline exécutée avec succès !'
            echo "📦 Image: ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
        }
        failure {
            echo '❌ Pipeline échouée, vérifier les logs.'
        }
        always {
            sh 'docker logout 2>/dev/null || true'
        }
    }
}
