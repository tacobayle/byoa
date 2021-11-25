data "template_file" "client_userdata" {
  template = file("${path.module}/userdata/client.userdata")
  vars = {
    pubkey        = chomp(tls_private_key.ssh.public_key_openssh)
    username = var.client["username"]
    netplan_file_path = var.client.netplan_file_path
    vip_ip = "${cidrhost(var.vcenter.vip_network.cidr, var.client.vip_ip)}/${split("/", var.vcenter.vip_network.cidr)[1]}"
    avi_dns_vs = "${cidrhost(var.vcenter.vip_network.cidr, var.vmw.vip_network.vipIpStartPool)}"
  }
}

data "vsphere_virtual_machine" "client" {
  name          = var.client["template_name"]
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "client" {
  name             = var.client.name
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
                      network_id = data.vsphere_network.networkMgt.id
  }

  network_interface {
    network_id = data.vsphere_network.networkVip.id
  }


  num_cpus = var.client["cpu"]
  memory = var.client["memory"]
  wait_for_guest_net_timeout = var.client["wait_for_guest_net_timeout"]
  guest_id = data.vsphere_virtual_machine.client.guest_id
  scsi_type = data.vsphere_virtual_machine.client.scsi_type
  scsi_bus_sharing = data.vsphere_virtual_machine.client.scsi_bus_sharing
  scsi_controller_count = data.vsphere_virtual_machine.client.scsi_controller_scan_count

  disk {
    size             = var.client["disk"]
    label            = "client.lab_vmdk"
    eagerly_scrub    = data.vsphere_virtual_machine.client.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.client.disks.0.thin_provisioned
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.client.id
  }

  vapp {
    properties = {
     hostname    = "client"
     public-keys = chomp(tls_private_key.ssh.public_key_openssh)
     user-data   = base64encode(data.template_file.client_userdata.rendered)
   }
 }

  connection {
    host        = vsphere_virtual_machine.client.default_ip_address
   type        = "ssh"
   agent       = false
   user        = var.client.username
   private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
   inline      = [
     "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
   ]
  }
}


//resource "null_resource" "add_nic_to_client" {
//  depends_on = [null_resource.ansible_avi, null_resource.ansible_bootstrap_cluster]
//
//  provisioner "local-exec" {
//    command = <<-EOT
//      export GOVC_USERNAME=${var.vsphere_username}
//      export GOVC_PASSWORD=${var.vsphere_password}
//      export GOVC_DATACENTER=${var.vcenter.dc}
//      export GOVC_URL=${var.vsphere_server}
//      export GOVC_CLUSTER=${var.vcenter.cluster}
//      export GOVC_INSECURE=true
//      /usr/local/bin/govc vm.network.add -vm "${var.vcenter.folder}-${var.client.name}" -net ${var.vcenter.vip_network.name}
//    EOT
//  }
//}
//
//resource "null_resource" "update_ip_to_client" {
//  depends_on = [null_resource.add_nic_to_client]
//
//  connection {
//    host        = vsphere_virtual_machine.client.default_ip_address
//    type        = "ssh"
//    agent       = false
//    user        = var.client.username
//    private_key = tls_private_key.ssh.private_key_pem
//  }
//
//  provisioner "remote-exec" {
//    inline = [
//      "ifaceFirstName=`ip -o link show | awk -F': ' '{print $2}' | head -2 | tail -1`",
//      "macFirst=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -2 | tail -1`",
//      "ifaceLastName=`ip -o link show | awk -F': ' '{print $2}' | tail -1`",
//      "macLast=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}'| tail -1`",
//      "sudo cp ${var.client.netplan_file_path} ${var.client.netplan_file_path}.old",
//      "echo \"network:\" | sudo tee ${var.client.netplan_file_path}",
//      "echo \"    ethernets:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"        $ifaceFirstName:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            dhcp4: true\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            dhcp4-overrides:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"              use-dns: false\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"        $ifaceLastName:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            dhcp4: false\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            addresses: [${cidrhost(var.vcenter.vip_network.cidr, var.client.vip_ip)}/${split("/", var.vcenter.vip_network.cidr)[1]}]\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            match:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"                macaddress: $macLast\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            set-name: $ifaceLastName\" | sudo tee -a ${var.client.netplan_file_path}",
////      "echo \"            dhcp4-overrides:\" | sudo tee -a ${var.client.netplan_file_path}",
////      "echo \"              use-dns: false\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"            nameservers:\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"              addresses: [${cidrhost(var.vcenter.vip_network.cidr, var.vmw.vip_network.vipIpStartPool)}]\" | sudo tee -a ${var.client.netplan_file_path}",
//      "echo \"    version: 2\" | sudo tee -a ${var.client.netplan_file_path}",
//      "sudo netplan apply"
//    ]
//  }
//}