resource "null_resource" "timestamp" {

  provisioner "local-exec" {
    command = "date +%s > time.log"
  }

}