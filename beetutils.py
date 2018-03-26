#!/usr/bin/env/python3
# beetutils.py
# A collection of helper functions for managing a beets library
import os,fnmatch,sqlite3

def get_library_albums(library_dir):
    """
    Retrieve all paths to albums in a library

    Args:
        library_dir: Path to the library which contains the artist folders
    
    Returns:
        An array of full paths to albums in the library
    """

    library_albums = []

    # Create the paths to all artist subdirectories in the provided directory
    library_artists = [os.path.join(library_dir, file) for file in os.listdir(os.path.abspath(library_dir))]
	
    # Go through each artist in the library
    for library_artist in library_artists:
        # Append the full path to each album subdirectory within this artist subdirectory
        for library_album in os.listdir(library_artist):
            library_albums.append(os.path.join(library_artist, library_album))
    
    return library_albums

def get_folder_artifacts(folder, artifact_extension):
    """
    Retrieve all artifacts that match an extension within a folder

    Args:
        folder: Folder to list artifacts for
        artifact_extension: Extension to match artifacts for
    
    Returns:
        An array of all artifact files that match an extension, without the full path
    """

    return fnmatch.filter(os.listdir(folder), "*.%s" % artifact_extension)

def get_beets_songs(db, extension="flac"):
    """
    Retrieve all paths to songs in a beets database

    Args:
        db: Path to the SQLite beets database
        extension: File extension of paths to return, if comparing converted files
    
    Returns:
        An array of all full song paths in a beets database
    """

    conn = sqlite3.connect(db)

    beets_songs = [row[0].decode("UTF-8") for row in conn.execute("SELECT path FROM items")]
    
    return [os.path.splitext(beets_song)[0] + ".%s" % extension for beets_song in beets_songs]

def get_library_songs(library_dir, extension="flac"):
    """
    Retrieve all paths to songs in a music library

    Args:
        library_dir: Path to the library which contains the artist folders
        extension: Extension of song files, defaults to flac
    
    Returns:
        An array of all full song paths in a music library
    """

    pattern = "*.%s" % extension
    library_songs = []

    # Walk through each the entire directory structure of the library
    for root, dirs, files in os.walk(library_dir):
        # Append any .flac files found
        for filename in fnmatch.filter(files, pattern):
            library_songs.append(os.path.join(root, filename))
    
    return library_songs