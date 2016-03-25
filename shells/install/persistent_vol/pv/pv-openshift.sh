. ./pv-config.sh

# This method create pv yaml script
function create_pv_script(){
  #VOL_NAME=${PV_NAME_PREFIX}${c}
  VOL_NAME=$1
  LVM_VOL_NAME=$2
cat << EOF > ${PV_SCRIPT_PATH}/${VOL_NAME}
     apiVersion: "v1"
     kind: "PersistentVolume"
     metadata:
       name: "${VOL_NAME}"
     spec:
       capacity:
         storage: "${VOL_SIZE}"
       accessModes:
         - "ReadWriteMany"
       nfs:
         path: "${NFS_MOUNT_PATH}/${LVM_VOL_NAME}"
         server: "${NFS_SERVER}"
         persistentVolumeReclaimPolicy: "Recycle"
EOF
  echo "Created def file for ${VOL_NAME}"
}



export exist_pv
export created_pv_script

#Check if PV_SCRIPT_PATH is exist. If exist, skip but don't exist, it will create the folder
if [[ -e ${PV_SCRIPT_PATH} ]]; then
  echo "${PV_SCRIPT_PATH} exist so it is not created."
else
  echo "${PV_SCIRPT_PATH} does not exist so it is created."
  mkdir -p ${PV_SCRIPT_PATH}
fi

# Flow
# 1. Check if there is same name of pv on openshift
# 2.1. If there is, it does not create even pv script.
# 2.2. If there is not, it create pv script under ${PV_SCRIPT_PATH}.
# 3. It will execute "oc create -f" with pv script
# 4. Ask if the pv script and folder remain or not.

for c in $(seq -f "%0${#PV_NAME_PAD}g" ${PV_RANGE_START} ${PV_RANGE_END})
do
  # pv name
  VOL_NAME=${PV_NAME_PREFIX}${c}

  #lvm vol name
  FORMATTED_LVM_SIZE=$(seq -f "%0${#LVM_NAME_SIZE_PAD}g" ${LVM_VOL_SIZE} ${LVM_VOL_SIZE})
  FORMATTED_LVM_RANGE=$(seq -f "%0${#LVM_NAME_RANGE_PAD}g" ${PV_RANGE_START} ${PV_RANGE_END})
  LVM_VOL_NAME="ose-${NFS_SERVER_TAG}-${LVM_NAME_PREFIX}${FORMATTED_LVM_SIZE}g$FORMATTED_LVM_RANGE"

echo $LVM_VOL_NAME
  pv_exist=$(oc get pv |grep ${VOL_NAME} |wc -l)

  if [[ $pv_exist == 1 ]]; then
      echo "${VOL_NAME} pv is already created so skip to create the persistent volume!!"
      exist_pv=("${exist_pv[@]}" "${VOL_NAME}")
  else
      echo "Creating ${VOL_NAME} pv script"
      create_pv_script ${VOL_NAME} ${LVM_VOL_NAME}
      oc create -f ${PV_SCRIPT_PATH}/${VOL_NAME}

      check_pv_is_created=$(oc get pv|grep ${VOL_NAME}|wc -l)

      if [[ $check_pv_is_created == 1 ]]; then
        created_pv_script=("${created_pv[@]}" "${VOL_NAME}")
      else
        echo "There were issues to create pv. Check user role"
      fi

  fi

done;

echo ""
echo ""
echo ""
echo "Summary :"
echo "====================================================="
echo "Exist pv :"
echo ${exist_pv[@]}
echo ""
echo Created pv  :
echo ${created_pv_script[@]}
echo ""
echo ""
oc get pv
echo ""

export finish="false"
while [ $finish == "false" ]
do
   echo -e "Do you want to clean all stuff such as pv scripts/folder?(y/n)"
   read clean
   if [ $clean == "y" ]; then
     echo "cleaning all stuff"
     rm -rf  ${PV_SCRIPT_PATH}
     finish="true"
   elif [ $clean == "n" ]; then
     echo "OK, you can see scripts from here :${PV_SCRIPT_PATH}"
     finish="true"
   else
     echo "You should type one of y or n!!!"
   fi
done
