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

# set Environment variable TF_VAR_s3_bucket_id.
# use bucket id.
variable "s3_bucket_id" {
    default = "my-tf-test-bczkeadcearccaatwrewu"
}

# db backup 
resource "aws_s3_bucket" "private" {
  bucket = var.s3_bucket_id
#   region = "ap-northeast-1"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    terraform        = "rds"
    Environment = "Dev"
  }
}

resource "aws_iam_role" "folder_action" {
  name = "folder_action"

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
}

resource "aws_iam_role_policy_attachment" "folder_action" {
  role       = aws_iam_role.folder_action.name
  # check policy arn aws iam list-policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "null_resource" "dbdownload" {
    depends_on = [ 
        aws_s3_bucket.private
     ]

  provisioner "local-exec" {
    command = "upload.sh"
    environment = {
        BucketName = aws_s3_bucket.private.bucket
        DirectolyName = var.s3_bucket_dbsamples
    }
  }
}

# labmda download dbsample
resource "aws_lambda_function" "unzip_lambda" {

  filename      = "unzip.zip"
  function_name = "unzip"
  # set db admin role
  role          = aws_iam_role.folder_action.arn
  handler       = "main.py"

  source_code_hash = filebase64sha256("unzip.zip")

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

resource "aws_sqs_queue" "bucket_queue" {
  name = "s3-event-notification-queue"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.private.arn}" }
      }
    }
  ]
}
POLICY
}

# regist sqs notification to bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.private.id

  queue {
    queue_arn     = aws_sqs_queue.bucket_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

# mapping labmda
resource "aws_lambda_event_source_mapping" "unzip_lambda" {
  event_source_arn = aws_sqs_queue.bucket_queue.arn
  function_name    = aws_lambda_function.unzip_lambda.arn
}

resource "aws_s3_bucket_object" "dbsample_directory" {
    depends_on = [ 
        aws_s3_bucket.private
        ,null_resource.dbdownload
     ]
    bucket = aws_s3_bucket.private.bucket
    acl    = "private"
    key    = "${var.s3_bucket_dbsamples}.zip"
    # terraform hasn't yet support aws s3 sync
    source = "/tmp/${var.s3_bucket_dbsamples}.zip"

#       provisioner "local-exec" {
#     command = "upload.sh"
#     environment = {
#         BucketName = self.bucket
#         DirectolyName = self.key
#     }
#   }

#   provisioner "local-exec" {
#       when = destroy
#     command = "upload_destroy.sh"
#     environment = {
#         BucketName = self.bucket
#         DirectolyName = self.key
#     }
#   }
    provisioner "local-exec" {
        command = "upload_destroy.sh"
        environment = {
            DirectolyName = var.s3_bucket_dbsamples
        }
    }
}



# resource "null_resource" "dbdownload_ato" {
#     depends_on = [ 
#         aws_s3_bucket_object.dbsample_directory
#      ]

#   provisioner "local-exec" {
#     command = "upload_destroy.sh"
#     environment = {
#         DirectolyName = var.s3_bucket_dbsamples
#     }
# }

resource "aws_vpc" "main_vpc" {
  # cidr_block       = "10.0.0.0/8"
  cidr_block       = "192.168.0.0/16"
  # cidr_block       = "192.168.1.0/8"
  instance_tenancy = "default"

  tags = {
    Name = "oracle_vpc"
    terraform = "How_to_install_rds"
  }
}

# resource "aws_internet_gateway" "main_gw" {
#   vpc_id = aws_vpc.main_vpc.id

#   tags = {
#     Name = "oracle_gw"
#     terraform = "How_to_install_oracle_in_fedora"
#   }
# }

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1a"
  cidr_block       = "192.168.255.0/28"

  tags = {
    Name = "oracle_subnet"
    terraform = "How_to_install_rds"
  }
}

resource "aws_subnet" "main_subnet2" {
  vpc_id     = aws_vpc.main_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1c"
  cidr_block       = "192.168.255.128/28"

  tags = {
    Name = "oracle_subnet"
    terraform = "How_to_install_rds"
  }
}

resource "aws_subnet" "main_subnet3" {
  vpc_id     = aws_vpc.main_vpc.id
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1d"
  cidr_block       = "192.168.254.128/28"

  tags = {
    Name = "oracle_subnet"
    terraform = "How_to_install_rds"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet_group"
  subnet_ids = [
      aws_subnet.main_subnet.id
      ,aws_subnet.main_subnet2.id
      ,aws_subnet.main_subnet3.id
  ]
}

variable "s3_bucket_dbsamples" {
    default = "dbsamples"
}

# resource "null_resource" "dbdownload" {
#     depends_on = [ 
#         aws_s3_bucket.private
#      ]

#   provisioner "local-exec" {
#     command = "upload.sh"
#     environment = {
#         BucketName = aws_s3_bucket.private.bucket
#         DirectolyName = var.s3_bucket_dbsamples
#     }
#   }

#   provisioner "local-exec" {
#       when = destroy
#     command = "upload_destroy.sh"
#     environment = {
#         BucketName = aws_s3_bucket.private.bucket
#         DirectolyName = var.s3_bucket_dbsamples
#     }
#   }
# }

variable "final_snapshot" {
    default = "mysql80-final-6"
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
#   parameter_group_name = "default.mysql8.0"
  
#   db_subnet_group_name = aws_db_subnet_group.db_subnet.name

#   skip_final_snapshot        = false
#   final_snapshot_identifier = var.final_snapshot
# }

# resource "aws_iam_role" "db_admin_role" {
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
#     tags = {
#         terraform        = "rds"
#         Environment = "Dev"
#     }
# }

# resource "aws_iam_policy" "policy" {
#   name        = "test_policy"
#   path        = "/"
#   description = "My test policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "s3:Write*"
#         ,"s3:List*"
#       ],
#       "Effect": "Allow",
#       "Resource": "${aws_s3_bucket.private.arn}"
#     }
#   ]
# }
# EOF

# }

# resource "aws_iam_role_policy_attachment" "test-attach" {
#   role       = aws_iam_role.db_admin_role.name
#   # check policy arn aws iam list-policy
#   policy_arn = aws_iam_policy.policy.arn
# }

# labmda download dbsample
# resource "aws_lambda_function" "test_lambda" {

#   filename      = "dbsample_download.zip"
#   function_name = "loaddbsample"
#   # set db admin role
#   role          = aws_iam_role.db_admin_role.arn
#   handler       = "dbsample_download.py"

#   source_code_hash = filebase64sha256("dbsample_download.zip")

#   runtime = "python3.8"

#   environment {
#     variables = {
#       BUCKET_NAME = aws_s3_bucket.private.bucket
#     }
#   }
#   tags = {
#     terraform        = "rds"
#     Environment = "Dev"
#   }
# }

