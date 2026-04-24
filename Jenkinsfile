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
                # ✅ Fixed: Added --role-arn so Jenkins assumes the correct IAM role
                aws eks update-kubeconfig \
                  --region $AWS_REGION \
                  --name $CLUSTER_NAME \
                  --role-arn arn:aws:iam::333982363626:role/jenkins-eks-role

                # ✅ Added: Verify connection works before deploying
                kubectl get nodes
                '''
            }
        }

        stage('Deploy to EKS') {
            when {
                expression { return params.DESTROY == false }
            }
            steps {
                sh '''
                kubectl apply -f k8s/deployment.yaml
                kubectl apply -f k8s/service.yaml

                # ✅ Added: Verify deployment rollout
                kubectl rollout status deployment -n default
                '''
            }
        }

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
            echo '❌ Pipeline failed - Check AWS credentials and IAM role permissions'
        }
    }
}
