#!/bin/bash

# Read version from version.txt
if [ ! -f version.txt ]; then
    echo "version.txt not found. Please create this file with the current version number."
    exit 1
fi

VERSION=$(cat version.txt)

# Set variables
IMAGE_NAME="act_diffs_project"
GITREPO_USERNAME="richardhightower"  # Change this to your GitHub username
PLATFORM="linux/amd64"

# Build the Docker image
echo "Building Docker image version $VERSION..."

# Tag the image for GitHub Container Registry
docker build --platform $PLATFORM -t ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION -t ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest --push .

echo "Docker image built and pushed as:"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest"

echo "Done!"