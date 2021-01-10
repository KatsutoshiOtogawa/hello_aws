terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.23.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}


# db backup 
resource "aws_s3_bucket" "private" {
  bucket = "my-tf-test-buczkeaatrewrewu"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    terraform        = "rds"
    Environment = "Dev"
  }
}

resource "aws_iam_role" "db_admin_role" {
  name = "db-admin-role"

    # principal Service is trusted entry.
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
    tags = {
        terraform        = "rds"
        Environment = "Dev"
    }
}

resource "aws_iam_policy" "policy" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Write*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.private.arn}"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.db_admin_role.name
  # check policy arn aws iam list-policy
  policy_arn = aws_iam_policy.policy.arn
}

# labmda download dbsample
resource "aws_lambda_function" "test_lambda" {

  filename      = "dbsample_download.zip"
  function_name = "loaddbsample"
  # set db admin role
  role          = aws_iam_role.db_admin_role.arn
  handler       = "dbsample_download.py"

  source_code_hash = filebase64sha256("dbsample_download.zip")

  runtime = "python3.8"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.private.bucket
    }
  }
  tags = {
    terraform        = "rds"
    Environment = "Dev"
  }
}

# resource "aws_db_instance" "default" {
#   allocated_storage    = 20
#   availability_zone = "ap-northeast-1a"
#   #   multi_az
#   # gp2 = general purpose.
#   storage_type         = "gp2"
#   engine               = "mysql"
#   engine_version       = "8.0"
#   # free tier db instance
#   instance_class       = "db.t2.micro"
#   name                 = "mydb"
#   username             = "foo"
#   password             = "foobarbaz"
#   parameter_group_name = "default.mysql5.7"

# #   db_subnet_group_name
# }

# resource "aws_s3_bucket" "private" {
#   bucket = "my-tf-test-bucketrewrewuivx"
#   acl    = "private"

#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
# }

# resource "aws_iam_role" "role" {
#   name = "db-admin-role"

#     # principal Service is trusted entry.
#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "sts:AssumeRole",
#             "Principal": {
#             "Service": "lambda.amazonaws.com"
#             },
#             "Effect": "Allow",
#             "Sid": ""
#         }
#     ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "test-attach" {
#   role       = aws_iam_role.role.name
#   # check policy arn aws iam list-policy
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3OutpostsFullAccess"
# }