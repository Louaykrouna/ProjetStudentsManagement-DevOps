pipeline {
    agent any

    stages {

        stage('Checkout Source Code') {
            steps {
                echo '===== Checkout du code ====='
                git branch: 'main', url: 'https://github.com/Louaykrouna/ProjetStudentsManagement-DevOps.git'
            }
        }

        stage('Build Backend') {
            steps {
                echo "===== Build backend ====="
                sh 'cd BackendSpring && mvn clean install -DskipTests'
            }
        }

        stage('Test Backend') {
            steps {
                echo "===== Tests Backend ====="
                sh 'cd BackendSpring && mvn test'
            }
        }

        stage('Build Frontend') {
            steps {
                echo "===== Build Frontend Angular ====="
                sh '''
                    cd Frontend
                    npm install
                    npm run build
                '''
            }
        }

        stage('Test Frontend') {
            steps {
                echo "===== Tests Frontend Angular ====="
                sh '''
                    cd Frontend
                    npm test --force
                '''
            }
        }

        stage('Packaging') {
            steps {
                echo "===== Packaging du Backend (JAR) ====="
                sh 'cd BackendSpring && mvn package -DskipTests'
            }
        }

        stage('Deploy') {
            steps {
                echo "===== Simulation Déploiement ====="
                sh 'echo "Déploiement terminé !"'
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline exécutée avec succès !"
        }
        failure {
            echo "❌ Pipeline échouée, vérifier les logs."
        }
    }
}
