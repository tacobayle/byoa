# Outputs for Terraform

//output "master_K8s_IPs" {
//  value = vsphere_virtual_machine.master.*.default_ip_address
//}

output "workers_K8s_IPs" {
  value = vsphere_virtual_machine.worker.*.default_ip_address
}

//output "destroy_env_vm_VM" {
//  value = vsphere_virtual_machine.destroy_env_vm.default_ip_address
//}

//output "client_VM_IP" {
//  value = vsphere_virtual_machine.client.default_ip_address
//}

output "Avi_controllers" {
  value = vsphere_virtual_machine.controller[0].default_ip_address
}

output "Avi_password" {
  value = var.avi_password
}

output "Destroy_command_all" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -t ubuntu@${vsphere_virtual_machine.destroy_env_vm.default_ip_address} 'cd aviAbsent ; ansible-playbook local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve -var-file=vcenter.json"
  description = "command to destroy the infra"
}

output "Destroy_command_wo_tf" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -t ubuntu@${vsphere_virtual_machine.destroy_env_vm.default_ip_address} './destroyAvi.sh'"
  description = "command to destroy the avi config"
}

output "ako_install_command_to_apply_on_master_node" {
  value = "helm --debug install ako/ako --generate-name --version ${var.vmw.kubernetes.clusters[0].ako.version} -f values.yml --namespace=${var.vmw.kubernetes.clusters[0].ako.namespace} --set avicredentials.username=admin --set avicredentials.password=$avi_password"
}

output "ssh_connect_to_client_VM" {
  value = "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.client.default_ip_address}"
}

output "ssh_connect_to_K8s_cluster1_master_node" {
  value = "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master[0].default_ip_address}"
}

output "ssh_connect_to_K8s_cluster2_master_node" {
  value = "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master[1].default_ip_address}"
}

output "ssh_connect_to_any_vm" {
  value = "ssh -i ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem -o StrictHostKeyChecking=no ubuntu@<VM_IP>"
}