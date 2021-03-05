
IMG_ID="ami-0b396f8ba523***"
KEY_NAME="LAb4-***"
REGION="us-east-2"
SUBNET_ID1="subnet-eedc****"
SUBNET_ID2="subnet-7c3***"
LB_NAME="Lab4-ELB"



SG_ID=$(aws ec2 create-security-group \
        --group-name "Lab4-ELBTrain" \
        --description "22, 80" \
        --query 'GroupId' \
        --output text \
        --region $REGION)
        
echo "----> Security group created"


LB_ARN=$(aws elbv2 create-load-balancer \
     --name $LB_NAME \
     --type application \
     --scheme internet-facing \
     --subnets $SUBNET_ID1 $SUBNET_ID2 \
     --security-groups $SG_ID \
     --query 'LoadBalancers[0].LoadBalancerArn' \
     --output text)
echo "----> ELB created"


#Enable port 80
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
echo "----> 80 Ports enabled"


# Create key
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text \
    > MyKeyPair.txt
echo "----> Created key"


SG_ID2=$(aws ec2 create-security-group \
        --group-name "Lab4-ELBEc2" \
        --description "80" \
        --query 'GroupId' \
        --output text \
        --region $REGION)       
echo "----> Security group created"


aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID2 \
    --protocol tcp \
    --port 80 \
    --source-group $SG_ID
echo "----> add permission only for LoadBalancer"


#Create ec2 Instance
INS_ID1=$(aws ec2 run-instances \
            --image-id $IMG_ID \
            --count 1 \
            --instance-type t2.micro \
            --key-name $KEY_NAME \
            --security-group-ids $SG_ID2 \
            --query 'Instances[0].InstanceId' \
            --output text \
            --region $REGION \
            --subnet-id $SUBNET_ID1)


INS_ID2=$(aws ec2 run-instances \
            --image-id $IMG_ID \
            --count 1 \
            --instance-type t2.micro \
            --key-name $KEY_NAME \
            --security-group-ids $SG_ID2 \
            --query 'Instances[0].InstanceId' \
            --output text \
            --region $REGION \
            --subnet-id $SUBNET_ID1)
echo "---> Two instances from AMI created"



TG_ARN=$(aws elbv2 create-target-group \
    --name LAB4-targets \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id vpc-f4e04a9f \
    --query "TargetGroups[0].TargetGroupArn"\
    --output text)
 echo "----> target group created"   
 

sleep 30
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$INS_ID1


aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$INS_ID2
echo "-----> Targets registered"


aws elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN
echo "----> Listener created"
