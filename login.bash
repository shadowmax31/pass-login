#!/usr/bin/env bash

usage() {
  echo "usage"
}

get_login() {
  local path="${1%/}"
  local passfile="$PREFIX/$path.gpg"
  check_sneaky_paths "$path"
  [[ ! -f $passfile ]] && die "$path: password file not found."

  local login
  local contents=$($GPG -d "${GPG_OPTS[@]}" "$passfile")

  if [ -z "$PASSWORD_STORE_LOGIN_PREFIX" ]; then
    PASSWORD_STORE_LOGIN_PREFIX="user|email"
  fi

  while read -r line; do
    if [[ "$line" =~ ($PASSWORD_STORE_LOGIN_PREFIX)+ ]]; then
      login=$line
      break
    fi
  done < <(echo "$contents")

  login=`echo $login | sed -r "s/($PASSWORD_STORE_LOGIN_PREFIX)+:[ ]*//g"`

  if [[ -z "$CLIP" ]]; then
    echo "$login"
  else
    clip "$login" "$path"
  fi
}

_show() {
  local path="${1%/}"
  local passfile="$PREFIX/$path.gpg"
  [[ -f $passfile ]] && { $GPG -d "${GPG_OPTS[@]}" "$passfile" || exit $?; }
}

# Getopt options
small_arg="hc"
long_arg="help,clip"
opts="$($GETOPT -o $small_arg -l $long_arg -n "$PROGRAM $COMMAND" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
	-c|--clip) CLIP="--clip"; shift ;;
	-h|--help) shift; usage; exit 0 ;;
	--) shift; break ;;
esac done

[[ $err -ne 0 ]] && usage && exit 1

get_login "$@"
