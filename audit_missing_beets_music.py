#!/usr/bin/env python3
# audit_missing_beets_music
# Retrieves all songs in both the beets datbase and library folder
# then returns a list of all paths in beets that do not exist in the library
# USAGE:
# --db - Path to the beets datbase file
# --dir - Directory to search, in beets format
# EXAMPLE:
# Search compare the ~/Music library with the ~/library.db beets database
# python3 audit_missing_beets_music.py --dir=~/Music --db=~/library.db
import argparse,beetutils
from os.path import expanduser

def main(db: str, library_dir: str) -> int:
    # Expansion
    library_dir = expanduser(library_dir)
    db = expanduser(db)
    
    # Retrieve both lists
    beets_songs = beetutils.get_beets_songs(db)
    library_songs = beetutils.get_library_songs(library_dir)

    audit_result = True

    # Print any songs in the beets database not present in the library folder
    for beets_song in beets_songs:
        if beets_song not in library_songs:
            audit_result = False
            print(beets_song)
    
    return 0 if audit_result else 1

if __name__ == "__main__":
    # Interactive command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", nargs="?", default="~/.config/beets/library.db", help="The beets database")
    parser.add_argument("--dir", nargs="?", default="~/media/Music/FLAC", help="Location of the beets music library files")
    args = parser.parse_args()

    exit(main(args.db, args.dir))