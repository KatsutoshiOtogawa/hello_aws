#!/bin/bash
set -eu

# BucketName=$1
# DirectolyName=$2

mkdir /tmp/${DirectolyName}
curl -o /tmp/world.sql.gz -L https://downloads.mysql.com/docs/world.sql.gz
gunzip /tmp/world.sql.gz
mv /tmp/world.sql /tmp/${DirectolyName}/

# sync file
# aws s3 sync /tmp/world.sql s3://${BucketName}/
# aws s3 cp /tmp/world.sql s3://${BucketName}/${DirectolyName}

curl -o /tmp/world_x-db.tar.gz -L https://downloads.mysql.com/docs/world_x-db.tar.gz
tar zxvf /tmp/world_x-db.tar.gz -C /tmp/${DirectolyName}/
# aws s3 sync /tmp/world_x-db s3://${BucketName}/${DirectolyName}/world_x-db

curl -o /tmp/sakila-db.tar.gz -L https://downloads.mysql.com/docs/sakila-db.tar.gz
tar zxvf /tmp/sakila-db.tar.gz -C /tmp/${DirectolyName}/
# aws s3 sync /tmp/sakila-db s3://${BucketName}/${DirectolyName}/sakila-db


curl -o /tmp/menagerie-db.tar.gz -L https://downloads.mysql.com/docs/menagerie-db.tar.gz
tar zxvf /tmp/menagerie-db.tar.gz -C /tmp/${DirectolyName}/
# aws s3 sync /tmp/menagerie-db s3://${BucketName}/${DirectolyName}/menagerie-db

# clone
git clone --depth 1 https://github.com/datacharmer/test_db.git /tmp/${DirectolyName}/test_db
# aws s3 sync /tmp/test_db s3://${BucketName}/${DirectolyName}/test_db

# conpact file
# tar czvf /tmp/${DirectolyName}.tar.gz /tmp/${DirectolyName}

zip /tmp/${DirectolyName}.zip /tmp/${DirectolyName}
# remove origine directory
rm -rf /tmp/${DirectolyName}

# remove file
rm -f /tmp/world.sql
rm -rf /tmp/world_x-db*
rm -rf /tmp/sakila-db*
rm -rf /tmp/menagerie-db*
rm -rf /tmp/test_db
