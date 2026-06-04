# DEV Deployment Guide

This codebase now includes a DEV deployment profile.

## Files added

```text
infrastructure/Tofu/environments/dev.tfvars
infrastructure/Tofu/bootstrap/environments/dev.tfvars
infrastructure/Tofu/backends/dev.hcl
.github/workflows/bootstrap-dev.yml
.github/workflows/infrastructure-dev.yml
```

## Local bootstrap

```bash
cd infrastructure/Tofu/bootstrap
tofu init
tofu plan -var-file=environments/dev.tfvars
tofu apply -var-file=environments/dev.tfvars
```

This creates:

```text
S3 bucket:      dpn-tfstate-dev-001
DynamoDB table: dpn-tfstate-lock-dev
```

## Local infrastructure plan

```bash
cd infrastructure/Tofu
tofu init -backend-config=backends/dev.hcl
tofu validate
tofu plan -var-file=environments/dev.tfvars
```

## DEV values to replace before apply

Update:

```text
infrastructure/Tofu/environments/dev.tfvars
```

Required client-specific values:

```hcl
route53_zone_id = "REPLACE_WITH_DEV_ROUTE53_ZONE_ID"
domain_name     = "dpn-dev.example.com"
```

Also confirm:

```hcl
vpc_cidr
azs
subnet_cidrs
db_instance_class
node group sizes
allowed_egress_fqdns
```

## Cost-reduced DEV defaults

The DEV profile reduces cost compared with the PART/PROD profile:

```text
system node group:   1 desired / 1 min / 2 max
workload node group: 1 desired / 1 min / 3 max
RDS:                 db.t4g.medium, 30GB, 7-day backup
```
