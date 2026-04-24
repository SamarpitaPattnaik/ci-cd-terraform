pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
        // ✅ Fixed path on Jenkins server to persist state
        STATE_FILE = '/var/jenkins_home/terraform-states/eks/terraform.tfstate'
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
                    # ✅ Restore state from Jenkins home if exists
                    mkdir -p /var/lib/jenkins/terraform-states/eks
                    if [ -f "$STATE_FILE" ]; then
                        echo "✅ Restoring existing state file..."
                        cp $STATE_FILE terraform.tfstate
                    else
                        echo "⚠️ No existing state found, fresh start"
                    fi

                    rm -rf .terraform .terraform.lock.hcl
                    terraform init -upgrade
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh '''
                    terraform apply -auto-approve

                    # ✅ Save state back to Jenkins home after apply
                    cp terraform.tfstate $STATE_FILE
                    echo "✅ State saved successfully"
                    '''
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
                aws eks update-kubeconfig \
                  --region $AWS_REGION \
                  --name $CLUSTER_NAME \
                  --role-arn arn:aws:iam::333982363626:role/jenkins-eks-role

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
                    sh '''
                    # ✅ Restore state before destroy
                    if [ -f "$STATE_FILE" ]; then
                        cp $STATE_FILE terraform.tfstate
                    fi

                    terraform destroy -auto-approve

                    # ✅ Clean up state after destroy
                    rm -f $STATE_FILE
                    '''
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
