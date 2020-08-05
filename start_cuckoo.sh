#!/bin/bash
#Ver1.1

#Colors
red=$(tput setaf 1)
green=$(tput setaf 2)
end=$(tput setaf 7)

#Services that have to run
declare -a services=("elasticsearch" "mongod" "suricata" "snort" "molochcapture" "molochviewer")
#Ports that have to be checked
declare -a ports=("2042" "8000" "8001" "8005")
#Start Guacamole
guac="sudo guacd start -l 4822 -b 127.0.0.1"

#Function takes a $service then checks if service is running and writes status in log.txt
#If status was not running functions starts sevice and logs aganin
log_status () {
for service in ${services[@]}
do 
if systemctl is-active --quiet $service #pgrep -f $service >/dev/null 2>&1
then 
echo "${green} $service is running | $(date) ${end}" >> log.txt
echo "${green} $service is now running | $(date) ${end}" 
else
echo "${red} Retry : $service is not running | $(date) ${end}" 
echo "${red} $service is not running -> retry to start | $(date) ${end}"  >> log.txt
start_service $services 
log_status $services
fi
done
}
#Function takes a $service then checks if service is running 
#If status was not running functions starts sevice 
start_all () {
for service in ${services[@]}
do 
if systemctl is-active --quiet $service #pgrep -f $service >/dev/null 2>&1
then
echo "${green} $service is running | $(date) ${end}" 
else
start_service $services 
fi
done
}


#Function takes a $service and starts it 
start_service () {
sudo systemctl start $service.service
}

#Function clears log.txt
clear_log () {
 > log.txt
}
#Function checks which service is running on ports and writes them to log.txt 
log_port () {
for port in ${ports[@]}
do 
if sudo netstat -tulpn | grep --line-buffered -q "$port .*LISTEN";
then
servID=$(sudo netstat -tulpn | grep "$port" | awk '{ print $7}')
echo "${green} $servID at port number $port ${end}" >> log.txt
else 
echo "${red} $port Port is not listing ${end}" >> log.txt
fi
done
}
#Start
start () {
clear_log
start_all $services
log_status $services
$guac
echo "#### All services are running! ###"
/bin/su -c ". /home/cuckoo/cuckoo/bin/activate; vmcloak-vboxnet0; cuckoo web --host 0.0.0.0 --port 8001 & cuckoo -d " - cuckoo
log_port $ports   
}

#### MAIN ####
start
