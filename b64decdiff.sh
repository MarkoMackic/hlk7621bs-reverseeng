#!/bin/bash

shopt -s extglob

prefix=""

if [[ ! -z "$DIFF_DIR" && -d $DIFF_DIR ]]; then
	prefix=${DIFF_DIR%%+(/)}/
fi

args=$(echo $@|xargs printf " <(cat $prefix%s | base64 --decode | xxd)")

eval diff $args


