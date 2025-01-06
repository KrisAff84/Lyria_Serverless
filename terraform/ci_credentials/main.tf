/*
Creates necessary credentials for CI/CD pipeline:
- IAM user
- IAM policy
- IAM user policy attachment
- IAM access key
*/

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
resource "aws_iam_user" "lyria_ci" {
  name = "lyria_ci"
}

resource "aws_iam_policy" "lyria_ci_policy" {
  name        = "lyria_ci_policy"
  description = "Provides necessary permissions for CI/CD pipeline to upload objects and invalidate CloudFront Cache"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowS3PutObject",
        "Effect" : "Allow",
        "Action" : "s3:PutObject",
        "Resource" : [
          "${data.aws_s3_bucket.dev.arn}/*",
          "${data.aws_s3_bucket.prod.arn}/*"
        ]
      },
      {
        "Sid" : "CreateCloudFrontInvalidation",
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        "Resource" : data.aws_cloudfront_distribution.static_files.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "lyria_ci" {
  user       = aws_iam_user.lyria_ci.name
  policy_arn = aws_iam_policy.lyria_ci_policy.arn
}

resource "aws_iam_access_key" "lyria_ci" {
  user = aws_iam_user.lyria_ci.name
}

resource "local_file" "access_key" {
  filename = "access_key.txt"
  content = jsonencode({
    "access_key_id" : "${aws_iam_access_key.lyria_ci.id}",
    "secret_access_key" : "${aws_iam_access_key.lyria_ci.secret}"
  })
  file_permission = "0600"
}