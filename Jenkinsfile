pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = 'louway'
        DOCKER_HUB_REPO = "${DOCKER_HUB_USERNAME}/students-management"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'BUILD_TYPE',
            choices: ['development', 'staging', 'production'],
            description: 'Type de build'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: true,
            description: 'Skip les tests'
        )
        booleanParam(
            name: 'PUSH_TO_REGISTRY',
            defaultValue: true,
            description: 'Pousser vers Docker Hub'
        )
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo '===== Checkout du code ====='
                git branch: 'master', url: 'https://github.com/Louaykrouna/ProjetStudentsManagement-DevOps.git'
                
                // Récupérer le hash du commit
                sh 'git rev-parse --short HEAD > commit_hash.txt'
                script {
                    env.COMMIT_HASH = readFile('commit_hash.txt').trim()
                    echo "Commit: ${env.COMMIT_HASH}"
                }
            }
        }

        stage('Initialize Variables') {
            steps {
                script {
                    // Déterminer la branche
                    env.BRANCH_NAME = env.GIT_BRANCH ? env.GIT_BRANCH.replace('origin/', '') : 'master'
                    env.IS_MASTER_BRANCH = (env.BRANCH_NAME == 'master')
                    env.IS_DEVELOP_BRANCH = (env.BRANCH_NAME == 'develop')
                    
                    echo "Branche détectée: ${env.BRANCH_NAME}"
                    echo "Is Master: ${env.IS_MASTER_BRANCH}"
                    echo "Is Develop: ${env.IS_DEVELOP_BRANCH}"
                    
                    // Créer un tag avec timestamp
                    def timestamp = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
                    env.TIMESTAMP_TAG = "build-${BUILD_NUMBER}-${timestamp}"
                }
            }
        }

        stage('Build & Test Backend') {
            steps {
                echo "===== Build Backend ====="
                script {
                    def testCommand = params.SKIP_TESTS ? '-DskipTests' : ''
                    sh """
                        mvn clean install ${testCommand}
                        echo "✅ Build Maven réussi"
                    """
                    
                    // Exécuter les tests uniquement si demandé
                    if (!params.SKIP_TESTS) {
                        sh '''
                            echo "===== Exécution des tests ====="
                            mvn test -Dspring.datasource.url=jdbc:h2:mem:testdb \
                                    -Dspring.jpa.hibernate.ddl-auto=create-drop \
                                    -Dspring.profiles.active=test
                        '''
                    }
                }
            }
        }

        stage('Packaging') {
            steps {
                echo "===== Packaging (JAR) ====="
                sh '''
                    mvn package -DskipTests
                    
                    # Vérifier que le JAR a été créé
                    echo "=== Fichiers générés ==="
                    ls -la target/*.jar
                    echo "=== Taille du JAR ==="
                    du -h target/*.jar | tail -1
                '''
                
                // Archive le JAR
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "===== Construction de l\'image Docker ====="
                script {
                    // Préparer les tags
                    def tags = [
                        "${DOCKER_HUB_REPO}:${IMAGE_TAG}",
                        "${DOCKER_HUB_REPO}:${env.TIMESTAMP_TAG}",
                        "${DOCKER_HUB_REPO}:commit-${env.COMMIT_HASH}"
                    ]
                    
                    // Ajouter le tag latest si c'est la branche master
                    if (env.IS_MASTER_BRANCH.toString() == 'true') {
                        tags.add("${DOCKER_HUB_REPO}:latest")
                        echo "✅ Ajout du tag 'latest' (branche master)"
                    }
                    
                    // Ajouter le tag develop si c'est la branche develop
                    if (env.IS_DEVELOP_BRANCH.toString() == 'true') {
                        tags.add("${DOCKER_HUB_REPO}:develop")
                        echo "✅ Ajout du tag 'develop' (branche develop)"
                    }
                    
                    // Afficher tous les tags
                    echo "Tags à construire: ${tags.join(', ')}"
                    
                    // Construire avec tous les tags
                    def dockerBuildCmd = "docker build"
                    tags.each { tag ->
                        dockerBuildCmd += " -t ${tag}"
                    }
                    dockerBuildCmd += " ."
                    
                    sh """
                        echo "=== Informations Docker ==="
                        docker version
                        
                        echo "=== Construction de l\'image ==="
                        ${dockerBuildCmd}
                        
                        echo "=== Images créées ==="
                        docker images ${DOCKER_HUB_REPO}
                        
                        echo "✅ Images Docker construites avec succès"
                    """
                    
                    // Sauvegarder les tags dans l'environnement
                    env.DOCKER_TAGS = tags.join(',')
                    env.DOCKER_IMAGE = "${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                }
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression { 
                    params.PUSH_TO_REGISTRY == true
                }
            }
            steps {
                echo "===== Push vers Docker Hub ====="
                script {
                    // Vérifier si les credentials existent
                    def dockerHubCredential = 'docker-hub-token'
                    
                    // Tentative de connexion avec les credentials
                    withCredentials([string(credentialsId: dockerHubCredential, variable: 'DOCKER_TOKEN')]) {
                        // Tentative avec retry en cas d'erreur réseau
                        retry(3) {
                            sh """
                                set +x  # Désactiver le debug pour le token
                                echo "🔐 Connexion à Docker Hub..."
                                echo "\${DOCKER_TOKEN}" | docker login --username ${DOCKER_HUB_USERNAME} --password-stdin
                                set -x  # Réactiver le debug
                                
                                echo "📤 Pushing images..."
                                
                                # Pousser toutes les images taggées
                                for tag in ${env.DOCKER_TAGS}; do
                                    echo "Pushing \${tag}..."
                                    docker push \${tag}
                                    echo "✅ \${tag} poussé avec succès"
                                done
                                
                                docker logout
                                echo "✅ Toutes les images ont été poussées avec succès!"
                            """
                        }
                        
                        // Afficher les URLs Docker Hub
                        echo "🎯 URLs des images Docker Hub:"
                        script {
                            env.DOCKER_TAGS.split(',').each { tag ->
                                def parts = tag.split(':')
                                if (parts.length >= 2) {
                                    def repoName = parts[0].replace('louway/', '')
                                    def tagName = parts[1]
                                    echo "🔗 https://hub.docker.com/r/louway/${repoName}/tags?name=${tagName}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "===== Nettoyage ====="
                script {
                    sh """
                        # Nettoyer les images intermédiaires
                        docker images --filter "dangling=true" -q | xargs -r docker rmi 2>/dev/null || true
                        
                        echo "✅ Nettoyage terminé"
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                echo "🎉 Pipeline exécutée avec succès !"
                echo "📦 Image Docker: ${env.DOCKER_IMAGE ?: 'N/A'}"
                echo "🏷 Tags: ${env.DOCKER_TAGS ?: 'Aucun tag généré'}"
                echo "🔗 Docker Hub: https://hub.docker.com/r/${DOCKER_HUB_REPO}"
                
                // Créer un fichier de rapport
                writeFile file: 'build-report.txt', text: """
                ===== RAPPORT DE BUILD =====
                Date: ${new Date()}
                Build: #${BUILD_NUMBER}
                Commit: ${env.COMMIT_HASH ?: 'N/A'}
                Branche: ${env.BRANCH_NAME ?: 'N/A'}
                Image: ${env.DOCKER_IMAGE ?: 'N/A'}
                Tags: ${env.DOCKER_TAGS ?: 'N/A'}
                JAR: target/student-management-*.jar
                Statut: SUCCÈS
                """
                
                // Archive le rapport
                archiveArtifacts artifacts: 'build-report.txt', fingerprint: true
            }
        }
        failure {
            script {
                echo '❌ Pipeline échouée'
                
                // Logs de débogage
                sh '''
                    echo "=== Logs de build ==="
                    find . -name "*.log" -type f | head -5 | xargs tail -50 2>/dev/null || echo "Pas de logs trouvés"
                    
                    echo "=== Docker status ==="
                    docker ps -a 2>/dev/null || echo "Docker non disponible"
                '''
            }
        }
        always {
            // Nettoyage final
            sh '''
                docker logout 2>/dev/null || true
                rm -f commit_hash.txt build-report.txt 2>/dev/null || true
            '''
            
            echo "=== Résumé du build ==="
            echo "Build: #${BUILD_NUMBER}"
            echo "Durée: ${currentBuild.durationString}"
            echo "Image: ${env.DOCKER_IMAGE ?: 'Non créée'}"
            echo "Push Registry: ${params.PUSH_TO_REGISTRY ? 'Configuré' : 'Désactivé'}"
        }
    }
}
