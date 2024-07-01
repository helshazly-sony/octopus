#!/bin/bash

# Number of applications to run (input parameter)
num_apps=$1

# Ensure the input is a valid number
if ! [[ "$num_apps" =~ ^[0-9]+$ ]]; then
  echo "Error: Number of applications to run must be a valid number."
  exit 1
fi

# Run TestApp1
if [ "$num_apps" -eq 1 ]; then
  echo "Running TestApp1..."
  spark-submit --master spark://job-dispatcher-container:7077 ./test-app1.py 
  sleep 5
fi

# Run TestApp2
if [ "$num_apps" -eq 2 ]; then
  echo "Running TestApp2..."
  spark-submit --master spark://job-dispatcher-container:7077 ./test-app2.py
  sleep 5
fi

# Run TestApp3
if [ "$num_apps" -eq 3 ]; then
  echo "Running TestApp3..."
  spark-submit --master spark://job-dispatcher-container:7077 ./test-app3.py 
  sleep 5
fi

# Check if no applications are to be run
if [ "$num_apps" -eq 0 ]; then
  echo "No applications to run. Please specify a number between 1 and 3."
fi

echo "Script completed."
