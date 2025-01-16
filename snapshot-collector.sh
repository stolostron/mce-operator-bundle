#!/bin/bash

get_latest_release() {
  releasePlan=$1
  latestRelease=$(oc get releases --sort-by=.metadata.creationTimestamp | awk '$3 == "'$releasePlan'"' | awk '{ print $1 }' | tail -1)
  if [ -n "${latestRelease}" ]; then
    echo "Latest Release: $latestRelease"
    latestSnapshot=$(oc get release $latestRelease -o yaml | yq '.spec.snapshot')
    if [ -n "${latestSnapshot}" ]; then
        echo "Latest Snapshot: $latestSnapshot"
        oc get snapshot $latestSnapshot -o yaml > latest-snapshot.yaml
    else
      echo "No snapshot found for the latest release."
    fi    
  else
    echo "No release found."
  fi
}

releasePlan=$1

# Check if the release plan is provided
if [ -z "$releasePlan" ]; then
  echo "Error: release-plan argument is missing."
  exit 1
fi

# Call the function with the release-plan passed into script
get_latest_release $releasePlan
