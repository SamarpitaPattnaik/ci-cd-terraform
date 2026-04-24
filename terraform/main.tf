module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-eks-cluster"
  cluster_version = "1.30"  # ⚠️ Changed: 1.35 doesn't exist yet, use 1.29 or 1.30

  # ✅ Disable KMS to avoid plugin crash
  create_kms_key            = false
  cluster_encryption_config = {}

  create_cloudwatch_log_group = false

  vpc_id = "vpc-0027db6152b73fc0d"
  subnet_ids = [
    "subnet-00f21c8a15164983f",
    "subnet-037b475270b0e713e",
    "subnet-0ebe331755e4e9e38"
  ]

  # ✅ Added: Automatically gives cluster creator admin access
  enable_cluster_creator_admin_permissions = true

  # ✅ Added: Allow public access to EKS API (needed for Jenkins to connect)
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      desired_size   = 2
      min_size       = 1  # ✅ Added: required fields
      max_size       = 3  # ✅ Added: required fields
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }

  access_entries = {
    jenkins = {
      principal_arn = "arn:aws:iam::333982363626:role/jenkins-eks-role"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
