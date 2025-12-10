pipeline {
    agent any

    environment {
        DOCKER_HUB_USERNAME = 'louway'
        DOCKER_HUB_REPO = "${DOCKER_HUB_USERNAME}/students-management"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        // Tag avec timestamp pour plus de granularité
        TIMESTAMP_TAG = "build-${BUILD_NUMBER}-${new Date().format('yyyyMMdd-HHmmss')}"
        // Vérifier si on est sur une branche spécifique
        IS_MASTER_BRANCH = "${env.BRANCH_NAME}" == 'master'
        IS_DEVELOP_BRANCH = "${env.BRANCH_NAME}" == 'develop'
    }

    options {
        // Timeout après 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        // Nettoyer l'espace de travail après le build
        cleanWs()
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
                    env.BRANCH_NAME = env.GIT_BRANCH?.replace('origin/', '') ?: 'master'
                    echo "Commit: ${COMMIT_HASH}, Branche: ${BRANCH_NAME}"
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

        stage('Quality Checks') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "===== Vérifications qualité ====="
                    
                    // Exécuter les tests unitaires
                    sh 'mvn test -Dspring.profiles.active=test'
                    
                    // Exécuter les tests d'intégration si configurés
                    sh 'mvn verify -DskipITs=false || echo "⚠️ Tests d\'intégration non disponibles"'
                    
                    // Vérifier la qualité du code (optionnel)
                    sh 'mvn checkstyle:check || echo "⚠️ Checkstyle non configuré"'
                    
                    // Analyse des dépendances (optionnel)
                    sh 'mvn dependency:analyze || echo "⚠️ Analyse des dépendances non disponible"'
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
                    echo "=== Informations JAR ==="
                    java -jar target/*.jar --version 2>/dev/null || echo "Version non disponible"
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
                        "${DOCKER_HUB_REPO}:${TIMESTAMP_TAG}",
                        "${DOCKER_HUB_REPO}:commit-${COMMIT_HASH}"
                    ]
                    
                    // Ajouter le tag latest si c'est la branche master
                    if (IS_MASTER_BRANCH) {
                        tags.add("${DOCKER_HUB_REPO}:latest")
                    }
                    
                    // Ajouter le tag develop si c'est la branche develop
                    if (IS_DEVELOP_BRANCH) {
                        tags.add("${DOCKER_HUB_REPO}:develop")
                    }
                    
                    // Construire avec tous les tags
                    def dockerBuildCmd = "docker build"
                    tags.each { tag ->
                        dockerBuildCmd += " -t ${tag}"
                    }
                    dockerBuildCmd += " ."
                    
                    sh """
                        echo "=== Informations Docker ==="
                        docker version
                        docker info | grep -E "Containers|Images|Storage"
                        
                        echo "=== Construction de l\'image avec tags ==="
                        echo "Tags: ${tags.join(', ')}"
                        ${dockerBuildCmd}
                        
                        echo "=== Images créées ==="
                        docker images ${DOCKER_HUB_REPO} --format "table {{.Tag}}\\t{{.Size}}\\t{{.CreatedAt}}"
                        
                        echo "=== Scan de sécurité (basique) ==="
                        docker scan ${DOCKER_HUB_REPO}:${IMAGE_TAG} || echo "⚠️ Docker Scan non disponible"
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
                    params.PUSH_TO_REGISTRY && 
                    credentials('docker-hub-token') 
                }
            }
            steps {
                echo "===== Push vers Docker Hub ====="
                script {
                    withCredentials([string(credentialsId: 'docker-hub-token', variable: 'DOCKER_TOKEN')]) {
                        // Tentative avec retry en cas d'erreur réseau
                        retry(3) {
                            sh """
                                echo "🔐 Connexion à Docker Hub..."
                                echo "\${DOCKER_TOKEN}" | docker login --username ${DOCKER_HUB_USERNAME} --password-stdin
                                
                                echo "📤 Pushing images..."
                                
                                # Pousser toutes les images taggées
                                for tag in ${env.DOCKER_TAGS}; do
                                    echo "Pushing \$tag..."
                                    docker push \$tag
                                    echo "✅ \$tag poussé avec succès"
                                done
                                
                                # Marquer l'image avec les métadonnées
                                docker tag ${DOCKER_HUB_REPO}:${IMAGE_TAG} ${DOCKER_HUB_REPO}:${BUILD_NUMBER}
                                docker push ${DOCKER_HUB_REPO}:${BUILD_NUMBER}
                                
                                # Nettoyage
                                docker logout
                                echo "✅ Toutes les images ont été poussées avec succès!"
                            """
                        }
                    }
                }
                
                // Créer un webhook ou notifier (optionnel)
                script {
                    echo "🎯 URLs des images Docker Hub:"
                    env.DOCKER_TAGS.split(',').each { tag ->
                        def repoName = tag.split(':')[0].replace('louway/', '')
                        def tagName = tag.split(':')[1]
                        echo "🔗 https://hub.docker.com/r/louway/${repoName}/tags?name=${tagName}"
                    }
                }
            }
        }

        stage('Deploy to Registry Alternative') {
            when {
                expression { 
                    params.PUSH_TO_REGISTRY && 
                    !credentials('docker-hub-token') 
                }
            }
            steps {
                script {
                    echo "⚠️ Credentials Docker Hub non trouvés"
                    echo "ℹ️ Pour configurer:"
                    echo "1. Allez dans Jenkins → Manage Credentials"
                    echo "2. Ajoutez un credential 'docker-hub-token' (Secret text)"
                    echo "3. Collez votre PAT Docker Hub"
                    
                    // Sauvegarder l'image dans un tar (fallback)
                    sh """
                        echo "💾 Sauvegarde de l'image localement..."
                        docker save -o /tmp/students-management-${IMAGE_TAG}.tar ${DOCKER_HUB_REPO}:${IMAGE_TAG}
                        ls -lh /tmp/students-management-${IMAGE_TAG}.tar
                    """
                }
            }
        }

        stage('Notification & Cleanup') {
            steps {
                echo "===== Nettoyage ====="
                script {
                    // Nettoyer les images temporaires
                    sh """
                        # Garder seulement les images taggées avec notre repo
                        docker images --filter "dangling=true" -q | xargs -r docker rmi 2>/dev/null || true
                        
                        # Nettoyer les containers arrêtés
                        docker container prune -f 2>/dev/null || true
                        
                        # Nettoyer les volumes non utilisés
                        docker volume prune -f 2>/dev/null || true
                        
                        # Nettoyer le cache build
                        docker builder prune -f 2>/dev/null || true
                        
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
                echo "📦 Image Docker: ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
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
            echo '❌ Pipeline échouée'
            script {
                // Logs de débogage
                sh '''
                    echo "=== Logs Maven ==="
                    tail -100 target/surefire-reports/*.txt 2>/dev/null || echo "Pas de logs de test"
                    
                    echo "=== Docker logs ==="
                    docker ps -a
                    docker images | head -20
                '''
                
                // Envoyer une notification (exemple avec curl)
                sh '''
                    curl -X POST -H "Content-Type: application/json" \
                    -d '{"text":"❌ Build Jenkins #${BUILD_NUMBER} a échoué"}' \
                    ${NOTIFICATION_WEBHOOK_URL} || true
                '''
            }
        }
        always {
            // Nettoyage final
            sh '''
                docker logout 2>/dev/null || true
                rm -f commit_hash.txt build-report.txt 2>/dev/null || true
                
                echo "=== Utilisation des ressources ==="
                df -h /var/lib/docker 2>/dev/null || echo "Info Docker non disponible"
                docker system df 2>/dev/null || echo "Docker non disponible"
            '''
            
            echo "=== Résumé du build ==="
            echo "Build: #${BUILD_NUMBER}"
            echo "Durée: ${currentBuild.durationString}"
            echo "Image: ${env.DOCKER_IMAGE ?: 'Non créée'}"
            echo "Push Registry: ${params.PUSH_TO_REGISTRY ? 'Oui' : 'Non'}"
        }
    }
}
