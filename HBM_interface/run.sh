xbutil reset --device 0000:4e:00.1
# sudo modprobe -r xocl
# sudo modprobe -r xclmgmt 
# sudo modprobe xclmgmt
sudo modprobe xocl
sleep 10
xbutil examine
#make host TARGET=hw
# make run_prepare TARGET=hw