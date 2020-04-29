#! /bin/bash
#set -x
# Controlscript for SAP data provisioning agents
# Design by Uwe Kaden uwe.kaden@allianz.com
# for SDI only
# Remarks:
# - invoking the stop command will NOT stop the agent!
# - 
#
# defining Variables

AGENT_CONTROL="/bin/dpagent_service.sh"
KILLFILE="/var/tmp/sdicontrol.pid"



# Codestart

start_agent () {
echo $$ > /var/tmp/sdicontrol.pid
# Find all configured filesystems for agents
while  true; do
   declare -a AGENTS=$()
   for i in $(df -h |grep datapro | grep -v grep| awk '{print $6}');do
      AGENTS+=($i)
   done;
   for l in ${AGENTS[@]}; do
       struct_control ${l}
   done;
   unset AGENTS
sleep 500
done;
}




stop_agent () {
   if [ -f "${KILLFILE}" ]; then
      kill $(cat ${KILLFILE})
	  echo "${KILLFILE} found, service killed."
	  rm ${KILLFILE}
   else
      echo "no kill - file found. Try to kill the process by looking for PID"  
      KILLPID=$(ps aux | grep -i sdi.sh | grep -v grep | awk '{print $2}')
      kill ${KILLPID}	  
	fi	  
}

struct_control () {

# Find user for agent
   U=$(ls -l ${1}${AGENT_CONTROL}| awk '{print $3}')
 if [ ! -f  "${1}/debug" ]; then
# Try to ping agent
   su - ${U} -c "${1}${AGENT_CONTROL} ping" | grep -w "dpagent_service is running" >> /dev/null 2>&1
   if [ "$?" -ne "0" ]; then
      echo "Agent for user ${U} is not running, attempting to start at $(date +"%Y-%m-%d_%H-%M-%S")."
	  su - ${U} -c "${1}${AGENT_CONTROL} start"
   else
      echo "Agent for user ${U} is up and running at $(date +"%Y-%m-%d_%H-%M-%S")"  
   fi
else
   echo "Debug file ${1}/debug is there. No startup for ${U}".
fi   
}


case "$1" in

           start)
             start_agent
             ;;
           stop)
             stop_agent
             ;;
            *)
             echo "Usage: sdi.sh stop | start" ;
esac
