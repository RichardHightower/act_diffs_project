#!/bin/bash

# Read version from version.txt
if [ ! -f version.txt ]; then
    echo "version.txt not found. Please create this file with the current version number."
    exit 1
fi

VERSION=$(cat version.txt)

# Set variables
IMAGE_NAME="diffs_project"
GITHUB_USERNAME="richardhightower"  # Change this to your GitHub username

# Full image name for ghcr.io
GHCR_IMAGE_NAME="ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME"

# Tag the image for GitHub Container Registry
echo "Tagging image for GitHub Container Registry..."
docker tag $IMAGE_NAME:$VERSION $GHCR_IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:$VERSION $GHCR_IMAGE_NAME:latest

# Push the image to GitHub Container Registry
echo "Pushing image to GitHub Container Registry..."
docker push $GHCR_IMAGE_NAME:$VERSION
docker push $GHCR_IMAGE_NAME:latest

echo "Image successfully pushed to GitHub Container Registry:"
echo "$GHCR_IMAGE_NAME:$VERSION"
echo "$GHCR_IMAGE_NAME:latest"
