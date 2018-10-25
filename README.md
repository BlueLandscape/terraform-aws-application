terraform-django-application
============================

This module is intended to create a generic way of managing infrastructure for
your django application on AWS.

It is opinionated, and it's intended to setup your application infrastructure
in the best and fastest possible way concerning default standards.

In short it wil completely setup your application with:

* Virtual Private Cloud
* Internal DNS
* Private S3 bucket for container registry data
* Private ECR Docker repository
* ECS cluster, launch configuration and autoscaling group
* RDS cluster
* ElastiCache cluster
* ELB to distribute requests across the EC2 instances

General setup and ideas are copied from https://github.com/dpetzold/terraform-django-ecs.

Quickstart
----------

We'll assume you've installed terraform. If not please refer to the terraform
site for instructions.

Start within the root of your project.
We're gonna make a terraform folder and clone this module in it.

```bash
mkdir terraform
cd terraform
git clone git@github.com:BlueLandscape/terraform-django-application.git
```

Create a main.tf file in the root containing the minimal setup.

```bash
# Store terraform state on S3 bucket
terraform {
  backend "s3" {
    region  = "eu-west-1"
    bucket  = "<YOUR BUCKET>"
    key     = "trss/<PROJECT NAME>.tfstate"
    encrypt = true
  }
}

# Load module
module "terraform-django-application" {
  source = "./terraform-django-application"
}
```

You should create a terraform.tfvars or set environment variables to override
some basic variables.

project_name
  Project name, using hyphens and lowercase characters

Initialize the terraform.

```bash
terraform init
```

Create the infrastructure

```bash
terraform apply
```








