import os
import json
import requests
import logging
import pytz
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_EXECUTED, EVENT_JOB_ERROR

# Set up logging to capture scheduler activity in addition to job logs
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load API key from environment variable
API_KEY = os.environ.get("api-key")
if not API_KEY:
    logger.error("API_KEY not found in environment variables.")
    exit(1)  # Exit if API key is not set

# Load instance type from environment variable
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE")
if not INSTANCE_TYPE:
    logger.error("INSTANCE_TYPE not found in environment variables.")
    exit(1)  # Exit if instance type is not set

# Load schedule configuration
try:
    with open('/etc/schedule/schedules.json', 'r') as f:
        schedules = json.load(f)
except FileNotFoundError:
    logger.error("Schedules file not found: /etc/schedule/schedules.json")
    exit(1)
except json.JSONDecodeError:
    logger.error("Failed to parse the schedules.json file.")
    exit(1)

# Set headers for API requests
HEADERS = {
    'X-API-Key': API_KEY,
    'accept': 'application/json',
    'content-type': 'application/json'
}

# Initialize timezone (replace with the desired timezone, e.g., 'UTC', 'America/New_York')
TIMEZONE = pytz.timezone('UTC')

def hibernate_cluster(cluster_id):
    logger.info(f"Triggering hibernate for cluster: {cluster_id}")
    url = f"https://api.cast.ai/v1/kubernetes/external-clusters/{cluster_id}/hibernate"
    try:
        response = requests.post(url, headers=HEADERS)
        if response.status_code == 200:
            logger.info(f"Cluster {cluster_id} hibernated successfully.")
        else:
            logger.error(f"Failed to hibernate cluster {cluster_id}: {response.status_code}, {response.text}")
    except requests.RequestException as e:
        logger.error(f"Request failed for cluster {cluster_id} during hibernation: {str(e)}")

def resume_cluster(cluster_id):
    logger.info(f"Triggering resume for cluster: {cluster_id}")
    url = f"https://api.cast.ai/v1/kubernetes/external-clusters/{cluster_id}/resume"
    data = json.dumps({"instanceType": INSTANCE_TYPE})
    try:
        response = requests.post(url, headers=HEADERS, data=data)
        if response.status_code == 200:
            logger.info(f"Cluster {cluster_id} resumed successfully.")
        else:
            logger.error(f"Failed to resume cluster {cluster_id}: {response.status_code}, {response.text}")
    except requests.RequestException as e:
        logger.error(f"Request failed for cluster {cluster_id} during resume: {str(e)}")

def job_listener(event):
    """Listen for job events (executed or failed) and log them."""
    if event.exception:
        logger.error(f"Job {event.job_id} failed: {event.exception}")
    else:
        logger.info(f"Job {event.job_id} executed successfully")

scheduler = BlockingScheduler()

# Attach listener to the scheduler to log job execution events
scheduler.add_listener(job_listener, EVENT_JOB_EXECUTED | EVENT_JOB_ERROR)

# Iterate through schedules and add jobs
for schedule in schedules:
    cluster_id = schedule.get('cluster_id')
    hibernate_cron = schedule.get('hibernate_cron')
    resume_cron = schedule.get('resume_cron')

    if not cluster_id or not hibernate_cron or not resume_cron:
        logger.error(f"Invalid schedule configuration for cluster {cluster_id}. Skipping.")
        continue

    # Add job to schedule hibernation with explicit timezone handling
    scheduler.add_job(
        hibernate_cluster, 
        CronTrigger.from_crontab(hibernate_cron, timezone=TIMEZONE), 
        args=[cluster_id], 
        id=f"hibernate_{cluster_id}"
    )
    logger.info(f"Scheduled hibernation for cluster {cluster_id} at cron {hibernate_cron}")

    # Add job to schedule resume with explicit timezone handling
    scheduler.add_job(
        resume_cluster, 
        CronTrigger.from_crontab(resume_cron, timezone=TIMEZONE), 
        args=[cluster_id], 
        id=f"resume_{cluster_id}"
    )
    logger.info(f"Scheduled resume for cluster {cluster_id} at cron {resume_cron}")

logger.info("Scheduler started.")
scheduler.start()