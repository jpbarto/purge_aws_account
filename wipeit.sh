#!/bin/sh

set -e

docker build . -t local/wipeit:latest

terraform init
terraform apply -auto-approve
