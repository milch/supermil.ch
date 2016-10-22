provider "aws" {
 	region     = "eu-central-1"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

resource "aws_s3_bucket" "s3-website-bucket" {
  bucket = "supermil.ch-site"
  acl = "public-read"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.s3-website-bucket.id}.s3.amazonaws.com"
    origin_id   = "myS3Origin"

    s3_origin_config { 
      origin_access_identity = ""
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

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
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
    cloudfront_default_certificate = true
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
