pipeline {
    agent any
    options {
        disableConcurrentBuilds()
        durabilityHint('PERFORMANCE_OPTIMIZED')
        timeout(time: 60, unit: 'MINUTES')
    }
    environment {
        AWS_REGION = 'ap-south-1'
        TF_IN_AUTOMATION = 'true'
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

      stage('Import Existing Resources') {
    when {
        expression { return params.DESTROY == false || params.DESTROY == 'false' }
    }
    steps {
        dir('terraform') {
            sh '''
            echo "Checking if EKS access entry exists in AWS..."

            if aws eks describe-access-entry \
                --cluster-name terraform-eks-cluster \
                --principal-arn arn:aws:iam::333982363626:role/jenkins-eks-role \
                --region ap-south-1 > /dev/null 2>&1; then

                STATE_CHECK=$(terraform state list 2>/dev/null | grep "aws_eks_access_entry.jenkins" || true)

                if [ -z "$STATE_CHECK" ]; then
                    echo "Importing EKS access entry..."

                    terraform import \
                      aws_eks_access_entry.jenkins \
                      "terraform-eks-cluster,arn:aws:iam::333982363626:role/jenkins-eks-role" || true

                else
                    echo "Already in state - skipping import"
                fi

            else
                echo "Access entry does not exist - will be created"
            fi
            '''
        }
    }
}
        stage('Terraform Apply') {
            when {
                expression { return params.DESTROY == false || params.DESTROY == 'false' }
            }
            steps {
                dir('terraform') {
                    sh '''
                    terraform apply -auto-approve
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
                    if [ -f "$STATE_FILE" ]; then
                        echo "✅ Restoring state for destroy..."
                        cp $STATE_FILE terraform.tfstate
                    else
                        echo "❌ No state file found, cannot destroy"
                        exit 1
                    fi
                    terraform destroy -auto-approve
                    rm -f $STATE_FILE
                    echo "✅ State cleaned up after destroy"
                    '''
                }
            }
        }
    }

    post {
        always {
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
