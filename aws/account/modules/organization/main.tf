terraform {
  required_version = "~> 0.11.14"
}

locals {
  name_prefix = "${join("-",
    list(
      var.tags["Namespace"],
      var.tags["Environment"],
      var.tags["Stage"]
    )
  )}"
}
