resource "proxmox_vm_qemu" "docker_n1" {
    name = "docker-n1"
    desc = "Kubernetes Node 1"
    vmid = "303"
    target_node = "pve"
    
    agent = 0
    
    clone = "ubuntu-docker-template"
    cores = 4
    sockets = 2
    cpu = "qemu64"
    memory = 16384
    scsihw = "virtio-scsi-pci"

    network {
        bridge = "vmbr0"
        model = "virtio"
        firewall = false
    }

    os_type = "cloud-init"
    ipconfig0 = "ip=10.10.95.230/24,gw=10.10.95.1"
    nameserver = "10.10.95.220"
    ciuser = var.ciuser
    cipassword = var.cipassword
    sshkeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6h3rAVMLxflQ7Ce3z/DbLjvfXcMA4OvTZdBoLBMjPS apexnerd@leviathan"
}