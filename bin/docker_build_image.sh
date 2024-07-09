#!/bin/bash

# Read version from version.txt
if [ ! -f version.txt ]; then
    echo "version.txt not found. Please create this file with the current version number."
    exit 1
fi

VERSION=$(cat version.txt)

# Set variables
IMAGE_NAME="diffs_project"
GITREPO_USERNAME="richardhightower"  # Change this to your GitHub username

# Build the Docker image
echo "Building Docker image version $VERSION..."
docker build -t $IMAGE_NAME:$VERSION -t $IMAGE_NAME:latest .

# Tag the image for GitHub Container Registry
docker tag $IMAGE_NAME:$VERSION ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:$VERSION ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest

echo "Docker image built and tagged as:"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest"

echo "Done!"