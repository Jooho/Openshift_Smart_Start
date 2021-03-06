#!/bin/bash
#
#  Author: Jooho Lee(ljhiyh@gmail.com)
#    Date: 2016.05.25
# Purpose: Check if each VM install necessary packages


. $CONFIG_PATH/ose_config.sh

#Check if the following base packages installed:
export base_packages="wget git net-tools bind-utils iptables-services bridge-utils bash-completion nfs-utils docker-1.8.2"
export installed_packages_count=0
export base_packages_count=0
export login_count=0
export all_hosts_count=0
export all_node_hosts_count=0
export docker_storage_count=0



#Master
if [[ $(hostname) == ${ose_cli_operation_vm} ]] && [[ ${ansible_operation_vm} == ${ose_cli_operation_vm} ]]
then
   
   base_packages="$base_packages atomic-openshift-utils"
     
   #Get information about rpm_list
   rpm -qa > ${ose_temp_dir}/rpm_list.out
   
   for package in ${base_packages} 
   do
     result=$(cat ${ose_temp_dir}/rpm_list.out |grep $package |wc -l)
     if [[ $result -gt 0 ]]
     then
        $((installed_count + 1))
     fi

 #  for host in $all_hosts 
 #  do
 #    all_hosts_count=$((all_hosts_count + 1))
 #    #echo "sshpass -p $password ssh root@\$host 'echo `hostname` can be logined from ${ansible_operation_vm}| wc -l'"
 #    ssh -q root@$host 'echo `hostname` can be logined from ' ${ansible_operation_vm}
 #    temp_login_result=$( ssh root@$host 'echo `hostname` can be logined from ${ansible_operation_vm}| wc -l')
 #    
 #    login_count=$((login_count + temp_login_result))
 #  done
elif [[ $(hostname) == ${ansible_operation_vm} ]] && [[ ${ansible_operation_vm} != ${ose_cli_operation_vm} ]]
then

cat << EOF > ./validation_pre_requites_remote.sh

   base_packages="$base_packages atomic-openshift-utils"

   for host in $all_hosts 
   do
     all_hosts_count=$((all_hosts_count + 1))
     #echo "sshpass -p $password ssh root@\$host 'echo `hostname` can be logined from ${ansible_operation_vm}| wc -l'"
     ssh -q root@$host 'echo `hostname` can be logined from ' ${ansible_operation_vm}
     temp_login_result=$( ssh root@$host 'echo `hostname` can be logined from ${ansible_operation_vm}| wc -l')
     
     login_count=$((login_count + temp_login_result))
   done

EOF

scp ./docker_registry_remote.sh root@${HOST}:${ose_temp_dir}/.
ssh root@${HOST} "sh ${ose_temp_dir}/docker_registry_remote.sh"



# Node only has docker-storage
elif [[ $(hostname) =~ ${node_prefix} ]]
then
    #Check Docker storage is configured
    all_node_hosts_count=$((all_node_hosts_count + 1))
    temp_docker_storage_result=$(lvs | grep docker-pool | wc -l)
    #lvs | grep docker-pool  

     docker_storage_count=$((docker_storage_count + temp_docker_storage_result))
    #echo $docker_storage_count
fi
#ls /var/lib/docker/

#ps -ef|grep docker
docker_log_opt_config=$(grep log-opt /etc/sysconfig/docker|wc -l)
docker_log_opt_runtime=$(ps -ef|grep log-opt /etc/sysconfig/docker|grep -v grep|wc -l)
#grep log-opt /etc/sysconfig/docker
#ps -ef|grep log-opt|grep -v grep




echo "------------------------------ "
echo "Neccessary packages $base_packages installation:"
if [[ $base_packages_count == $installed_packages_count ]];then
   echo "** Result >> PASS !!"
else
   echo "** Result >> FAIL ;("
fi    

if [[ $(hostname) == ${ansible_operation_vm} ]]
then
   echo "" 
   echo "Access to all vms from ${ansible_operation_vm}:" 
   if [[ $all_hosts_count == $login_count ]];then
       echo "** Result >> PASS !!"
   else
      echo "** Result >> FAIL ;("
   fi
fi

#echo $(hostname) =~ ${node_prefix} 
if [[ $(hostname) =~ ${node_prefix} ]]
then
    echo "" 
    echo "Set up docker storage on node vm :"
    if [[ $docker_storage_count == $all_node_hosts_count ]];then
        echo "** Result >> PASS !!"
    else
        echo "** Result >> FAIL ;("
    fi
fi

echo "" 
echo "Config docker log-opt on vm :"
if [[ $docker_log_opt_config == 1 && $docker_log_opt_runtime == 1 ]];then
    echo "** Result >> PASS !!"
else
    echo "** Result >> FAIL ;("
fi
