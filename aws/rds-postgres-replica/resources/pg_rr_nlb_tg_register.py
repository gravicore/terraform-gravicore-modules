
import boto3
import botocore
import os
import socket
import json
from datetime import datetime
os.sys.path.append('/opt')

from logger import logger
import alert_support as alerting

## From Datadog layer ##
from datadog import initialize, api
from datadog_lambda.wrapper import datadog_lambda_wrapper

@datadog_lambda_wrapper
def handler(event, context):
    ### setup log function ####
    func_log = logger('func_log')
    func_log.log_entry('RDS events function begin.')
    print(event)

    alrt_mess = {'alert_source':'rds_events'}

    tags=['lambda:{0}'.format(os.environ['AWS_LAMBDA_FUNCTION_NAME']),
                        'alerttime:{0}'.format(datetime.now().strftime('%Y%m%d|%H%M%S'))]

    dd_metric = 'aws.lambda.alert.rds.monitor'

    ### get environment variables ####
    stage = os.environ['stage']
    mod_prefix = os.environ['module_prefix']
    region = os.environ['aws_region']
    stage_pre = os.environ['stage_prefix']
    rds_mas_id = os.environ['rds_master_instance_id']
    nlb_tar = os.environ['nlb_target_group']

    session = boto3.Session()
    s3c = session.client('s3', region_name=region)
    stsc = session.client('sts')
    acc_id = stsc.get_caller_identity()['Account']
    ssmc = session.client('ssm')
    elbc = session.client('elbv2')
    rdsc = session.client('rds')

    dd_api_key = ssmc.get_parameter(Name='/{0}/datadog-agent-api-key'.format(stage_pre), WithDecryption=True)['Parameter']['Value']
    os.environ['DD_API_KEY'] = dd_api_key
    dd_app_key = ssmc.get_parameter(Name='/{0}/datadog-agent-app-key'.format(stage_pre), WithDecryption=True)['Parameter']['Value']
    options = {'api_key': '{0}'.format(dd_api_key), 'app_key': '{0}'.format(dd_app_key)}
    initialize(**options)

    rds_event_info = json.loads(event['Records'][0]['Sns']['Message'])
    rds_info_id = rds_event_info['Source ID']
    print(rds_event_info)

    if rds_event_info['Event Message'] == 'DB instance shutdown':

        a_mess = 'RDS instance {0} is shutting down'.format(rds_info_id)
        func_log.log_entry(a_mess)
        alrt_mess['alert_subject'] = 'RDS shutdown {0}'.format(stage_pre)
        alrt_mess['alert_message'] = a_mess
        alrt_mess['datadog_metric'] = 'rds.shutdown'
        alerting.handler(alrt_mess, '')
        print(e)

        api.Event.create(title='RDS Alert', text=a_mess, alert_type='warning', aggregation_key=dd_metric,
                        source_type_name='{0}'.format(os.environ['AWS_LAMBDA_FUNCTION_NAME']), tags=tags)

        return



    ####### checking for proper rr nlb target ips ##########

    ### get list of rds instances ###
    resp = rdsc.describe_db_instances()
    # print(resp)

    ### get master instance and read recplica ids ###
    try:
        func_log.log_entry('Checking db instance {0}'.format(rds_mas_id))
        mas_resp = rdsc.describe_db_instances(DBInstanceIdentifier = rds_mas_id)
        # print(mas_resp)
        rds_mas_endpoint = mas_resp['DBInstances'][0]['Endpoint']['Address']
        func_log.log_entry('Master endpoint: {0}'.format(rds_mas_endpoint))
        rds_rr_ids = mas_resp['DBInstances'][0]['ReadReplicaDBInstanceIdentifiers']
        func_log.log_entry('Found {0} read replicas'.format(len(rds_rr_ids)))
        func_log.log_entry(rds_rr_ids)

        ### get ip addresses ###
        rds_mas_ip = socket.gethostbyname(rds_mas_endpoint)
        func_log.log_entry('Master IP address: {0}'.format(rds_mas_ip))

        rr_ips = []

        for r in rds_rr_ids:
            resp = rdsc.describe_db_instances(DBInstanceIdentifier = r)
            rds_rr_endpoint = resp['DBInstances'][0]['Endpoint']['Address']
            func_log.log_entry('Replica endpoint: {0}'.format(rds_rr_endpoint))
            if resp['DBInstances'][0]['DBInstanceStatus'] == 'available':
                rr_ips.append({'Id': socket.gethostbyname(rds_rr_endpoint)})


        ### nlb for targets ###
        func_log.log_entry('Checking NLB targets')
        resp = elbc.describe_target_groups(Names=[nlb_tar])
        print(resp)
        tar_grp_arn = resp['TargetGroups'][0]['TargetGroupArn']

        func_log.log_entry('Target group arn: {0}'.format(tar_grp_arn))
        func_log.log_entry('Target IPs: {0}'.format(rr_ips))
        resp = elbc.register_targets(TargetGroupArn = tar_grp_arn, Targets = rr_ips)
        print(resp)
        


    except Exception as e:
        a_mess = 'Error updating NLB IP targets'
        func_log.log_entry(a_mess)
        alrt_mess['alert_subject'] = 'Error updating NLB targets {0}'.format(stage_pre)
        alrt_mess['alert_message'] = a_mess + '\n{0}'.format(e)
        alrt_mess['datadog_metric'] = 'monitor'
        alerting.handler(alrt_mess, '')
        print(e)

        text = 'Lambda alert was triggered: {0}'.format(a_mess)
        
        api.Event.create(title='Lambda Alert', text=text, alert_type='error', aggregation_key=dd_metric,
                        source_type_name='{0}'.format(os.environ['AWS_LAMBDA_FUNCTION_NAME']), tags=tags)


    func_log.log_entry('RDS events function end.')
