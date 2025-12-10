pipeline {
    agent any

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
            }
        }

        stage('Deploy') {
            steps {
                echo "===== Simulation déploiement ====="
                sh 'echo Application prête à être déployée !'
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline exécutée avec succès !'
        }
        failure {
            echo '❌ Pipeline échouée, vérifier les logs.'
        }
    }
}
