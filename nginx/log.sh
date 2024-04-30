#! /bin/bash
sudo touch /etc/logrotate.d/nginx

cat << EOF | sudo tee -a /etc/logrotate.d/nginx
/mnt/docker/nginx/logs/*.log {
    daily
    dateext
    missingok
    rotate 999
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
    docker kill nginx -s USR1
    endscript
}
EOF