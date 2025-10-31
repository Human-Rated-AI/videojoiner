#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $(basename "$0") <number>"
    echo "       $(basename "$0") -o|--output <filename>"
    echo "       $(basename "$0") -d|--delete"
    echo
    echo "Joins matching video files from */Gemini/ and */Sora/ directories."
    echo "- Extends 8s horizontal 1280x720 Gemini videos to 10s"
    echo "- Scales 10s vertical 704x1280 Sora videos to 396x720"
    echo "- Joins them side by side into 10s 1676x720 videos"
    echo "- Outputs to parent directory with same name as source files"
    echo
    echo "Arguments:"
    echo "  <number>              Number of files to process"
    echo "  -o, --output <file>   Join all existing processed files into one output file"
    echo "  -d, --delete          Delete all processed files to start over"
    exit 0
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed" >&2
    exit 1
fi

cd "$(dirname "$0")"

# Delete mode
if [[ "$1" == "-d" || "$1" == "--delete" ]]; then
    deleted=0
    
    for gemini_file in */Gemini/*; do
        [[ -f "$gemini_file" ]] || continue
        
        base_dir=$(dirname "$(dirname "$gemini_file")")
        filename=$(basename "$gemini_file")
        name="${filename%.*}"
        
        for ext in mp4 MP4; do
            sora_file="$base_dir/Sora/$name.$ext"
            joined_file="$base_dir/$name.$ext"
            
            if [[ -f "$sora_file" && -f "$joined_file" ]]; then
                rm "$joined_file"
                echo "Deleted: $joined_file"
                ((deleted++))
                break
            fi
        done
    done
    
    if [[ $deleted -eq 0 ]]; then
        echo "No processed files found to delete"
    else
        echo "Deleted $deleted file(s)"
    fi
    exit 0
fi

# Output mode
if [[ "$1" == "-o" || "$1" == "--output" ]]; then
    if [[ -z "$2" ]]; then
        echo "Error: output filename required" >&2
        exit 1
    fi
    
    output_file="$2"
    concat_list="/tmp/concat_$$.txt"
    > "$concat_list"
    
    echo "Finding files to join..."
    
    for gemini_file in */Gemini/*; do
        [[ -f "$gemini_file" ]] || continue
        
        base_dir=$(dirname "$(dirname "$gemini_file")")
        filename=$(basename "$gemini_file")
        name="${filename%.*}"
        
        for ext in mp4 MP4; do
            sora_file="$base_dir/Sora/$name.$ext"
            joined_file="$base_dir/$name.$ext"
            
            if [[ -f "$sora_file" && -f "$joined_file" ]]; then
                echo "file '$PWD/$joined_file'" >> "$concat_list"
                echo -e "  $joined_file\033[K"
                break
            fi
        done
    done
    
    if [[ ! -s "$concat_list" ]]; then
        echo "No processed files found to join"
        rm "$concat_list"
        exit 0
    fi
    
    echo -ne "Joining into: $output_file\033[K\r"
    ffmpeg -f concat -safe 0 -i "$concat_list" -c copy "$output_file" -y -loglevel error || exit 1
    rm "$concat_list"
    echo -e "Created: $output_file\033[K"
    exit 0
fi

# Process mode
if [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: $(basename "$0") <number>"
    echo "       $(basename "$0") -o|--output <filename>"
    exit 0
fi

max_files=$1
processed=0

for gemini_file in */Gemini/*; do
    [[ -f "$gemini_file" ]] || continue
    
    base_dir=$(dirname "$(dirname "$gemini_file")")
    filename=$(basename "$gemini_file")
    name="${filename%.*}"
    
    for ext in mp4 MP4; do
        sora_file="$base_dir/Sora/$name.$ext"
        output_file="$base_dir/$name.$ext"
        
        if [[ -f "$sora_file" && ! -f "$output_file" ]]; then
            gemini_10s="${gemini_file%.*}_10s.mp4"
            sora_720p="${sora_file%.*}_720p.$ext"
            
            echo -ne "Extending to 10s: $gemini_file\033[K\r"
            ffmpeg -i "$gemini_file" -vf "tpad=stop_mode=clone:stop_duration=2" -af "apad=whole_dur=10" "$gemini_10s" -y -loglevel error || exit 1
            
            echo -ne "Converting to 720p: $sora_file\033[K\r"
            ffmpeg -i "$sora_file" -vf "scale=-2:720" -c:a copy "$sora_720p" -y -loglevel error || exit 1
            
            echo -ne "Joining into: $output_file\033[K\r"
            ffmpeg -i "$gemini_10s" -i "$sora_720p" -filter_complex "[0:v][1:v]hstack=inputs=2[v];[0:a]aresample=48000[a0];[1:a]aresample=48000[a1];[a0][a1]amix=inputs=2:duration=longest[a]" -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset fast -c:a aac -ar 48000 "$output_file" -y -loglevel error || exit 1
            
            rm "$gemini_10s" "$sora_720p"
            
            echo -e "Created: $output_file\033[K"
            
            ((processed++))
            [[ $processed -ge $max_files ]] && exit 0
            break
        fi
    done
done

if [[ $processed -eq 0 ]]; then
    echo "No files to process found"
fi
