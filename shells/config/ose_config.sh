# Essecial package : nfs-util

export password="redhat"
export all_hosts="master1.example.com master2.example.com master3.example.com node1.example.com node2.example.com node3.example.com node4.example.com node5.example.com lb.example.com "
export all_ip="192.168.200.100 192.168.200.101 192.168.200.102 192.168.200.104 192.168.200.105 192.168.200.106 192.168.200.107 192.168.200.108 192.168.200.108"
export node_prefix="node"
export master_prefix="master"
export etcd_prefix="etcd"
export infra_selector="region=infra"

export ansible_operation_vm="master1.example.com"
export etcd_is_installed_on_master="true"
export docker_log_max_file="3"
export docker_log_max_size="300m"
export docker_storage_dev="vda"
export docker_registry_route_url=registry.cloudapps.example.com

#docker image version
export image_version=v3.1.1.6

. ./nfs_config.sh
. ./pv_config.sh
