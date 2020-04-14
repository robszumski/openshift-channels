#!/usr/bin/env bash

PWD=$(pwd)
WEB_OUTPUT=$PWD/index.html

git clone https://github.com/openshift/cincinnati-graph-data.git
CINI_GRAPH_DIR=$PWD/cincinnati-graph-data


parse_channel() {
	FILE=$1
	NAME=$(./yq r $FILE name)
	VERSIONS=$(./yq r $FILE versions) # grab it all, including comments
	HTML_OUT="html/$NAME.html"
	LAST_MODIFIED=$(cd $CINI_GRAPH_DIR && git log -1 --format="%ad" -- $FILE)

	#clear previous state
	echo "" > $HTML_OUT

	echo $NAME
	echo "<div class='channel'>" >> $HTML_OUT
	echo "  <div class='name'>$NAME</div>" >> $HTML_OUT

	# find latest version
	CURRENT=$(./yq r $FILE versions | grep -v "#" | tail -n1 | sed 's/- //') #ignore comments, find last entry
	if [ $CURRENT == '[]' ]; then
		echo "  <div class='current muted'>No release</div>" >> $HTML_OUT
	else 
		echo "  <div class='current'>$CURRENT</div>" >> $HTML_OUT
	fi
	
	echo "  <div class='modified'>Last Modified: $LAST_MODIFIED</div>" >> $HTML_OUT
	echo "  <div class='versions hidden'>" >> $HTML_OUT

	echo "$VERSIONS" | sed 's/- /    <li>/' | sed 's/# /    <li class="muted">/' | sed 's/$/<\/li>/' >> $HTML_OUT

	echo '  </div>' >> $HTML_OUT
	echo '</div>' >> $HTML_OUT

	cat $HTML_OUT >> $WEB_OUTPUT
}

# make temp directory
mkdir -p html

# construct header
echo "" > $WEB_OUTPUT
cat $PWD/header.html >> $WEB_OUTPUT

for filename in $(find $CINI_GRAPH_DIR/channels/* -type f -name "*yaml"); do

	# format each channel
    parse_channel $filename

done

# construct footer
cat $PWD/footer.html >> $WEB_OUTPUT

# remove artifacts



echo 'Generation complete. Starting nginx.'

nginx -g "daemon off;"
