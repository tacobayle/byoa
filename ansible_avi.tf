resource "null_resource" "ansible_hosts_avi_header_1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  count            = (var.controller.cluster == true ? 3 : 1)
  provisioner "local-exec" {
    command = "echo '        ${vsphere_virtual_machine.controller[count.index].default_ip_address}:' | tee -a hosts_avi "
  }
}


resource "null_resource" "ansible_avi" {
  depends_on = [vsphere_virtual_machine.destroy_env_vm, vsphere_virtual_machine.master, vsphere_virtual_machine.worker, null_resource.ansible_hosts_avi_header_1, null_resource.ansible_bootstrap_cluster]
  connection {
    host = vsphere_virtual_machine.destroy_env_vm.default_ip_address
    type = "ssh"
    agent = false
    user = var.destroy_env_vm.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    source = "hosts_avi"
    destination = "hosts_avi"
  }

  provisioner "file" {
    source = "ansible/aviConfigure"
    destination = "aviConfigure"
  }

  provisioner "file" {
    source = "ansible/aviAbsent"
    destination = "aviAbsent"
  }

  provisioner "remote-exec" {
    inline = [
      "cd aviConfigure",
      "ansible-playbook -i ../hosts_avi local.yml --extra-vars '{\"vcenter\": ${jsonencode(var.vcenter)}, \"vmw\": ${jsonencode(var.vmw)}, \"vsphere_password\": ${jsonencode(var.vsphere_password)}, \"avi_vsphere_server\": ${jsonencode(var.avi_vsphere_server)}, \"vsphere_user\": ${jsonencode(var.vsphere_user)}, \"avi_username\": ${jsonencode(var.avi_username)}, \"avi_password\": ${jsonencode(var.avi_password)}, \"avi_version\": ${split("-", var.controller.version)[0]}, \"controllerPrivateIps\": ${jsonencode(vsphere_virtual_machine.controller.*.default_ip_address)}, \"controller\": ${jsonencode(var.controller)}}'"
    ]
  }
}