#!/bin/bash

# Set the threshold for disk usage percentage
threshold=90

# Set the email recipient
email_recipient="youremail@example.com"

# Set the email subject
email_subject="Server Status Report"

# Initialize the email message with the table header
email_message="<table border='1'><tr><th>Server</th><th>RStudio Status</th><th>Disk Usage</th></tr>"

# Loop over the list of servers
while read -r server
do
  # Get the RStudio service status
  rstudio_status=$(ssh $server systemctl is-active --quiet rstudio-server && echo "OK" || echo "NOT OK")

  # Get the disk usage for all mounted filesystems
  disk_usage=$(ssh $server df -h)

  # Initialize a variable to keep track of the exceeded disks
  exceeded_disks=""

  # Loop over the output of the df command
  while read -r line
  do
    # Skip the header line
    if [[ $line == Filesystem* ]]; then
      continue
    fi

    # Extract the filesystem and usage percentage
    filesystem=$(echo $line | awk '{print $1}')
    usage=$(echo $line | awk '{print $5}' | cut -d'%' -f1)

    # Check if usage is above the threshold
    if [[ $usage -gt $threshold ]]; then
      # Add the disk usage message to the exceeded disks variable
      exceeded_disks="$exceeded_disks $filesystem ($usage%),"
      disk_usage_status="NOT OK"
    else
      disk_usage_status="OK"
    fi

    # Add the filesystem and usage percentage to the disk usage message
    disk_usage_message="$disk_usage_message $filesystem ($usage%),"
  done <<< "$disk_usage"

  # Remove the trailing comma from the disk usage message and the exceeded disks list
  disk_usage_message=${disk_usage_message%,}
  exceeded_disks=${exceeded_disks%,}

  # Add a new row to the email message for this server
  email_message="$email_message<tr><td>$server</td><td>$rstudio_status</td><td>$disk_usage_status ($disk_usage_message $exceeded_disks)</td></tr>"
done < server_list.txt

# Add the table footer to the email message
email_message="$email_message</table>"

# Send the email with the table
echo -e "$email_message" | mail -a "Content-type: text/html" -s "$email_subject" "$email_recipient"
