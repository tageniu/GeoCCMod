#!/bin/zsh

CC=CN
# Specify GEOConfigStore.db location
macos_version=$(sw_vers -productVersion)
major_version=$(echo $macos_version | awk -F '.' '{print $1}')
if [ "$major_version" -ge 14 ]; then
    DATABASE_FILE=~/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod/Vault/GEOConfigStore.db
else
    DATABASE_FILE=~/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod/GEOConfigStore.db
fi

# SQL queries
CHECK_OCC="SELECT * FROM defaults WHERE key='OverrideCountryCode';"
CHECK_SOCC="SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';"
CHECK_SENR="SELECT * FROM defaults WHERE key='GEOShowEnvironmentNameRule';"
ADD_OCC="INSERT INTO defaults (key,parent,type,value) VALUES ('OverrideCountryCode','0','str','$CC');"
ADD_SOCC="INSERT INTO defaults (key,parent,type,value) VALUES ('ShouldOverrideCountryCode','0','int','1');"
ADD_SENR="INSERT INTO defaults (key,parent,type,value) VALUES ('GEOShowEnvironmentNameRule','0','int','2');"
UPDATE_OCC="UPDATE defaults SET value='$CC' WHERE key='OverrideCountryCode';"
UPDATE_SOCC="UPDATE defaults SET value='1' WHERE key='ShouldOverrideCountryCode';"
UPDATE_SENR="UPDATE defaults SET value='2' WHERE key='GEOShowEnvironmentNameRule';"
DELETE_OCC="DELETE FROM defaults WHERE key='OverrideCountryCode';"
DELETE_SOCC="DELETE FROM defaults WHERE key='ShouldOverrideCountryCode';"
DELETE_SENR="DELETE FROM defaults WHERE key='GEOShowEnvironmentNameRule';"

killGEOD() { 
	killall -9 com.apple.geod 2>/dev/null; sleep 0.1
}

query() {  # e.g. query "$CHECK_OCC"
	if [ $# != 1 ]; then
		echo "Error: Exactly 1 argument is required."
		exit 1
	fi
	
	killGEOD
	RESULT=$(sqlite3 -line "$DATABASE_FILE" "$1" 2>/dev/null)
	while [ $? != 0 ]; do
		killGEOD
		RESULT=$(sqlite3 -line "$DATABASE_FILE" "$1" 2>/dev/null)
	done
	echo "$RESULT"
}

check() {
	RESULT_OCC=$(query "$CHECK_OCC")
	RESULT_SOCC=$(query "$CHECK_SOCC")
	RESULT_SENR=$(query "$CHECK_SENR")
	
	if [ -z "$RESULT_OCC" ]; then
		echo "========== OCC NOT found. =========="
	else
		echo "========== OCC Result =========="
		echo "$RESULT_OCC"
	fi
	
	if [ -z "$RESULT_SOCC" ]; then
		echo "========== SOCC NOT found. =========="
	else
		echo "========== SOCC Result =========="
		echo "$RESULT_SOCC"
	fi

	if [ -z "$RESULT_SENR" ]; then
		echo "========== SENR NOT found. =========="
	else
		echo "========== SENR Result =========="
		echo "$RESULT_SENR"
	fi
}

updateOCC() {
	RESULT_OCC=$(query "$CHECK_OCC")
	
	if [ -z "$RESULT_OCC" ]; then
		echo "========== OCC NOT found. Adding OCC... =========="
		query "$ADD_OCC" >/dev/null
		query "$CHECK_OCC"
	else
		echo "========== OCC found. =========="
		echo "$RESULT_OCC"
		echo "========== Updating OCC... =========="
		killGEOD
		query "$UPDATE_OCC" >/dev/null
		query "$CHECK_OCC"
	fi
}

updateSOCC() {
	RESULT_SOCC=$(query "$CHECK_SOCC")

	if [ -z "$RESULT_SOCC" ]; then
		echo "========== SOCC NOT found. Adding SOCC... =========="
		query "$ADD_SOCC" >/dev/null
		query "$CHECK_SOCC"
	else
		echo "========== SOCC found. =========="
		echo "$RESULT_SOCC"
		echo "========== Updating SOCC... =========="
		query "$UPDATE_SOCC" >/dev/null
		query "$CHECK_SOCC"
	fi
}

updateSENR() {
	RESULT_SENR=$(query "$CHECK_SENR")

	if [ -z "$RESULT_SENR" ]; then
		echo "========== SENR NOT found. Adding SENR... =========="
		query "$ADD_SENR" >/dev/null
		query "$CHECK_SENR"
	else
		echo "========== SENR found. =========="
		echo "$RESULT_SENR"
		echo "========== Updating SENR... =========="
		query "$UPDATE_SENR" >/dev/null
		query "$CHECK_SENR"
	fi
}

restoreSOCC() {
	RESULT_SOCC=$(query "$CHECK_SOCC")

	if [ -z "$RESULT_SOCC" ]; then
		echo "========== SOCC NOT found, no need to restore. =========="
	else
		echo "========== SOCC found. =========="
		echo "$RESULT_SOCC"
		echo "========== Restoring SOCC... =========="
		query "UPDATE defaults SET value='0' WHERE key='ShouldOverrideCountryCode';" >/dev/null
		query "$CHECK_SOCC"
	fi
}

restoreSENR() {
	RESULT_SENR=$(query "$CHECK_SENR")

	if [ -z "$RESULT_SENR" ]; then
		echo "========== SENR NOT found, no need to restore. =========="
	else
		echo "========== SENR found. =========="
		echo "$RESULT_SENR"
		echo "========== Restoring SENR... =========="
		query "UPDATE defaults SET value='0' WHERE key='GEOShowEnvironmentNameRule';" >/dev/null
		query "$CHECK_SENR"
	fi
}

delete() {
	query "$DELETE_OCC" >/dev/null
	query "$DELETE_SOCC" >/dev/null
	query "$DELETE_SENR" >/dev/null
	echo "========== Deleted OCC and SOCC. =========="
}

clear
while true; do
	if [ ! -f "$DATABASE_FILE" ]; then
		echo "Error: Database file not found."
		exit 1
	fi
	echo "Menu:"
    echo "	1. Check"
    echo "	2. Override"
    echo "	3. Restore Default"
	echo "	4. Show Environment"
	echo "	5. Hide Environment"
	echo "	6. Delete ALL Keys"
    echo "	7. Exit"
	echo "Enter your choice: "
    read choice
    case $choice in
        1)
			clear
			echo "You selected Option 1, checking..."
            check
            echo "========== END ==========\n"
            ;;
        2)
            clear
            echo "You selected Option 2, overriding..."
            updateOCC
            updateSOCC
            echo "========== END ==========\n"
            ;;
        3)
            clear
            echo "You selected Option 3, restoring..."
            restoreSOCC
            echo "========== END ==========\n"
            ;;
		4)
			clear
			echo "You selected Option 4, showing environment..."
			updateSENR
			echo "========== END ==========\n"
            ;;
		5)
			clear
			echo "You selected Option 5, hiding environment..."
			restoreSENR
			echo "========== END ==========\n"
			;;
        6)
            clear
			echo "You selected Option 5, deleting all keys..."
			delete
			echo "========== END ==========\n"
            ;;
		7)
			echo "Exiting the script. Goodbye!"
			exit 0
			;;
        *)
            clear
            echo "Invalid choice. Please enter a number between 1 and 5."
            echo "====================\n"
            ;;
    esac
done