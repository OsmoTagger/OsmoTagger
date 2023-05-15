import os

# This script renames the preset icons so that the name consists of the path to the file.
# For example: presets/accommodation/basic_hut.svg -> presets+accommodation+basic_hut.svg
#
# In the file with presets, the path to the icon is stored as: presets/accommodation/basic_hut.svg
# When parsing a file, the "/" symbol is replaced with a "+", thus getting a set of icons with unique names.
# 
# You can download the original icons from the Josm repository - https://github.com/JOSM/josm/tree/master/resources/images/presets
# Place the script in the same directory as the "presets" folder and run it.
# All files will be renamed and saved in the original directory.

dir_path = 'presets'

def list_files(directory):
    for filename in os.listdir(directory):
        path = os.path.join(directory, filename)
        if os.path.isfile(path):
            newName = path.replace("/", "+")
            os.rename(path, newName)

def list_folders(path):
    print("-------------------------------------")
    print(path)
    list_files(path)
    for foldername in os.listdir(path):
        folderpath = os.path.join(path, foldername)
        if os.path.isdir(folderpath):
            list_folders(folderpath)

# Run
list_folders(dir_path)