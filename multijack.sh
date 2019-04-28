#!/bin/bash

# TODO:
# -- Identify if VLC is installed, if not display error message
# -- Identify if wmctrl is installed, if not display error message

# Establish file location and critical threshold for refreshing POOL
file_location='/home/oem/Documents'
file_threshold=10
# Plays files from Document

case $1 in

    "--help")
    echo --refresh --prepare --restore
    exit 1
        ;;  

    "--refresh")
    rm -r POOL
    exit 1 
        ;;    

    # Logic for removing non-standard characters from filenames. All non-standard characters are converted to underscores
    # Original filenames are stored in a hidden subdirectory and can be recovered using the --restore command
    # UPDATE 04/28 This code doesn't appear to be necessary anymore as we have encapsulated all variable names in quotes
    "--prepare")
    mkdir "$file_location/.original_names"
    let string_length="${#file_location} + 2"
    for file_name in "$file_location/*"; do
        old_name=`echo "$file_name"| cut -c $string_length-`
        old_name="${old_name// /_}"
        new_name=`echo $old_name | sed -e 's/[^A-Za-z 0-9._-]/_/g'`
        echo $new_name >> new_name_logs
        touch $file_location/.original_names/$new_name
        echo "$file_name"> $file_location/.original_names/$new_name
        mv "$file_name" "$file_location/$new_name"
    done
    exit 1
        ;;
    
    # logic for restoring filenames that were altered by the --prepare command
    # UPDATE 04/28 This doesn't appear to be necessary because filename handling was fixed
    "--restore")
    for file_name in $file_location/.original_names/*; do
        temp_filename=$( cat $file_location/.original_names/$file_name )
        mv $file_location/$temp_filename $file_location/$file_name
    done
    exit 1
        ;;

    *) 
        ;;
esac

# Close empty VLC windows
while [ -n "$(wmctrl -l | grep 'N/A VLC media player' 2>&1)" ]; do
    wmctrl -i -c $(wmctrl -p -G -l | grep 'N/A VLC media player' | cut -c1-10)
done

# Calculate Screen Dimensions
x_screen=$(echo `xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'` | cut -f1 -dx)
y_screen=$(echo `xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'` | cut -f2 -dx)
let x_window="x_screen/2 - 1"
let y_window="y_screen/2 - 29"
let x_offset="x_screen/2 + 11"
let y_offset="y_screen/2 + 64"
# constants are for Linux Mint. May not be compatable with other distributions

# Evaluate if POOL exists. If Not, POOL is created with hidden subdirectories
if [ ! -d "POOL" ]; then
    mkdir POOL
    mkdir POOL/.1 POOL/.2 POOL/.3 POOL/.4
    touch POOL/.logs
    echo DIRECTORIES CREATED
fi


# Number of files left in POOL is counted. Hidden directories are excluded
remaining_files=`ls -l POOL | wc -l`

# Number of files in POOL is compared to threshold. If below threshold, POOL is reset
if [ "$remaining_files" -lt "$file_threshold" ]; then
    let string_length="${#file_location} + 2"
    for file_name in "$file_location"/*; do
        pool_name=`echo "$file_name"| cut -c "$string_length"-`

        touch "POOL/$pool_name"
    done
fi

# Reads head from subfolder and closes VLC with head name
wmctrl -c "multijack_video_$1"
pkill -f "multijack_video_$1" #necessary in Linux because of issuse with audio playing after video close. This has been necessary since the addition of the "-I dummy" args 


# Random file popped from POOL and added to hidden subfolder
next_file=`ls POOL | shuf -n 1`
echo "$next_file" >> POOL/.logs
touch "POOL/.$1/$next_file"
rm "POOL/$next_file"
#file can't be moved using mv as it will preserve original timestamp

# 
vlc --video-title="multijack_video_$1" "$file_location/$next_file" -I dummy & 
echo "$file_location/$next_file"

until [ -n "$(wmctrl -l | grep "multijack_video_$1" 2>&1)" ] # this is the key line
do
sleep 0.8
done

case $1 in
    "2")
        wmctrl -r "multijack_video_$1" -e 0,"$x_offset",0,"$x_window","$y_window"
        ;;
    "3")
        wmctrl -r "multijack_video_$1" -e 0,0,"$y_offset","$x_window","$y_window"
        ;;
    "4")
        wmctrl -r "multijack_video_$1" -e 0,"$x_offset","$y_offset","$x_window","$y_window"
        ;;
    *)
        wmctrl -r "multijack_video_$1" -e 0,0,0,"$x_window","$y_window"
        ;;
esac


