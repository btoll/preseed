Read the article [On Building A Kubernetes Cluster With kubeadm](https://benjamintoll.com/2026/10/25/on-building-a-kubernetes-cluster-with-kubeadm/).

# Usage

```bash
$ cat << EOF | ./install.sh
[
    {
        "name": "control-plane",
        "os": "debian13",
        "network_interface": "enp2s0",
        "netmask": "255.255.255.0",
        "ip_address": "192.168.122.100",
        "gateway": "192.168.122.1",
        "nameserver": "1.1.1.1",
        "full_name": "Benjamin Toll",
        "username": "btoll",
        "memory": 4096,
        "disk": 40
    }
]
EOF
```

```bash
$ ./install.sh < cluster.json
```

```bash
$ ./install.sh <<< '
[
    {
        "name": "control-plane",
        "os": "debian13",
        "network_interface": "enp2s0",
        "netmask": "255.255.255.0",
        "ip_address": "192.168.122.100",
        "gateway": "192.168.122.1",
        "nameserver": "1.1.1.1",
        "full_name": "Benjamin Toll",
        "username": "btoll",
        "memory": 4096,
        "disk": 40
    }
]
'
```
