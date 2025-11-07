#!/usr/bin/env bash

# Code supported by Chat GPT!

# Automatically download and replace velocity.jar with the latest Velocity proxy build.
# Requirements: curl + jq

set -euo pipefail

API_BASE="https://api.papermc.io/v2/projects/velocity"
OUTPUT_FILE="velocity.jar"
USER_AGENT="Velocity_Service_Updater"  # optional but polite

echo "🔍 Checking latest Velocity version..."

# Step 1: Get latest supported version
LATEST_VERSION=$(curl -s -H "User-Agent: ${USER_AGENT}" "${API_BASE}" | jq -r '.versions[-1]')
echo "Latest Velocity version: ${LATEST_VERSION}"

# Step 2: Get latest build number for that version
BUILD_DATA_URL="${API_BASE}/versions/${LATEST_VERSION}/builds"
LATEST_BUILD=$(curl -s -H "User-Agent: ${USER_AGENT}" "${BUILD_DATA_URL}" | jq -r '.builds[-1].build')
echo "Latest build number: ${LATEST_BUILD}"

# Step 3: Get the jar name and download URL
JAR_NAME=$(curl -s -H "User-Agent: ${USER_AGENT}" "${BUILD_DATA_URL}" | jq -r ".builds[-1].downloads.application.name")
DOWNLOAD_URL="${API_BASE}/versions/${LATEST_VERSION}/builds/${LATEST_BUILD}/downloads/${JAR_NAME}"

echo "⬇️  Downloading latest Velocity build..."
curl -L -o "${OUTPUT_FILE}" -H "User-Agent: ${USER_AGENT}" "${DOWNLOAD_URL}"

echo "✅ Download complete. ${OUTPUT_FILE} now updated to build ${LATEST_BUILD} (version ${LATEST_VERSION})."
