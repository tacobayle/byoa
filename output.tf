# Outputs for Terraform

output "master_K8s" {
  value = vsphere_virtual_machine.master.*.default_ip_address
}

output "workers_K8s" {
  value = vsphere_virtual_machine.worker.*.default_ip_address
}

output "jump_VM" {
  value = vsphere_virtual_machine.jump.default_ip_address
}

output "client_VM" {
  value = vsphere_virtual_machine.client.default_ip_address
}

output "Avi_controllers" {
  value = vsphere_virtual_machine.controller.*.default_ip_address
}

output "Avi_password" {
  value = var.avi_password
  description = "avi_password"
}

output "Destroy_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -t ubuntu@${vsphere_virtual_machine.jump.default_ip_address} 'cd aviAbsent ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}

output "ako_install_command" {
  value = "helm --debug install ako/ako --generate-name --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password"
}

output "ssh_connect_to_any_vm" {
  value = "use the following to connect to any VM: ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -o StrictHostKeyChecking=no ubuntu@<VM_IP>"
}