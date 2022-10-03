#! /usr/bin/bash

zip -j lambda.zip ../lambda_functions/lambda.py 
terraform init
terraform apply -auto-approve