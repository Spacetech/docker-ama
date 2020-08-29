#!/usr/bin/with-contenv bash
export XDG_CONFIG_HOME="/config/deemix/xdg"
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

Configuration () {
	processstartid="$(ps -A -o pid,cmd|grep "start.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	processdownloadid="$(ps -A -o pid,cmd|grep "download.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	echo "To kill script, use the following command:"
	echo "kill -9 $processstartid"
	echo "kill -9 $processdownloadid"
	echo ""
	echo ""
	sleep 2.
	echo "############################################ $TITLE"
	echo "############################################ SCRIPT VERSION 1.0.1"
	echo "############################################ DOCKER VERSION $VERSION"
	echo "############################################ CONFIGURATION VERIFICATION"
	error=0

	if [ "$AUTOSTART" = "true" ]; then
		echo "Automatic Start: ENABLED"
	else
		echo "Automatic Start: DISABLED"
	fi

	if [ -d "/downloads-ama" ]; then
			LIBRARY="/downloads-ama"
		echo "LIBRARY Location: $LIBRARY"
	else
		echo "ERROR: Missing /downloads-ama docker volume"
		error=1
	fi
	
	if [ ! -z "$mode" ]; then
		if [ "$mode" == "artist" ]; then
			echo "Audio Download Mode: artist"
		fi
		
		if [ "$mode" == "discography" ]; then
			echo "Audio Download Mode: discography"
		fi
	else
		echo "WARNING: mode setting invalid, defaulting to: artist"
		mode="artist"
	fi

	if [ ! -z "$ARL_TOKEN" ]; then
		echo "ARL Token: Configured"
		if [ -f "$XDG_CONFIG_HOME/deemix/.arl" ]; then
			rm "$XDG_CONFIG_HOME/deemix/.arl"
		fi
		 if [ ! -f "$XDG_CONFIG_HOME/deemix/.arl" ]; then
			echo -n "$ARL_TOKEN" > "$XDG_CONFIG_HOME/deemix/.arl"
		fi
	else
		echo "ERROR: ARL_TOKEN setting invalid, currently set to: $ARL_TOKEN"
		error=1
	fi

	if [ ! -z "$NumberConcurrentProcess" ]; then
		echo "Number of Concurrent Processes: $NumberConcurrentProcess"
		sed -i "s%queueConcurrency\"] = 1%queueConcurrency\"] = $NumberConcurrentProcess%g" "/config/scripts/dlclient.py"
	else
		echo "WARNING: NumberConcurrentProcess setting invalid, defaulting to: 1"
		NumberConcurrentProcess="1"
	fi


	if [ "$RELATED_ARTIST" = "true" ]; then
		echo "Related Artist: ENABLED"
	else
		echo "Related Artist: DISABLED"
	fi

	if [ "$RELATED_ARTIST_RELATED" = "true" ]; then
		echo "Related Artist Related (loop): ENABLED"
	else
		echo "Related Artist Related (loop): DISABLED"
	fi
	
	if [ ! -z "$relatedcount" ]; then
		echo "Artist Maximum Related Import Count: $relatedcount"
	else
		echo "ERROR: relatedcount not set, using default..."
		relatedcount="20"
		echo "Artist Maximum Related Import Count: $relatedcount"
	fi
	
	if [ ! -z "$fancount" ]; then
		echo "Related Artist Minimum Fan Count: $fancount"
	else
		echo "ERROR: fancount not set, using default..."
		fancount="1000000"
		echo "Related Artist Minimum Fan Count: $fancount"
	fi

	if [ ! -z "$FORMAT" ]; then
		echo "Download Format: $FORMAT"
		if [ "$FORMAT" = "ALAC" ]; then
			dlquality="FLAC"
			options="-c:a alac -movflags faststart"
			setextension="m4a"
		elif [ "$FORMAT" = "FLAC" ]; then
			dlquality="FLAC"
			setextension="flac"
		elif [ "$FORMAT" = "OPUS" ]; then
			dlquality="FLAC"
			options="-acodec libopus -ab ${ConversionBitrate}k -application audio -vbr off"
		    setextension="opus"
			echo "Download File Bitrate: $ConversionBitrate"
		elif [ "$FORMAT" = "AAC" ]; then
			dlquality="FLAC"
			options="-c:a libfdk_aac -b:a ${ConversionBitrate}k -movflags faststart"
			setextension="m4a"
			echo "Download File Bitrate: $ConversionBitrate"
		elif [ "$FORMAT" = "MP3" ]; then
			if [ "$ConversionBitrate" = "320" ]; then
				dlquality="320"
				setextension="mp3"
				echo "Download File Bitrate: $ConversionBitrate"
			elif [ "$ConversionBitrate" = "128" ]; then
				dlquality="128"
				setextension="mp3"
				echo "Download File Bitrate: $ConversionBitrate"
			else
				dlquality="FLAC"
				options="-acodec libmp3lame -ab ${ConversionBitrate}k"
				setextension="mp3"
				echo "Download File Bitrate: $ConversionBitrate"
			fi
		else
			echo "ERROR: \"$FORMAT\" Does not match a required setting, check for trailing space..."
			error=1
		fi
	else
		dlquality="FLAC"
		ConversionBitrate="320"
		FORMAT="AAC"
		echo "Download Format: $FORMAT"
		echo "Download File Bitrate: $ConversionBitrate"
	fi

	if [ ! -z "$replaygain" ]; then
		if [ "$replaygain" == "true" ]; then
			echo "Audio: Replaygain Tagging: ENABLED"
		else
			echo "Audio: Replaygain Tagging: DISABLED"
		fi
	else
		echo "WARNING: replaygain setting invalid, defaulting to: false"
		replaygain="false"
	fi

	if [ ! -z "$FilePermissions" ]; then
		echo "File Permissions: $FilePermissions"
	else
		echo "ERROR: FilePermissions not set, using default..."
		FilePermissions="666"
		echo "File Permissions: $FilePermissions"
	fi

	if [ ! -z "$FolderPermissions" ]; then
		echo "Folder Permissions: $FolderPermissions"
	else
		echo "ERROR: FolderPermissions not set, using default..."
		FolderPermissions="777"
		echo "Folder Permissions: $FolderPermissions"
	fi

	if [ "$LidarrListImport" = "true" ]; then
		echo "Lidarr List Import: ENABLED"
		wantit=$(curl -s --header "X-Api-Key:"${LidarrAPIkey} --request GET  "$LidarrUrl/api/v1/Artist/")
		wantedtotal=$(echo "${wantit}"| jq -r '.[].sortName' | wc -l)
		MBArtistID=($(echo "${wantit}" | jq -r ".[].foreignArtistId"))
		if [ "$wantedtotal" -gt "0" ]; then
			echo "Lidarr Connection : Successful"
		else
		   echo "Lidarr Connection : Error"
		   echo "Verify Lidarr is online at this address: $LidarrUrl"
		   echo "Verify Lidarr API Key is correct: $LidarrAPIkey"
		   error=1
		fi
	else
		echo "Lidarr List Import: DISABLED"
	fi
	
	if [ "$NOTIFYPLEX" == "true" ]; then
		echo "Plex Library Notification: ENABLED"
		plexlibraries="$(curl -s "$PLEXURL/library/sections?X-Plex-Token=$PLEXTOKEN" | xq .)"
		plexlibrarykey="$(echo "$plexlibraries" | jq -r ".MediaContainer.Directory[] | select(.Location.\"@path\"==\"$LIBRARY\") | .\"@key\"" | head -n 1)"
		if [ -z "$plexlibrarykey" ]; then
			echo "ERROR: No Plex Library found containg path \"/downloads-ama\""
			echo "ERROR: Add /downloads-ama as a folder to a Plex Music Library or Disable NOTIFYPLEX"
			error=1
		fi
	else
		echo "Plex Library Notification: DISABLED"
	fi
	
	

	if [ $error = 1 ]; then
		echo "Please correct errors before attempting to run script again..."
		echo "Exiting..."
		exit 1
	fi

}

