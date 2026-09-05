# state.tf       ← state management (remote state, locking) where the state will be saved to 

# S3 bucket with use_lockfile = true for state locking - dynamodb_table no longer best 

terraform {
    backend "s3"{
        bucket = "dg-nextjs-terraform-state"
        key = "global/s3/terraform.tfstate"
        region = "eu-west-2"
        # dynamodb_table = "s3-tf-table"
            # has been depreacted since v.10, now use_lockfile for native handling 
        use_lockfile = true 
        encrypt = true
    }
}