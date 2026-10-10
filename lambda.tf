# Zip the Python code
data "archive_file" "hello" {
  type        = "zip"
  source_file = "${path.module}/lambda/hello.py"
  output_path = "${path.module}/lambda/hello.zip"
}

# Role the Lambda runs as
resource "aws_iam_role" "lambda_exec" {
  name = "kean-hello-world-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Lets the Lambda write its print() output to CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "hello" {
  function_name    = "kean-hello-world"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.12"
  handler          = "hello.lambda_handler"
  filename         = data.archive_file.hello.output_path
  source_code_hash = data.archive_file.hello.output_base64sha256
}

output "lambda_function_name" {
  value = aws_lambda_function.hello.function_name
}