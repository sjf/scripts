# alias dcu='docker compose up -d'
# alias dps='docker ps'

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
  if [ ! -f "compose.yaml" ];then
    echo "Not in docker compose directory"
    return
  fi

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
  if [ ! -f "compose.yaml" ];then
    echo "Not in docker compose directory"
    return
  fi
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
  if [ ! -f "compose.yaml" ];then
    echo "Not in docker compose directory"
    return
  fi
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

NAME=`basename $0`
case "$NAME" in
  "dlogs")
    dlogs "$@"
    ;;
  "dattach")
    dattach "$@"
    ;;
  "drebuild")
    drebuild "$@"
    ;;
  "dcd")
    dcd "$@"
    ;;
  "dcs")
    dcd "$@"
    ;;
  "bash")
    # this happens if this file is sourced
    ;;
  *)
    echo "Unhandled case: $NAME"
    ;;
esac

