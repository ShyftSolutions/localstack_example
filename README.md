# localstack_example
Example of running localstack with dynamodb, lambda, apigateway using terraform.

# Devcontainer
This project uses a docker compose based devcontainer for vs code. The docker-compose.yml file creates a basic localstack container to run in parallel
with a Ubuntu based devcontainer instance that has terraform and awslocal installed on it with the vscode extensions.

# Terraform
The top section of the terraform script located in `tf-build/sample-build.tf` includes some important settings for deploying aws services to your localstack docker container. The service endpoints declared there are only for the services being used in this example, if you added Cognito, you would need to add another endpoint for it. This is what tells terraform to deploy to your localstack instance instead of actually trying to build the resources in the AWS cloud. The included example builds out the following resources:
- S3 bucket called `my-bucket` (_not currently used in this example_)
- API Gateway REST API called `wxchange`
- API Gateaway resource
- API Gateway proxy
- API Gateway integration (to tie it to the lambda function)
- API Gateway deployment (to push all of it to a defined stage)
- Lambda Permissions (so API Gateway can execute it)
- Lambda Function
- DynamoDB Table


# Starting up the stack
The `tf-build` directory contains the sample terraform configuration file and a deploy.sh script. In order to run your localstack environment, after the dev container is running in your terminal navigate to the `tf-build` directory and run the `deploy.sh` script. 

**Important** you must be in the `tf-build` directory as it has a relative path to zip up the `lambda.py` function for uploading to the lambda service upon creation.

```
cd tf-build
bash deploy.sh

...
Lots of output about terraform initializing
...
```

Once terraform is finished creating all of the resources, you should see a "Apply complete!" message. In order to test out your lambda function, you will need to get the id from your rest api that was created. Just a little ways up the output messages you will see several lines related to aws resources that were created in your localstack, you need to find the id for `aws_api_gateway_rest_api.sample_api`

Example output:

```
Plan: 10 to add, 0 to change, 0 to destroy.
aws_iam_role.iam_for_lambda: Creating...
aws_api_gateway_rest_api.sample_api: Creating...
aws_s3_bucket.sample_data_bucket: Creating...
aws_dynamodb_table.wxchange-dynamodb-table: Creating...
aws_api_gateway_rest_api.sample_api: Creation complete after 0s [id=iqrsz5bz1x]
aws_api_gateway_resource.resource: Creating...
aws_api_gateway_resource.resource: Creation complete after 0s [id=wir2rxcn43]
aws_api_gateway_method.proxy: Creating...
aws_api_gateway_method.proxy: Creation complete after 0s [id=agm-iqrsz5bz1x-wir2rxcn43-ANY]
aws_dynamodb_table.wxchange-dynamodb-table: Creation complete after 0s [id=WxChangeSample]
aws_iam_role.iam_for_lambda: Creation complete after 0s [id=iam_for_lambda]
aws_lambda_function.wxchange_lambda: Creating...
aws_s3_bucket.sample_data_bucket: Creation complete after 1s [id=my-bucket]
aws_lambda_function.wxchange_lambda: Creation complete after 5s [id=wxchange_example]
aws_lambda_permission.apigw_lambda: Creating...
aws_api_gateway_integration.integration: Creating...
aws_api_gateway_integration.integration: Creation complete after 0s [id=agi-iqrsz5bz1x-wir2rxcn43-ANY]
aws_api_gateway_deployment.apigw_deployment: Creating...
aws_api_gateway_deployment.apigw_deployment: Creation complete after 0s [id=dvtg7opyu8]
aws_lambda_permission.apigw_lambda: Creation complete after 1s [id=AllowExecutionFromAPIGateway]
```

In the above example, the relevant line is with the id of `iqrsz5bz1x`
> aws_api_gateway_rest_api.sample_api: Creation complete after 0s [id=**iqrsz5bz1x**]

API Gateway uses a convention for accessing all rest routes, and in turn all lambda functions behind them. In a real deployment you would use a DNS service (like AWS Route 53) to hide this path from the users, but for localstack testing you will need to string together the url using the id above. The URL format is

`http://{api-gateway-path}/restapis/{rest-api-id}/{name-of-your-stage}]/_user_request_/{resource}?{query-args}`

In our case using localstack, these variables become:

`api-gateway-path`
This will be the path to your localstack server running in docker on port 4566, in almost all cases it will be `localhost:4566`

`rest-api-id`
This will be the id you retrieve from the console output above, in this case `iqrsz5bz1x`. This will not change if you update your terraform deployment or lambda function, only when you build a new stack from scratch (if you destroy your localstack container or build on a new machine).

`name-of-your-stage`
This is the name you set up for your api gateway stage, in our case this is defined in the terraform configuration file on line 77 and it is set to `test`

snippet from the file
```
resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.sample_api.id
  stage_name = "test"
}
```

`resource`
This is the name of the API Gateway resource you have created. In our case this is defined in the terraform configuration file on line 51 and is set to `resource`

snippet from the file
```
resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.sample_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.sample_api.id
}
```

`query-args`
These will be any optional arguments you want to pass into your REST API, in this example our lamba function is set up to take in `parameter, customer, metadata` arguments

### Fully constructed URL using the above example
http://localhost:4566/restapis/iqrsz5bz1x/test/_user_request_/resource?parameter=Winds&customer=781&metadata=somethingelse

Response:
```
{
Action: "Added Winds for customer 781",
Current_items: "[{"MetaData": "somethingelse", "WeatherParameter": "Winds", "CustomerId": 781}]"
}
```
