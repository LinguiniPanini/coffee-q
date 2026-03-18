#!/bin/bash

AWS_REGION="us-east-1"
KEY_FILE="$(dirname "$0")/infra/coffee-orders-key.pem"
EC2_IP="54.90.95.86"
SSH_OPTS="-i $KEY_FILE -o StrictHostKeyChecking=no"
SQS_QUEUE_URL="https://sqs.us-east-1.amazonaws.com/027265528584/coffee-orders-queue"
RDS_HOST="coffee-orders-db.cwdk0au0k2xu.us-east-1.rds.amazonaws.com"
RDS_DB="coffee_shop"
RDS_USER="dbadmin"
RDS_PASSWORD="CoffeeShop2026!"

# copiar app a EC2
scp $SSH_OPTS -r "$(dirname "$0")/app" "ec2-user@${EC2_IP}":~/

# instalar dependencias
ssh $SSH_OPTS "ec2-user@${EC2_IP}" "sudo dnf install -y python3-pip && pip3 install -r ~/app/requirements.txt"

# iniciar consumer
ssh $SSH_OPTS "ec2-user@${EC2_IP}" "
    export AWS_REGION=$AWS_REGION
    export SQS_QUEUE_URL=$SQS_QUEUE_URL
    export RDS_HOST=$RDS_HOST
    export RDS_DB=$RDS_DB
    export RDS_USER=$RDS_USER
    export RDS_PASSWORD=$RDS_PASSWORD
    nohup python3 ~/app/consumer.py > ~/consumer.log 2>&1 &
"

echo "Logs: ssh $SSH_OPTS ec2-user@$EC2_IP 'tail -f ~/consumer.log'"
