#!/usr/bin/env bash

while getopts ":f:s:i:n:g:v:" opt; do
  case $opt in
    f)
      declare -r file="$OPTARG"
      ;;
    s)
      declare -r startFrame="$OPTARG"
      ;;
    i)
      declare -r intervalScreenshots="$OPTARG"
      ;;
    n)
      declare -r numberScreenshots="$OPTARG"
      ;;
    g) 
      declare -r videoHeight="$OPTARG"
      ;;
    v)
      declare -r verbose="TRUE"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Quit if we missed -f, -s or -n
if [[ -z "$file" ]] || [[ -z "$startFrame" ]] || [[ -z "$numberScreenshots" ]] ; then
  printf 'You must at the minimum set -f, -s and -n
	-f <the video file>
	-s <the number of the frame of the first screenshot>
	-i <the interval of frames of the next screenshot>
	-n <the number of screenshots you want>
	-g <the desired display resolution>
	-v <TRUE or FALSE>\n'
  exit 1
fi

 #make Folder
mkdir "$(basename "${file}" | cut -d "." -f1)"

 #start mpv
 
 mpv --pause --quiet --no-osc --no-audio --osd-level=0  --no-border --vo=opengl --framedrop=no --scaler-lut-size=8 --scale=spline36 --cscale=spline36 --opengl-fbo-format=rgb16 --linear-scaling --geometry="$videoHeight" --screenshot-template=%F_%ws --screenshot-format=png --screenshot-png-compression=5 --screenshot-directory="$(basename "${file}" | cut -d "." -f1)" "$file" --input-ipc-server=/tmp/mpvsocket  > /dev/null 2>&1 &
 
 
# Informations grabbing
declare -r filename="$(basename "${file}" )"

 sleep 1

 declare -r lastFrame="$(echo '{ "command": ["get_property", "estimated-frame-count"]}' | socat - /tmp/mpvsocket | cut -d":" -f2 | cut -d , -f1)" 
 
 sleep 1

 declare -r fpsVideo="$(echo '{ "command": ["get_property", "estimated-vf-fps"]}' | socat - /tmp/mpvsocket | cut -d":" -f2 | cut -d , -f1)"



 sleep 1

# Declare interval for each screenshot
if [[ -z "$intervalScreenshots" ]] ; then
  declare -r diffFrame="$(awk "BEGIN {printf $lastFrame - $startFrame}")"
  declare -r intervalFrame="$(awk "BEGIN {printf $diffFrame / $numberScreenshots}")"
  
else
  declare -r intervalFrame="$intervalScreenshots"
fi

# Looping to take screenshots
declare currentFrame="$startFrame"
for i in $(seq 1 "$numberScreenshots") ; do
  
   declare currentTime="$(awk "BEGIN {printf $currentFrame / $fpsVideo}")"
  
  if [[ -n "$verbose" ]] ; then
    printf 'Filename: %s\n\n' "$filename"
 
    printf 'Current time: %.2f\n\n' "$currentTime"
    
    printf 'Last frame: %s\n' "$lastFrame"
    printf 'FPS: %s\n' "$fpsVideo"
    printf 'Interval: %s\n' "$intervalFrame"
    printf 'Screenshot: %02d\n\n\n' "$i"
  
 fi
  # Debug line
  # mpv --really-quiet --load-scripts=no --no-audio --no-sub --frames 1 --start "$currentTime" "$file" -o "${filename%.*}_${currentTime%%0*}.png"

   
   
   
   
   echo '{ "command": ["set_property", "pause", true] }'	| socat - /tmp/mpvsocket
  
   sleep 1
   
   echo '{ "command": ["seek", '$currentTime', "absolute" ] }' | socat - /tmp/mpvsocket
   
   sleep 1
   
   echo '{ "command": ["screenshot", "window"] }' | socat - /tmp/mpvsocket
   
   sleep 1
   
   

currentFrame="$(awk "BEGIN {printf $currentFrame+$intervalFrame}")"



done

pkill mpv

exit