AddReplaygainTags () {
	if [ "$replaygain" == "true" ]; then
		if find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -newer "/config/scripts/temp" | read; then
			OLDIFS="$IFS"
			IFS=$'\n'
			replaygainlist=($(find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -newer "/config/scripts/temp"))
			IFS="$OLDIFS"
			for id in ${!replaygainlist[@]}; do
				processid=$(( $id + 1 ))
				folder="${replaygainlist[$id]}"
				echo "$logheader :: Adding Replaygain Tags using r128gain to: $folder"
				r128gain -r -a -s -c $NumberConcurrentProcess "$folder"
			done
		fi
	fi
}

LidarrListImport () {

	for id in ${!MBArtistID[@]}; do
		artistnumber=$(( $id + 1 ))
		mbid="${MBArtistID[$id]}"
		deezerartisturlcount="$(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .links | .[] | select(.name==\"deezer\") | .url" | wc -l)"
		deezerartisturl=($(echo "${wantit}" | jq -r ".[] | select(.foreignArtistId==\"${mbid}\") | .links | .[] | select(.name==\"deezer\") | .url"))
		for url in ${!deezerartisturl[@]}; do
			deezerid="${deezerartisturl[$url]}"
			lidarrdeezerid=$(echo "${deezerid}" | grep -o '[[:digit:]]*')
			if [ -f "/config/list/$lidarrdeezerid" ]; then
			   rm "/config/list/$lidarrdeezerid"
			fi
	    		if [ -f "/config/list/$lidarrdeezerid-related" ]; then
			   rm "/config/list/$lidarrdeezerid-related"
			fi
			if [ -f "/config/list/$lidarrdeezerid-complete" ]; then
			   rm "/config/list/$lidarrdeezerid-complete"
			fi
			if [ ! -f "/config/list/$lidarrdeezerid-lidarr" ]; then
				echo -n "$mbid" > "/config/list/$lidarrdeezerid-lidarr"
			fi
		done
	done
}


