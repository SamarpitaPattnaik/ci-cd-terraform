pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
    }
    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/SamarpitaPattnaik/ci-cd-terraform.git'
            }
        }
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'rm -rf .terraform .terraform.lock.hcl'
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -destory-approve'
                }
            }
        }
}
