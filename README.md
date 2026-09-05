# Next.js Portfolio Website on AWS with Terraform

A static Next.js portfolio website deployed to AWS using Terraform, following current AWS security best practices.

## Architecture

```
Browser → CloudFront (HTTPS) → OAC → S3 (Private)
```

- **Next.js** — static site exported as HTML/CSS/JS files
- **S3** — private bucket storing the static files, not publicly accessible
- **CloudFront** — CDN serving the site globally over HTTPS
- **OAC (Origin Access Control)** — secures the connection between CloudFront and S3

## AWS Security Best Practices Applied

- S3 bucket is fully private — all public access block flags set to `true`
- OAC used instead of legacy OAI (deprecated August 2022) for CloudFront to S3 access
- Bucket policy restricts access to the specific CloudFront distribution only via `AWS:SourceArn` condition
- HTTPS enforced via `redirect-to-https` viewer protocol policy
- Terraform state encrypted at rest with native S3 state locking (`use_lockfile = true`) — DynamoDB state locking deprecated in Terraform AWS provider v5.x
- No bucket ACLs or ownership controls — not required post April 2023 as AWS disabled ACLs by default on new buckets

## Project Structure

```
Terraform-next.js/
├── nextjs-blog/          ← Next.js application
│   ├── pages/
│   ├── public/
│   ├── styles/
│   ├── next.config.js    ← output: 'export' for static generation
│   └── package.json
└── terraform-nextjs/     ← Terraform infrastructure
    ├── main.tf           ← core resources (S3, CloudFront, OAC)
    ├── state.tf          ← remote state configuration
    ├── outputs.tf        ← CloudFront URL output
    ├── backend.tf        ← backend configuration
    └── .terraform.lock.hcl
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- [Node.js](https://nodejs.org) >= 18
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- AWS account with appropriate permissions

## Deployment

### 1. Create the Terraform state bucket manually
```bash
aws s3api create-bucket --bucket <your-state-bucket-name> --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
aws s3api put-bucket-versioning --bucket <your-state-bucket-name> --versioning-configuration Status=Enabled
```

### 2. Update state.tf with your state bucket name
```hcl
bucket = "<your-state-bucket-name>"
```

### 3. Deploy the infrastructure
```bash
cd terraform-nextjs
terraform init
terraform plan
terraform apply
```

### 4. Build and upload the Next.js site
```bash
cd ../nextjs-blog
npm install
npm run build
aws s3 sync out/ s3://<your-s3-bucket-name>
```

### 5. Access the site
The CloudFront URL is output after `terraform apply`:
```bash
terraform output cloudfront_url
```

## Teardown

Empty the S3 buckets first, then destroy the infrastructure:
```bash
aws s3 rm s3://<your-s3-bucket-name> --recursive
aws s3 rm s3://<your-state-bucket-name> --recursive
terraform destroy
```

## Technologies Used

- [Next.js](https://nextjs.org/)
- [Terraform](https://www.terraform.io/)
- [AWS S3](https://aws.amazon.com/s3/)
- [AWS CloudFront](https://aws.amazon.com/cloudfront/)
