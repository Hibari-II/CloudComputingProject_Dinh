resource "exoscale_nlb" "service" {
  name        = "nlb_service"
  description = "The Network Load Balancer for balancing my life & my service"
  zone        = var.zone
}

resource "exoscale_nlb_service" "service" {
  zone             = exoscale_nlb.service.zone
  name             = "service-http"
  description      = "Service over HTTP"
  nlb_id           = exoscale_nlb.service.id
  instance_pool_id = exoscale_instance_pool.service.id
  protocol       = "tcp"
  port           = 80
  target_port    = 8080
  strategy       = "round-robin"

  healthcheck {
    mode     = "http"
    port     = 8080
    uri      = "/health"
    interval = 5
    timeout  = 3
    retries  = 1
  }
}
