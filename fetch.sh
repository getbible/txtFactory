#!/bin/bash

# Usage:        fetch.sh [version]
# Or:           bash <(./fetch.sh all)
# Requirements: curl, unzip, grep, sed

LIST_URL='http://unbound.biola.edu/index.cfm?method=downloads.showDownloadMain'
DOWNLOAD_URL='http://unbound.biola.edu/index.cfm?method=downloads.downloadBible'

if [[ -z "$1" ]]; then
	versions="$(curl -s "$LIST_URL" |\
		grep -A 1 "<select name='version_download'>" | tail -1 |\
		sed -r 's/ ?<option value='\''([^'\'']*)'\''>([^<]*)<\/option>/\1\t\2\n/g')"
	
	select version in $(echo "$versions" | head -n -1 | cut -f2 | sed 's/[[:space:]]/./g'); do
		version="$(echo "$versions" | grep "$version" | cut -f1)"
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

echo "Which file should I convert?"
select file in $(ls -S *.txt); do
	break
done

read -p "Version name:   " version
read -p "Abbreviation:   " abbreviation
read -p "Language:       " language
read -p "Text direction: " textdirection

newfile="$(../convert.sh \
	-l "$language" -d "$textdirection" -t "$version" -a "$abbreviation" \
	-i "$file")"

cd ..
mkdir -p bibles
cp "tmp/$newfile" bibles
cp tmp/*.html "bibles/${newfile/\.txt/}-copyright.html"
rm -r tmp

echo "Successfully downloaded $newfile."
