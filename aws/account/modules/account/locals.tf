locals {
  name_prefix = join(
    "-",
    [
      var.tags["Namespace"],
      var.tags["Environment"],
      var.tags["Stage"],
    ],
  )
}

