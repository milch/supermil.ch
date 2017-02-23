provider "aws" {
    region     = "eu-central-1"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
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
  bucket = "supermil.ch-site"
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
      "Resource":["arn:aws:s3:::supermil.ch-site/*"]
    }
  ]
}
EOF

  website {
    index_document = "index.html"
    error_document = "public/404.html"
  }
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
    minimum_protocol_version = "TLSv1"
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
