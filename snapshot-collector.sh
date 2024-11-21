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
  fi    
  else
    echo "No release found."
  fi
}

# Currently calling the function with 'publish' aka my test releasePlan as an argument
get_latest_release publish
