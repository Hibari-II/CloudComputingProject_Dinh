resource "exoscale_compute" "prometheus" {
  zone         = var.zone
  hostname     = "prometheus-server"
  display_name = "prometheus-server"
  template_id  = data.exoscale_compute_template.ubuntu.id
  size         = "micro"
  disk_size    = 10
  key_pair     = exoscale_ssh_keypair.admin.name
  state        = "Running"

  security_group_ids = [exoscale_security_group.sg.id]

  user_data = templatefile("userdata/prometheus.sh", {
    exoscale_key = var.exoscale_key,
	exoscale_secret = var.exoscale_secret,
	exoscale_zone = var.zone,
	exoscale_zone_id = 0,
	exoscale_instancepool_id = exoscale_instance_pool.service.id,
	target_port = 9100
  })
}
