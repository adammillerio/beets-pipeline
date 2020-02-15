#!/bin/bash
if [ -e .env ]; then
	echo 'env found, loading'
	export $(xargs < .env)
fi

PYTHON_VERSION=${PYTHON_VERSION:-2.7.14}
BEETS_VERSION=${BEETS_VERSION:-1.4.6}
PYLAST_VERSION=${PYLAST_VERSION:-2.1.0}
BS4_VERSION=${BS4_VERSION:-4.6.0}
DISCOGS_CLIENT_VERSION=${DISCOGS_CLIENT_VERSION:-2.2.1}
REQUESTS_VERSION=${REQUESTS_VERSION:-2.11.1}
REQUESTS_OAUTHLIB_VERSION=${REQUESTS_OAUTHLIB_VERSION:-0.8.0}
BEETS_COPYARTIFACTS_VERSION=${BEETS_COPYARTIFACTS_VERSION:-0.1.2}
MUTAGEN_VERSION=${MUTAGEN_VERSION:-1.40.0}

PLATFORM=$(lsb_release -i -s)
USE_VENV=${USE_VENV:-true}
BEETS_BIN=${BEETS_BIN:-beet}
PYTHON_BIN=${PYTHON_BIN:-python}
IMPORT_DIR=${IMPORT_DIR:-~/media/Music/Import}
LIBRARY_DIR=${LIBRARY_DIR:-~/media/Music/FLAC}
CONVERTED_DIR=${CONVERTED_DIR:-~/media/Music/V2}
ARTIFACT_DIR=${ARTIFACT_DIR:-~/media/Music/Misc/Artifacts}
BEETS_DB=${BEETS_DB:-~/.config/beets/library.db}
BEETS_SUBDIR=${BEETS_SUBDIR:-FLAC}
LIBRARY_SUBDIR=${LIBRARY_SUBDIR:-FLAC}
CONVERTED_SUBDIR=${CONVERTED_SUBDIR:-V2}
CONVERTED_EXTENSION=${CONVERTED_EXTENSION:-mp3}
INTERACTIVE=${INTERACTIVE:-true}
BELL=${BELL:-\\a}
USE_SUBSONIC=${USE_SUBSONIC:-false}

activate_venv() {
	echo 'Adding pyenv to PATH'
	PATH="~/.pyenv/bin:$PATH"

	echo 'Activating pyenv'
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"

	echo 'Activating beets venv'
	pyenv activate beets

	echo 'Rehash beets venv'
	pyenv rehash
}

install() {
	if [[ $USE_VENV == 'true' ]]; then
		echo 'Installing beets virtual environment'
		deploy_venv
	fi
	
	echo 'Installing beets'
	deploy_certbot
}

deploy_venv() {
	echo 'Installing platform specific tools'
	if [[ $PLATFORM == 'Debian' ]]; then
		sudo apt update
		sudo apt-get install --no-install-recommends -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
		libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
		xz-utils tk-dev
	fi

	echo 'Checking if pyenv is installed'
	PATH="~/.pyenv/bin:$PATH"
	which pyenv
	if [ $? == '1' ]; then
		echo 'Pyenv not found, installing'

		echo 'Installing pyenv'
		git clone https://github.com/pyenv/pyenv-installer.git pyenv-installer
		chmod +x ./pyenv-installer/pyenv-installer
		./pyenv-installer/pyenv-installer
		rm -rf ./pyenv-installer
	fi

	echo 'Activating pyenv'
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"

	echo "Installing Python v$PYTHON_VERSION"
	pyenv install -s -v $PYTHON_VERSION

	echo 'Creating beets virtualenv'
	pyenv virtualenv $PYTHON_VERSION beets

	echo 'virtualenv created'
}

deploy_beets() {
	echo 'Installing ffmpeg and imagemagick'
	if [[ $PLATFORM == 'Debian' ]]; then
		sudo apt update
		sudo apt install --no-install-recommends -y ffmpeg imagemagick
	fi

	echo 'Installing beets and plugins'
	pip install \
		beets==$BEETS_VERSION \
		pylast==$PYLAST_VERSION \
		beautifulsoup4==$BS4_VERSION \
		discogs-client==$DISCOGS_CLIENT_VERSION \
		requests==$REQUESTS_VERSION \
		requests_oauthlib==$REQUESTS_OAUTHLIB_VERSION \
		beets-copyartifacts==$BEETS_COPYARTIFACTS_VERSION \
		mutagen==$MUTAGEN_VERSION

	echo 'Installing python-itunes'
	pip install https://github.com/ocelma/python-itunes/archive/master.zip
}

