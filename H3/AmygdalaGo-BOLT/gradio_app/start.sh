sh stop.sh
nohup python gradio_app_release.py &
netstat -an | grep 6006