#! /bin/bash
sudo touch /etc/cron.daily/docker-prune

cat << EOF | sudo tee -a /etc/cron.daily/docker-prune
#!/bin/bash 
sudo docker system prune -af  --filter "until=$((30*24))h"
EOF