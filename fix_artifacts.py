#!/usr/bin/env python3
# fix_artifacts.py
# A tool for managing artifacts within a music library
# Detects all artifacts matching an extension and either deletes them, or
# renames them in "$artist - $album" format
# USAGE:
# --dir - Directory to search, in beets format
# --ext - File extension of artifacts to search for, jpg will skip cover.jpg
# --delete - Delete the artifacts instead of correcting them
# --dryrun - List the nonstandard artifacts without correction
# EXAMPLE:
# Search ~/media/Music/FLAC for cue files and rename them
# python3 fix_artifacts.py --dir=~/media/Music/FLAC --ext=cue
# Search ~/Music for jpg files other than cover.jpg and delete them
# python3 fix_artifacts.py --dir=~/media/Music/FLAC --ext=jpg --delete
import argparse,os,beetutils

def main(library_dir, artifact_extension, delete, dry_run):
    # Extension
    library_dir = os.path.expanduser(library_dir)

    library_albums = beetutils.get_library_albums(library_dir)

    audit_result = True

    # Go through each album in the library
    for library_album in library_albums:
        # Retrieve only the folder name from the full path, which is the album name
        album_name = os.path.basename(library_album)

        # Retrieve artifacts in this album's folder and go through them
        for artifact in beetutils.get_folder_artifacts(library_album, artifact_extension):
            # Skip the artifact if it is just cover.jpg
            if os.path.basename(artifact) == "cover.jpg":
                continue
            
            # Retrieve the name of the file without the extension, test.jpg becomes test
            artifact_album = os.path.splitext(artifact)[0]

            # If the name of the file does not match the album name, act on it
            if artifact_album != album_name:
                # Create the full path to the artifact and print it
                artifact_path = os.path.join(library_album, artifact)
                print(artifact_path)

                # If this is not a dry run, act on it
                if not dry_run:
                    if delete:
                        # Delete the artifact, unless it is a directory
                        os.remove(artifact_path, dir_fd=None)
                    else:
                        # Create the "corrected" filename and path "$artist - $album.$extension"
                        fixed_path = os.path.join(library_album, "%s.%s" % (album_name, artifact_extension))
                        
                        # Perform the correction rename
                        os.rename(artifact_path, fixed_path)
                else:
                    audit_result = False
    
    exit(0 if audit_result else 1)

def string_to_boolean(string_value):
    """
    Convert a string argument to a boolean

    Args:
        string_value: String value to be converted
    
    Returns:
        A boolean representation of the string value
    
    Raises:
        argparse.ArgumentTypeError: If the string provided does not have a boolean equivalent
    """

    if string_value.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif string_value.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

if __name__ == "__main__":
    # Interactive command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", nargs="?", default="~/media/Music/FLAC", help="Location of the beets music library files")
    parser.add_argument("--ext", nargs="?", default="cue", help="The extension of the artifact to fix")
    parser.add_argument("--delete", type=string_to_boolean, nargs="?", const=True, default="no", help="Delete the artifact instead of renaming it (DANGEROUS)")
    parser.add_argument("--dryrun", type=string_to_boolean, nargs="?", const=True, default="no", help="Dry run, don't modify artifacts")
    args = parser.parse_args()

    exit(main(args.dir, args.ext, args.delete, args.dryrun))
