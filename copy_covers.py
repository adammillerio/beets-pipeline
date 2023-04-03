#!/usr/bin/env python3
# copy_covers.py
# Lists all albums in a music library as well as a converted library
# then, if cover.jpg is not present, copies it from the music library
# Optionally, it will also embed the art in the mp3s at time of copy
# Requires mutagen
# USAGE:
# --dir - Directory to search, in beets format
# --librarydir - Name of the subdir for the library folder
# --converteddir - Name of the subdir for the converted folder
# --dryrun - List the folders without missing covers only
# --embed - Embed covers into the mp3 files at time of copy
# EXAMPLE:
# Copy all missing covers from ~/Music/FLAC into ~/Music/V2
# python3 copy_covers.py --dir=~/Music/FLAC --librarydir=FLAC --converteddir=V2
# Copy all missing covers from ~/Music/FLAC into ~/Music/V2 and embed
# python3 copy_covers.py --dir=~/Music/FLAC --librarydir=FLAC --converteddir=V2 --embed
# List all missing covers from ~/Music/V2 without copying them
# python3 copy_covers.py --dir=~/Music/FLAC --librarydir=FLAC --converteddir=V2 --dryrun
import argparse,os,beetutils,fnmatch
from shutil import copyfile
from mutagen.mp3 import MP3
from mutagen.id3 import ID3, APIC, error

def main(library_dir: str, library_subdir: str, converted_subdir: str, dry_run: bool, embed: bool) -> int:
    # Expansion
    library_dir = os.path.expanduser(library_dir)

    # List all albums in the library
    library_albums = beetutils.get_library_albums(library_dir)
    # Replace the library path with the converted path, e.g. ~/Music/FLAC/Artist becomse ~/Music/V2/Artist
    converted_albums = [library_album.replace(library_subdir, converted_subdir) for library_album in library_albums]

    audit_result = True

    # Go through each album in the library
    for index, item in enumerate(library_albums):
        # Form the cover.jpg path
        library_cover_path = os.path.join(library_albums[index], "cover.jpg")
        converted_cover_path = os.path.join(converted_albums[index], "cover.jpg")

        # If the cover.jpg doesn't exist in the converted album path, print it
        if not os.path.isfile(converted_cover_path):
            print(converted_cover_path)

            if not dry_run:
                # Copy the cover.jpg from the library path to the converted path
                copyfile(library_cover_path, converted_cover_path)

                # If embedding, embed the copied cover.jpg into every song in the album folder
                if embed:
                    with open(converted_cover_path, "rb") as cover_file:
                        # Load the cover
                        cover = cover_file.read()

                        for song in fnmatch.filter(os.listdir(converted_albums[index]), "*.mp3"):
                            embed_cover(os.path.join(converted_albums[index], song), cover)
            else:
                audit_result = False
    
    return 0 if audit_result else 1

def embed_cover(song_path: str, cover: bytes) -> None:
    """
    Embeds a provided jpg file into a song's ID3 metadata

    Args:
        song_path: Path to the song to embed within
        cover: Bytes object containing song cover
    """

    # Mutagen MP3 object using the song path
    song = MP3(song_path, ID3=ID3)

    # Attempt to add ID3 tags and just continue if they already exist
    try:
        song.add_tags()
    except error:
        pass
    
    # Add the cover file as an ID3 tag
    song.tags.add(
        APIC(
            encoding=3, # utf-8
            mime="image/jpeg",
            type=3, # cover image
            desc=u'Cover',
            data=cover
        )
    )

    # Save the song
    song.save()

if __name__ == "__main__":
    # Interactive command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", nargs="?", default="~/media/Music/FLAC", help="Location of the beets music library files")
    parser.add_argument("--librarydir", nargs="?", default="FLAC", help="Name of the subdir for the library folder")
    parser.add_argument("--converteddir", nargs="?", default="V2", help="Name of the subdir for the converted folder")
    parser.add_argument("--dryrun", type=beetutils.string_to_boolean, nargs="?", const=True, default="no", help="Dry run, don't modify artifacts")
    parser.add_argument("--embed", type=beetutils.string_to_boolean, nargs="?", const=True, default="no", help="Embed the cover in the songs")
    args = parser.parse_args()

    exit(main(args.dir, args.librarydir, args.converteddir, args.dryrun, args.embed))