AlbumDL () {

	if python3 /config/scripts/dlclient.py -b $dlquality "$dlurl"; then
		echo "$logheader :: Downloads Complete"
	else
		echo "$logheader :: ERROR: DL CLient failed"
		exit 1
	fi
}

ArtistCache () {
	if [ ! -d "/config/temp" ]; then
		mkdir -p "/config/temp"
	fi

	if ! [ -f "/config/cache/${DeezerArtistID}-info.json" ]; then
		if curl -sL --fail "https://api.deezer.com/artist/${DeezerArtistID}" -o "/config/temp/${DeezerArtistID}-temp-info.json"; then
			jq "." "/config/temp/${DeezerArtistID}-temp-info.json" > "/config/cache/${DeezerArtistID}-info.json"
			echo "$logheader :: AUDIO CACHE :: Caching Artist Info..."
			rm "/config/temp/${DeezerArtistID}-temp-info.json"
		else
			echo "$logheader :: AUDIO CACHE :: ERROR: Cannot communicate with Deezer"
		fi
	fi

	if ! [ -f "/config/cache/${DeezerArtistID}-related.json" ]; then
		if curl -sL --fail "https://api.deezer.com/artist/${DeezerArtistID}/related" -o "/config/temp/${DeezerArtistID}-temp-related.json"; then
			jq "." "/config/temp/${DeezerArtistID}-temp-related.json" > "/config/cache/${DeezerArtistID}-related.json"
			echo "$logheader :: AUDIO CACHE :: Caching Artist Related Info..."
			rm "/config/temp/${DeezerArtistID}-temp-related.json"
		else
			echo "$logheader:: AUDIO CACHE :: ERROR: Cannot communicate with Deezer"
		fi
	fi

	if [ -d "/config/temp" ]; then
		rm -rf "/config/temp"
	fi
	
	artistname="$(cat "/config/cache/${DeezerArtistID}-info.json" | jq -r ".name")"

}

ConverterTagger () {

	flacfilecount=$(find "$LIBRARY" -iname "*.flac" | wc -l)
	echo "$logheader :: Number of FLAC files to process $flacfilecount"
	echo "$logheader :: Processing Files using $NumberConcurrentProcess Threads"
    	find "$LIBRARY" -iname "*.flac" -print0 | while IFS= read -r -d '' file; do
		if [ ! -f "${file%.flac}.$setextension" ]; then
			Tag "$file"
		fi
		if [ ! -f "${file%.flac}.$setextension" ]; then
			echo "$logheader :: Failed Encoding and Tagging: $file"
		fi
    done
}


