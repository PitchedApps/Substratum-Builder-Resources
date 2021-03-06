#!/bin/bash

#####################################
#   Substratum Overlay Builder      #
#   run with sh and full path to    #
#   assets/overlays directory       #
#              - Pitched Apps       #
#####################################

# $1    full package dir
# $2    framework dir
# $3	aapt type
# http://elinux.org/Android_aapt
# -M    AndroidManifest.xml dir
# -S    resource directory
# -I    add existing package to base
# -f    force overwrite of existing files
# -F    apk output file
# -v	verbose for debug
buildApk() {
	if [ -d "${1}res" ]; then
		name="$(basename "$1")"
		printf "\n%s\n" "$name"
		# compile and save error log to $result
		extra=""
		if [ -d "${1}type3_Clear" ]; then
			extra="-S ${1}type3_Clear "
		fi
		result="$("./packager/$3" p -M AndroidManifest.xml -S "${1}res" ${extra}-I "$2" -f --auto-add-overlay -F "builds/${name}.test.apk" 2>&1 > /dev/null)"
		if [ ! -z "$result" ] ; then
			echo "$result" # just so the logs show on Travis
			printf "~~~ %s ~~~\n\n%s\n\n" "$name" "$result" 1>&2 # print error and append package name
		fi
	fi
}

# $1	parent dir
main() {
	if [ -d builds ]; then # clean build dir
		rm -r builds
	fi
	mkdir builds
	
	# get proper aapt version
	# http://stackoverflow.com/a/8597411
	case "$OSTYPE" in
		"")
			echo "empty OSTYPE; defaulting to linux"
			aapt="aapt86"
			;;
		linux-gnu) 
			aapt="aapt"
			;;
		cygwin|msys)
			aapt="aapt.exe"
			;;
		*)
			printf "Unsupported OS type %s\n" "$OSTYPE" 1>&2
			exit 1
			;;
	esac
	cd packager
	if [ ! -f "./$aapt" ]; then
		printf "%s not found; make sure you run the script at its given directory\nYou are now in %s\n" "$aapt" "$PWD"
		ls -l
		exit 2
	fi
	cd ..
	printf "AAPT: %s\nBuilding overlays...\nin %s\nfrom dir %s\n" "$aapt" "$1" "$PWD"
	chmod +x "./packager/$aapt"
	for f in ${1}/*/; do
		buildApk "$f" "frameworks/n-lineage-nexus-5.apk" "$aapt" 2>> builds/log.txt
	done
}

main "$@"