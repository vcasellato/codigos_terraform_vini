provider "aws" {
   region = "us-east-1"
}

resource "aws_dynamodb_table" "ddbtable" {
  name             = "Itau_teste"
  hash_key         = "tweet_id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "tweet_id"
    type = "N"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.role_for_LDC.id

  policy = file("policy.json")
}


resource "aws_iam_role" "role_for_LDC" {
  name = "myrole"

  assume_role_policy = file("assume_role_policy.json")

}

resource "aws_lambda_function" "myLambda" {

  function_name = "Itau_Done"
  s3_bucket     = "terraform-itau"
  s3_key        = "site-packages1234.zip"
  role          = aws_iam_role.role_for_LDC.arn
  handler       = "twitter.handler"
  runtime       = "python3.8"
  timeout       = "512"

  
}


resource "aws_cloudwatch_event_rule" "every_five_minutes" {
    name = "every-five-minutes"
    description = "Fires every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
    rule = "${aws_cloudwatch_event_rule.every_five_minutes.name}"
    target_id = "myLambda"
    arn = "${aws_lambda_function.myLambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.myLambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_five_minutes.arn}"
}
