#!/bin/bash
set -eu
# set -x
INTERVAL=$1; shift
TIMEOUT=$1; shift

elapsed=0
containers=("$@")
failed=0

containers=()
for service in $@; do
  # Get the container name, can be multiple if `all` is used.
  names=`service_to_container $service`
  if [ -z "$names" ]; then
    echo Couldn\'t find container for service $service.
    let failed+=1
  else
    containers+=($names)
  fi
done

# echo "${containers[@]}"

while [ ${#containers[@]} -gt 0 ]; do
  not_ready=()
  for container in "${containers[@]}"; do
    health=$(docker inspect --format='{{.State.Health}}' $container)
    if [[ $health == "<nil>" ]]; then
      echo "$container does not have a health check."
      echo -n "$container running: "
      docker inspect --format='{{.State.Running}}' $container
      continue
    fi
    status=$(docker inspect --format='{{.State.Health.Status}}' $container)
    if [ "$status" == "healthy" ]; then
      echo "$container became healthy in $elapsed seconds!"
      continue
    elif [ "$status" == "unhealthy" ]; then
      echo "$container is unhealthy"
      docker logs $container
      let failed+=1
      continue
    elif [ $elapsed -ge $TIMEOUT ]; then
      echo "Timeout reached: $container did not become healthy within $TIMEOUT seconds."
      let failed+=1
      continue
    fi
    echo "Waiting for $container to become healthy, $elapsed seconds..."
    not_ready+=("$container")
  done
  if [ ${#not_ready[@]} -eq 0 ]; then
    # Not waiting for any more containers.
    exit $failed
  fi
  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
  containers=("${not_ready[@]}")
done
