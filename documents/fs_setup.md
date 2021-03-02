

# Set up FreeSurfer 
Before using any FreeSurfer command, including freeview (or tksurfer etc), FreeSurfer has to be set properly (in the terminal). The steps in bash are:

- `export FREESURFER_HOME=/Applications/freesurfer`
- `source $FREESURFER_HOME/SetUpFreeSurfer.sh`
- `export SUBJECTS_DIR=/full/path/to/subject/dir`
- `cd to/the/functional/data/folder`

Note: for FreeSurfer 7.1 or later, you may need to update bash if you are still using the default bash in Mac. You may follow the instruction [here](https://itnext.io/upgrading-bash-on-macos-7138bd1066ba).
