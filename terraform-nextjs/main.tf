# main.tf    ← core resources

# Provider
provider "aws" {
    region = "eu-west-2"
}

# Resources 

# S3 Bucket 
resource "aws_s3_bucket" "website" {
    bucket = "dg-nextjs-s3-bucket"

    tags = {
        Name = "Portfolio Website"
        Environment = "Production"
    }
}

# S3 website bucket 
resource "aws_s3_bucket_website_configuration" "website" {
    bucket = aws_s3_bucket.website.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "index.html"
    }
}

# No ownership controls or bucket ACLs resources as not needed post 04/23

# S3 Bucket Policy 
resource "aws_s3_bucket_policy" "website_policy" {
    bucket = aws_s3_bucket.website.id
    depends_on = [aws_s3_bucket_public_access_block.website]

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # sid to describe what the statement does 
                Sid = "AllowCloudFrontServicePrincipal"
                Effect = "Allow"
                # principal changed from * to cloudfront only
                Principal = {
                  Service = "cloudfront.amazonaws.com"
                }
                Action = "s3:GetObject"
                Resource = "${aws_s3_bucket.website.arn}/*"
                # condition locks access to the specified cloudfront distribution only
                Condition = {
                  StringEquals = {
                    "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
                  }
                }
            }
        ]
    })
    }

resource "aws_s3_bucket_public_access_block" "website" {
    bucket = aws_s3_bucket.website.id
    
    # changed from false to true to fully lock down the bucket 
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

# Origin Access Control better than OAI 
resource "aws_cloudfront_origin_access_control" "website_oac" {
  name = "dg_nextjs_oac"
  description = "Origin Access Control for Next.js CloudFront Distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}


# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    # domain name points to private s3 regional domain instead of public website endpoint 
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-Website"
    # custom origin confi removed and replaced with oac_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website_oac.id
    
  }
  
  enabled             = true
  default_root_object = "index.html"
  
  # to serve content to users
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    # redirect users to https to ensure security over http
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # who can access the content based on geographical location - none means no restriction "whitelist"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # certificate to use for https - default means no custom certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "Portfolio CloudFront"
    Environment = "Production"
  }
}
