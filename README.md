# Code for talk: CI/CD: GitHub Actions to ECS

## Slides

- [CI/CD: GitHub Actions to ECS](https://answersforaws.com/slides)

## Code

There are 3 main sections in this repository:

- [App](#app)
- [Infrastructure](#infrastructure)
- [GitHub Actions](#github-actions)

### App

For the purpose of demonstration, we have a basic web application (written in Go) that serves up a static HTML page. The Dockerfile is used by GitHub Actions to build the image and push it to ECR.

See the [app](app) directory for more details.

### Infrastructure

The AWS infrastructure is defined using Terraform. There are 3 components:

- [repo](tf/repo): Creates an ECR repository with lifecycle management. GitHub Actions will push the Docker image to this repository.
- [cicd-resources](tf/cicd-resources): Creates an IAM policy and role that allows GitHub Actions to make AWS API calls (this is the OIDC part)
- [ecs-service](tf/ecs-service): Shows how to connect the various ECS pieces together. It assumes you already have a VPC and ECS cluster created.

See the [tf](tf) directory for more details.

### GitHub Actions

The GitHub Actions workflow is defined in [.github/workflows/ci.yml](.github/workflows/ci.yml). It is triggered on every push to the `main` branch.

The workflow consists of multiple jobs:

- `test`: Runs the application tests
- `lint`: Lints and validates the Terraform code
- `make_image`: Builds, tags & pushes the app's image to ECR
- `deploy`: Deploys the app to ECS Fargate

This workflow was extracted from a real-world project ([Ensorcell](https://ensorcell.co)), so it will not work out of the box for you and does not have the required permissions to work in this repository. You will see the failure to access the AWS account right here:

https://github.com/pas256/cicd-talk-2024/actions/runs/10695330006/job/29648591008

## License

This library is licensed under the Apache 2.0 License, so use this as you wish.

## Questions

If you have any questions or suggestions, feel free to open a GitHub Issue.
