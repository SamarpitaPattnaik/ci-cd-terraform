module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "terraform-eks-cluster"
  cluster_version = "1.30"

  # 🔥 Important: avoid CloudWatch conflict
  create_cloudwatch_log_group = false

  # 🔥 Networking
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id = "vpc-0027db6152b73fc0d"
  subnet_ids = [
    "subnet-00f21c8a15164983f",
    "subnet-037b475270b0e713e",
    "subnet-0ebe331755e4e9e38"
  ]

  # 🔥 Node group
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }

  # 🔥 Permanent SG fix (Jenkins → EKS API)
  cluster_security_group_additional_rules = {
    jenkins_access = {
      description              = "Allow Jenkins EC2"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = "sg-0ed4fa7ca57184105"
    }
  }
}

# 🔥 CRITICAL FIX: Give Jenkins ROLE access (not user)
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::333982363626:role/jenkins-eks-role"
  type          = "STANDARD"
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
