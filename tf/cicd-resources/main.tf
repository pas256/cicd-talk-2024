# ------------------------------------------------------------------------------
# The policy to update the ECS task definitions and services
# ------------------------------------------------------------------------------

# Get current account ID
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id

  # Set the name of your GitHub repo in the format "owner/repo"
  github_repo = "pas256/cicd-talk-2024"

  # ECS Cluster name
  cluster_name = "my-cluster"

  # ECS Service name
  service_name = "my-webapp-prod"

  # ECS Task Execution IAM Role name
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  task_execution_role_name = "my-ecs-task-execution-role"

  # ECS Task IAM Role name
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  task_role_name = "my-task-role"
}


# Create policy to update the ECS task definition and service
resource "aws_iam_policy" "update_service_policy" {
  name        = "update-service-ensorcell-webapp-prod"
  description = "Allows updating the ECS task definition and service"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageTaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
        ]
        Resource = "*"
      },
      {
        Sid    = "PassRolesInTaskDefinition",
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          # The task execution role
          "arn:aws:iam::${local.account_id}:role/${local.task_execution_role_name}",
          # The task role
          "arn:aws:iam::${local.account_id}:role/${local.task_role_name}",
        ]
      },
      {
        Sid    = "DeployService",
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource = [
          "arn:aws:ecs:${local.region}:${local.account_id}:service/${local.cluster_name}/${local.service_name}",
          # Add additional ECS services here
        ]
      }
    ]
  })
}


# GitHub OIDC permissions to push images to ECR
module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 2.2"

  create_oidc_provider = true
  create_oidc_role     = true
  # repositories         = ["pas256/ensorcell:ref:refs/heads/main"]
  # Use the following if you want to deploy PRs as well as the main branch
  repositories = [local.github_repo]
  oidc_role_attach_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    aws_iam_policy.update_service_policy.arn,
  ]

  tags = {
    ManagedBy = "Terraform"
  }
}
