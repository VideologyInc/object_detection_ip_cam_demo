#!/usr/bin/env bash

gst-launch-1.0 \
    rtspsrc location=rtsp://admin:admin1234@10.105.1.41:554/rtsp_stream_02 latency=0 ! \
    rtph264depay ! h264parse ! avdec_h264 ! \
    videoconvert ! videoscale ! videorate ! video/x-raw,width=640,height=640,framerate=15/1 ! \
    tee name=t \
    t. ! queue leaky=2 max-size-buffers=2 ! \
    videoconvert ! videoscale ! video/x-raw,width=320,height=320,format=RGB ! \
    tensor_converter ! \
    tensor_filter latency=1 framework=tensorflow2-lite model=yolov8n_int8_320.tflite \
    custom=Delegate:External,ExtDelegateLib:libvx_delegate.so accelerator=true:npu ! \
    tensor_transform mode=transpose option=1:0:2:3 ! \
    tensor_transform mode=arithmetic option=typecast:float32,add:-1,mul:0.005010209511965513 ! \
    tensor_decoder mode=bounding_boxes option1=yolov8 option2=coco.txt option4=640:640 option5=320:320 ! \
    videoconvert ! mix.sink_0 \
    t. ! queue leaky=2 max-size-buffers=2 ! videoconvert ! mix.sink_1 \
    compositor name=mix sink_0::zorder=2 sink_1::zorder=1 ! \
    videoconvert ! autovideosink sync=false