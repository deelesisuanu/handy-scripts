# Automating Docker Cleaner Execution with Cron

### To ensure this script runs automatically, we will set up a cron job that executes it every 20 minutes.

Run command below to edit crontab
``crontab -e``

Add this line at the end of the file:
``*/20 * * * * ~/docker_prune.sh >> ~/docker_prune.log 2>&1``

### What This Does:
#### - Runs docker_prune.sh every 20 minutes.
#### - Logs output to docker_prune.log for monitoring.

To check if the cron job is set up correctly, run:
``crontab -l``

To confirm execution, inspect the log after 20 minutes:
``cat ~/docker_prune.log``

Alternatively, check cron logs:
``grep CRON /var/log/syslog | tail -20``
