
# How to create FreeSurfer-format directory from HCP pipeline outputs?

## From HCP to FreeSurfer

0. Set up FreeSurfer with `fs_setup()`;
1. Set the HCP project folder with `hcp_dir()`;
2. Generate functional data in native space (volume) from MNI space with `hcp_mni2native()`;
3. Create FreeSurfer-format directory, project functional data in native space to surface, and perform (re-)preprocessing with `fs_hcp_preproc()`;
4. Create run list files with `fs_hcp_runlistfile()`, which will be used to perform first and second level analysis in FreeSurfer.

## Potential issues
The functional data in Volume (native space) copied from HCP outputs are already pre-processed. These data are further [(re-)preprocessed](https://surfer.nmr.mgh.harvard.edu/fswiki/preproc-sess#Description) by FreeSurfer (motion correction `mc-sess` and brain-mask creation `mkbrainmask-sess`) before they are projected to surface. It remains unclear whether it is appropriate.
