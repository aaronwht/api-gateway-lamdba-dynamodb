resource "aws_iam_role" "lambda" {
  for_each = local.function
  name     = "${terraform.workspace}-${var.aws_region}-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "logs" {
  for_each = local.function
  name     = "${each.key}-logs"
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "logs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "logs" {
  for_each   = local.function
  policy_arn = aws_iam_policy.logs[each.key].arn
  role       = aws_iam_role.lambda[each.key].name
}

resource "aws_iam_policy" "questions_db" {
  for_each = toset([for s in keys(local.function) : s if length(regexall("question", s)) > 0])
  name     = "${each.key}-questions_db"
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Questions",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "${aws_dynamodb_table.questions.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "questions_db" {
  for_each   = toset([for s in keys(local.function) : s if length(regexall("question", s)) > 0])
  policy_arn = aws_iam_policy.questions_db[each.key].arn
  role       = aws_iam_role.lambda[each.key].name
}
