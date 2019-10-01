provider "aws" {
    region     = "us-east-1"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

terraform {
  backend "s3" {
    bucket = "supermil.ch-site-us"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config {
    bucket = "supermil.ch-site-us"
    region = "us-east-1"
    key    = "terraform.tfstate"
  }
}

resource "aws_iam_server_certificate" "lets-encrypt" {
  name_prefix       = "lets-encrypt"
  certificate_body  = "${file("letsencrypt/ssl/supermil.ch/cert.pem")}"
  private_key       = "${file("letsencrypt/ssl/supermil.ch/privkey.pem")}"
  certificate_chain = "${file("letsencrypt/ssl/supermil.ch/chain.pem")}"
  path              = "/cloudfront/letsencrypt/"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "s3-website-bucket" {
  bucket = "supermil.ch-site-us"
  acl = "public-read"

  # The policy is needed because the public-read permissions don't transfer to all object in the bucket
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::supermil.ch-site-us/*"]
    }
  ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "public/404.html"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "cloudfront_lambda" {
  filename         = "cloudfront_lambda.zip"
  function_name    = "cloudfront_lambda"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "cloudfront_lambda.handler"
  runtime          = "nodejs10.x"
  source_code_hash = "${base64sha256(file("cloudfront_lambda.zip"))}"
  publish          = "true"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.s3-website-bucket.website_endpoint}"
    origin_id   = "myS3Origin"
    origin_path = "/public"

    custom_origin_config { 
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  enabled             = true
  comment             = "Cloudfront"
  default_root_object = "index.html"

  aliases = ["supermil.ch"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"
    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

    }

    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = "${aws_lambda_function.cloudfront_lambda.arn}:${aws_lambda_function.cloudfront_lambda.version}"
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    iam_certificate_id = "${aws_iam_server_certificate.lets-encrypt.id}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  logging_config {
    include_cookies = false
    bucket = "${aws_s3_bucket.s3-website-bucket.bucket_domain_name}"
    prefix = "logs/"
  }
}

resource "aws_route53_zone" "site" {
   name = "supermil.ch."
}

resource "aws_route53_record" "site" {
  zone_id = "${aws_route53_zone.site.zone_id}"
  name = "supermil.ch"
  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.s3_distribution.hosted_zone_id}"
    evaluate_target_health = true
  }
}
