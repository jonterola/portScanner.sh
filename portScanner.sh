#!/bin/bash


#Colours
greenC="\e[0;32m\033[1m"
endC="\033[0m\e[0m"
redC="\e[0;31m\033[1m"
blueC="\e[0;34m\033[1m"
yellowC="\e[0;33m\033[1m"
purpleC="\e[0;35m\033[1m"
turquoiseC="\e[0;36m\033[1m"
grayC="\e[0;37m\033[1m"


function ctrl_c(){
  echo -e "${yellowC}\n[+]${endC}${grayC} Saliendo...${endC}"
  exit 0
}

#Ctrl + C
trap ctrl_c INT


function helpPanel(){
  echo -e "\n${yellowC}[+]${endC} ${grayC}Uso:${endC}"
  echo -e "\t${purpleC}a)${endC} ${grayC}Aplicar la búsqueda sobre todos los puertos (0-65535)${endC}"
  echo -e "\t${purpleC}h)${endC} ${grayC}Mostrar este panel de ayuda${endC}"
  echo -e "\t${purpleC}t)${endC} ${grayC}IP o rango de red a escanear ${endC}\n"
}

declare -a openPorts

function extractPorts(){
  hostPorts=$(cat $1 | grep Ports: | awk -F'Ports: ' '{print $1, $2}' | awk '{print $2, $4}' | awk '{ORS=(NR%2?":":""); print}' | sed 's/ /_/g')
  IFS=':' read -ra targetArray <<< "$hostPorts"
 
  declare -i i=0
  for target in ${targetArray[@]}; do
    i+=1
    host=$(echo "$target" | cut -d '_' -f1)
    ports=$(echo "$target" | cut -d '_' -f2)
    ports=$(echo "$ports" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    echo -e "\n${yellowC}[+]${endC} ${grayC}Host $i:${endC} ${blueC}$host${endC} ${yellowC}|${endC} ${grayC}Puertos abiertos:${endC} ${blueC}$ports${endC}"
    echo -e "\n${grayC}[+] Buscando vulnerabilidades en los puertos abiertos...\n${endC}"
    nmap -sS -sCV -n -Pn -p$ports $host
  done
}


function scanTarget(){
  echo -e "\n${yellowC}[+]${endC} ${grayC}Comenzando escaneo de puertos sobre $1${endC}"
  nmap $allPorts --open -n -Pn -oG "/tmp/extractPorts.tmp" "$1" 1>/dev/null
  extractPorts "/tmp/extractPorts.tmp"
  echo -e "\n${yellowC}[+]${endC} ${grayC}Escaneo finalizado${endC}"
  rm "/tmp/extractPorts.tmp"
}

declare -i parameter_counter=0
allPorts=""
     
while getopts "aht:" arg; do
  case $arg in
    a) allPorts="-p-";let parameter_counter+=1;;
    t) target=$OPTARG;let parameter_counter+=2;;
    h) ;;
  esac 
done

if [ $parameter_counter -ge 2 ]; then
  scanTarget $target
else
  helpPanel
fi

