provider "aws" {
  region                      = "us-east-1"
  access_key                  = "fake"
  secret_key                  = "fake"
  s3_use_path_style           = true 
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway = "http://host.docker.internal:4566"
    iam        = "http://host.docker.internal:4566"
    dynamodb   = "http://host.docker.internal:4566"
    lambda     = "http://host.docker.internal:4566"
    s3         = "http://host.docker.internal:4566"
  }
}

# # IAM
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<POLICY
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
POLICY
}

# S3 Bucket
resource "aws_s3_bucket" "sample_data_bucket" {
  bucket = "my-bucket"
}

# API Gateway
resource "aws_api_gateway_rest_api" "sample_api" {
  name = "wxchange"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.sample_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.sample_api.id
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.sample_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.sample_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.wxchange_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on = [
    aws_api_gateway_integration.integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.sample_api.id
  stage_name = "test"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.wxchange_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.sample_api.execution_arn}/*/*"
}


resource "aws_lambda_function" "wxchange_lambda" {
  filename      = "lambda.zip"
  function_name = "wxchange_example"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.7"

  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_dynamodb_table" "wxchange-dynamodb-table" {
  name           = "WxChangeSample"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "WeatherParameter"
  range_key      = "CustomerId"

  attribute {
    name = "WeatherParameter"
    type = "S"
  }

  attribute {
    name = "CustomerId"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }
}

