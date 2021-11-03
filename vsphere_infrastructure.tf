data "vsphere_datacenter" "dc" {
  name = var.vcenter.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMgt" {
  name = var.vcenter.management_network.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkMaster" {
  name = var.vcenter.k8s_network.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "networkWorker" {
  name = var.vcenter.k8s_network.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_folder" "folder" {
  path          = var.vcenter.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

