(Working in progress...) \
Last updated: 23-Jan-2020

<!-- TOC -->

- [Introduction](#introduction)
  - [Dependencies](#dependencies)
  - [Setup global environment](#setup-global-environment)
- [Pre-processing](#pre-processing)
  - [FreeSurfer (to be updated later)](#freesurfer-to-be-updated-later)
  - [HCP pipeline](#hcp-pipeline)
- [First-level analysis](#first-level-analysis)
  - [Preparations](#preparations)
  - [Make analysis](#make-analysis)
  - [Make contrast](#make-contrast)
  - [Draw label based on contrast](#draw-label-based-on-contrast)
- [Group level analysis (???)](#group-level-analysis-)
  - [Univariate analysis](#univariate-analysis)
  - [Multivariate analysis](#multivariate-analysis)
  - [Searchlight with CoSMoMVPA](#searchlight-with-cosmomvpa)
- [Data visualization](#data-visualization)
  - [Visualize nifty files](#visualize-nifty-files)
  - [Check recon-all results](#check-recon-all-results)
    - [Check surface files only](#check-surface-files-only)
    - [Check co-registration](#check-co-registration)
  - [Check first-level analysis results](#check-first-level-analysis-results)
    - [Screenshots for contrast results](#screenshots-for-contrast-results)
    - [Screenshots for label overlapping](#screenshots-for-label-overlapping)
  - [Check searchlight results](#check-searchlight-results)
- [Future work](#future-work)
- [Q&A](#qa)

<!-- /TOC -->

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/d90f46be5ec94928ab6a56244eed0968)](https://app.codacy.com/manual/HaiyangJin/fMRI-Matlab?utm_source=github.com&utm_medium=referral&utm_content=HaiyangJin/fMRI-Matlab&utm_campaign=Badge_Grade_Dashboard)

# Introduction

These Matlab functions mainly call [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/) commands to analyze fMRI data on the surface, perform multivariate pattern analysis (MVPA) with [CoSMoMVPA](http://www.cosmomvpa.org/) toolbox, and visualize some results with [FreeView](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeviewGuide/FreeviewIntroduction).

**Note**:
1. These functions are only tested in Mac, but have not been tested in Linux.
2. These functions are built based on FreeSurfer 6.0, and therefore some may fail when previous FreeSurfer versions are loaded.  
3. Some default parameters in the functions were set based on our data acquisition protocol, they may be not appropriate for other protocols.

## Dependencies
The following software and toolboxes should be installed properly before using the current toolbox. Also, it is assumed that the user understands [the FS-FAST directory structure](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct) and the general steps (and commands) for performing fMRI data analysis in [FS-Fast](http://freesurfer.net/fswiki/FsFastTutorialV6.0).
- [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/)
- [NIfTI_20140122](https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image)
- [CoSMoMVPA](http://www.cosmomvpa.org/)

## Setup global environment
As most of the functions in this toolbox call FreeSurfer commands which are linux commands, the path to FreeSurfer needs to be added to the global environment `$PATH`. In addition, the matlab/ folder in FreeSurfer (`$FREESURFER_HOME/matlab/`) also needs to be added to Matlab path. These setups could be accomplished in two ways. Once the setup is finished, the functions should work.

- **Method 1**:
  1. Start a new terminal;
  2. Set all the necessary global environment variables (e.g., `$FREESURFER_HOME`, `$SUBJECTS_DIR`) and set up FreeSurfer (the instruction is available in the [FreeSurfer website](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall#Setup.26Configuration));
  3. Start Matlab in the *same* terminal by running `path-to-matlab-folder/bin/matlab` in the terminal. [You also can add the `path-to-matlab-folder/bin` to `$PATH` by following [this](https://apple.stackexchange.com/questions/358687/right-way-to-add-paths-to-path-in-mojave) and run `matlab` in the terminal].

- **Method 2**:
  1. Start Matlab and make sure you added all folders of this toolbox to the Matlab `path`;
  2. Run `fs_setup('path-to-freesurfer-home');` to set `'path-to-freesurfer-home'` as `$FREESURFER_HOME` and add necessary paths to `$PATH`;
  3. Run `fs_subjdir('path-to-subjects-dir');` to set `'path-to-subjects-dir'` as `$SUBJECTS_DIR`;
  4. Run `project = fs_projectinfo('projectName', 'path-to-functional-data-folder');` to save the information about this project (e.g., the path to structure data, the path to the functional data, the number of participants, etc) into the Matlab structure `project`, which will be used by other functions.

# Pre-processing
Data can be pre-processed with FreeSurfer or with [workbench](https://www.humanconnectome.org/software/connectome-workbench) (i.e., HCP pipeline). After pre-processing, there should be one folder consisting the functional data and a separate folder consisting structural data (i.e., the `recon-all` results).

## FreeSurfer (to be updated later)
- Structure Data
  - `system('recon-all -s subjCode -i path/to/T1/image -all')`  
- Functional data
  - `system('preproc-sess -sf sessFile -fsd bold -surface self lhrh -mni305 -fwhm 0 -per-run -force')`

## HCP pipeline
Please check [the HCP website](https://www.humanconnectome.org/) or [this paper](https://www.sciencedirect.com/science/article/pii/S1053811913005053?via%3Dihub) for more information about the pre-processing.

To perform the analyses in FreeSurfer for the outputs from HCP, [the FS-FAST directory structure](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct) should be created. `fs_hcp_prepro()` can be used for this purpose.

# First-level analysis
After the preprocessing,

## Preparations

- create paradigm files
- run files
- subjectname
- sessFile

## Make analysis
`fs_mkanalysis()`

## Make contrast
`fs_mkcontrast()`

## Draw label based on contrast
`fv_drawlabel()`

# Group level analysis (???)

## Univariate analysis

## Multivariate analysis
`fs_fun_cosmo_classification()`

## Searchlight with CoSMoMVPA
`fs_fun_cosmo_searchlight()`

# Data visualization

## Visualize nifty files
[ITK-SNAP](http://www.itksnap.org/pmwiki/pmwiki.php)

## Check recon-all results
Run `fv_volmgz('', subjCode)`

### Check surface files only
Run `fv_surfmgz('', 'inflated')` and then select which participants to be displayed in FreeView.

### Check co-registration
`fv_checkreg()`

## Check first-level analysis results

### Screenshots for contrast results
`fs_fun_screenshot_label()`

### Screenshots for label overlapping
`fs_labeloverlap()`

## Check searchlight results
`fv_mgz()`

# Future work
- [ ] Plots
- [ ] Videos

# Q&A
- **How to run linux commands via Matlab?** \
For most cases, you can use the Matlab function [`system()`](https://www.mathworks.com/help/matlab/ref/system.html) to run linux commands (e.g., `system('linux commands')`). However, `system()` does not always do what you want to do. For example, for setting the global environment variable (e.g., `$FREESURFER_HOME`), the Matlab function `setenv()` has to be used (e.g., `setenv('FREESURFER_HOME', '/Applications/freesurfer/')`).  

- **Question** \
The answers.
