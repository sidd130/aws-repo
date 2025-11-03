import json
import os
import boto3
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Lambda handler to associate EIP and complete lifecycle action
    """
    ec2_client = boto3.client('ec2')
    asg_client = boto3.client('autoscaling')
    eip_allocation_id = os.environ['EIP_ALLOCATION_ID']
    
    try:
        # Parse the SNS message from ASG
        message = json.loads(event['Records'][0]['Sns']['Message'])
        instance_id = message['EC2InstanceId']
        
        # Extract lifecycle information
        asg_name = message['AutoScalingGroupName']
        lifecycle_hook_name = message['LifecycleHookName']
        lifecycle_action_token = message['LifecycleActionToken']
        
        # Associate EIP with the new instance
        response = ec2_client.associate_address(
            AllocationId=eip_allocation_id,
            InstanceId=instance_id
        )
        logger.info(f"Successfully associated EIP {eip_allocation_id} with instance {instance_id}")
        
        # Complete the lifecycle action
        asg_client.complete_lifecycle_action(
            LifecycleHookName=lifecycle_hook_name,
            AutoScalingGroupName=asg_name,
            LifecycleActionToken=lifecycle_action_token,
            InstanceId=instance_id,
            LifecycleActionResult='CONTINUE'
        )
        logger.info(f"Successfully completed lifecycle action for instance {instance_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('EIP association and lifecycle completion successful')
        }
        
    except Exception as e:
        logger.error(f"Error in lambda execution: {str(e)}")
        # If there's an error, try to complete the lifecycle action with ABANDON
        try:
            if 'asg_name' in locals() and 'lifecycle_hook_name' in locals() and 'lifecycle_action_token' in locals():
                asg_client.complete_lifecycle_action(
                    LifecycleHookName=lifecycle_hook_name,
                    AutoScalingGroupName=asg_name,
                    LifecycleActionToken=lifecycle_action_token,
                    InstanceId=instance_id,
                    LifecycleActionResult='ABANDON'
                )
                logger.info("Lifecycle action abandoned due to error")
        except Exception as complete_error:
            logger.error(f"Error completing lifecycle action: {str(complete_error)}")
        raise