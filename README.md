# Object Detection IP Camera Demo

## Setup
- Git clone the repository on your SCAiLX

## Run the Demo
- Run the demo directly using our global shutter camera: 
    ```
    bash demo.sh
    ```

## Run the IP Camera Demo
- Identify your video input stream link e.g **rtsp://admin:admin1234@10.105.1.41:554/rtsp_stream_02** 
- Set the resolution video at width 1280 and height 720 , the requires framerate should be at 30 FPS.
- Run the demo with the video input stream link:
    ```
    bash ip_demo.sh rtsp://USERNAME:PASSWORD@IP:PORT/stream
    ```
- Run the demo with video input stream link, width and height:
    ```
    bash ip_demo.sh rtsp://USERNAME:PASSWORD@IP:PORT/stream 1280 720
    ```

## Result
- Open the browser http://scailx-ai.local:8091 or http://IPADDRESS:8091 to see the result.