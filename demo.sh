#!/bin/bash

gst-launch-1.0 \
    v4l2src device=/dev/video0 ! \
    video/x-raw,pixel-aspect-ratio=1/1,width=1280,height=720,framerate=30/1 ! \
    tee name=t \
    t. ! queue max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    imxvideoconvert_g2d ! \
    videoconvert ! \
    video/x-raw,format=RGB,width=320,height=320 ! \
    tensor_converter ! \
    queue max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_filter latency=1 framework=tensorflow2-lite model=yolov8n_int8_320.tflite \
    custom=Delegate:External,ExtDelegateLib:libvx_delegate.so \
    accelerator=true:npu ! \
    queue max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_transform mode=transpose option=1:0:2:3 ! \
    queue max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    tensor_transform mode=arithmetic option=typecast:float32,mul:0.00513091403990984 ! \
    tensor_decoder mode=bounding_boxes option1=yolov8 option2=coco.txt option4=1280:720 option5=320:320 ! \
    videoconvert ! \
    mix.sink_0 \
    t. ! queue max-size-buffers=5 max-size-bytes=0 max-size-time=0 ! \
    videoconvert ! \
    mix.sink_1 \
    imxcompositor_g2d name=mix sink_0::zorder=2 sink_1::zorder=1 ! \
    queue ! \
    imxvideoconvert_g2d ! \
    queue ! \
    vpuenc_h264 bitrate=3000 ! \
    video/x-h264,profile=baseline,stream-format=byte-stream ! \
    websink 

    