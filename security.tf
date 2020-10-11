resource "exoscale_security_group" "sg" {
	name = "ip_sg"
	description = "Security Group for instance pool"
}

resource "exoscale_security_group_rule" "ssh" {
	security_group_id = exoscale_security_group.sg.id
	type = "INGRESS"
	protocol = "TCP"
	cidr = "0.0.0.0/0"
	start_port = 22
	end_port = 22
}

resource "exoscale_security_group_rule" "loadGenerator" {
	security_group_id = exoscale_security_group.sg.id
	type = "INGRESS"
	protocol = "TCP"
	cidr = "0.0.0.0/0"
	start_port = 8080
	end_port = 8080
}

