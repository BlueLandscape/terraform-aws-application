terraform-aws-application
=========================

This module is intended to create a generic way of application deployment on
aws based on containerized applications.

It is opinionated, and it's intended to setup your application infrastructure
in the best and fastest possible way concerning default standards.

This project is currently in development phase. Contributions are welcome.

In short it wil completely setup your application with:

* Virtual Private Cloud
* Internal DNS
* External DNS
* Cloudwatch log group
* Private S3 bucket for static files
* CloudFront distribution for static files
* Private ECR Docker repository
* ECS cluster, launch configuration
* RDS
* ElastiCache
* ELB to distribute requests across the EC2 instances

Quickstart
----------

We'll assume you've installed terraform. If not please refer to the terraform
site for instructions.

Start within the root of your project.
We're gonna make a terraform folder and clone this module in it.

```bash
mkdir terraform
cd terraform
git clone git@github.com:BlueLandscape/terraform-aws-application.git
```

Create a main.tf file in the root containing the minimal setup.

```bash
variable "project_name" {}
variable "database_password" {}
variable "app_image" {}
variable "domain_name" {}
variable "environment" {}
variable "google_site_verification" {}
variable aws_access_key_id {}
variable aws_secret_access_key {}
variable application_debug {}

module "terraform-aws-application" {
  source = "./terraform-aws-application"
  project_name = "${var.project_name}"
  database_password = "${var.database_password}"
  app_image = "${var.app_image}"
  domain_name = "${var.domain_name}"
  environment = "${var.environment}"
  google_site_verification = "${var.google_site_verification}"
  aws_access_key_id = "${var.aws_access_key_id}"
  aws_secret_access_key = "${var.aws_secret_access_key}"
  application_debug = "{$var.application_debug}"
}

# Place you project specific requirements here

```

You should create a terraform.tfvars or set environment variables to override
some basic variables.

Initialize the terraform.

```bash
terraform init
```

Create the infrastructure

```bash
terraform apply
```








