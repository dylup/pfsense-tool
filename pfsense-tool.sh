#!/usr/local/bin/bash

# pfsense-tool
# Dylan Johnson

#function for errors
die () {
	echo >&2 "$@"
	exit 1
}

#make sure we supply a path to a file
[ "$#" -eq 1 ] || die "[-] Must supply modified file name"

# remove work directory if it exists
if [ -d "/pfsense-ports/net/openbgpd/work/" ]
then
	echo "[+] Removing work directory"
	rm -rf "/pfsense-ports/net/openbgpd/work/"
	echo -e "\t...done!"
fi

# setup paths for our files, .orig and modified file
origFilePath=$1".orig"
origFile=`basename $origFilePath`
file=`basename $1`
folder=${file%.*}

# create the patch file using diff
echo "[+] Creating patch file for '$file'"
output="/pfsense-ports/net/openbgpd/files/patch-"$folder"_"$file
diff -u $origFilePath $1 > $output
echo -e "\t...done!"

# update paths in patch file
# create escaped paths for sed
echo "[!] Modifying paths in patchfile"
origPathEsc=`echo $origFilePath | sed 's_/_\\\\/_g'`
origSedString="s/"$origPathEsc"/"$folder"\/"$origFile"/"

filePathEsc=`echo $1 | sed 's_/_\\\\/_g'`
fileSedString="s/"$filePathEsc"/"$folder"\/"$file"/"

# replace work candidate directory with proper directory
# for building openbgpd
sed -i '' $origSedString $output || die "[-] error modifying paths in patch file"
sed -i '' $fileSedString $output || die "[-] error modifying paths in patch file"
echo -e "\t...done!"

# build openbgpd, save log file
echo "[+] Building openbgpd... please wait..."
make > compileLog.txt
echo -e "\t...done! Log is located in 'compileLog.txt'"

# scp our binary to the firewall
echo "[+] Copying to pfSense_dev!"
echo "[!] Enter password below:"
binaryPath="/pfsense-ports/net/openbgpd/work/openbgpd-"*"/"$folder"/"${file%.*}
scp $binaryPath "root@172.16.1.1:/usr/local/sbin"
echo -e "\t...done!"
echo "[+] Goodbye!"