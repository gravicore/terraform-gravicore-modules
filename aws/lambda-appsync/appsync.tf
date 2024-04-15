
resource "aws_appsync_graphql_api" "example" {
  authentication_type = "AWS_IAM"
  name                = "example"

  schema = <<EOF
schema {
    query: Query
}
type Query {
  test: Int
}
EOF
}
