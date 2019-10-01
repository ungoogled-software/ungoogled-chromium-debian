# set noninteractive installation
# From https://serverfault.com/a/949998
export DEBIAN_FRONTEND=noninteractive
apt-get install -y tzdata
# set your timezone
ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
