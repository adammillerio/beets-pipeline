#!/usr/bin/env python3
# audit_missing_library_music
# Retrieves all songs in both the beets datbase and converted library folder
# then returns a list of all paths in the beets database that do not exist in the converted library folder
# USAGE:
# --db - Path to the beets datbase file
# --dir - Directory to search, in beets format
# --beetsdir - Name of the subdir for the beets library present in the db
# --librarydir - Name of the subdir for the library folder
# --ext - File format of the converted directory
# EXAMPLE:
# Check all mp3 versions of songs in ~/library.db located at ~/Music/FLAC that do not exist under ~/Music/V2
# python3 audit_missing_converted_music.py --db=~/library.db --dir=~/Music/V2 --beetsdir=FLAC --librarydir=V2 --ext=mp3
import argparse,beetutils
from os.path import expanduser

def main(db, library_dir, beets_subdir, library_subdir, extension):
    # Expansion
    db = expanduser(db)
    library_dir = expanduser(library_dir)

    # Retrieve both lists
    beets_songs = [beets_song.replace(beets_subdir, library_subdir) for beets_song in beetutils.get_beets_songs(db, extension)]
    library_songs = beetutils.get_library_songs(library_dir, extension)

    audit_result = True

    # Print any songs in the library folder not present in the beets database
    for beets_song in beets_songs:
        if beets_song not in library_songs:
            audit_result = False
            print(beets_song)
    
    exit(0 if audit_result else 1)

if __name__ == "__main__":
    # Interactive command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", nargs="?", default="~/.config/beets/library.db", help="The beets database")
    parser.add_argument("--dir", nargs="?", default="~/media/Music/V2", help="Location of the beets music library files")
    parser.add_argument("--beetsdir", nargs="?", default="FLAC", help="Name of the subdir for the beets library present in the db")
    parser.add_argument("--librarydir", nargs="?", default="V2", help="Name of the subdir for the library folder")
    parser.add_argument("--ext", nargs="?", default="mp3", help="File format of the converted directory")
    args = parser.parse_args()

    exit(main(args.db, args.dir, args.beetsdir, args.librarydir, args.ext))