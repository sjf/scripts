#!/usr/bin/env bash
# ^^ this needs bash 4+, mac is only on 3.
# Use the first bash from the path.

function dlogs() {
  if [ -z "$@" ]; then
    echo "Missing container name"
    return
  fi
  docker logs -f "$@"
}

function dattach(){
  if [ -z "$1" ]; then
    echo "Missing container name"
    return
  fi
  CONTAINER=$1
  shift

  if [ -z "$1" ]; then
    CMD=/bin/bash
  else
    CMD="$@"
  fi
  set -x
  docker exec -u root -it $CONTAINER $CMD
  set +x
}

function drebuild(){
  check_compose_dir

  FORCE=
  if [ "$1" == "-f" ];then
    shift
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
  fi
  set -x
  docker compose up --build --force-recreate --no-deps --remove-orphans -d "$@"
  set +x
  echo "Showing '$@' logs with -f (Quitting will not stop the container.)"
  docker compose logs -f "$@"
}

function dcs() {
  check_compose_dir

  if [ -z "$1" ]; then
    echo "Not stopping everything, pass container name"
    return
  fi

  echo "Continue to stop '$@'"
  read
  set -x
  docker compose stop "$@"
  set +x
}

function dcd() {
  check_compose_dir

  if [ -z "$1" ]; then
    echo "Not downing everything, pass container name"
    return
  fi

  echo "Continue to down '$@'"
  echo " ** This removes the container (but not the volumes)"
  echo " ** To stop the container running use 'dcs'"
  read
  set -x
  docker compose down "$@"
  set +x
}

function dcu() {
  check_compose_dir

  if [ -z "$1" ]; then
    echo "Not up-ing everything, pass container name"
    return
  fi

  set -x
  docker compose up -d "$@"
  set +x
}

function check_compose_dir(){
  if [ ! -f "compose.yaml" ];then
    echo "Not in docker compose directory"
    exit 1
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

