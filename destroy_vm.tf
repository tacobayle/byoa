data "template_file" "destroy_env_vm_userdata" {
  depends_on = [local_file.private_key]
  template = file("${path.module}/userdata/destroy_env_vm.userdata")
  vars = {
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    avisdkVersion = var.destroy_env_vm["avisdkVersion"]
    ansibleVersion = var.ansible["version"]
    vsphere_username  = var.vsphere_username
    vsphere_password = var.vsphere_password
    vsphere_server = var.vsphere_server
    username = var.destroy_env_vm["username"]
    privateKey = "${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem"
  }
}

data "vsphere_virtual_machine" "destroy_env_vm" {
  name          = var.destroy_env_vm["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "destroy_env_vm" {
  name             = var.destroy_env_vm["name"]
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path
  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  num_cpus = var.destroy_env_vm["cpu"]
  memory = var.destroy_env_vm["memory"]
  wait_for_guest_net_timeout = var.destroy_env_vm["wait_for_guest_net_timeout"]
  guest_id = data.vsphere_virtual_machine.destroy_env_vm.guest_id
  scsi_type = data.vsphere_virtual_machine.destroy_env_vm.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.destroy_env_vm.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.destroy_env_vm.scsi_controller_scan_count

  disk {
    size             = var.destroy_env_vm["disk"]
    label            = "destroy_env_vm.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.destroy_env_vm.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.destroy_env_vm.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.destroy_env_vm.id
  }

  vapp {
    properties = {
     hostname    = var.destroy_env_vm["name"]
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = base64encode(data.template_file.destroy_env_vm_userdata.rendered)
   }
 }

  connection {
   host        = vsphere_virtual_machine.destroy_env_vm.default_ip_address
   type        = "ssh"
   agent       = false
   user        = var.destroy_env_vm.username
   private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }

  provisioner "file" {
    source      = "~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem"
    destination = "~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem"
  }

  provisioner "file" {
    source      = "bash/destroyAvi.sh"
    destination = "~/destroyAvi.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/.ssh/${var.ssh_key.private_key_basename}-${var.vcenter.folder}.pem"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x ~/destroyAvi.sh"
    ]
  }

}