#### Localization ####
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i keyboard-configuration/xkb-layout string us
d-i keyboard-configuration/xkb-model string pc105

#### Networking ####
d-i netcfg/choose_interface select NETWORK_INTERFACE
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string IP_ADDRESS
d-i netcfg/get_netmask string NETMASK
d-i netcfg/get_gateway string GATEWAY
d-i netcfg/get_nameservers string NAMESERVER
d-i netcfg/get_hostname string HOSTNAME
d-i netcfg/get_domain string localdomain
d-i netcfg/hostname string HOSTNAME

#d-i netcfg/choose_interface select auto
#d-i netcfg/dhcp_timeout string 60

#### Mirror Selection ####
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

#### Clock & Time Zone ####
d-i time/zone string UTC
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string 0.debian.pool.ntp.org

#### Partitioning ####
d-i partman-auto/disk string /dev/vda
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto-lvm/guided_size string max
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

#### User Creation ####
d-i passwd/root-login boolean false
d-i passwd/user-fullname string FULL_NAME
d-i passwd/username string USERNAME
d-i passwd/user-password password USERNAME
d-i passwd/user-password-again password USERNAME
d-i user-setup/allow-password-root boolean false
d-i user-setup/encrypt-home boolean false

d-i apt/cdrom/set-first boolean false
d-i apt/cdrom/set-next boolean false
d-i apt/cdrom/set-failed boolean false

tasksel tasksel/first multiselect standard

#### Package Selection ####
d-i pkgsel/include string openssh-server ca-certificates sudo curl wget git build-essential python3 python3-dev libncurses-dev tcpdump iproute2 debootstrap strace
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false

#### Sudo Access ####
d-i sudo/user-fullname string FULL_NAME
d-i sudo/user string USERNAME

#### Grub Boot Loader ####
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean false
d-i grub-installer/bootdev string /dev/vda

d-i preseed/interactive false

#### Late Command (Post-Installation) ####
d-i preseed/late_command string \
    cp -a /post_install.sh /target/root/post_install.sh; \
    cp -a /sshd_config /target/etc/ssh/sshd_config; \
    cp -a /passwordless_guest /target/etc/sudoers.d/passwordless_guest; \
    in-target /bin/bash -c 'mkdir --mode 700 --parents /home/USERNAME/.ssh'; \
    cp -a /key.pub /target/home/USERNAME/.ssh/authorized_keys; \
    in-target /bin/bash -c 'chmod 600 /home/USERNAME/.ssh/authorized_keys'; \
    in-target /bin/bash -c 'chown -R USERNAME:USERNAME /home/USERNAME/'; \
    in-target /bin/bash -c '/root/post_install.sh > /root/post_install.log 2>&1'

d-i debian-installer/add-kernel-opts string console=ttyS0,115200

d-i cdrom/eject boolean false
d-i debian-installer/exit/halt boolean false
d-i debian-installer/exit/poweroff boolean false
d-i debian-installer/exit/reboot boolean false

#### Automate the last Continue button ####
d-i finish-install/reboot_in_progress note

#### Return to shell ####
d-i debian-installer/exit/poweroff boolean true
#d-i debian-installer/exit/halt boolean true

