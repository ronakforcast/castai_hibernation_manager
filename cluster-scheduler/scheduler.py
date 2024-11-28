import os
import json
import requests
import logging
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_EXECUTED, EVENT_JOB_ERROR

# Set up logging to capture scheduler activity in addition to job logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load API key from secret
API_KEY = os.environ.get("API_KEY")

# Load instance type from environment variable
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE")

# Load schedule configuration
with open('/etc/schedule/schedules.json', 'r') as f:
    schedules = json.load(f)

HEADERS = {
    'X-API-Key': API_KEY,
    'accept': 'application/json',
    'content-type': 'application/json'
}

def hibernate_cluster(cluster_id):
    logger.info(f"Triggering hibernate for cluster: {cluster_id}")
    url = f"https://api.cast.ai/v1/kubernetes/external-clusters/{cluster_id}/hibernate"
    response = requests.post(url, headers=HEADERS)
    if response.status_code == 200:
        logger.info(f"Cluster {cluster_id} hibernated successfully.")
    else:
        logger.error(f"Failed to hibernate cluster {cluster_id}: {response.status_code}, {response.text}")

def resume_cluster(cluster_id):
    logger.info(f"Triggering resume for cluster: {cluster_id}")
    url = f"https://api.cast.ai/v1/kubernetes/external-clusters/{cluster_id}/resume"
    data = json.dumps({"instanceType": INSTANCE_TYPE})
    response = requests.post(url, headers=HEADERS, data=data)
    if response.status_code == 200:
        logger.info(f"Cluster {cluster_id} resumed successfully.")
    else:
        logger.error(f"Failed to resume cluster {cluster_id}: {response.status_code}, {response.text}")

def job_listener(event):
    """Listen for job events (executed or failed) and log them."""
    if event.exception:
        logger.error(f"Job {event.job_id} failed: {event.exception}")
    else:
        logger.info(f"Job {event.job_id} executed successfully")

scheduler = BlockingScheduler()

# Attach listener to the scheduler to log job execution events
scheduler.add_listener(job_listener, EVENT_JOB_EXECUTED | EVENT_JOB_ERROR)

for schedule in schedules:
    cluster_id = schedule['cluster_id']
    hibernate_cron = schedule['hibernate_cron']
    resume_cron = schedule['resume_cron']

    # Add job to schedule hibernation
    scheduler.add_job(hibernate_cluster, CronTrigger.from_crontab(hibernate_cron), args=[cluster_id], id=f"hibernate_{cluster_id}")
    logger.info(f"Scheduled hibernation for cluster {cluster_id} at cron {hibernate_cron}")

    # Add job to schedule resume
    scheduler.add_job(resume_cluster, CronTrigger.from_crontab(resume_cron), args=[cluster_id], id=f"resume_{cluster_id}")
    logger.info(f"Scheduled resume for cluster {cluster_id} at cron {resume_cron}")

logger.info("Scheduler started.")
scheduler.start()
