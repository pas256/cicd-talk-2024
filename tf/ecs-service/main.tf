# ------------------------------------------------------------------------------
# TODO
# ------------------------------------------------------------------------------

locals {
  # Name of your ECR repository
  repo_name = "my-repo"

  # The image tag to deploy that lives inside your ECR repository
  image = "latest"

  # Set the name of your ECS environment
  environment = {
    short_lowercase_name = "prod"
    human_name           = "Production"
  }

  # ECS Cluster name (must already exist)
  cluster_name = "my-cluster"

  # ECS Service name
  service_name = "my-webapp-prod"

  # ECS Task Execution IAM Role name
  # The role used by the ECS/Fargate agents to manage the task
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  task_execution_role_name = "my-task-execution-role"

  # ECS Task IAM Role name
  # The role your app inside the container can assume and use
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
  task_role_name = "arn:aws:iam::123456789012:my-task-role"

  # VPC subnet IDs
  vpc_subnet_ids = [
    "subnet-1234567890abcdef0",
    "subnet-1234567890abcdef1",
    "subnet-1234567890abcdef2",
  ]

  # VPC security group you want the ECS service to use
  security_group_id = "sg-1234567890abcdef0"

  # Set the port the app will listen on
  server_port = 8081

  # Application Load Balancer (ALB) target group ARN
  alb_target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-target-group/1234567890123456"

  # Name of the container in the task definition
  container_name = "${local.service_name}-${local.environment.short_lowercase_name}"

  # Configuration environment variables (env_vars) and secrets (secrets)
  env_vars = {
    APP_ENV = local.environment.short_lowercase_name == "prod" ? "production" : "development"
  }
  secrets = {
    MY_SECRET = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.environment.short_lowercase_name}/some/secret"
  }
}

# CloudWatch log group for the ECS task
resource "aws_cloudwatch_log_group" "service" {
  name              = "/${local.environment.short_lowercase_name}/ecs/${local.service_name}"
  retention_in_days = 30

  tags = {
    Name        = "${local.service_name} ${local.environment.human_name} Logs"
    Environment = local.environment.human_name
    ManagedBy   = "Terraform"
  }
}

# ECS IAM Execution Role the container will use
resource "aws_iam_role" "execution_role" {
  name = local.task_execution_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })

  inline_policy {
    name = "ecs-task-execution-role"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "WriteLogs"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = [
            "${aws_cloudwatch_log_group.service.arn}:*",
          ]
        },
        {
          Sid    = "DownloadContainerImage"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken",
            "ecr:GetDownloadUrlForLayer",
          ]
          Resource = "*"
        },
        {
          Sid    = "FetchParametersAndSecrets"
          Effect = "Allow"
          Action = [
            "ssm:GetParameters",
            "secretsmanager:GetSecretValue",
            "kms:Decrypt",
          ],
          Resource = [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.environment.short_lowercase_name}/*",
            "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:my_secret_name",
            "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/alias/aws/ssm",
          ]
        },
      ]
    })
  }

  tags = {
    Name        = local.task_execution_role_name
    Environment = local.environment.human_name
    ManagedBy   = "Terraform"
  }
}


# ECS Service to run the task
resource "aws_ecs_service" "service" {
  name                   = "${local.service_name}-${local.environment.short_lowercase_name}"
  cluster                = data.aws_ecs_cluster.cluster.arn
  task_definition        = aws_ecs_task_definition.td.arn
  enable_execute_command = true
  desired_count          = 1
  launch_type            = "FARGATE"
  network_configuration {
    subnets          = local.vpc_subnet_ids
    security_groups  = [local.security_group_id]
    assign_public_ip = true # Or use NATs
  }

  load_balancer {
    target_group_arn = local.alb_target_group_arn
    container_name   = local.container_name
    container_port   = local.server_port
  }

  tags = {
    Name        = "${local.service_name} ${local.environment.human_name}"
    Environment = local.environment.human_name
    ManagedBy   = "Terraform"
  }
}

# Task definition for a basic Ruby on Rails web application
resource "aws_ecs_task_definition" "td" {
  family                   = "${local.service_name}-${local.environment.short_lowercase_name}-family"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = local.task_role_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.repo_name}:${local.image}"
      cpu       = 1024
      memory    = 2048
      essential = true
      linuxParameters = {
        # Set initProcessEnabled to true to avoid the SSM agent child processes becoming orphaned
        initProcessEnabled = true
      }
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = local.server_port
          hostPort      = local.server_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.service.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        # Loop through environment variables
        for key, value in local.env_vars : {
          name  = key
          value = value
        }
      ]
      secrets = [
        # Loop through secrets
        for key, value in local.secrets : {
          name      = key
          valueFrom = value
        }
      ]
    },
  ])

  tags = {
    Name        = "${local.service_name} ${local.environment.human_name} Webapp"
    Environment = local.environment.human_name
    ManagedBy   = "Terraform"
  }
}
