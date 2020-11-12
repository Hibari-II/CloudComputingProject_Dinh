data "exoscale_compute_template" "ubuntu" {
	zone = var.zone
	name = "Linux Ubuntu 20.04 LTS 64-bit"
}

resource "exoscale_instance_pool" "service" {
	zone = var.zone
	name = "instancepool"
	template_id = data.exoscale_compute_template.ubuntu.id
	size = 2
	service_offering = "micro"
	disk_size = 10
	description = "Instance Pool for my webapplication"
	key_pair = "ssh_dinh"

	security_group_ids = [exoscale_security_group.sg.id]

	user_data = file("userdata/loadgenerator.sh")
}
