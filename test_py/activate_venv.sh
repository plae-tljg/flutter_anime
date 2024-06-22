#!/bin/bash

# Set the virtual environment path (replace with your actual path)
VENV_PATH="$HOME/Documents/ai_venv"


# Check if the virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
  echo "Error: Virtual environment not found at '$VENV_PATH'"
  exit 1
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Run your command here
# For example, to run a Python script:
# python your_script.py

# Deactivate the virtual environment
# deactivate
