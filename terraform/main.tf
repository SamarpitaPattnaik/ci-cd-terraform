module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-eks-cluster"
  cluster_version = "1.30"

  create_kms_key            = false
  cluster_encryption_config = {}
  create_cloudwatch_log_group = false

  cluster_endpoint_public_access = true

  vpc_id = "vpc-0027db6152b73fc0d"
  subnet_ids = [
    "subnet-00f21c8a15164983f",
    "subnet-037b475270b0e713e",
    "subnet-0ebe331755e4e9e38"
  ]

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }

  # ✅ Removed access_entries block - handled separately below
}

# ✅ Separate resource - easier to import and manage
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::333982363626:role/jenkins-eks-role"
  type          = "STANDARD"

  # Ignore if already exists
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_eks_access_policy_association" "jenkins_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::333982363626:role/jenkins-eks-role"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.jenkins]
}
