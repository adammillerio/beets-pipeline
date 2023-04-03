#!/usr/bin/env python3
# audit_missing_artifacts.py
# Given a filename, look for albums in the library which do not contain it
# Detects all albums in a beets library that do not contain a certain artifact
# and outputs their paths to the console
# USAGE:
# --dir - Directory to search, in beets format
# --artifact - The full filename of the artifact to search for
# EXAMPLE:
# Check every album path in ~/Music and report albums that do not have cover.jpg
# python3 audit_missing_artifacts.py --dir=~/Music --artifact=cover.jpg
import argparse,os,beetutils

def main(library_dir: str, artifact: str) -> int:
    library_dir = os.path.expanduser(library_dir)
    library_albums = beetutils.get_library_albums(library_dir)

    audit_result = True

    # Go through each album in the library
    for library_album in library_albums:
        # Build the full path to the album
        album_path = os.path.join(library_dir, library_album)

        # If the artifact is not present in the album path, print it
        if not os.path.exists(os.path.join(album_path, artifact)):
            audit_result = False
            print(album_path)
    
    return 0 if audit_result else 1

if __name__ == "__main__":
    # Interactive command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", nargs="?", default="~/media/Music/FLAC", help="Location of the beets music library files")
    parser.add_argument("--artifact", nargs="?", default="cover.jpg", help="The filename of the artifact to audit for")
    args = parser.parse_args()

    exit(main(args.dir, args.artifact))