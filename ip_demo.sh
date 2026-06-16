#!/bin/bash
# Usage: 
#   bash object_detection_demo.sh <rtsp_url> [width] [height]
# Example: 
#   bash object_detection_demo.sh rtsp://admin:admin1234@10.105.1.41:554/rtsp_stream_02
#   bash object_detection_demo.sh rtsp://10.105.1.43:8554/cam0-gs-AR0234_0_1280x720_NV12_fps=30

RTSP_URL=$1
WIDTH=${2:-1280}
HEIGHT=${3:-720}

if [ -z "$RTSP_URL" ]; then
    echo "Usage: $0 rtsp://USERNAME:PASSWORD@IP:PORT/stream"
    exit 1
fi

gst-launch-1.0 \
    rtspsrc location=$RTSP_URL latency=0 ! \
    rtph264depay ! \
    queue ! \
    vpudec ! \
    imxvideoconvert_g2d ! \
    queue ! \
    tee name=t \
    t. ! queue leaky=2 max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    imxvideoconvert_g2d ! \
    videoscale ! \
    videoconvert ! \
    video/x-raw,format=RGB,width=320,height=320 ! \
    tensor_converter ! \
    queue leaky=2 max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_filter latency=1 framework=tensorflow2-lite model=yolov8n_int8_320.tflite \
    custom=Delegate:External,ExtDelegateLib:libvx_delegate.so \
    accelerator=true:npu ! \
    queue leaky=2 max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_transform mode=transpose option=1:0:2:3 ! \
    queue leaky=2 max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_transform mode=arithmetic option=typecast:float32,mul:0.00513091403990984 ! \
    tensor_decoder mode=bounding_boxes option1=yolov8 option2=coco.txt option4=${WIDTH}:${HEIGHT} option5=320:320 ! \
    videoconvert ! \
    mix.sink_0 \
    t. ! queue leaky=2 max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    imxvideoconvert_g2d ! \
    video/x-raw,width=${WIDTH},height=${HEIGHT} ! \
    videoscale ! \
    videoconvert ! \
    mix.sink_1 \
    imxcompositor_g2d \
    name=mix sink_0::zorder=2 sink_1::zorder=1 ! \
    queue ! \
    imxvideoconvert_g2d ! \
    queue ! \
    vpuenc_h264 bitrate=3000 ! \
    video/x-h264,profile=baseline,stream-format=byte-stream ! \
    websink 