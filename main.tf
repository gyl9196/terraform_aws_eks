# EKS Terraform module
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "ap-southeast-2" 
}

terraform {
  backend "s3" {
    region  = "ap-southeast-2"
    encrypt = true
  }
}
module "eks" {
  source             = "./modules/eks"
  key_name           = "${var.key_name}"
  cluster-name       = "${var.cluster-name}"
  k8s-version        = "${var.k8s-version}"
  aws-region         = "${var.aws-region}"
  node-instance-type = "${var.node-instance-type}"
  desired-capacity   = "${var.desired-capacity}"
  max-size           = "${var.max-size}"
  min-size           = "${var.min-size}"
  vpc-subnet-cidr    = "${var.vpc-subnet-cidr}"
}
