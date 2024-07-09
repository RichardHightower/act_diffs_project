#!/bin/bash

# Function to read version from version.txt
read_version_from_file() {
    if [ ! -f version.txt ]; then
        echo "version.txt not found. Please create this file with the current version number."
        exit 1
    fi
    cat version.txt
}

# Check if version is provided as an argument, otherwise read from file
if [ -z "$1" ]; then
    VERSION=$(read_version_from_file)
else
    VERSION=$1
fi

# Set variables
IMAGE_NAME="diffs_project"
GITHUB_USERNAME="richardhightower"  # Change this to your GitHub username

# Full image name
FULL_IMAGE_NAME="ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$VERSION"

echo "Running tests for $FULL_IMAGE_NAME"

# Run the container and execute tests
docker run --rm $FULL_IMAGE_NAME pytest tests/

# Check the exit code of the last command
if [ $? -eq 0 ]; then
    echo "Tests passed successfully!"
else
    echo "Tests failed. Please check the output above for details."
fi
