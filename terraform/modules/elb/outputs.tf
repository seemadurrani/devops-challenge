output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = kubernetes_service.example_app.status[0].load_balancer[0].ingress[0].hostname
}
