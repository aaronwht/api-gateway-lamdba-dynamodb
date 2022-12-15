locals {
  function = {
    catch-all        = "$default"
    hello-world      = "GET /hello-world"
    home             = "GET /api/home"
    index            = "GET /"
    question         = "POST /api/question"
    questions        = "GET /api/questions"
    questions_delete = "DELETE /api/question"
  }
  bucket_name = replace(terraform.workspace, "_", "-")
}

variable "aws_region" {
  type    = string
  default = "us-west-1"
}
