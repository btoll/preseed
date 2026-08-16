# preseed

Read the article [On Building A Kubernetes Cluster With kubeadm](https://benjamintoll.com/2026/10/25/on-building-a-kubernetes-cluster-with-kubeadm/).

## Install the Project

To create a new directory with the necessary files:

```bash
$ ./init.sh --dir foobar
[INFO] Copied ./common/install.sh into ./post-install/foobar
[INFO] Copied ./common/node.json into ./post-install/foobar
[INFO] Copied ./common/post_install.sh into ./post-install/foobar
[INFO] Copied ./common/preseed.cfg into ./post-install/foobar
[INFO] Copied ./common/uninstall.sh into ./post-install/foobar
```

It will also create a directory called `include.d/`, i.e.:

```bash
$ tree post-install/foobar
post-install/foobar/
├── include.d/
├── install.sh*
├── node.json
├── post_install.sh*
├── preseed.tpl
└── uninstall.sh*

2 directories, 5 files
```

## Install the VM

Anything you put in `include./d/` will be automatically copied into the virtual machine.  However, you must also instruct the preseeding process on how this should be included in the virtual machine in the `late_command` block in `preseed.tpl`:

```
#### Late Command (Post-Installation) ####
d-i preseed/late_command string \
    cp -a /post_install.sh /target/root/post_install.sh; \
    cp -a /sshd_config /target/etc/ssh/sshd_config; \
    in-target /bin/bash -c 'mkdir --mode 700 --parents /home/USERNAME/.ssh'; \
    cp -a /key.pub /target/home/USERNAME/.ssh/authorized_keys; \
    in-target /bin/bash -c 'chmod 600 /home/USERNAME/.ssh/authorized_keys'; \
    in-target /bin/bash -c 'chown -R USERNAME:USERNAME /home/USERNAME/'; \
    in-target /bin/bash -c '/root/post_install.sh > /root/post_install.log 2>&1'
```

Most projects in `post-install` can be initiated by running the following:

```bash
$ cat node.json | ./install.sh
```

Or, if you're cool:

```bash
$ < node.json ./install.sh
```

> The `node.json` file is copied into each new project directory by `init.sh`.

The exception to this is the `kubernetes` project.  See its `README.md` for more information.

## Uninstall the VM

```bash
$ ./uninstall.sh
```

## References

- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

## License

[GPLv3](COPYING)

## Author

[Benjamin Toll](https://benjamintoll.com)

