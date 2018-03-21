Libvirt VM
==========

This role configures an creates (or destroys) a VM on a KVM hypervisor.

Requirements
------------

The host should have Virtualization Technology (VT) enabled and should
be preconfigured with libvirt/KVM.

Role Variables
--------------

`libvirt_vm_state`: set to `present` to create or `absent` to destroy the VM.
Defaults to `present`.

`libvirt_vm_name`: the name to assign to the VM.

`libvirt_vm_memory_mb`: the memory to assign to the VM, in megabytes.

`libvirt_vm_vcpus`: the number of VCPU cores to assign to the VM.

`libvirt_vm_engine`: virtualisation engine. If not set, the role will attempt
to auto-detect the optimal engine to use.

`libvirt_vm_emulator`: path to emulator binary. If not set, the role will
attempt to auto-detect the correct emulator to use.

`libvirt_vm_arch`: CPU architecture, default is `x86_64`.

`libvirt_vm_volumes`: a list of volumes to attach to the VM.  Each volume is
defined with the following dict:
- `name`: Name to associate with the volume being created.
- `device`: `disk` 
- `format`: options include `raw`, `qcow2`, `vmdk`.  See `man virsh` for the
full range.  Default is `qcow2` 
- `capacity`: volume capacity (can be suffixed with M,G,T or MB,GB,TB, etc)
- `image`: (optional) a URL to an image with which the volume is initalised.
- `pool`: Name or UUID of the storage pool from which the volume should be
allocated.

`libvirt_vm_interfaces`: a list of network interfaces to attach to the VM.
Each network interface is defined with the following dict:
- `network`: Name of the network to which an interface should be attached.

`libvirt_vm_image_cache_path`: path to cache downloaded images.

Dependencies
------------

None

Example Playbook
----------------

    ---
    - name: Create a VM
      hosts: hypervisor
      roles:
        - role: stackhpc.libvirt-vm
          libvirt_vm_state: present
          libvirt_vm_name: 'my-vm'
          libvirt_vm_memory_mb: 512
          libvirt_vm_vcpus: 2
          libvirt_vm_volumes:
            - name: 'data'
              device: 'disk'
              format: 'qcow2'
              capacity: '400GB'
              pool: 'my-pool'
          libvirt_vm_interfaces:
            - network: 'br-datacentre'

Author Information
------------------

- Mark Goddard (<mark@stackhpc.com>)
