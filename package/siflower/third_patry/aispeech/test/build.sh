if [[ -z $1 ]]; then
	echo "usage: ./build.sh target_platform module_name"
elif [[ -z $2 ]]; then
	echo "usage: ./build.sh target_platform module_name"
else
	make TARGET_PLATFORM=$1 MODULE_NAME=$2 clean all
fi