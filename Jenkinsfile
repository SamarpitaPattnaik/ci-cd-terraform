pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
    }
    stages {
        stage('Clone Repo') {
            steps {
                git 'https://github.com/your-username/jenkins-eks-terraform.git'
            }
        }
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Update kubeconfig') {
            steps {
                script {
                    env.CLUSTER_NAME = sh(
                        script: "cd terraform && terraform output -raw cluster_name",
                        returnStdout: true
                    ).trim()
                }
                sh "aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME"
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
            }
        }
    }
}