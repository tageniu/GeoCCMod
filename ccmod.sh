#!/bin/zsh

# Specify your SQLite database file and queries
DATABASE_FILE=~/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod/GEOConfigStore.db
CC=CN

CHECK_OCC="SELECT * FROM defaults WHERE key='OverrideCountryCode';"
CHECK_SOCC="SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';"
ADD_OCC="INSERT INTO defaults (key,parent,type,value) VALUES ('OverrideCountryCode','0','str','$CC');"
ADD_SOCC="INSERT INTO defaults (key,parent,type,value) VALUES ('ShouldOverrideCountryCode','0','int','1');"
UPDATE_OCC="UPDATE defaults SET value='$CC' WHERE key='OverrideCountryCode';"
UPDATE_SOCC="UPDATE defaults SET value='1' WHERE key='ShouldOverrideCountryCode';"
DELETE_OCC="DELETE FROM defaults WHERE key='OverrideCountryCode';"
DELETE_SOCC="DELETE FROM defaults WHERE key='ShouldOverrideCountryCode';"

killGEOD() { killall com.apple.geod 2>/dev/null; sleep 0.1 }

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

clear
while true; do
	echo "Menu:"
    echo "	1. Check"
    echo "	2. Override"
    echo "	3. Restore Default"
    echo "	4. Exit"
	echo "Enter your choice: "
    read choice
    case $choice in
        1)
        	clear
            echo "You selected Option 1, checking..."
            echo "========== OCC Result =========="
            query "$CHECK_OCC"
            echo "========== SOCC Result =========="
            query "$CHECK_SOCC"
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
            echo "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            clear
            echo "Invalid choice. Please enter a number between 1 and 4."
            echo "====================\n"
            ;;
    esac
done