module "flow_log_destination" {
  source            = "./central-logging-agent-destination"
  namespace         = "${var.namespace}"
  environment       = "${var.environment}"
  stage             = "${var.stage}"
  enabled           = "${var.enabled}"
  master_account_id = "${var.master_account_id}"
  account_id        = "${var.account_id}"
  repository        = "${var.repository}"
  log_type          = "flow-logs"
  filter_pattern    = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action, flowlogstatus]"
}
