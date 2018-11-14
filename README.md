Libvirt VM
==========

This role configures and creates (or destroys) VMs on a KVM hypervisor.

Requirements
------------

The host should have Virtualization Technology (VT) enabled and should
be preconfigured with libvirt/KVM.

Role Variables
--------------

- `libvirt_vm_default_console_log_dir`: The default directory in which to store
  VM console logs, if a VM-specific log file path is not given. Default is
  "/var/log/libvirt/qemu/".

- `libvirt_vm_image_cache_path`: The directory in which to cache downloaded
  images. Default is "/tmp/".

- `libvirt_vm_engine`: virtualisation engine. If not set, the role will attempt
  to auto-detect the optimal engine to use.

- `libvirt_vm_emulator`: path to emulator binary. If not set, the role will
  attempt to auto-detect the correct emulator to use.

- `libvirt_vm_arch`: CPU architecture, default is `x86_64`.

- `libvirt_vm_uri`: Override the libvirt connection URI. See the 
  [libvirt docs](https://libvirt.org/remote.html) docs for more details.

- `libvirt_vm_virsh_default_env`: Variables contained within this dictionary are
  added to the environment used when executing virsh commands.

- `libvirt_vms`: list of VMs to be created/destroyed. Each one may have the
  following attributes:

    - `state`: set to `present` to create or `absent` to destroy the VM.
      Defaults to `present`.

    - `name`: the name to assign to the VM.

    - `memory_mb`: the memory to assign to the VM, in megabytes.

    - `vcpus`: the number of VCPU cores to assign to the VM.

    - `machine`: Virtual machine type. Default is `None` if
      `libvirt_vm_engine` is `kvm`, otherwise `pc-1.0`.

    - `cpu_mode`: Virtual machine CPU mode. Default is `host-passthrough` if
      `libvirt_vm_engine` is `kvm`, otherwise `host-model`.

    - `volumes`: a list of volumes to attach to the VM.  Each volume is
      defined with the following dict:
        - `name`: Name to associate with the volume being created.
        - `device`: `disk`
        - `format`: options include `raw`, `qcow2`, `vmdk`.  See `man virsh` for the
          full range.  Default is `qcow2`
        - `capacity`: volume capacity (can be suffixed with M,G,T or MB,GB,TB, etc)
        - `image`: (optional) a URL to an image with which the volume is initalised.
        - `pool`: Name or UUID of the storage pool from which the volume should be
          allocated.

    - `interfaces`: a list of network interfaces to attach to the VM.
      Each network interface is defined with the following dict:

        - `type`: The type of the interface. Possible values:

            - `network`: Attaches the interface to a named Libvirt virtual
              network. This is the default value.
            - `direct`: Directly attaches the interface to one of the host's
              physical interfaces, using the `macvtap` driver.
        - `network`: Name of the network to which an interface should be
          attached. Must be specified if and only if the interface `type` is
          `network`.
        - `source`: A dict defining the host interface to which this
          VM interface should be attached. Must be specified if and only if the
          interface `type` is `direct`. Includes the following attributes:

            - `dev`: The name of the host interface to which this VM interface
              should be attached.
            - `mode`: options include `vepa`, `bridge`, `private` and
              `passthrough`. See `man virsh` for more details. Default is
              `vepa`.

    - `console_log_enabled`: if `true`, log console output to a file at the
      path specified by `console_log_path`, **instead of** to a PTY. If
      `false`, direct terminal output to a PTY at serial port 0. Default is
      `false`.

    - `console_log_path`: Path to console log file. Default is
      `{{ libvirt_vm_default_console_log_dir }}/{{ name }}-console.log`.

    - `start`: Whether to immediately start the VM after defining it. Default
      is `true`.

    - `autostart`: Whether to start the VM when the host starts up. Default is
      `true`.


N.B. the following variables are deprecated: `libvirt_vm_state`,
`libvirt_vm_name`, `libvirt_vm_memory_mb`, `libvirt_vm_vcpus`,
`libvirt_vm_engine`, `libvirt_vm_machine`, `libvirt_vm_cpu_mode`,
`libvirt_vm_volumes`, `libvirt_vm_interfaces` and
`libvirt_vm_console_log_path`. If the variable `libvirt_vms` is left unset, its
default value will be a singleton list containing a VM specification using
these deprecated variables.

Dependencies
------------

None

Example Playbook
----------------

    ---
    - name: Create VMs
      hosts: hypervisor
      roles:
        - role: stackhpc.libvirt-vm
          libvirt_vms:
            - state: present
              name: 'vm1'
              memory_mb: 512
              vcpus: 2
              volumes:
                - name: 'data1'
                  device: 'disk'
                  format: 'qcow2'
                  capacity: '400GB'
                  pool: 'my-pool'
              interfaces:
                - network: 'br-datacentre'

            - state: present
              name: 'vm2'
              memory_mb: 1024
              vcpus: 1
              volumes:
                - name: 'data2'
                  device: 'disk'
                  format: 'qcow2'
                  capacity: '200GB'
                  pool: 'my-pool'
              interfaces:
                - network: 'br-datacentre'


Author Information
------------------

- Mark Goddard (<mark@stackhpc.com>)
