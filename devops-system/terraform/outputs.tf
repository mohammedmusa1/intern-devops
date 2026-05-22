output "setup_instructions" {
  value = <<EOF

==================================================
🚀 DEPLOYMENT COMPLETED!
==================================================

It may take 10-15 minutes for all services to start.
If a page isn't loading, please wait a few more minutes.

--------------------------------------------------
🔑 SSH ACCESS
--------------------------------------------------
First, secure your private key:
  chmod 400 devops-key.pem

Then SSH into the server:
  ssh -i devops-key.pem ubuntu@${aws_eip.devops_eip.public_ip}

--------------------------------------------------
🌐 SERVICE URLS & CREDENTIALS
--------------------------------------------------
Jenkins URL     : http://${aws_eip.devops_eip.public_ip}:30080
Jenkins Login   : admin / admin

Grafana URL     : http://${aws_eip.devops_eip.public_ip}:30082
Grafana Login   : admin / admin

ArgoCD URL      : http://${aws_eip.devops_eip.public_ip}:30081
ArgoCD Username : admin
ArgoCD Password : To get the initial password, run this command:
  ssh -i devops-key.pem ubuntu@${aws_eip.devops_eip.public_ip} "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"

Prometheus URL  : http://${aws_eip.devops_eip.public_ip}:30090
Application     : http://${aws_eip.devops_eip.public_ip}:30000

==================================================
EOF
  description = "Setup Instructions and Credentials"
}

output "public_ip" {
  value       = aws_eip.devops_eip.public_ip
  description = "Public IP of the DevOps Server"
}
