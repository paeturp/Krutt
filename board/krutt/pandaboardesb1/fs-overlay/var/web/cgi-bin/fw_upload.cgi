#!/bin/sh
#
#
#
VOL=/data
DIR=$VOL/updates

mount $VOL
if [ ! -d $DIR ]
then
    mkdir -p $DIR
fi

file=$DIR/PayLoad_$$-$RANDOM

LOCK=/var/lock/fw_upload.lock


CR=`printf '\r'`

# CGI output must start with at least empty line (or headers)
printf '\r\n'

IFS="$CR"
read -r delim_line
IFS=""

# Create a lock file
if [ -e $LOCK ]
then 
    cat > /dev/null
    printf "\n\n<html>\n<body>\nMalformed lock-file found on target." 
    sync
    exit 1
fi 

# Create a lock file.
echo -n " " > $LOCK 

while read -r line; do
    test x"$line" = x"" && break
    test x"$line" = x"$CR" && break
done

cat >"$file"

sync

# We need to delete the tail of "\r\ndelim_line--\r\n"
tail_len=$((${#delim_line} + 6))

# Get and check file size
filesize=`stat -c"%s" "$file"`
test "$filesize" -lt "$tail_len" && exit 1

# Check that tail is correct
dd if="$file" skip=$((filesize - tail_len)) bs=1 count=1000 >"$file.tail" 2>/dev/null
sync
printf "\r\n%s--\r\n" "$delim_line" >"$file.tail.expected"
if ! diff -q "$file.tail" "$file.tail.expected" >/dev/null
then
    printf "\n\n<html>\n<body>\nMalformed file upload"
    sync
    exit 1
fi

rm "$file.tail"
rm "$file.tail.expected"

# Truncate the file
dd of="$file" seek=$((filesize - tail_len)) bs=1 count=0 >/dev/null 2>/dev/null

printf "\n\n<html>\n<body>\nFile upload has been accepted<br><br>"
printf "<pre>\n"

filesize2=`stat -c"%s" "$file"`

# Strip signature of the zipped tar file.
split -b $((filesize2 - 44)) $file $DIR/SV_
rm -rf $file
sync

# Check if signature of tar file.
if [ -e $DIR/SV_ab ]
then 
    echo "krutt installation secure hash key" | cat $DIR/SV_aa - | sha1sum -s -c $DIR/SV_ab 
    if [ $? -eq 0 ]
    then 

        # Unzip and untar tar file.
        zcat $DIR/SV_aa | tar -C $DIR -xf -
        
        # Update file system
        sync

        # Run the install script if it exits.
        if [ -x $DIR/Install.sh ]
        then
            cd $DIR
            $DIR/Install.sh
        else
            echo "Error: Could not execute install script!"
        fi
    else 
        echo "Error: Wrong signature!" 
    fi 
else
    echo "Error: Signature does not exist!"
fi

printf "</pre>\n"
printf "</body></html>\n"

# Remove temp files.
if [ -e $DIR/SV_aa ]
then
    rm -rf $DIR/SV_aa 
    if [ -e $DIR/SV_ab ]
    then
        rm -rf $DIR/SV_ab
    fi
fi

# Remove lock file
rm -rf $LOCK
 
