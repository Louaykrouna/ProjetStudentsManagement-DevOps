pipeline {
    agent any

    tools {
        maven 'Maven3'  // si tu as configuré Maven dans Jenkins
        jdk 'JDK17'      // si tu as configuré Java dans Jenkins
        nodejs 'Node18'  // si tu as configuré NodeJS dans Jenkins
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                git branch: 'main', url: 'https://github.com/Louaykrouna/ProjetStudentsManagement-DevOps.git'
            }
        }

        stage('Build Backend') {
            steps {
                echo "Building Backend..."
                sh 'cd BackendSpring && mvn clean install -DskipTests'
            }
        }

        stage('Test Backend Unit') {
            steps {
                echo "Running Unit Tests for Backend..."
                sh 'cd BackendSpring && mvn test'
            }
        }

        stage('Build Frontend') {
            steps {
                echo "Building Frontend..."
                sh '''
                cd Frontend
                npm install
                npm run build
                '''
            }
        }

        stage('Test Frontend') {
            steps {
                echo "Running Frontend Tests..."
                sh '''
                cd Frontend
                npm test --force
                '''
            }
        }

        stage('Packaging') {
            steps {
                echo "Packaging artifacts..."
                sh 'cd BackendSpring && mvn package -DskipTests'
            }
        }

        stage('Deploy') {
            steps {
                echo "Deployment step..."
                // Simuler déploiement:
                sh 'echo "Deploying.... done!"'
            }
        }
    }

    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check logs.'
        }
    }
}
