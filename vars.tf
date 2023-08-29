## Variable declaration file for tf deployment

# Cloud-Init Username
variable "ciuser" {
    type = string
}

# Cloud-Init User Password
variable "cipassword" {
    type = string
    sensitive = true
}