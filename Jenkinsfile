pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
    }

    parameters {
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Destroy infrastructure instead of creating'
        )
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
                    sh '''
                    rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
                    terraform init -upgrade
                    '''
                }
            }
        }

        // 🔥 APPLY ONLY IF NOT DESTROY
        stage('Terraform Apply') {
            when {
                expression { return params.DESTROY == false }
            }
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        // 🔥 UPDATE KUBECONFIG ONLY IF APPLY
        stage('Update kubeconfig') {
            when {
                expression { return params.DESTROY == false }
            }
            steps {
                script {
                    env.CLUSTER_NAME = sh(
                        script: "cd terraform && terraform output -raw cluster_name",
                        returnStdout: true
                    ).trim()
                }

                sh '''
                aws eks update-kubeconfig \
                --region $AWS_REGION \
                --name $CLUSTER_NAME
                '''
            }
        }

        // 🔥 DEPLOY ONLY IF APPLY
        stage('Deploy to EKS') {
            when {
                expression { return params.DESTROY == false }
            }
            steps {
                sh '''
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml
                '''
            }
        }

        // 🔥 DESTROY ONLY IF SELECTED
        stage('Terraform Destroy') {
            when {
                expression { return params.DESTROY == true }
            }
            steps {
                dir('terraform') {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline executed successfully'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
