# ------------------------------------------------------------------------------
# ECS Service Module - Resource lookups
# ------------------------------------------------------------------------------

# Look up what region this is running in
data "aws_region" "current" {}

# Look up the AWS Account ID
data "aws_caller_identity" "current" {}

# Look up the ECS cluster
data "aws_ecs_cluster" "cluster" {
  cluster_name = local.cluster_name
}
