resource "aws_security_group" "this" {
  name        = "rds-sec-group"
  description = "Allow internal and VPN traffic"
  vpc_id      = "${var.sg_vpc}"

  ingress {
    from_port   = "${var.port}"
    to_port     = "${var.port}"
    protocol    = "6"
    cidr_blocks = ["${var.ingress_sg_cidr}"]
  }

  egress {
    from_port   = "${var.port}"
    to_port     = "${var.port}"
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