import_library() {
	echo "Importing music from $IMPORT_DIR"
	$BEETS_BIN import "$IMPORT_DIR"

	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

audit_library() {
	echo -e "Auditing missing beets music\n"
	audit_beets_music

	if [ $? == '1' ]; then
		echo -e "$BELL \nMusic in beets db not in library! Fix and press any key to continue"
		read < /dev/tty
	fi

	echo -e "Auditing missing library music\n"
	audit_library_music

	if [ $? == '1' ]; then
		echo -e "$BELL \nMusic in library not in beets db! Fix and press any key to continue"
		read < /dev/tty
	fi

	echo -e "Auditing missing music covers\n"
	audit_music_covers

	if [ $? == '1' ]; then
		echo -e "$BELL \nCovers missing! Fix and press any key to continue"
		read < /dev/tty
	fi
}

audit_beets_music() {
	echo "Checking for music in $BEETS_DB not present in $LIBRARY_DIR"
	$PYTHON_BIN audit_missing_beets_music.py \
		--db="$BEETS_DB" \
		--dir="$LIBRARY_DIR"
	
	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

audit_library_music() {
	echo "Checking for music in $LIBRARY_DIR not present in $BEETS_DB"
	$PYTHON_BIN audit_missing_beets_music.py \
		--db="$BEETS_DB" \
		--dir="$LIBRARY_DIR"
	
	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

audit_music_covers() {
	echo "Checking for missing covers in $LIBRARY_DIR"
	$PYTHON_BIN audit_missing_artifacts.py \
		--dir="$LIBRARY_DIR" \
		--artifact="cover.jpg"

	RESULT=$?
	
	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

fix_library() {
	echo "Fixing cue artifacts"
	fix_cue_artifacts

	echo "Fixing log artifacts"
	fix_log_artifacts

	echo "Moving jpg artifacts"
	fix_jpg_artifacts

	echo "Deleting dir artifacts"
	fix_dir_artifacts
}

fix_log_artifacts() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing log artifacts in $LIBRARY_DIR \n"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="log" \
			--dryrun
		RESULT=$?

		if [[ $RESULT == '1' ]]; then
			echo -e "$BELL \nThe above logs will be fixed, press any key to continue"
			read < /dev/tty
		fi
	fi

	if [[ $RESULT == '1' ]]; then
		echo "Fixing log artifacts in $LIBRARY_DIR"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="log"
		RESULT=$?
	fi

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

fix_cue_artifacts() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing cue artifacts in $LIBRARY_DIR \n"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="cue" \
			--dryrun
		RESULT=$?

		if [[ $RESULT == '1' ]]; then
			echo -e "$BELL \nThe above cues will be fixed, press any key to continue"
			read < /dev/tty
		fi
	fi

	if [[ $RESULT == '1' ]]; then
		echo "Fixing cue artifacts in $LIBRARY_DIR"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="cue"
		RESULT=$?
	fi

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

fix_jpg_artifacts() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing jpg artifacts in $LIBRARY_DIR \n"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="jpg" \
			--dryrun
		RESULT=$?

		if [[ $RESULT == '1' ]]; then
			echo -e "$BELL \nThe above jpgs will be moved, press any key to continue"
			read < /dev/tty
		fi
	fi

	if [[ $RESULT == '1' ]]; then
		echo "Moving jpg artifacts in $LIBRARY_DIR"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="jpg" \
			--move \
			--movedir="$ARTIFACT_DIR"
		RESULT=$?
	fi

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

fix_dir_artifacts() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing dir artifacts in $LIBRARY_DIR \n"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="dir" \
			--dryrun
		RESULT=$?

		if [[ $RESULT == '1' ]]; then
			echo -e "$BELL \nThe above dirs will be DELETED, press any key to continue"
			read < /dev/tty
		fi
	fi

	if [[ $RESULT == '1' ]]; then
	echo "Deleting dir artifacts in $LIBRARY_DIR"
		$PYTHON_BIN fix_artifacts.py \
			--dir="$LIBRARY_DIR" \
			--ext="dir" \
			--delete
		RESULT=$?
	fi

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

convert_library() {	
	echo "Converting music in $LIBRARY_DIR"
	$BEETS_BIN convert -y "added:-1d.." > ./convert.log 2>&1

	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

audit_converted() {
	echo -e "Auditing missing converted\n"
	audit_converted_music

	if [ $? == '1' ]; then
		echo -e "$BELL \nConverted music missing! Check converted.log, fix and press any key to continue"
		read < /dev/tty
	fi
}

audit_converted_music() {	
	echo "Checking for music in $CONVERTED_DIR not present in $BEETS_DB"
	$PYTHON_BIN audit_missing_converted_music.py \
		--db="$BEETS_DB" \
		--dir="$CONVERTED_DIR" \
		--beetsdir="$BEETS_SUBDIR" \
		--librarydir="$CONVERTED_SUBDIR" \
		--ext="$CONVERTED_EXTENSION"
	
	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

fix_converted() {
	echo -e "Fixing missing converted covers\n"
	fix_converted_covers
}

fix_converted_covers() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing covers in $CONVERTED_DIR \n"
		$PYTHON_BIN copy_covers.py \
			--dir="$LIBRARY_DIR" \
			--librarydir="$LIBRARY_SUBDIR" \
			--converteddir="$CONVERTED_SUBDIR" \
			--dryrun
		RESULT=$?

		if [[ $RESULT == '1' ]]; then
			echo -e "$BELL \nThe above covers will be copied and embedded, press any key to continue"
			read < /dev/tty
		fi
	fi

	if [[ $RESULT == '1' ]]; then
	echo "Copying and embedding covers in $CONVERTED_DIR"
		$PYTHON_BIN copy_covers.py \
			--dir="$LIBRARY_DIR" \
			--librarydir="$LIBRARY_SUBDIR" \
			--converteddir="$CONVERTED_SUBDIR" \
			--embed
		RESULT=$?
	fi

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

cleanup_import() {	
	if [[ $INTERACTIVE == 'true' ]]; then
		echo -e "Listing files to be deleted in $IMPORT_DIR \n"
		find $IMPORT_DIR/*
		
		echo -e "$BELL \nThe above files and folders will be DELETED, press any key to continue"
		read < /dev/tty
	fi

	rm -rv $IMPORT_DIR/*
	RESULT=$?

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

update_subsonic() {
	echo 'Updating subsonic library'
	
	SUBSONIC_CLIENT=${SUBSONIC_CLIENT:-beets-pipeline}
	SUBSONIC_VERSION=${SUBSONIC_VERSION:-1.15.0}
	SUBSONIC_FORMAT=${SUBSONIC_FORMAT:-json}
	SUBSONIC_URL=${SUBSONIC_URL:?'ERROR: Specify the full URL to subsonic in $SUBSONIC_URL'}
	SUBSONIC_USERNAME=${SUBSONIC_USERNAME:?'ERROR: Specify the username to authenticate to subsonic as $SUBSONIC_USERNAME'}
	SUBSONIC_PASSWORD=${SUBSONIC_PASSWORD:?'ERROR: Specify the password to authenticate to subsonic as $SUBSONIC_PASSWORD'}

	curl -k -X GET \
		"$SUBSONIC_URL/rest/startScan?u=$SUBSONIC_USERNAME&p=$SUBSONIC_PASSWORD&c=$SUBSONIC_CLIENT&v=$SUBSONIC_VERSION&f=$SUBSONIC_FORMAT"
	RESULT=$?

	if [[ $RESULT != '0' ]]; then
		>&2 echo 'ERROR: Subsonic library not updated, check configuration and connectivity'
	else
		echo -e '\nSubsonic library update started'
	fi 

	if [[ $INTERACTIVE == 'false' ]]; then
		exit $RESULT
	else
		return $RESULT
	fi
}

full() {
	import_library
	audit_library
	fix_library
	convert_library
	audit_converted
	fix_converted
	cleanup_import

	if [[ $USE_SUBSONIC == 'true' ]]; then
		update_subsonic
	fi
}

if [[ $USE_VENV == 'true' && $1 != 'deploy_venv' && $1 != 'install' ]]; then
	echo 'Activating beets virtual environment'
	activate_venv
fi

$1
