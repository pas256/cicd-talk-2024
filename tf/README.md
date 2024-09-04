# Terraform code for talk: CI/CD: GitHub Actions to ECS

There is no requirement to use Terraform for this talk. The Terraform code is provided for reference purposes only and is incomplete.

## Modules

### `repo`

Creates an ECR repository with lifecycle management. GitHub Actions will push the Docker image to this repository.

### `cicd-resources`

Creates the OIDC Identity Provider, and an IAM Role with an inline policy that allows GitHub Actions to make AWS API calls.

### `ecs-service`

A partially complete module that shows how to connect the various ECS pieces together. It assumes you already have a VPC and ECS cluster created.

## Usage

Go into each of the directories. Modify the `provider.tf` file with your desired AWS profile and region.

Then you can run:

```bash
terraform init
terraform apply
```

Note: There is no backend defined, so you will need to keep track of the state files yourself.

## Install Terraform

If you don't have Terraform installed, you can use `brew` on macOS:

```bash
brew install terraform
```