FileVerification () {

	verificationerror="0"
	if find "$LIBRARY" -type f -iname "errors.txt" | read; then
		OLDIFS="$IFS"
		IFS=$'\n'
		listerror=($(find "$LIBRARY" -iname "errors.txt"))
		for id in ${!listerror[@]}; do
			processid=$(( $id + 1 ))
			file="${listerror[$id]}"
			if cat "$file" | grep -i "is not a valid FLAC file" | read; then
				folder="$(dirname "$file")"
				if find "$folder" -type f -iname "*.flac" | read; then
					for fname in "${folder}"/*.flac; do
						filename="$(basename "$fname")"
						directory="$(basename "$(dirname "$fname")")"
						if flac -t --totally-silent "$fname"; then
							echo "$logheader :: Verified :: $directory :: $filename"
						else
							echo "$logheader :: ERROR: File verificatio failed :: $directory :: $filename :: deleting..."
							rm "$fname"
						fi
					done
				fi
				if find "$folder" -type f -iname "*.mp3" | read; then
					for fname in "${folder}"/*.mp3; do
						filename="$(basename "$fname")"
						directory="$(basename "$(dirname "$fname")")"
						if mp3val -f -nb "$fname" > /dev/null; then
							echo "$logheader :: Verified :: $directory :: $filename"
						else
							echo "$logheader :: ERROR: File verificatio failed :: $directory :: $filename :: deleting..."
							rm "$fname"
						fi
					done
				fi
				rm "$file"
				verificationerror="1"
			fi
		done
		IFS="$OLDIFS"
	fi

	if [ "$dlquality" == "FLAC" ]; then
		if [ "$verificationerror" == "1" ]; then
			echo "$logheader :: File Verification Error :: Downloading missing tracks as MP3"
			dlquality="320"
			AlbumDL
			dlquality="FLAC"
			FileVerification
		fi
	fi
}


Tag () {
	file="$1"
	extension="${1##*.}"
	filedest="${file%.$extension}.$setextension"
	filename="$(basename "$filedest")"
	directory="$(basename "$(dirname "$file")")"
	filelrc="${file%.$extension}.lrc"
	cover="$(dirname "$1")/folder.jpg"
	if [ ! -f "$file" ]; then
		echo "$logheader :: ERROR: EXITING :: $file"
	fi
	#reset tags
	songtitle="null"
	songalbum="null"
	songartist="null"
	songartistalbum="null"
	songoriginalbpm="null"
	songbpm="null"
	songcopyright="null"
	songtracknumber="null"
	songtracktotal="null"
	songdiscnumber="null"
	songdisctotal="null"
	songlyricrating="null"
	songcompilation="null"
	songdate="null"
	songyear="null"
	songgenre="null"
	songcomposer="null"
	songisrc="null"

	tags="$(ffprobe -v quiet -print_format json -show_format "$file" | jq -r '.[] | .tags')"
	if [ "$extension" = "flac" ]; then
		songtitle="$(echo "$tags" | jq -r ".TITLE")"
		songalbum="$(echo "$tags" | jq -r ".ALBUM")"
		songartist="$(echo "$tags" | jq -r ".ARTIST")"
		songartistalbum="$(echo "$tags" | jq -r ".album_artist")"
		songoriginalbpm="$(echo "$tags" | jq -r ".BPM")"
		songbpm=${songoriginalbpm%.*}
		songcopyright="$(echo "$tags" | jq -r ".COPYRIGHT")"
		songpublisher="$(echo "$tags" | jq -r ".PUBLISHER")"
		songtracknumber="$(echo "$tags" | jq -r ".track")"
		songtracktotal="$(echo "$tags" | jq -r ".TRACKTOTAL")"
		songdiscnumber="$(echo "$tags" | jq -r ".disc")"
		songdisctotal="$(echo "$tags" | jq -r ".DISCTOTAL")"
		songlyricrating="$(echo "$tags" | jq -r ".ITUNESADVISORY")"
		songcompilation="$(echo "$tags" | jq -r ".COMPILATION")"
		songdate="$(echo "$tags" | jq -r ".DATE")"
		songyear="${songdate:0:4}"
		songgenre="$(echo "$tags" | jq -r ".GENRE" | cut -f1 -d";")"
		songcomposer="$(echo "$tags" | jq -r ".composer")"
		songcomment="Source File: FLAC"
		songisrc="$(echo "$tags" | jq -r ".ISRC")"
		songauthor="$(echo "$tags" | jq -r ".author")"
		songartists="$(echo "$tags" | jq -r ".ARTISTS")"
		songengineer="$(echo "$tags" | jq -r ".engineer")"
		songproducer="$(echo "$tags" | jq -r ".producer")"
		songmixer="$(echo "$tags" | jq -r ".mixer")"
		songwriter="$(echo "$tags" | jq -r ".writer")"
		songbarcode="$(echo "$tags" | jq -r ".BARCODE")"
	fi
	if [ "$extension" = "mp3" ]; then
		songtitle="$(echo "$tags" | jq -r ".title")"
		songalbum="$(echo "$tags" | jq -r ".album")"
		songartist="$(echo "$tags" | jq -r ".artist")"
		songartistalbum="$(echo "$tags" | jq -r ".album_artist")"
		songoriginalbpm="$(echo "$tags" | jq -r ".TBPM")"
		songbpm=${songoriginalbpm%.*}
		songcopyright="$(echo "$tags" | jq -r ".copyright")"
		songpublisher="$(echo "$tags" | jq -r ".publisher")"
		songtracknumber="$(echo "$tags" | jq -r ".track" | cut -f1 -d "/")"
		songtracktotal="$(echo "$tags" | jq -r ".track" | cut -f2 -d "/")"
		songdiscnumber="$(echo "$tags" | jq -r ".disc" | cut -f1 -d "/")"
		songdisctotal="$(echo "$tags" | jq -r ".disc" | cut -f2 -d "/")"
		songlyricrating="$(echo "$tags" | jq -r ".ITUNESADVISORY")"
		songcompilation="$(echo "$tags" | jq -r ".compilation")"
		songdate="$(echo "$tags" | jq -r ".date")"
		songyear="$(echo "$tags" | jq -r ".date")"
		songgenre="$(echo "$tags" | jq -r ".genre" | cut -f1 -d";")"
		songcomposer="$(echo "$tags" | jq -r ".composer")"
		songcomment="Source File: MP3"
		songisrc="$(echo "$tags" | jq -r ".TSRC")"
		songauthor=""
		songartists="$(echo "$tags" | jq -r ".ARTISTS")"
		songengineer=""
		songproducer=""
		songmixer=""
		songbarcode="$(echo "$tags" | jq -r ".BARCODE")"
	fi

	if [ -f "$filelrc" ]; then
		songsyncedlyrics="$(cat "$filelrc")"
	else
		songsyncedlyrics=""
	fi

	if [ "$songtitle" = "null" ]; then
		songtitle=""
	fi

	if [ "$songpublisher" = "null" ]; then
		songpublisher=""
	fi

	if [ "$songalbum" = "null" ]; then
		songalbum=""
	fi

	if [ "$songartist" = "null" ]; then
		songartist=""
	fi

	if [ "$songartistalbum" = "null" ]; then
		songartistalbum=""
	fi

	if [ "$songbpm" = "null" ]; then
		songbpm=""
	fi

	if [ "$songlyricrating" = "null" ]; then
		songlyricrating="0"
	fi

	if [ "$songcopyright" = "null" ]; then
		songcopyright=""
	fi

	if [ "$songtracknumber" = "null" ]; then
		songtracknumber=""
	fi

	if [ "$songtracktotal" = "null" ]; then
		songtracktotal=""
	fi

	if [ "$songdiscnumber" = "null" ]; then
		songdiscnumber=""
	fi

	if [ "$songdisctotal" = "null" ]; then
		songdisctotal=""
	fi

	if [ "$songcompilation" = "null" ]; then
		songcompilation="0"
	fi

	if [ "$songdate" = "null" ]; then
		songdate=""
	fi

	if [ "$songyear" = "null" ]; then
		songyear=""
	fi

	if [ "$songgenre" = "null" ]; then
		songgenre=""
	fi

	if [ "$songcomposer" = "null" ]; then
		songcomposer=""
	else
		if [ "$extension" = "mp3" ]; then
			songcomposer=${songcomposer//;/, }
		else
			songcomposer=${songcomposert//\//, }
		fi
	fi

	if [ "$songwriter" = "null" ]; then
		songwriter=""
	fi

	if [ "$songauthor" = "null" ]; then
		songauthor="$songwriter"
	fi

	if [ "$songartists" = "null" ]; then
		songartists=""
	fi

	if [ "$songengineer" = "null" ]; then
		songengineer=""
	fi

	if [ "$songproducer" = "null" ]; then
		songproducer=""
	fi

	if [ "$songmixer" = "null" ]; then
		songmixer=""
	fi

	if [ "$songbarcode" = "null" ]; then
		songbarcode=""
	fi

	if [ "$songcomment" = "null" ]; then
		songcomment=""
	fi

	if [ -f "$file" ]; then
		if [ ! -f "$filedest" ]; then
			if [ "$FORMAT" = "OPUS" ]; then 
				if opusenc --bitrate $ConversionBitrate --vbr "$file" "$filedest" 2> /dev/null; then
					if [ -f "$filedest" ]; then
						echo "$logheader :: Encoding Succcess :: $FORMAT :: $directory :: $filename"
					fi
				else
					echo "Error"
				fi			
			else
				if ffmpeg -loglevel warning -hide_banner -nostats -i "$file" -n -vn $options "$filedest" < /dev/null; then
					if [ -f "$filedest" ]; then
						echo "$logheader :: Encoding Succcess :: $FORMAT :: $directory :: $filename"
					fi
				else
					echo "$logheader :: Error"
				fi
			fi
		fi
		if [ ! -f "$filedest" ]; then
			echo "$logheader :: ERROR: EXITING :: $directory :: $filename"
		fi
	fi
	if [ "$setextension" == "m4a" ]; then
		if [ -f "$filedest" ]; then
			echo "$logheader :: Tagging :: $directory :: $filename"
			python3 /config/scripts/tag.py \
				--file "$filedest" \
				--songtitle "$songtitle" \
				--songalbum "$songalbum" \
				--songartist "$songartist" \
				--songartistalbum "$songartistalbum" \
				--songbpm "$songbpm" \
				--songcopyright "$songcopyright" \
				--songtracknumber "$songtracknumber" \
				--songtracktotal "$songtracktotal" \
				--songdiscnumber "$songdiscnumber" \
				--songdisctotal "$songdisctotal" \
				--songcompilation "$songcompilation" \
				--songlyricrating "$songlyricrating" \
				--songdate "$songdate" \
				--songyear "$songyear" \
				--songgenre "$songgenre" \
				--songcomposer "$songcomposer" \
				--songisrc "$songisrc" \
				--songauthor "$songauthor" \
				--songartists "$songartists" \
				--songengineer "$songengineer" \
				--songproducer "$songproducer" \
				--songmixer "$songmixer" \
				--songpublisher "$songpublisher" \
				--songcomment "$songcomment" \
				--songbarcode "$songbarcode" \
				--songartwork "$cover"
			echo "Tagged :: $directory :: $filename"
		fi
	fi
	if [ -f "$filedest" ]; then
		if [ -f "$file" ]; then
			rm "$file"
			echo "$logheader :: Deleted :: $directory :: $filename"
		fi
	fi

}

ProcessArtistList () {
	for id in ${!list[@]}; do
		artistnumber=$(( $id + 1 ))
		artistid="${list[$id]}"
		DeezerArtistID="$artistid"
		logheader="$artistnumber of $listcount :: $artistid"
		echo "$logheader :: Processing..."
		ProcessArtist
	done
}

Permissions () {

	find "$LIBRARY" -type f -exec chmod $FilePermissions "{}" + &> /dev/null
	find "$LIBRARY" -type f -exec chmod chown abc:abc "{}" + &> /dev/null
	find "$LIBRARY" -type d -exec chmod $FolderPermissions "{}" + &> /dev/null
	find "$LIBRARY" -type d -exec chmod chown -R abc:abc "{}" + &> /dev/null

}

CleanArtistsWithoutImage () {
	if find "$LIBRARY"  -maxdepth 2 -type f -iname "folder.jpg" | read; then
		artistlist=($(ls /config/list -I "*-related" | cut -f1 -d "-" | sort -u))
		OLDIFS="$IFS"
		IFS=$'\n'
		cleanartistlist=($(find "$LIBRARY" -maxdepth 2 -type f -iname "folder.jpg" | sort -u))
		for id in ${!cleanartistlist[@]}; do
			processid=$(( $id + 1 ))
			file="${cleanartistlist[$id]}"
			folder="$(dirname "$file")"
			found="0"
			notfound="0"
			blankartistmd5="15726542fbe903788d2890ef560a9804"
			md5="$(md5sum "$file")"
			md5clean="$(echo "$md5" | cut -f1 -d " ")"
			if [ "$md5clean" == "$blankartistmd5" ]; then
				for id in ${!artistlist[@]}; do
					processid=$(( $id + 1 ))
					artistid="${artistlist[$id]}"
					#echo "$artistid"
					if echo "$folder" | grep -i "($artistid)" | read; then
						found="1"
						break
					else
						continue
					fi
				done
				if [ "$found" = "0" ]; then
					notfound="1"
				elif [ "$found" = "1" ]; then
					notfound="0"
				fi
			fi
			if [ "$notfound" = "1" ]; then
				echo "Blank Artist Image Found :: $folder :: ArtistID not found in list (/config/list), deleting..."
				rm -rf "$folder"
			else
				continue
			fi
		done
		IFS="$OLDIFS"
	fi
}

ProcessArtist () {
	DeezerArtistID="$artistid"
	if [ "$mode" == "artist" ]; then
		dlurl="https://www.deezer.com/artist/${DeezerArtistID}"
	fi
	if [ "$mode" == "discography" ]; then
		dlurl="https://www.deezer.com/artist/${DeezerArtistID}/discography"
	fi
	ArtistCache
	logheader="$logheader :: $artistname"
	if [ -f "/config/cache/${DeezerArtistID}-complete" ]; then
		echo "$logheader :: Already archived..."
	elif find /config/ignore -type f -iname "${DeezerArtistID}" | read; then
		echo "$logheader :: Skipping :: Ignore Artist ID Found... "
	else

	sleep 2
		touch "/config/scripts/temp"
		AlbumDL
		if [ "$RemoveDuplicates" = "true" ]; then
			RemoveDuplicatesFunction
		fi

		FileVerification

		if [ "$RemoveArtistWithoutImage" = "true" ]; then
			CleanArtistsWithoutImage
		fi

		if [[ "$FORMAT" == "AAC" || "$FORMAT" = "OPUS" || "$FORMAT" = "ALAC" ]]; then
			ConverterTagger
		elif [ "$FORMAT" == "MP3" ]; then
			if [ "$ConversionBitrate" == "320" ]; then
				sleep 0.01
			elif [ "$ConversionBitrate" == "128" ]; then
				sleep 0.01
			else
				ConverterTagger
				sleep 60
			fi
		fi
		AddReplaygainTags
		Permissions
		PlexNotification
		if [ -f "/config/cache/${DeezerArtistID}-info.json" ]; then
			echo "$logheader :: ARTIST CACHE :: Updating with successful archive information..."
			touch "/config/cache/${DeezerArtistID}-complete"
		fi
		rm "/config/scripts/temp"
	fi
}

ProcessArtistRelated () {
	if  [ "$RELATED_ARTIST_RELATED" = "true" ]; then
		relatedprocesslist=($(ls /config/list | cut -f2 -d "/" | cut -f1 -d "-" | sort -u))
	else
		relatedprocesslist=($(ls /config/list -I "*-related" | cut -f2 -d "/" | cut -f1 -d "-" | sort -u))
	fi
	for id in ${!relatedprocesslist[@]}; do
		artistnumber=$(( $id + 1 ))
		artistid="${relatedprocesslist[$id]}"
		DeezerArtistID="$artistid"
		if [ -f "/config/cache/${DeezerArtistID}-related.json" ]; then
			artistrelatedfile="$(cat "/config/cache/${DeezerArtistID}-related.json")"
			artistrelatedcount="$(echo "$artistrelatedfile" | jq -r ".total")"
			if [ "$artistrelatedcount" -gt "0" ]; then
				echo  "Processing Artist ID: ${DeezerArtistID} :: $artistrelatedcount Related artists..."
				artistrelatedidlist=($(echo "$artistrelatedfile" | jq ".data[] | select(.nb_fan >= $fancount) | .id" | head -n $relatedcount))
				artistrelatedidlistcount=$(echo "$artistrelatedfile" | jq ".data[] | select(.nb_fan >= $fancount) | .id" | head -n $relatedcount | wc -l)
				echo  "Processing Artist ID: ${DeezerArtistID} :: $artistrelatedidlistcount Related artists matching minimum fancount of $fancount"
				for id in ${!artistrelatedidlist[@]}; do
					relatedartistnumber=$(( $id + 1 ))
					artistrelatedid="${artistrelatedidlist[$id]}"					
					if [ ! -f "/config/list/$artistrelatedid-related" ]; then
						touch "/config/list/$artistrelatedid-related"
					fi
				done
			fi
		fi
	done
}

CleanCacheCheck () {
	if [ -d "/config/cache" ]; then

		if [ -f "/config/cache/cleanup-cache-check" ]; then
			rm "/config/cache/cleanup-cache-check"
		fi
		if [ -f "/config/cache/cleanup-cache-related-check" ]; then
			rm "/config/cache/cleanup-cache-related-check"
		fi
		touch -d "168 hours ago" "/config/cache/cleanup-cache-check"
		touch -d "730 hours ago" "/config/cache/cleanup-cache-related-check"
		if find "/config/cache" -type f -iname "*-info.json" -not -newer "/config/cache/cleanup-cache-check" | read; then
			cachechecklist=($(find "/config/cache" -type f -iname "*.json" -not -newer "/config/cache/cleanup-cache-check" | cut -f2 -d "/" | cut -f1 -d "-" | sort -u))
			for id in ${!cachechecklist[@]}; do
				listprocess=$(( $id + 1 ))
				artistid="${cachechecklist[$id]}"
				onlinealbumlistcount="$(curl -s "https://api.deezer.com/artist/${artistid}" |  jq -r '.nb_album')"
				sleep 1
				cachealbumlistcount="$(cat "/config/cache/$artistid-info.json" | jq -r '.nb_album')"
				if [ "${onlinealbumlistcount}" -ne "${cachealbumlistcount}" ]; then
					echo "Cache Artist ID: $artistid invalid... removing..."
					rm "/config/cache/$artistid-info.json"
					if [ -f "/config/cache/${artistid}-complete" ]; then
						rm "/config/cache/${artistid}-complete"
					fi
				else
					echo "Cache Artist ID: $artistid still valid... updating timestamp..."
					touch "/config/cache/$artistid-info.json"
				fi
			done
		fi
		if find "/config/cache" -type f -iname "*-related.json" -not -newer "/config/cache/cleanup-cache-related-check" | read; then
			echo "Removing Cached Artist Related Info files older than 730 Hours..."
			find "/config/cache" -type f -iname "*-related.json" -not -newer "/config/cache/cleanup-cache-related-check" -delete
		fi
	        if [ -f "/config/cache/cleanup-cache-check" ]; then
			rm "/config/cache/cleanup-cache-check"
		fi
			if [ -f "/config/cache/cleanup-cache-related-check" ]; then
			rm "/config/cache/cleanup-cache-related-check"
		fi
	fi
}

RemoveDuplicatesFunction () {
	if find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -newer "/config/scripts/temp" | read; then
		OLDIFS="$IFS"
		IFS=$'\n'
		explicitfolderlist=($(find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -iname "* (Explicit)" -newer "/config/scripts/temp"))
		cleanfolderlist=($(find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -not -iname "* (Explicit)" -not -iname "* (Deluxe*" -newer "/config/scripts/temp"))
		IFS="$OLDIFS"
		echo "$logheader :: Removing Duplicate Clean Albums"
		for id in ${!explicitfolderlist[@]}; do
			processid=$(( $id + 1 ))
			folder="${explicitfolderlist[$id]}"
			foldername="$(basename "$folder")"
			folderpath="$(dirname "$folder")"
			foldernameclean="$(echo "${foldername}" | sed 's/\ -\ /;/;s/\ -\ /;/;s/\ -\ /;/;s/\ -\ /;/')"
			OLDIFS="$IFS"
			IFS=';' read -r -a foldersplit <<< "$foldernameclean"
			IFS="$OLDIFS"
			Artist="$(echo "${foldersplit[0]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Type="$(echo "${foldersplit[1]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Year="$(echo "${foldersplit[2]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Album="$(echo "${foldersplit[4]}" | sed 's/ *$//g' | sed 's/^ *//g' | sed 's/ (Explicit)//g')"
			find "$LIBRARY" -type d -iname "${Artist} - ${Type} - * - * - ${Album}" -not -iname "* (Explicit)" -exec rm -rf {} \;

		done

		echo "$logheader :: Removing Duplicate non-deluxe Clean Albums"
		for id in ${!cleanfolderlist[@]}; do
			processid=$(( $id + 1 ))
			folder="${cleanfolderlist[$id]}"
			foldername="$(basename "$folder")"
			folderpath="$(dirname "$folder")"
			foldernameclean="$(echo "${foldername}" | sed 's/\ -\ /;/;s/\ -\ /;/;s/\ -\ /;/;s/\ -\ /;/')"
			OLDIFS="$IFS"
			IFS=';' read -r -a foldersplit <<< "$foldernameclean"
			IFS="$OLDIFS"
			Artist="$(echo "${foldersplit[0]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Type="$(echo "${foldersplit[1]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Year="$(echo "${foldersplit[2]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			Album="$(echo "${foldersplit[4]}" | sed 's/ *$//g' | sed 's/^ *//g')"
			if find "$LIBRARY" -type d -iname "${Artist} - Album - * - * - ${Album} (Deluxe*" -not -iname "* (Explicit)" | read; then
				rm -rf "$folder"
			fi
		done
	fi
}

AddMissingArtists () {
	completeartistlist=($(find $LIBRARY -maxdepth 1 -mindepth 1 | grep -o '(*[[:digit:]]*)' | sed 's/(//g;s/)//g' | sort -u))
	for id in ${!completeartistlist[@]}; do
		completeprocessid=$(( $id + 1 ))
		completeartistid="${completeartistlist[$id]}"
		if ls /config/list | cut -f2 -d "/" | cut -f1 -d "-" | sort -u | grep -i "$completeartistid" | read; then
			continue
		fi
		if [ ! -f "/config/list/$completeartistid-complete" ]; then
			echo "Adding missing artistid $completeartistid"
			touch "/config/list/$completeartistid-complete"
		fi
	done
}

PlexNotification () {

	if [ "$NOTIFYPLEX" == "true" ]; then
		if find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d -newer "/config/scripts/temp" | read; then
			OLDIFS="$IFS"
			IFS=$'\n'
			updatedfolders=($(find "$LIBRARY" -mindepth 2 -maxdepth 2 -type d  -newer "/config/scripts/temp"))
			IFS="$OLDIFS"
			for id in ${!updatedfolders[@]}; do
				processid=$(( $id + 1 ))
				plexfolder="${updatedfolders[$id]}"
				plexfolderencoded="$(jq -R -r @uri <<<"${plexfolder}")"
				curl -s "$PLEXURL/library/sections/$plexlibrarykey/refresh?path=$plexfolderencoded&X-Plex-Token=$PLEXTOKEN"
				echo "$logheader :: Plex Scan notification sent! ($plexfolder)"
			done
		fi
	fi
}


Configuration
CleanCacheCheck
echo "############################################ SCRIPT START"
if [ "$LidarrListImport" = "true" ] || [ "$CompleteMyArtists" = "true" ] || [ "$RELATED_ARTIST" = "true" ]; then
	echo "Adding Missing Artist ID's..."
	if [ "$LidarrListImport" = "true" ]; then
		LidarrListImport
	fi
	if [ "$CompleteMyArtists" = "true" ]; then
		AddMissingArtists
	fi
	if  [ "$RELATED_ARTIST" = "true" ]; then
		ProcessArtistRelated
	fi
fi
if ls /config/list | read; then
	if ls /config/list -I "*-related" -I "*-lidarr" -I "*-complete" | read; then
		listcount="$(ls /config/list -I "*-related" -I "*-lidarr" -I "*-complete" | wc -l)"
		listregtext="$listcount Artists (Not realted/imported)"
	else
		listregtext="0 Artists (Not realted/imported)"
	fi

	if ls /config/list/*-related 2> /dev/null | read; then
		listrelatedcount="$(ls /config/list | grep "related" | cut -f1 -d "-" | sort -u | wc -l)"
		relatedtext="$listrelatedcount Related Artists"
		if [ "$RELATED_ARTIST" = "true" ]; then
			relatedoption=""
		else
			relatedoption=" -not -iname *-related"
		fi
	else
		relatedtext="0 Related Artists"
	fi

	if ls /config/list/*-lidarr 2> /dev/null | read; then
		listlidarrcount="$(ls /config/list | grep "lidarr" | cut -f1 -d "-" | sort -u | wc -l)"
		lidarrtext="$listlidarrcount Lidarr Artists"
		if [ "$LidarrListImport" = "true" ]; then
			lidarroption=""
		else
			lidarroption=" -not -iname *-lidarr"
		fi
	else
		lidarrtext="0 Lidarr Artists"
	fi

	if ls /config/list/*-complete 2> /dev/null | read; then
		listcompletecount="$(ls /config/list | grep "complete" | cut -f1 -d "-" | sort -u | wc -l)"
		completetext="$listcompletecount Complete Artists"
		if [ "$CompleteMyArtists" = "true" ]; then
			completeoption=""
		else
			completeoption=" -not -iname *-complete"
		fi
	else
		completetext="0 Complete Artists"
	fi

	listcount="$(find /config/list -mindepth 1${lidarroption}${relatedoption}${completeoption} | sed 's%/config/list/%%g' | cut -f1 -d "-" | sort -u | wc -l)"
	list=($(find /config/list -mindepth 1${lidarroption}${relatedoption}${completeoption} | sed 's%/config/list/%%g' | cut -f1 -d "-" | sort -u))
	echo "Finding Artist ID files"
	echo "$listcount Artists Found!"
	echo "Artist List comprised of:"
	echo "$listregtext"
	if [ "$RELATED_ARTIST" = "true" ]; then
		echo "$relatedtext"
	fi
	if [ "$LidarrListImport" = "true" ]; then
		echo "$lidarrtext"
	fi
	if [ "$CompleteMyArtists" = "true" ]; then
		echo "$completetext"
	fi
	ProcessArtistList
else
	echo "No artists to process, add artist files to list directory"
fi

Permissions
echo "############################################ SCRIPT END"
exit 0
