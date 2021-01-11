#!/bin/bash
set -eu

BucketName=$1
DirectolyName=$2

aws s3 rm s3://${BucketName}/${DirectolyName} --recursive

