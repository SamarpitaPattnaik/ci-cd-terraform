provider "aws" {
  region = "ap-south-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "demo-eks-cluster"
  cluster_version = "1.29"

  subnet_ids = ["subnet-xxxx", "subnet-yyyy"]
  vpc_id     = "vpc-xxxx"

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
    }
  }
}
