# AWS Account ID: 627657103820 (dpn-dev-01)
project_name = "dpn"
environment  = "dev"
aws_region   = "eu-west-2"

cluster_name       = "eks-dpn-dev-eu-west-2"
kubernetes_version = "1.33"

vpc_cidr = "10.85.32.0/24"
azs      = ["eu-west-2a", "eu-west-2b"]

subnet_cidrs = {
  tgw    = ["10.85.32.0/28", "10.85.32.16/28"]
  fw     = ["10.85.32.32/28", "10.85.32.48/28"]
  public = ["10.85.32.64/28", "10.85.32.80/28"]
  mgmt   = ["10.85.32.96/28", "10.85.32.112/28"]
  app    = ["10.85.32.128/26", "10.85.32.192/26"]
  data   = ["10.85.32.224/28", "10.85.32.240/28"]
}
