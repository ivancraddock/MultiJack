#!/bin/bash

# TODO:
# -- Identify if VLC is installed !? Display Error Message
# -- Identify if wmctrl is installed !? Display Error Message
# -- Identify if xdpyinfo is installed !? Display Error Message 
# -- Record which videos are played in a log file. Include a timestamp and information on which arguments that MultiJack was passed

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
file_location='/home/oem/Documents' ## $file_location is the directory that MultiJack will use to create and maintain it's Directory Pool. By default it is set to the default location for videos in Linux Mint
file_threshold=10 ## $file_threshold is the minimum number of files in the Directory Pool. If the number of files in the Directory Pool drops below this number, the Directory Pool will be refreshed.

case $1 in

    "--help")
    echo --refresh 1 2 3 4
    exit 1
        ;;  

    "--refresh") ## This option will delete the Directory Pool from the filesystem. When MultiJack will then recreate the Directory Pool the next time it is run with a standard argument (1-4)
    rm -r "$CACHE_DIR/POOL"
    exit 1 
        ;;    

    *) 
        ;;
esac

x_screen=$(echo `xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'` | cut -f1 -dx) ## These 2 lines set $x_screen and $y_screen equal to the corresponding pixel dimensions of the screen resolution.
y_screen=$(echo `xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'` | cut -f2 -dx) ## 
let x_window="x_screen/2 - 1" ## These 4 lines are used to calculate the size and screen-placement for the active VLC windows launched by MultiJack. The constants used are set for Linux Mint, and will ensure proper placement in Mint 19.1
let y_window="y_screen/2 - 29"
let x_offset="x_screen/2 + 11"
let y_offset="y_screen/2 + 64"

if [ ! -d "$CACHE_DIR/POOL" ]; then
    mkdir "$CACHE_DIR/POOL"
    touch "$CACHE_DIR/.multijack_logs"
fi

remaining_files=`ls "$CACHE_DIR/POOL" | wc -l` ## $remaining_files is the number of files remaining in the Directory Pool due to how `wc -l` displays data

if [ "$remaining_files" -lt "$file_threshold" ]; then ## This conditional checks if the Directory Pool has fallen below the number set by $file_threshold ? 
    let string_length="${#file_location} + 2" ## $string_length is the length of the string stored in $file_location + 2
    rm -r "$CACHE_DIR/POOL" ## The Directory Pool is deleted and recreated
    mkdir "$CACHE_DIR/POOL"
    for file_name in "$file_location"/*; do ## This loop iterates through every file in $file_location and creates a blank file with the same filename in the Directory Pool
        pool_name=`echo "$file_name"| cut -c "$string_length"-` ## $pool_name is the relative name of files in $file_location. The cut command is necessary to strip off the leading directory information.
        touch "$CACHE_DIR/POOL/$pool_name" ## A file with the correct name i
    done
fi

wmctrl -c "multijack_video_$1" ## Closes a VLC window that corresponds to the argument that was passed ("1" for Top Left, etc)
pkill -f "multijack_video_$1" ## necessary in Linux because of issuse with audio playing after video close. This has been necessary since the addition of the "-I dummy" args 

#next_file=`ls POOL | shuf -n 1`  ## Deprecated to eliminate shuf
let next_index="(($RANDOM%($remaining_files - 2)) + 2)" ## Testing out nested arethmatic statements in BASH
next_file=`ls "$CACHE_DIR/POOL" | awk '{if(NR=='"$next_index"') print $0}'` ## Mixed single and double quotes were needed to make awk function with a variable as input. Selects the filename based on its random index

echo "WINDOW_$1:`date`:$next_file" >> .multijack_logs ## records the video that was played, aloncd g with the window position and start time.
rm "$CACHE_DIR/POOL/$next_file" ## removes the selected file from the POOL, thus preventing its reselection

vlc --video-title="multijack_video_$1" "$file_location/$next_file" -I dummy & ## Creates a VLC video with a video title that corresponds to the argument passed to MultiJack

until [ -n "$(wmctrl -l | grep "multijack_video_$1" 2>&1)" ] ## This conditional will test if a window exists with the proper naming conventions. It will sleep the script until a window appears that matches these conventions.
do
sleep 1
done

case $1 in ## Depending on args this block will resize the window and place it correctly for Linux
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

