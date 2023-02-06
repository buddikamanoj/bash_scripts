#!/bin/bash

# Prompt for username and password
echo "Enter username: "
read username
echo "Enter password: "
read -s password

# Array of servers
servers=("server1" "server2" "server3" "server4" "server5" "server6" "server7" "server8")

# Define the email subject and recipient
subject="Server Storage and Rstudio Status Report"
recipient="youremail@example.com"

# Define the message body
message="Checking storage and Rstudio status on the following servers:\n"

for server in "${servers[@]}"
do
  message+="\nServer: $server\n"

  # Check the storage on the server
  storage_output=$(ssh $username@$server "df -h")
  storage_usage=$(echo "$storage_output" | awk 'NR==2 {print $5}' | cut -d '%' -f1)
  
  if [ "$storage_usage" -gt 90 ]
  then
    message+="Storage: WARNING - usage is over 90%.\n"
  else
    message+="Storage: OK - usage is under 90%.\n"
  fi

  # Check the status of Rstudio on the server
  rstudio_status=$(ssh $username@$server "systemctl status rstudio-server")
  if echo "$rstudio_status" | grep -q "active (running)"
  then
    message+="Rstudio: OK - Rstudio is running.\n"
  else
    message+="Rstudio: WARNING - Rstudio is not running.\n"
  fi
done

# Send the email
echo -e "$message" | mail -s "$subject" "$recipient"
