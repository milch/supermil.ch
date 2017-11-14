---
title: "Quick Tip: Using Lambda@Edge with Terraform"
author: "Manu Wallner"
tags: ["terraform", "aws"]
date: 2017-11-14T13:21:13+01:00
---

If you want to learn how to use Lambda@Edge with Hashicorp's [Terraform](https://www.terraform.io), here's how.

<!--more-->

**Note: Your lambda function has to be in the `us-east-1` region! Any other region will result in errors.**

In your Terraform configuration, first add a new IAM role with a policy like this: 

```nix
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
```

It is important that both `lambda.amazonaws.com` and `edgelambda.amazonaws.com` are included in the `Service` list of your policy or it will not work. Next, create your lambda function like this: 

```
resource "aws_lambda_function" "cloudfront_lambda" {
  filename         = "cloudfront_lambda.zip"
  function_name    = "cloudfront_lambda"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "cloudfront_lambda.handler"
  runtime          = "nodejs6.10"
  source_code_hash = "${base64sha256(file("cloudfront_lambda.zip"))}"
  publish          = "true"
}
```

Make sure to modify the `filename`, `handler` and `source_code_hash` to match the files you created. 

Lambda@Edge only supports the `nodejs` runtime, and `nodejs6.10` is the most recent one as of the time of this writing. For this runtime, it is enough to just take your `.js` files and zip them up, then the name of the handler has to be changed to `<name of your JS file>.<exported function>` (i.e., in my `cloudfront_lambda.zip` archive there is a single `cloudfront_lambda.js` file with an exported function that is called `handler`). 

Finally, in your Cloudfront distribution configuration's cache behaviour settings, add the function association: 

```nix
    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = "${aws_lambda_function.cloudfront_lambda.arn}:${aws_lambda_function.cloudfront_lambda.version}"
    }
```

Just change the `event_type` to one of `viewer-request`, `viewer-response`, `origin-request`, `origin-response` as needed, and you are done. 
