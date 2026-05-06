#!/bin/bash
# Usage: 
#   bash object_detection_demo.sh <rtsp_url> [width] [height]
# Example: 
#   bash object_detection_demo.sh rtsp://admin:admin1234@10.105.1.41:554/rtsp_stream_02
#   bash object_detection_demo.sh rtsp://... 640 480

RTSP_URL=$1
WIDTH=${2:-640}
HEIGHT=${3:-480}

if [ -z "$RTSP_URL" ]; then
    echo "Usage: $0 rtsp://USERNAME:PASSWORD@IP:PORT/stream"
    exit 1
fi

gst-launch-1.0 \
    rtspsrc location=$RTSP_URL latency=0 ! \
    rtph264depay ! h264parse ! avdec_h264 ! \
    tee name=t \
    t. ! queue leaky=2 max-size-buffers=2 ! \
    videoconvert ! videoscale ! video/x-raw,format=RGB,width=320,height=320 ! \
    tensor_converter ! \
    tensor_filter latency=1 framework=tensorflow2-lite model=yolov8n_int8_320.tflite \
    custom=Delegate:External,ExtDelegateLib:libvx_delegate.so accelerator=true:npu ! \
    tensor_transform mode=transpose option=1:0:2:3 ! \
    tensor_transform mode=arithmetic option=typecast:float32,mul:0.00513091403990984 ! \
    tensor_decoder mode=bounding_boxes option1=yolov8 option2=coco.txt option4=${WIDTH}:${HEIGHT} option5=320:320 ! \
    videoconvert ! \
    mix.sink_0 \
    t. ! queue leaky=2 max-size-buffers=2 ! \
    videoconvert ! \
    mix.sink_1 \
    compositor name=mix sink_0::zorder=2 sink_1::zorder=1 ! \
    videoconvert ! autovideosink sync=false