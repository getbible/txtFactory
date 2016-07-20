#!/bin/bash

# Usage:        fetch.sh [version]
# Or:           fetch.sh version language translation abbreviation textdirection [auto]
# Or:           bash <(./fetch.sh all)
# Or:           bash <(./fetch.sh all-with-file translations.txt)
# Requirements: curl, unzip, grep, sed

LIST_URL='http://unbound.biola.edu/index.cfm?method=downloads.showDownloadMain'
DOWNLOAD_URL='http://unbound.biola.edu/index.cfm?method=downloads.downloadBible'

if [[ -z "$1" ]]; then
	versions="$(curl -s "$LIST_URL" |\
		grep -A 1 "<select name='version_download'>" | tail -1 |\
		sed -r 's/ ?<option value='\''([^'\'']*)'\''>([^<]*)<\/option>/\1\t\2\n/g')"
	
	select version in $(echo "$versions" | head -n -1 | cut -f2 | sed 's/[[:space:]]/./g'); do
		version="$(echo "$versions" | grep -F "${version//./ }" | cut -f1)"
		break
	done
elif [[ "$1" = "all" ]]; then
	curl -s "$LIST_URL" |\
		grep -A 1 "<select name='version_download'>" | tail -1 |\
		sed -r 's/ ?<option value='\''([^'\'']*)'\''>([^<]*)<\/option>/\1\t\2\n/g' |\
		head -n -1 | cut -f1 |\
		while read version; do
			echo "$0" "$version"
		done
	exit
elif [[ "$1" = "all-with-file" ]]; then
	LISTFILE="$2"
	I=0
	curl -s "$LIST_URL" |\
		grep -A 1 "<select name='version_download'>" | tail -1 |\
		sed -r 's/ ?<option value='\''([^'\'']*)'\''>([^<]*)<\/option>/\1\t\2\n/g' |\
		head -n -1 | cut -f1 |\
		while read version; do
			I=$((I+1))
			LINE="$(grep -v '^#' "$LISTFILE" | sed "${I}q;d")"
			language="$(echo "$LINE" | cut -f 2)"
			translation="$(echo "$LINE" | cut -f 3)"
			abbreviation="$(echo "$LINE" | cut -f 4)"
			textdirection="$(echo "$LINE" | cut -f 5)"
			echo "$0" "'$version'" "'$language'" "'$translation'" "'$abbreviation'" "'$textdirection'" "auto"
		done
	exit
else
	version="$1"
fi

echo "Going to download $1..."

rm -rf tmp
mkdir tmp
cd tmp

curl \
	--location --progress-bar \
	--data-urlencode "version_download=$version" \
	"$DOWNLOAD_URL" > bible.zip
unzip bible.zip >/dev/null
rm bible.zip

if [[ "$6" = "auto" ]]; then
	file="$(ls -S | grep -v 'NRSVA\|html' | head -1)"
else
	echo "Which file should I convert?"
	select file in $(ls -S *.txt); do
		break
	done
fi

if [ "$#" -ge 5 ]; then
	language="$2"
	translation="$3"
	abbreviation="$4"
	textdirection="$5"
else
	read -p "Language:       " language
	read -p "Translation:    " translation
	read -p "Abbreviation:   " abbreviation
	read -p "Text direction: " textdirection
fi

newfile="$(../convert.sh \
	-l "$language" -d "$textdirection" -t "$translation" -a "$abbreviation" \
	-i "$file")"

cd ..
mkdir -p bibles
cp "tmp/$newfile" bibles
cp tmp/*.html "bibles/${newfile/\.txt/}-copyright.html"
rm -r tmp

echo "Successfully downloaded $newfile."
