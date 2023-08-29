resource "proxmox_vm_qemu" "teleport" {
    name = "teleport"
    desc = "teleport server"
    vmid = "302"
    target_node = "pve"
    
    agent = 0
    
    clone = "ubuntu-docker-template"
    cores = 4
    sockets = 2
    cpu = "qemu64"
    memory = 8192
    scsihw = "virtio-scsi-pci"

    network {
        bridge = "vmbr0"
        model = "virtio"
        firewall = false
    }

    os_type = "cloud-init"
    ipconfig0 = "ip=10.10.95.229/24,gw=10.10.95.1"
    nameserver = "10.10.95.220"
    ciuser = var.ciuser
    cipassword = var.cipassword
    sshkeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6h3rAVMLxflQ7Ce3z/DbLjvfXcMA4OvTZdBoLBMjPS apexnerd@leviathan"
}
