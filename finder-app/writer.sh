#!/bin/bash

if [ $# -ne 2 ]; then
        echo "Wrong number of arguments, please retry."
        exit 1
fi

DIRNAME=$(dirname "$1")
mkdir -p "$DIRNAME"

if [ ! -d "$DIRNAME" ]; then
	echo "The creation of "$DIRNAME" failed, please retry."
        exit 1
fi

touch "$1"
echo "$2" > "$1"

if [ ! -f "$1" ]; then
	echo "The creation of "$1" failed, please retry."
	exit 1
fi
