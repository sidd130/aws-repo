import json
import os
import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Lambda handler to associate EIP with new EC2 instance in ASG
    """
    ec2_client = boto3.client('ec2')
    eip_allocation_id = os.environ['EIP_ALLOCATION_ID']
    
    try:
        # Parse the SNS message from ASG
        message = json.loads(event['Records'][0]['Sns']['Message'])
        instance_id = message['EC2InstanceId']
        
        # Associate EIP with the new instance
        response = ec2_client.associate_address(
            AllocationId=eip_allocation_id,
            InstanceId=instance_id
        )
        
        logger.info(f"Successfully associated EIP {eip_allocation_id} with instance {instance_id}")
        return {
            'statusCode': 200,
            'body': json.dumps('EIP association successful')
        }
        
    except Exception as e:
        logger.error(f"Error associating EIP: {str(e)}")
        raise