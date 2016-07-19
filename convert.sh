#!/bin/bash

# Usage:        convert.sh [-l LANGUAGE] [-d TEXTDIRECTION] -t TRANSLATION -a ABBREVIATION -i INFILE
# Requirements: moreutils, grep, sed

INFILE=
LANGUAGE="English"
TRANSLATION=
ABBREVIATION=
TEXTDIRECTION="LTR"

while getopts l:t:a:d:i: opt
do
	case "$opt" in
		l)
			LANGUAGE="$OPTARG"
			;;
		t)
			TRANSLATION="$(echo "$OPTARG" | sed 's/[^a-zA-Z0-9]/_/g')"
			;;
		a)
			ABBREVIATION="$OPTARG"
			;;
		d)
			TEXTDIRECTION="$OPTARG"
			;;
		i)
			INFILE="$OPTARG"
			;;
	esac
done

if [[ -z "$INFILE" ]] || [[ -z "$TRANSLATION" ]] || [[ -z "$ABBREVIATION" ]]
then
	echo "Usage: $0 [-l LANGUAGE] [-d TEXTDIRECTION] -t TRANSLATION -a ABBREVIATION -i INFILE"
	exit -1
fi

OUTFILE="${LANGUAGE}__${TRANSLATION}__${ABBREVIATION}__${TEXTDIRECTION}.txt"

rm -f "$OUTFILE"

grep -v '^#' "$INFILE" | sed 's/\t\+/||/g' > "$OUTFILE"

iconv -t UTF-8 "$OUTFILE" | sponge "$OUTFILE"

echo "$OUTFILE"
