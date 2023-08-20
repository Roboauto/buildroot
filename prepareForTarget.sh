#!/bin/bash

# Accept 2 arguments -> where the buildroot output archive is, and where to put modified archive
# Help func
function help {
	echo "Usage: $0 <buildroot output archive> <modified archive>"
	echo "For progress use env variable named SHOW_PROGRESS"
}

# Check if 2 arguments are given. 
if [ $# -ne 2 ]; then
	help
	exit 1
fi

# Check if the first argument is a file
if [ ! -f $1 ]; then
	help
	exit 1
fi

# Check if the second argument is a directory, if doesn't exist, offer to create it.
if [ ! -d $2 ]; then
	# Qoute the path so it is more readable
	qoutedPath="\"$2\""
	
	echo "Directory $qoutedPath does not exist. Do you want to create it? [y/n]"
	read answer
	if [ "$answer" == "y" ]; then
		mkdir -p $2
	else
		exit 1
	fi
fi

# Check if the second argument is writable
if [ ! -w $2 ]; then
	echo "Directory $2 is not writable."
	exit 1
fi

# If not empty directory, offer to empty it
if [ "$(ls -A $2)" ]; then
	echo "Directory $2 is not empty. Do you want to empty it? [y/n]"
	read answer
	if [ "$answer" == "y" ]; then
		rm -rf $2/*
	else
		exit 1
	fi
fi


# Extract the archive to the target directory
tar -xf $1 -C $2

currentDir=$(pwd)
# Go to the target directory
cd $2

# Progress argument is optional based on SHOW_PROGRESS env variable
progress_shown=""
if [ "$SHOW_PROGRESS" == "1" ]; then
	progress_shown="--progress"
fi

# Inform user that the progress is shown
if [ "$progress_shown" != "" ]; then
	echo "Progress is shown."
fi


# Copy the libraries to the correct location. Print with green color.
echo -e "\e[32mCopying libraries to the correct location.\e[0m"
find ./usr/lib -maxdepth 1 -type f -exec rsync -azhHl --remove-source-files $progress_shown {} ./usr/lib/aarch64-linux-gnu/ \;
find ./usr/lib -maxdepth 1 -type l -exec rsync -azhHl --remove-source-files $progress_shown {} ./usr/lib/aarch64-linux-gnu/ \;
find ./usr/lib/aarch64-linux-gnu/ -type l -lname "../*" -exec sh -c 'ln -sf ../$(readlink "$0") "$0"' {} \;    

rsync -azhHl --remove-source-files $progress_shown ./lib/* ./lib/aarch64-linux-gnu/
rsync -azhHl --remove-source-files $progress_shown ./lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 ./lib/

# Copy includes to the correct location
echo -e "\e[32mCopying includes to the correct location.\e[0m"
# Print cwd
echo "Current working directory: $(pwd)"
mkdir -p ./usr/include/aarch64-linux-gnu
mv ./usr/include/bits ./usr/include/aarch64-linux-gnu
mv ./usr/include/gnu ./usr/include/aarch64-linux-gnu
mv ./usr/include/sys ./usr/include/aarch64-linux-gnu
mv ./usr/include/fpu_control.h ./usr/include/aarch64-linux-gnu
mv ./usr/include/a.out.h ./usr/include/aarch64-linux-gnu
mv ./usr/include/ieee754.h ./usr/include/aarch64-linux-gnu

mv ./usr/include/asm ./usr/include/aarch64-linux-gnu

# Fix the links
echo -e "\e[32mFixing links.\e[0m"
find ./usr/lib/aarch64-linux-gnu/ -type l -lname "../../../lib/*" -exec sh -c 'ln -sf ../../../lib/aarch64-linux-gnu/$(basename "$(readlink "$0")") "$0"' {} \;
# rm this file as it contains loader path, which is correct on the jetsons, so we don't want to overwrite it
echo -e "\e[32mRemoving libc.so to keep the correct loader path.\e[0m"
rm ./usr/lib/aarch64-linux-gnu/libc.so

# Cleanup unnecessary directories
# dev, etc, media, mnt, proc, run, sys, tmp, var, opt, root
echo -e "\e[32mCleaning up unnecessary directories.\e[0m"
rm -rf ./dev ./etc ./media ./mnt ./proc ./run ./sys ./tmp ./var ./opt ./root


# on host
# rsync -arl usr/lib/aarch64-linux-gnu/libstdc++* /lib/aarch64-linux-gnu/
# maybe symlink from usr/lib64 to usr/lib?
# Ask user if he wants to archive the target directory
echo "Do you want to archive the target directory? [y/n]"
read answer
if [ "$answer" == "y" ]; then
	echo -e "\e[32mArchiving the target directory.\e[0m"
	echo "tar -czf $currentDir/target.tar.gz *"
	tar -czf $currentDir/target.tar.gz *
fi

