module "flow_log_destination" {
  source         = "./central-logging-agent-destination"
  enabled        = "${var.enabled}"
  log_type       = "flow-logs"
  filter_pattern = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}
