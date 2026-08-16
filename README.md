# preseed

Read the article [On Building A Kubernetes Cluster With kubeadm](https://benjamintoll.com/2026/10/25/on-building-a-kubernetes-cluster-with-kubeadm/).

To create a new directory with the necessary files:

```bash
$ ./init.sh --dir foobar
[INFO] Copied ./include.d/install.sh into ./post-install/foobar
[INFO] Copied ./include.d/post_install.sh into ./post-install/foobar
[INFO] Copied ./include.d/preseed.cfg into ./post-install/foobar
```

Most projects in `post-install` can be initiated by running the following:

```bash
$ ./install.sh --name minikube
```

The exception to this is the `kubernetes` project.  See its `README.md` for more information.

## References

- [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

## License

[GPLv3](COPYING)

## Author

[Benjamin Toll](https://benjamintoll.com)

