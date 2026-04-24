output "cluster_name" {
  value = module.eks.cluster_name
}

# ✅ Added: Needed for kubeconfig and debugging
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# ✅ Added: Handy command printed after terraform apply
output "configure_kubectl" {
  description = "Run this to configure kubectl"
  value       = "aws eks update-kubeconfig --region ap-south-1 --name ${module.eks.cluster_name}"
}
