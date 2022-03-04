#!/bin/bash
echo "===[Mini Tools - User and Data Migration]="
PS3='= Choose the Tool: '
tools=("Make User and Data Backup" "Restore User and Data" "Quit")
select tool in "${tools[@]}"
do
	case $tool in
		"Make User and Data Backup")
			#Input filename for Migration
			echo "= Input Backup File Name:"
			read FILE_NAME
			if [ -z "$FILE_NAME" ]; then FILE_NAME="migration"; else FILE_NAME=$FILE_NAME; fi
			echo

			echo "= Set the Backup Directory (/root/migration/):"
			#Input dir for Migration
			read DIR
			echo

			if [ -z "$DIR" ]; then DIR="/root/migration/"; else DIR="$DIR/$FILE_NAME/"; fi
			
			#Create dir for Migration
			mkdir $DIR -p
			
			#Migrate /etc/passwd file only non-system user
			awk -v LIMIT=1000 -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd > "$DIR"passwd.mig
			echo "==[Success Migrate /etc/passwd]="
			ls -lh $DIR	
			echo

			#Migrate /etc/group file only non-system user
                        awk -v LIMIT=1000 -F: '($3>=LIMIT) && ($3!=65534)' /etc/group > "$DIR"group.mig
                        echo "==[Success Migrate /etc/group]="
                        ls -lh $DIR
			echo

			#Migrate /etc/shadow file only non-system user
			awk -v LIMIT=1000 -F: '($3>=LIMIT) && ($3!=65534) {print $1}' /etc/passwd | tee - |egrep -f - /etc/shadow > "$DIR"shadow.mig
			echo "==[Success Migrate /etc/shadow]="
			ls -lh $DIR
			echo

			#Migrate all data on /etc/gshadow
			cp /etc/gshadow "$DIR"gshadow.mig
			echo "==[Success Migrate /etc/gshadow]="
			ls -lh $DIR
			echo

			#tar.gz /home 
			tar -zcpf "$DIR"home.tar.gz /home
			echo "==[Success Migrate /home]="
			ls -lh $DIR
			echo

			cd $DIR
			cd ..
			UP_DIR=$(pwd)
			
			#tar.gz Migration Data
			tar -zcpf "$UP_DIR"/"$FILE_NAME".tar.gz $DIR
			echo "==[Success Tape the Migration Data]="
			ls -lh $UP_DIR
			echo

			echo "===[Success Make Backup Data]="
			echo "===[Your Data Directory: $UP_DIR/$FILE_NAME.tar.gz]="
			echo
			;;
		"Restore User and Data")
			PS3='= Choose the Tool: '
			tools=("Get Current Non-System User Lists" "Get Data From Old Server Using Rsync" "Restore the Data" "Quit")
			select tool in "${tools[@]}"
			do
        			case $tool in
                			"Get Current Non-System User Lists")
						echo "===[Current User Lists]="
						awk -v LIMIT=1000 -F: '($3>=LIMIT) && ($3!=65534)' /etc/passwd
						echo
						;;
					"Get Data From Old Server Using Rsync")
						echo "= Input Old Server Username:"
						read USERNAME
						echo

						echo "= Input Old Server Host:"
						read HOST
						echo

						echo "= Input Old Server SSH Port (22):"
						read PORT
						if [ -z "$PORT" ]; then PORT="22"; else PORT=$PORT; fi
						echo

						echo "= Input Old Server Backup File Directory (Ie. /home/username/):"
						read FILE_DIR
						echo

						echo "= Input Old Server Backup File Name"
						read FILE_NAME
						FILE_NAME="$FILE_NAME.tar.gz"
						echo
						
						rsync -zvhPe "ssh -p $PORT" $USERNAME@$HOST:"$FILE_DIR""$FILE_NAME" /
						echo

						echo "===[Success Get Backup Data]="
						echo "===[The Backup Data on /$FILE_NAME]="
						echo 
						;;

					"Restore the Data")
						cd /
						pwd

						echo "= Input Backup File Directory (Ie. /):"
                                                read FILE_DIR
                                                echo

                                                echo "= Input Old Server Backup File Name"
                                                read FILE_NAME
                                                FILE_NAME_EXTRACT="$FILE_NAME.tar.gz"
						tar -xf /$FILE_NAME_EXTRACT
                                                echo

						echo "===[Success Extract Backup Migration File]="
						
						DATAEXTRACT_DIR=$(tar -tf /$FILE_NAME_EXTRACT  | head -1)
						ls -lh $DATAEXTRACT_DIR			
						echo

						cd $DATAEXTRACT_DIR
						cat passwd.mig >> /etc/passwd
						cat group.mig >> /etc/group
						cat shadow.mig >> /etc/shadow
						cp -p gshadow.mig /etc/gshadow
						echo "===[Success Copy Old Server User List to the New Server User List]="

						#copy the old server user data to the new server use data directory
						cd /
						tar -zxf /"$DATAEXTRACT_DIR"/"home.tar.gz" 
						echo "===[Success Copy Old Server User Data to the New Server User Data]="
						;;
		
					"Quit")	
						break 
						;;
					*)	echo "===[Invalid Option $REPLY]=";;
				esac
			done
			;;
		"Quit")
			echo "===[Mini Tools Exit]="
			exit
			break
			;;
		*)	echo "===[Invalid Option $REPLY]=";;
	esac
done	

