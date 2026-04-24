pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
        // ✅ Fixed: Correct Jenkins home path
        STATE_FILE = '/var/lib/jenkins/terraform-states/eks/terraform.tfstate'
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
                    # ✅ Fixed: Correct directory path
                    mkdir -p /var/lib/jenkins/terraform-states/eks

                    # ✅ Restore state from Jenkins home if exists
                    if [ -f "$STATE_FILE" ]; then
                        echo "✅ Restoring existing state file..."
                        cp $STATE_FILE terraform.tfstate
                    else
                        echo "⚠️ No existing state found, fresh start"
                    fi

                    # ✅ Only remove plugin cache, never state
                    rm -rf .terraform .terraform.lock.hcl
                    terraform init -upgrade
                    '''
                }
            }
        }

        // ✅ Fixed: Apply only when DESTROY is false
        stage('Terraform Apply') {
            when {
                expression { return params.DESTROY == false || params.DESTROY == 'false' }
            }
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
                expression { return params.DESTROY == false || params.DESTROY == 'false' }
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

                # ✅ Verify connection before deploying
                kubectl get nodes
                '''
            }
        }

        stage('Deploy to EKS') {
            when {
                expression { return params.DESTROY == false || params.DESTROY == 'false' }
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
                expression { return params.DESTROY == true || params.DESTROY == 'true' }
            }
            steps {
                dir('terraform') {
                    sh '''
                    # ✅ Restore state before destroy
                    if [ -f "$STATE_FILE" ]; then
                        echo "✅ Restoring state for destroy..."
                        cp $STATE_FILE terraform.tfstate
                    else
                        echo "❌ No state file found, cannot destroy"
                        exit 1
                    fi

                    terraform destroy -auto-approve

                    # ✅ Clean up state after successful destroy
                    rm -f $STATE_FILE
                    echo "✅ State cleaned up after destroy"
                    '''
                }
            }
        }
    }

    post {
        always {
            // ✅ Added: Always save state even if pipeline fails
            dir('terraform') {
                sh '''
                if [ -f "terraform.tfstate" ]; then
                    mkdir -p /var/lib/jenkins/terraform-states/eks
                    cp terraform.tfstate $STATE_FILE
                    echo "✅ State backed up in post step"
                fi
                '''
            }
        }
        success {
            echo '✅ Pipeline executed successfully'
        }
        failure {
            echo '❌ Pipeline failed - Check AWS credentials and IAM role permissions'
        }
    }
}
