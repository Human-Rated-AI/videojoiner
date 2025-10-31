# Video Joining Script

A bash script to join horizontal and vertical videos side by side.

## Example

See the result of this script in action:
[Gemini Veo 3.1 vs Sora 2: the same prompts](https://youtu.be/T4WZjyJQQTA)

## Requirements

- ffmpeg

## Directory Structure

The script expects videos in the following structure:
```
project/
├── join_videos.sh
├── DIR1/
│   ├── Gemini/
│   │   └── video_name.mp4    (8s, 1280x720, horizontal)
│   └── Sora/
│       └── video_name.mp4    (10s, 704x1280, vertical)
├── DIR2/
│   ├── Gemini/
│   │   └── video_name.mp4
│   └── Sora/
│       └── video_name.mp4
└── ...
```

The script should be placed at the same level as the directories containing Gemini/ and Sora/ subdirectories.

## Usage

### Process videos
```bash
./join_videos.sh <number>
```
Processes the specified number of video pairs:
- Extends Gemini videos from 8s to 10s (pads last frame for 2s)
- Scales Sora videos to 720p (396x720)
- Joins them side by side into 1676x720 videos
- Merges audio from both sources
- Outputs to `DIR/video_name.mp4`

### Join all processed videos
```bash
./join_videos.sh -o output.mp4
```
Concatenates all processed videos into a single output file.

### Delete processed videos
```bash
./join_videos.sh -d
```
Deletes all processed videos to start over.

### Help
```bash
./join_videos.sh -h
```
Shows usage information.

## Examples

```bash
# Process 5 video pairs
./join_videos.sh 5

# Process all available pairs
./join_videos.sh 100

# Join all processed videos
./join_videos.sh -o final.mp4

# Delete all processed videos
./join_videos.sh -d
```
