#!/usr/bin/env bash

while getopts ":f:s:i:n:v" opt; do
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
	-v <TRUE or FALSE>\n'
  exit 1
fi
 
#start mpv
 
 mpv --pause --loop-file=inf --quiet --no-audio --osd-level=0  --no-border --vo=opengl --scaler-lut-size=8 --scale=spline36 --cscale=spline36 --opengl-fbo-format=rgb16 --linear-scaling --geometry=x1080 --screenshot-template=%F_%ws --input-ipc-server=/tmp/mpvsocket "$file"  > /dev/null 2>&1 &

# Informations grabbing
#declare -r filename="$(basename "${file}")"
#declare -r lastFrame="$(mpv --term-playing-msg='frame=${estimated-frame-count}' --load-scripts=no --quiet --vo=null --ao=null --no-sub --no-cache --no-config --frames 1 "$file" | grep 'frame' | cut -d '=' -f2)"
#declare -r fpsVideo="$(mpv --term-playing-msg='fps=${estimated-vf-fps}' --load-scripts=no --quiet --vo null --ao=null --no-sub --no-cache --no-config --frames 1 "$file" | grep 'fps' | cut -d '=' -f2)"

sleep 1

 declare lastframe=$(echo '{ "command": ["get_property", "estimated-frame-count"]}' | socat - /tmp/mpvsocket | cut -d":" -f2 | cut -d , -f1) 

sleep 1

declare fpsVideo=$(echo '{ "command": ["get_property", "estimated-vf-fps"]}' | socat - /tmp/mpvsocket | cut -d":" -f2 | cut -d , -f1)



sleep 1

# Set flipBit
#Needed to correct math. Otherwise variable will be -1/25 of it's needed value, lowering (and reversing) seek.
#Change if deemed needed. It will increase/decrease the interval when using only the -s and -n switches. Using -i will bypass this.

 declare -r flipBit=-25
# Declare interval for each screenshot
if [[ -z "$intervalScreenshots" ]] ; then
  declare -r diffFrame="$(bc -l <<< "$lastFrame - $startFrame")"
  declare -r preFrame="$(bc -l <<< "$diffFrame / $numberScreenshots")"
  declare -r intervalFrame="$(bc -l <<< "$preFrame * $flipBit ")"
else
  declare -r intervalFrame="$intervalScreenshots"
fi

# Looping to take screenshots
declare currentFrame="$startFrame"
for i in $(seq 1 "$numberScreenshots") ; do
  
  declare currentTime="$(bc -l <<< "$currentFrame / $fpsVideo")"
  
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
   
   sleep 2
   
   echo '{ "command": ["seek", '$currentFrame', "absolute"] }' | socat - /tmp/mpvsocket
   
   sleep 2
   
   echo '{ "command": ["screenshot", "window"] }' | socat - /tmp/mpvsocket
   
   sleep 2
   
   

currentFrame="$(bc -l <<< "$currentFrame+$intervalFrame")"


done
