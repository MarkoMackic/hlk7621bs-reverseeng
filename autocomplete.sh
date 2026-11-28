#!/bin/bash

shopt -s globstar

_autocomplete_mqtt_packets() {
	local file
	for file in $(pwd)/logs/**/$2*.bin; do
		[[ -e $file ]] || continue
		COMPREPLY+=( "$file" )
	done
}

complete -F _autocomplete_mqtt_packets -o default -o bashdefault -D

