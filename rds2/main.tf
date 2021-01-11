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
    default = "my-tf-test-bczkeadaatrewrewu"
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

resource "aws_s3_bucket_object" "dbsample_directory" {
    bucket = aws_s3_bucket.private.bucket
    acl    = "private"
    key    = "${var.s3_bucket_dbsamples}/"
    source = "/dev/null"

      provisioner "local-exec" {
    command = "upload.sh"
    environment = {
        BucketName = self.bucket
        DirectolyName = self.key
    }
  }

  provisioner "local-exec" {
      when = destroy
    command = "upload_destroy.sh"
    environment = {
        BucketName = self.bucket
        DirectolyName = self.key
    }
  }
}

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

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  availability_zone = "ap-northeast-1a"
  #   multi_az
  # gp2 = general purpose.
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  # free tier db instance
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql8.0"
  
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name

  skip_final_snapshot        = false
  final_snapshot_identifier = "mysql80-final-1"
}

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