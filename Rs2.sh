#!/bin/bash

# Set the threshold for disk usage percentage
threshold=90

# List of servers to check
servers=(
    "server1.example.com"
    "server2.example.com"
    "server3.example.com"
)

# Initialize the email message with the table header
message="<table border='1'><tr><th>Server</th><th>Filesystem</th><th>Usage</th><th>RStudio Service Status</th></tr>"

# Loop over the servers
for server in "${servers[@]}"
do
  # Get the current disk usage for all mounted filesystems
  df_output=$(ssh $server df -h)

  # Initialize the table row for this server
  row="<tr><td rowspan='2'>$server</td>"

  # Initialize a counter to determine the rowspan for the RStudio service status column
  rstudio_rowspan=0

  # Iterate over the output of the df command
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
      # Add the disk usage message to the table row
      row="$row<td>$filesystem</td><td style='color:red'>$usage%</td>"
    else
      row="$row<td>$filesystem</td><td>$usage%</td>"
    fi

    # Add a new row to the table for this filesystem
    message="$message$row</tr><tr>"

    # Increment the RStudio rowspan counter
    rstudio_rowspan=$((rstudio_rowspan+1))
  done <<< "$df_output"

  # Check the status of the RStudio service
  if ssh $server systemctl is-active --quiet rstudio-server; then
    rstudio_status="Running"
  else
    rstudio_status="Not Running"
  fi

  # Add the RStudio service status to the table row
  row="<td rowspan='$rstudio_rowspan'>$rstudio_status</td></tr>"
  message="$message$row"
done

# Add the table footer to the message
message="$message</table>"

# Send the email with the table
if [[ $threshold -ge 0 ]]; then
  # Compose the email subject
  subject="Server status alert on $(hostname)"

  # Send the email using the mail command
  echo -e "$message" | mail -a "Content-type: text/html" -s "$subject" your-email@your-domain.com
fi
