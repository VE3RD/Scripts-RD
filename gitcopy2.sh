#!/bin/bash
#########################################################
#  Nextion TFT Support for Nextion 2.4" 		#
#  Gets all Scripts and support files from github       #
#  and copies them into the Nextion_Support directory   "
#  and copies the NX??? tft file into /usr/local/etc    #
#  and returns a script duration time to the Screen 	#
#  as a script completion flag				#
#							#
#  KF6S/VE3RD                               2020-05-12  #
#########################################################
# Valid Screen Names for EA7KDO - NX3224K024, NX4832K935
# Valid Screen Names for VE3RD - NX3224K024
parm="$1"
ver="20200512"
declare -i tst
sed -i '/use_colors = /c\use_colors = ON' ~/.dialogrc
sed -i '/screen_color = /c\screen_color = (WHITE,BLUE,ON)' ~/.dialogrc
sed -i '/title_color = /c\title_color = (YELLOW,RED,ON)' ~/.dialogrc
echo -e '\e[1;44m'
clear

# EA7KDO Script Function
function getea7kdo
{
	tst=0
#	echo "Function EA7KDO"
	calltxt="EA7KDO"

if [ -d /home/pi-star/Nextion_Temp ]; then
  	sudo rm -R /home/pi-star/Nextion_Temp
fi

    	if [ "$scn" == "NX3224K024" ]; then
	  	sudo git clone --depth 1 https://github.com/EA7KDO/Nextion.Images /home/pi-star/Nextion_Temp
		tst=1
	fi     
	if [ "$scn" == "NX4832K035" ]; then
	  	sudo git clone --depth 1 https://github.com/EA7KDO/NX4832K035 /home/pi-star/Nextion_Temp
		tst=2
     	fi
	
}

# VE3RD Script Function
function getve3rd
{
if [ -d /home/pi-star/Nextion_Temp ]; then
  	sudo rm -R /home/pi-star/Nextion_Temp
fi
	tst=0
#	echo "Function VE3RD"
     	
	calltxt="VE3RD"
	if [ "$scn" = "NX3224K024" ]; then	
	 	tst=1  
	  	sudo git clone --depth 1 https://github.com/VE3RD/Nextion /home/pi-star/Nextion_Temp
	else
		errtext="Invalid VE3RD Screen Name $scn,  $s1,  $s2"
		exitcode 
	fi

}

function getcall
{
#Set Screen Author
calltxt=""
if [ "$parm" == VE3RD ]; then
	calltxt="VE3RD"
else
	calltxt="EA7KDO"
fi
}

function exitcode
{
txt='Abort Funtion
This Script will Now Stop
"$errtext"'

whiptail --title " Programmed Exit Function" --msgbox "$txt"  8 78
echo -e '\e[1;40m'

exit

}

#### Sart of Main Code

## Select User Screens
getcall
S1=""
S2=""
if [ -f "/usr/local/etc/NX4832K035.tft" ]; then
   S1="NX4832K035"
   S1A=" Available     "
else 
   S1="NX4832K035"
   S1A=" Not Available "
fi
if [ -f "/usr/local/etc/NX3224K024.tft" ]; then
   S2="NX3224K024"
   S2A=" Available     "
else
   S2="NX3224K024"
   S2=" Not Available "
fi
result=$(whiptail --title "Get $calltxt Screen Package From Github" --menu "Choose Your Nextion Screen Type" --backtitle "This Script by VE3RD $ver" 25 78 16 \
"$S1" "$S1A 3.5 Inch Nextion Screen" \
"$S2" "$S2A 2.4 Inch Nextion Screen" \
"Abort" "Exit Script" 3>&1 1>&2 2>&3)

errt="$?"
echo "$result"
scn="$result"

if [ "$errt" == 1 ]||[ "$result" == "Abort" ]; then
     errtext="Abort Chosen From Main Menu err=$errt"
echo "Trap1"
     exitcode
fi

if [ "$calltxt" = "VE3RD" ]; then
	if [ "$result" == "NX3224K024" ]; then
echo "Trap2"
		scn="$result"
	else
echo "Trap3"
		errtext=" Invalid  Screen name for $calltxt"
	fi
fi

echo "$scn $calltxt"

#echo " End Processing Parameters  - $scn $calltxt"

#Start Duration Timer
start=$(date +%s.%N)

model="$scn"
tft='.tft' 
#gz='.gz'
#Put Pi-Star file system in RW mode
sudo mount -o remount,rw /
sleep 1s

#Stop the cron service
sudo systemctl stop cron.service  > /dev/null


#Test for /home/pi-star/Nextion_Temp and remove it, if it exists

if [ -d /home/pi-star/Nextion_Temp ]; then
  	sudo rm -R /home/pi-star/Nextion_Temp
fi

  # Get Nextion Screen/Scripts and support files from github
  # Get EA7KDO File Set

if [ "$calltxt" == "EA7KDO" ]; then
	echo "getting Screens for $calltxt"
	getea7kdo
 
fi


  # Get VE3RD File Set
if [ "$calltxt" == "VE3RD" ]; then
	echo "Getting Screens for $calltxt"
	getve3rd
fi


if [ ! -d /usr/local/etc/Nextion_Support ]; then
	sudo mkdir /usr/local/etc/Nextion_Support
else
       sudo rm -R /usr/local/etc/Nextion_Support
	sudo mkdir /usr/local/etc/Nextion_Support
fi

sudo chmod +x /home/pi-star/Nextion_Temp/*.sh
sudo rsync -avqru /home/pi-star/Nextion_Temp/* /usr/local/etc/Nextion_Support/ --exclude=NX* --exclude=profiles.txt

if [ -f /home/pi-star/Nextion_Temp/profiles.txt ]; then
	if [ ! -f /usr/local/etc/Nextion_Support/profiles.txt ]; then
        	if [ "$fb" ]; then
			txtn= "Replacing Missing Profiles.txt"
			txt="$txt\n""$txtn"
        	fi
        	sudo cp  /home/pi-star/Nextion_Temp/profiles.txt /usr/local/etc/Nextion_Support/
	fi
fi

model="$scn"
    echo "Remove Existing $model$tft and copy in the new one"
txtn="Remove Existing $model$tft and copy in the new one"
txt="$txt""$txtn"
#whiptail --title "$title" --msgbox "$txt" 8 80

if [ -f /usr/local/etc/"$model$tft" ]; then
	sudo rm /usr/local/etc/NX*K*.tft
fi
sudo cp /home/pi-star/Nextion_Temp/"$model$tft" /usr/local/etc/


 FILE=/usr/local/etc/"$model$tft"
 if [ ! -f "$FILE" ]; then
        # Copy failed
      	echo "No TFT File Available to Flash - Try Again"
	errtext="Missing tft File Parameter"
	exitcode
 fi

sudo systemctl start cron.service  > /dev/null

duration=$(echo "$(date +%s.%N) - $start" | bc)
execution_time=`printf "%.2f seconds" $duration`


txt="$calltxt Scripts Loaded: $execution_time"
whiptail --title "$title" --msgbox "$txt" 8 90

echo -e '\e[1;40m'
clear



