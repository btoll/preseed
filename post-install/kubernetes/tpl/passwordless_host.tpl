USERNAME HOSTNAME=(ALL:ALL) NOPASSWD: \
	/usr/bin/cp PROJECT_SHARE/mnt/config /home/USERNAME/.kube, \
	/usr/bin/chown USERNAME\:USERNAME /home/USERNAME/.kube/config, \
	/usr/bin/grep "kubeadm join" PROJECT_SHARE/control-plane/mnt/kubeadm-init.log, \
	/usr/bin/sed -n '/kubeadm join/\,$p' PROJECT_SHARE/control-plane/mnt/kubeadm-init.log

