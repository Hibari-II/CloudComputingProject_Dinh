# Defining the OS for my instances
data "exoscale_compute_template" "ubuntu" {
	zone = var.zone
	name = "Linux Ubuntu 20.04 LTS 64-bit"
}


# Creating the Instance Pool for my webservice
resource "exoscale_instance_pool" "service" {
	zone = var.zone
	name = "instancepool"
	template_id = data.exoscale_compute_template.ubuntu.id
	size = 2
	service_offering = "micro"
	disk_size = 10
	description = "Instance Pool for my webapplication"
	key_pair = exoscale_ssh_keypair.admin.name

	security_group_ids = [exoscale_security_group.sg.id]

	user_data = file("userdata/loadgenerator.sh")
}


# Creating the Monitoring Resource
resource "exoscale_compute" "monitoring" {
  zone         = var.zone
  hostname     = "monitoring-server"
  display_name = "monitoring-server"
  template_id  = data.exoscale_compute_template.ubuntu.id
  size         = "micro"
  disk_size    = 10
  key_pair     = exoscale_ssh_keypair.admin.name
  state        = "Running"

  security_group_ids = [exoscale_security_group.sg.id]

  user_data = templatefile("userdata/monitoring.sh", {
    exoscale_key = var.exoscale_key,
	exoscale_secret = var.exoscale_secret,
	exoscale_zone = var.zone,
	exoscale_zone_id = 0,
	exoscale_instancepool_id = exoscale_instance_pool.service.id,
	target_port = 9100,
    listen_port = 8090,
	grafana_prometheus_datasource = file("userdata/grafana_configs/prometheus_datasource.yaml"),
	grafana_cpu_dashboard = file("userdata/grafana_configs/cpu_dashboard.yaml"),
	grafana_upscale_notifier = file("userdata/grafana_configs/notification_upscale.yaml"),
	grafana_downscale_notifier = file("userdata/grafana_configs/notification_downscale.yaml"),
	grafana_cpu_panels = file("userdata/grafana_configs/cpu_panels.json")
  })
}
