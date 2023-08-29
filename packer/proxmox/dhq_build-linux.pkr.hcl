packer {
    required_plugins {
      proxmox = {
        version = ">= 1.1.3"
        source  = "github.com/hashicorp/proxmox"
      }
    }
  }
 
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-sysforge-template" {

    # * Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # ? (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # * VM General Settings
    # ! This needs to match the name of the proxmox node the template will be on
    node = "pve"
    # ! VM ID needs to be unique
    vm_id = "501"

    vm_name = "ubuntu-sysforge-template"
    template_description = "Ubuntu Server jammy Image preconfigured with docker"

    # * VM OS Settings
    # ? This optional way specifys an iso file on proxmox
    iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
    
    # ? This Will download the iso file every time and check it against the checksum
    #iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
    #iso_checksum = "84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
    #iso_storage_pool = "local"
    unmount_iso = true

    # * VM System Settings
    qemu_agent = true

    # * VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"
    disks {
        disk_size = "128G"
        format = "raw"
        storage_pool = "vmd2"
        type = "virtio"
    }

    # * VM CPU Settings
    cores = "4"
    sockets = "2"
    
    # * VM Memory Settings
    memory = "65536" 

    # * VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "vmd2"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "0.0.0.0"  # set this to your ip 
    http_port_min = 8802
    http_port_max = 8802

    ssh_username = "apexnerd"

    # (Option 1) Add your Password here
    ssh_password = "cTWhUj_Thh8-.qcG!AA9"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/id_ubuntu-sysforge-lev"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-sysforge-template"
    sources = ["source.proxmox-iso.ubuntu-sysforge-template"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        # * The source is relative to the directory where the packer command is being ran from
        source = "./files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
    # Add additional provisioning scripts here
        provisioner "shell" {
        inline = [ 
            "sudo apt-get update -y",
            "sudo apt-get dist-upgrade -y",
            "sudo apt-get install -y vim net-tools",
            "mkdir ~/sysforge",
            "mkdir ~/sysforge/terraform/",
            "mkdir ~/sysforge/terraform/install",
            "mkdir ~/sysforge/ansible",
            "cd ~/sysforge/terraform/install",
            "sudo apt update -y && sudo apt-get install -y gnupg software-properties-common",
            "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg",
            "gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint",
            "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main | sudo tee /etc/apt/sources.list.d/hashicorp.list'",
            "sudo apt update -y",
            "sudo apt-get install terraform -y",
            "sudo apt install pipx -y",
            "pipx install --include-deps ansible",
            "pipx upgrade ansible"
            ]
    }
}

source "proxmox-iso" "ubuntu-docker-template" {

    # * Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # ? (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # * VM General Settings
    # ! This needs to match the name of the proxmox node the template will be on
    node = "pve"
    # ! VM ID needs to be unique
    vm_id = "502"

    vm_name = "ubuntu-docker-template"
    template_description = "Ubuntu Server Template with Docker"

    # * VM OS Settings
    # ? This optional way specifys an iso file on proxmox
    iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
    
    # ? This Will download the iso file every time and check it against the checksum
    #iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
    #iso_checksum = "84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
    #iso_storage_pool = "local"
    #unmount_iso = true

    # * VM System Settings
    qemu_agent = true

    # * VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"
    disks {
        disk_size = "128G"
        format = "raw"
        storage_pool = "vmd2"
        type = "virtio"
    }

    # * VM CPU Settings
    cores = "4"
    
    # * VM Memory Settings
    memory = "16384" 

    # * VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "vmd2"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "0.0.0.0"  # set this to your ip 
    http_port_min = 8803
    http_port_max = 8803

    ssh_username = "apexnerd"

    # (Option 1) Add your Password here
    ssh_password = "cTWhUj_Thh8-.qcG!AA9"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/id_ubuntu-docker-lev"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-docker-template"
    sources = ["source.proxmox-iso.ubuntu-docker-template"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        # * The source is relative to the directory where the packer command is being ran from
        source = "./files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
    provisioner "shell" {
        inline = [
        "sudo apt-get update -y",
        "sudo apt-get dist-upgrade -y",
        "sudo apt-get install -y vim net-tools"
        ]
    }
    # Add additional provisioning scripts here
        provisioner "shell" {
        inline = [ 
            "sudo apt-get install -y curl ca-certificates gnupg lsb-release",
            "sudo apt-get update -y",
            "sudo curl -sSL https://get.docker.com | bash" ,
            "sudo usermod -aG docker $(whoami)",
            "sudo apt-get install -y docker-compose"
            ]
    }
}