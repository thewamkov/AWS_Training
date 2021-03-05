#!/bin/bash
IMG_ID="ami-03657b56516a***"
USER_DATA='file://userdata.sh'
SSH_KEY="output.txt"
KEY_NAME="***"
REGION="us-east-2"
SUBNET_ID="subnet-eed****"


 # Create security group inside VPC
SG_ID=$(aws ec2 create-security-group \
        --group-name "Lab3" \
        --description "22, 80, 443" \
        --query 'GroupId' \
        --output text \
        --region $REGION)
        
echo "Security group created"


# Enable SSH Access port 22
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \


#Enable port 80
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \


# Enable port 443
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \


echo "Port enabled "
# Create key
aws ec2 create-key-pair \
    --key-name lab3 \
    --query 'KeyMaterial' \
    --output text \
    > MyKeyPair.txt


aws ec2 modify-subnet-attribute \
     --subnet-id $SUBNET_ID \
     --map-public-ip-on-launch

echo "Created key"


#Create ec2 Instance
INS_ID=$(aws ec2 run-instances \
            --image-id $IMG_ID \
            --count 1 \
            --instance-type t2.micro \
            --key-name lab3\
            --security-group-ids $SG_ID \
            --subnet-id $SUBNET_ID \
            --user-data $USER_DATA \
            --query 'Instances[0].{InstanceId:InstanceId}' \
            --output text \
            --region $REGION)

echo "Created ec2 instance"


#Create tag
aws ec2 create-tags \
    --resources $INS_ID \
    --tags "Key=Apache, Value=lab3" \
    --region $REGION

echo "Created tag"
sleep 40


#Create ec2 instance
IMGI_ID=$(aws ec2 create-image \
    --instance-id $INS_ID \
    --name "My server" \
    --query "ImageId" \
    --output text)

echo $IMGI_ID
echo "Image created"


sleep 180
#Delete ec2 instance
aws ec2 terminate-instances \
    --instance-ids $INS_ID


INS_ID=$(aws ec2 run-instances \
            --image-id $IMGI_ID \
            --count 1 \
            --instance-type t2.micro \
            --key-name lab3\
            --security-group-ids $SG_ID \
            --subnet-id $SUBNET_ID \
            --user-data $USER_DATA \
            --query 'Instances[0].{InstanceId:InstanceId}' \
            --output text \
            --region $REGION)

echo "Created ec2 from image"


# Delete security group
# aws ec2 delete-security-group \
#     --group-id $SG_ID


