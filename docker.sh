#!/usr/bin/env bash
# ^^ this needs bash 4+, mac is only on 3.
# Use the first bash from the path and not /bin/bash
# set -x

bash --version | grep -q -e 'version [45]' || { echo "Error: Bash version must be 4+" >&2; exit 1; }

COMPOSE_FILE=${COMPOSE_FILE:-compose.yaml}

function dlogs() {
  # if [ -z "$@" ]; then
  #   echo "Missing container name"
  #   return
  # fi
  docker compose logs -f "$@"
}

function dattach(){
  if [ -z "$1" ]; then
    echo "Missing service name"
    return
  fi
  SERVICE=$1
  CONTAINER=`service_to_container $SERVICE`
  shift

  if [ -z "$1" ]; then
    CMD=/bin/bash
  else
    CMD="$@"
  fi

  if [ $CMD != '/bin/sh' ]; then
    # Fall back to sh if there is no bash
    set -x
    docker exec -u root -it $CONTAINER $CMD || docker exec -u root -it $CONTAINER /bin/sh
    set +x
  else
    set -x
    docker exec -u root -it $CONTAINER $CMD
    set +x
  fi
}

function drebuild(){
  check_compose_dir
  ARGS=$(compose_files)
  FLAGS=
  FORCE=
  if [ "$1" == "-f" ];then
    shift
    FORCE="yes"
  fi
  if [ "$DOCKER_ENV" == "dev" ];then
    FORCE="yes"
  fi

  if [ -z "$1" ]; then
    echo "Not rebuilding everything, pass container name"
    return
  elif [ "$1" == "all" ];then
    shift
    NAMES=all
  else
    NAMES="$@"
  fi

  if [ -z $FORCE ]; then
    echo "Continue to rebuild '$NAMES'"
    echo " ** This deletes the current container (but not the volumes)"
    read
  else
    FLAGS="--force-recreate"
  fi
  set -x
  # Use --force-recreate to completely rebuild the container and not use cached layers.
  docker compose $ARGS up --build --no-deps --remove-orphans -d $FLAGS "$@" || exit 1
  set +x
  # echo "Showing '$NAMES' logs with -f (Quitting will not stop the container.)"
  # dlogs "$@"
  wait_for_containers.sh 2 40 $NAMES
}

function dcs() {
  check_compose_dir
  ARGS=$(compose_files)

  if [ -z "$1" ]; then
    echo "Not stopping everything, pass container name"
    return
  fi
  FORCE=
  if [ "$1" == "-f" ];then
    shift
    FORCE="yes"
  fi
  if [ "$DOCKER_ENV" == "dev" ];then
    FORCE="yes"
  fi
  if [ -z $FORCE ]; then
    echo "Continue to stop '$@'"
    read
  fi
  set -x
  docker compose $ARGS stop "$@"
  set +x
}

function dcd() {
  check_compose_dir
  ARGS=$(compose_files)

  if [ -z "$1" ]; then
    echo "Not downing everything, pass container name"
    return
  elif [ "$1" == "all" ];then
    shift
    NAMES=all
  else
    NAMES="$@"
  fi
  FORCE=
  if [ "$1" == "-f" ];then
    shift
    FORCE="yes"
  fi
  if [ "$DOCKER_ENV" == "dev" ];then
    FORCE="yes"
  fi
  if [ -z $FORCE ]; then
    echo "Continue to down '$NAMES'"
    echo " ** This removes the container (but not the volumes)"
    echo " ** To stop the container running use 'dcs'"
    read
  fi
  set -x
  docker compose $ARGS down "$@"
  set +x
}

function dcu() {
  check_compose_dir
  ARGS=$(compose_files)

  # if [ -z "$1" ]; then
  #   echo "Not up-ing everything, pass container name"
  #   return
  # fi

  set -x
  docker compose $ARGS up --no-deps --remove-orphans -d "$@"
  set +x
  # echo "Showing '$@' logs with -f (Quitting will not stop the container.)"
  # dlogs "$@"
  wait_for_containers.sh 2 40 "$@"
}

function check_compose_dir(){
  while [[ "$PWD" == $HOME/* ]]; do
    if [[ -f $COMPOSE_FILE ]]; then
      return
    fi
    cd ..
  done
  if [[ ! -f $COMPOSE_FILE ]]; then
    echo "Not in docker compose directory"
    exit 1
  fi
}

function compose_files(){
  if [[ -n "$DOCKER_ENV" && -f "compose.${DOCKER_ENV}.yaml" ]]; then
    echo $PWD/compose.yaml $PWD/compose.${DOCKER_ENV}.yaml >&2
    echo "-f compose.yaml -f compose.${DOCKER_ENV}.yaml"
  else
    echo $PWD/$COMPOSE_FILE >&2
  fi
}

NAME=`basename $0`
case "$NAME" in
  "dlogs")
    ;&
  "dattach")
    ;&
  "drebuild")
    ;&
  "dcd")
    ;&
  "dcs")
    ;&
  "dcu")
    # all supported commands fall through to here.
    $NAME "$@"
    ;;
  "bash")
    # this happens if this file is sourced.
    ;;
  *)
    echo "Unhandled case: $NAME"
    ;;
esac

