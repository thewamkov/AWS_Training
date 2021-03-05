REGION="us-east-2"
ELB_ARN="arn:aws:.."
TG_ARN="arn:aws..."
EMAIL="*********@gmail.com"



TOPIC_ARN=$(aws sns create-topic \
        --name lab5 \
        --query "TopicArn" \
        --output text)
echo "!   Topic created"
echo "$TOPIC_ARN"


SUB_ARN=$(aws sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol email \
    --notification-endpoint $EMAIL \
    --query "SubscriptionArn" \
    --output text)
echo "!  sns subscription created"
echo "$SUB_ARN"


aws cloudwatch put-metric-alarm \
    --alarm-name healthyCheck \
    --alarm-description "Health Alarm" \
    --metric-name HealthyHostCount \
    --namespace AWS/ApplicationELB \
    --statistic Minimum \
    --period 300 \
    --threshold 2 \
    --evaluation-periods 2 \
    --comparison-operator LessThanThreshold \
    --dimensions Name=LoadBalancer,Value=app/Lab4-ELB/c7f5eea4a2ca3d81 Name=TargetGroup,Value=targetgroup/LAB4-targets/634f6325a3d5bd24 \
    --alarm-actions $TOPIC_ARN \
    --unit Count
    echo "alarm metric created"