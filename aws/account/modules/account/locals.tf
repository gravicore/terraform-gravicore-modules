locals {
  name_prefix = "${join("-",
    list(
      var.tags["Namespace"],
      var.tags["Environment"],
      var.tags["Stage"]
    )
  )}"
}
