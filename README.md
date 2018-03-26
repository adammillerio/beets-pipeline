# beets

This is a collection of scripts used for a beets music management workflow.

# Components
This workflow is composed of beets music manager, several python scripts, and a manager script called beets.sh.

## beets
The beets music manager is used to perform the intial import steps on an album. There are two resources which beets relies on in order to function, stored under `~/.config/beets`. 

* `config.yaml` - Provides the configuration to be used by the beets music manager. The configuration file is well documented, but additional documentation can be found on the beets website.
* `library.db` - SQLite database representing the library as beets sees it. Typically, this should NOT modified outside of the beets application. The only exception is when moving the library location, at which point `fix_paths.py` should be ran in order to update the paths to music files in the database.

## Scripts
A collection of Python scripts have been created in order to fill in the gaps of the beets music manager. General workflow descriptions follow, but additional information is available as comments within the scripts themselves.

### beetutils.py

A collection of helper functions referenced by all scripts, they are documented in the file itself.

### audit_missing_beets_music.py

In order to ensure that no music is in the beets database that does not exist in the music library, this performs the following steps:

* Retrieves all of the song paths from the beets database as an array
* Retrieves all of the song paths from the music library folder as an array
* Compares both arrays, and prints any songs present in beets but not in the library
* Exits with 0 if no missing songs, 1 if there are songs missing

### audit_missing_library_music.py

The inverse of `audit_missing_beets_music.py`, which performs the following steps:

* Retrieves all of the song paths from the beets database as an array
* Retrieves all of the song paths from the music library folder as an array
* Compares both arrays, and prints any songs present in the library but not in the beets database
* Exits with 0 if no missing songs, 1 if there are songs missing

### audit_missing_artifacts.py

Checks whether or not a certain artifact (typically cover.jpg) is not present in an album within the library:

* Retrieves a list of all paths to albums in the music library
* Checks for the presence of the artifact in each album path, printing the path if it is missing
* Exits with 0 if no missing artifacts, 1 if there are artifacts missing

### fix_artifacts.py

Checks for all artifacts of a provided filetype (or directories if `--ext=dir`), and ensures that they match the "$artist - $album" format:

* Retrieves a list of all paths to albums in the music library
* Checks for the presence of the artifact recursively in each album path, printing the path if it is detected
    * If a dryrun, indicate that it found a matching file, and end processing
* Renames the artifact to "$artist - $album" format
    * If `--delete` specified, deletes the artifact instead
    * If `--move` specified, moves artifact to directory specified in `--movedir`
* Exits with 0 if not a dry run, or no matching files, 1 if a dry run with matched files

The only exception is if it is checking jpg artifacts, in which `cover.jpg` will always be skipped.

### audit_missing_converted_music.py

Checks if there are songs in the beets database that do not have converted equivalents:

* Retrieves a list of all song paths in the beets database
* Retrieves a list of all song paths in the specified converted directory
* Prints out any paths in the beets database that are not present in the converted directory
* Exits with 0 if no missing converted files, 1 if there are converted files missing

### copy_covers.py

Copies any missing `cover.jpg` files over to the converted directory, and optionally embeds them into the tracks as ID3 tags:

* Retrieves a list of all paths to albums in the converted library
* Checks for the presence of `cover.jpg` in each album path, printing the path if it is not found
    * If a dryrun, indicate that it found no matching file, and end processing
* Copies the cover.jpg from the library album to the converted album
    * If `--embed` is specified, embeds the cover into every track
* exits with 0 if not a try run, or no missing covers, 1 if a dry run with missing covers

## beets.sh

`beets.sh` is a script that provides an automation of the music management workflow, which utilizes the above scripts. It offers the following configuration options:

| Name  | Default  | Description  |
|---|---|---|
| BEETS_BIN | beet | Path to the `beet` binary to use for beets operations |
| PYTHON_BIN | python3 | Path to the `python3` binary to use for python scripts |
| IMPORT_DIR | ~/media/Music/Import | Path for beets to import music from |
| LIBRARY_DIR | ~/media/Music/FLAC | Path to the library folder that beets manages |
| CONVERTED_DIR | ~/media/Music/V2 | Path to the converted music folder that beets manages |
| ARTIFACT_DIR | ~/media/Misc/Artifacts | Path to move artifacts to |
| BEETS_DB | ~/.config/beets/library.db | Path to the SQLite database beets maintains |
| BEETS_SUBDIR | FLAC | Subdirectory of the base Music folder that is in the beets database, e.g. FLAC if the library folder is ~/media/Music/FLAC |
| LIBRARY_SUBDIR | FLAC | Subdirectory of the base Music folder that beets manages, e.g. FLAC if the library folder is ~/media/Music/FLAC |
| CONVERTED_SUBDIR | V2 | Subdirectory of the converted music folder that beets manages, e.g. V2 if the converted folder is ~/media/Music/V2 |
| CONVERTED_EXTENSION | mp3 | Extension of the converted song files |
| INTERACTIVE | true | Whether or not script is being ran interactively, if set to false, it will never pause for user input |

Currently, the script provides the following "steps":

| Step | Description |
|---|---|
| import_library | Imports all files currently in the import directory |
| audit_library | Runs audit_beets_music, audit_library_music, and audit_music_covers |
| audit_beets_music | Checks for music in the beets database not present in the library folder |
| audit_library_music | Checks for music in the library folder not present in the beets database |
| audit_music_covers | Checks for albums that do not have cover.jpg files present |
| fix_library | Runs fix_cue_artifacts, fix_log_artifacts, fix_jpg_artifacts, and fix_dir_artifacts |
| fix_log_artifacts | Checks for log artifacts and corrects them if necessary |
| fix_cue_artifacts | Checks for cue artifacts and corrects them if necessary |
| fix_jpg_artifacts | Checks for jpg artifacts other than `cover.jpg` and moves them if necessary |
| fix_dir_artifacts | Checks for dir artifacts and deletes them if necessary |
| convert_library | Converts all music in the beets database, storing output in ./convert.log |
| audit_converted | Runs audit_converted_music |
| audit_converted_music | Checks for music in the beets database not present in the converted folder |
| fix_converted | Runs fix_converted_covers |
| fix_converted_covers | Copies any missing covers from the library folder to the converted folder and embeds them |
| cleanup_import | Lists all leftover files in the import directory, and deletes them if necessary |
| full | Runs import_library, audit_library, fix_library, convert_library, audit_converted, fix_converted, and cleanup_import |

These can be invoked with `./beets.sh $STEP`. This MUST be ran from the working directory of beets.sh so it can reference the Python scripts
