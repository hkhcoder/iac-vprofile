module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name    = local.cluster_name
  cluster_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true


  # Allow GitHub Actions IAM identity to access Kubernetes
  access_entries = {

    github_actions = {

      principal_arn = "arn:aws:iam::579275327561:user/final"

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


  eks_managed_node_group_defaults = {

    ami_type = "AL2023_x86_64_STANDARD"

  }


  eks_managed_node_groups = {

    one = {

      name = "node-group-1"

      instance_types = [
        "t3.medium"
      ]

      min_size     = 1
      max_size     = 3
      desired_size = 2

    }


    two = {

      name = "node-group-2"

      instance_types = [
        "t3.medium"
      ]

      min_size     = 1
      max_size     = 2
      desired_size = 1

    }

  }

}