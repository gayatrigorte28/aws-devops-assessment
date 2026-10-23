# Testing and submission checklist

## Local checks (no AWS resources created)
- [ ] `terraform fmt -recursive`
- [ ] `terraform init -backend=false`
- [ ] `terraform validate`
- [ ] GitHub Actions validation workflow passes after push
- [ ] Review `.gitignore`; ensure state files and secrets are not committed

## If an approved AWS deployment is later available
- [ ] Confirm budget and AWS Pricing Calculator estimate first
- [ ] Confirm ACM certificate is issued in the same region as the ALB
- [ ] Confirm target group targets become healthy
- [ ] Open the HTTPS endpoint and verify redirect from HTTP
- [ ] Confirm RDS is private and only accepts MySQL from app security group
- [ ] Confirm S3 public access block and encryption
- [ ] Confirm ALB access logs arrive in the log bucket
- [ ] Confirm Secrets Manager contains generated DB credentials
- [ ] Capture real screenshots and redact account IDs or sensitive details

## Evidence log
Record only results that were actually observed:
- Date/time:
- Terraform version:
- `terraform fmt` result:
- `terraform init -backend=false` result:
- `terraform validate` result:
- GitHub Actions run URL (if available):
- AWS deployment URL (only if actually deployed):
