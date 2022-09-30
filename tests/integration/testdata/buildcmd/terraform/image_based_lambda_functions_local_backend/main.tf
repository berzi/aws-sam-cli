provider "aws" {
    region = "us-west-1"
    
    # Make it faster by skipping something
    skip_get_ec2_platforms      = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
}

resource "aws_iam_role" "iam_for_lambda" {
    name = "dummy_iam_role"

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

locals {
    lambda_src_path = "./hello_world"
}

resource "aws_lambda_function" "my_image_function" {
    function_name = "my_image_function"
    role = aws_iam_role.iam_for_lambda.arn
    package_type = "Image"
    handler = null

    image_uri = "some_image_uri"
}

resource "null_resource" "sam_metadata_aws_lambda_function_my_image_function" {
    triggers = {
        resource_name = "aws_lambda_function.my_image_function"
        resource_type = "IMAGE_LAMBDA_FUNCTION"

        docker_context = local.lambda_src_path
        # docker_context_property_path = ""
        docker_file = "Dockerfile"
        docker_build_args = ""
        docker_tag = "latest"
    }
}

module "l1_lambda" {
    source = "./l1_lambda"
    function_name = "my_l1_lambda"
    image_uri = "my_l1_lambda_image_uri"
    l2_function_name = "my_l2_lambda"
    l2_image_uri = "my_l2_lambda_image_uri"
}

resource "null_resource" "sam_metadata_aws_lambda_function_l1_function" {
    triggers = {
        resource_name = "module.l1_lambda.aws_lambda_function.this"
        resource_type = "IMAGE_LAMBDA_FUNCTION"

        docker_context = local.lambda_src_path
        docker_context_property_path = ""
        docker_file = "Dockerfile"
        docker_build_args = ""
        docker_tag = "latest"
    }
}

resource "null_resource" "sam_metadata_aws_lambda_function_l2_function" {
    triggers = {
        resource_name = "module.l1_lambda.module.l2_lambda.aws_lambda_function.this"
        resource_type = "IMAGE_LAMBDA_FUNCTION"

        docker_context = local.lambda_src_path
        docker_context_property_path = ""
        docker_file = "Dockerfile"
        docker_build_args = ""
        docker_tag = "latest"
    }
}