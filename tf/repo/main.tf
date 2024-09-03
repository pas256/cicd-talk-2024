# ------------------------------------------------------------------------------
# Create a container repository in ECR
# ------------------------------------------------------------------------------

locals {
  # Set the name of your repository
  repo_name = "my-repo"
}


# The container repository
resource "aws_ecr_repository" "repo" {
  name                 = local.repo_name
  image_tag_mutability = "MUTABLE"
  tags = {
    Name      = local.repo_name
    ManagedBy = "Terraform"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Define lifecycle policy to remove old images based on our tagging strategy
data "aws_ecr_lifecycle_policy_document" "cleanup" {
  rule {
    priority    = 1
    description = "Keep the last 20 main images only"

    selection {
      tag_status      = "tagged"
      tag_prefix_list = ["main."]
      count_type      = "imageCountMoreThan"
      count_number    = 20
    }
  }

  rule {
    priority    = 2
    description = "Remove PR images after 45 days"

    selection {
      tag_status      = "tagged"
      tag_prefix_list = ["pr-"]
      count_number    = 7
      count_unit      = "days"
      count_type      = "sinceImagePushed"
    }
  }

  rule {
    priority    = 3
    description = "Remove anything untagged after 7 days"

    selection {
      tag_status   = "untagged"
      count_number = 7
      count_unit   = "days"
      count_type   = "sinceImagePushed"
    }
  }
}

# Add the lifecycle policy to the repository
resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.repo.name
  policy     = data.aws_ecr_lifecycle_policy_document.cleanup.json
}
