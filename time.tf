resource "null_resource" "timestamp_start" {
  provisioner "local-exec" {
    command = "date +%s > time_start.log"
  }
}

resource "null_resource" "timestamp_end" {
  depends_on = [null_resource.K8s_sanity_check]
  provisioner "local-exec" {
    command = "date +%s > time_end.log"
  }
}