data "archive_file" "lambda" {
  for_each    = toset(["api", "client"])
  type        = "zip"
  source_dir  = "${path.module}/${each.key}"
  output_path = "${path.module}/zip/${each.key}.zip"
}

resource "aws_s3_object" "lambda" {
  for_each = toset(["api", "client"])
  bucket   = aws_s3_bucket.lambda.id
  key      = "${each.key}.zip"
  source   = data.archive_file.lambda[each.key].output_path
  etag     = filemd5(data.archive_file.lambda[each.key].output_path)
}

resource "aws_lambda_function" "lambda" {
  for_each         = local.function
  function_name    = "${terraform.workspace}-${each.key}"
  s3_bucket        = aws_s3_bucket.lambda.id
  s3_key           = length(regexall("/api/", each.value)) > 0 ? aws_s3_object.lambda["api"].key : aws_s3_object.lambda["client"].key
  runtime          = "nodejs12.x"
  handler          = each.key == "questions_delete" ? replace(each.key, "_", ".") : "${each.key}.handler"
  source_code_hash = length(regexall("/api/", each.value)) > 0 ? data.archive_file.lambda["api"].output_base64sha256 : data.archive_file.lambda["client"].output_base64sha256
  role             = aws_iam_role.lambda[each.key].arn
}

resource "aws_lambda_permission" "lambda" {
  for_each      = local.function
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
