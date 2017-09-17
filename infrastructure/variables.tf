variable "aws_access_key" {}
variable "aws_secret_key" {}

output "cloudfront-dns" {
  value = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "s3-bucket" {
  value = "${aws_s3_bucket.s3-website-bucket.id}.s3.amazonaws.com"
}

output "s3-bucket-name" {
  value = "${aws_s3_bucket.s3-website-bucket.id}"
}

output "site" {
  value = "${aws_route53_record.site.fqdn}"
}

output "distribution-id" {
  value = "${aws_cloudfront_distribution.s3_distribution.id}"
}
