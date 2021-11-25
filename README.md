[![DOI](https://zenodo.org/badge/222379947.svg)](https://zenodo.org/badge/latestdoi/222379947)

(Working in progress...) \
Last updated: 2021-11-16

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Introduction](#introduction)
  - [Dependency](#dependency)
- [Preparations](#preparations)
  - [Setup global environment](#setup-global-environment)
  - [Create files needed for FreeSurfer](#create-files-needed-for-freesurfer)
- [Pre-processing](#pre-processing)
  - [FreeSurfer](#freesurfer)
- [First-level analysis](#first-level-analysis)
  - [Configure analysis, contrasts and perform the analysis](#configure-analysis-contrasts-and-perform-the-analysis)
  - [Draw labels based on contrast](#draw-labels-based-on-contrast)
- [Group level analysis](#group-level-analysis)
  - [1. Group level analysis on fsaverage](#1-group-level-analysis-on-fsaverage)
  - [2. Univariate analysis of ROIs on self surface](#2-univariate-analysis-of-rois-on-self-surface)
  - [3. Classification/decoding with CoSMoMVPA](#3-classificationdecoding-with-cosmomvpa)
  - [4. Searchlight with CoSMoMVPA](#4-searchlight-with-cosmomvpa)
  - [Some suggestion for these analyses (or notes for myself)](#some-suggestion-for-these-analyses-or-notes-for-myself)
- [Data visualization](#data-visualization)
  - [Quality assurance of recon-all results](#quality-assurance-of-recon-all-results)
  - [Check other results](#check-other-results)
- [How-to](#how-to)
- [Future work](#future-work)
- [Q&A](#qa)

<!-- /TOC -->


# Introduction

These Matlab functions mainly call [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/) commands to analyze fMRI data on the surface, perform multivariate pattern analysis (MVPA) with [CoSMoMVPA](http://www.cosmomvpa.org/) toolbox, and visualize results with [FreeView](https://surfer.nmr.mgh.harvard.edu/fswiki/FreeviewGuide/FreeviewIntroduction) and codes based on [Dr. Kendrick Kay](https://github.com/kendrickkay)'s work.

Now some wrappers for BIDS, fMRIPrep, and HCPPipeline are also included.

**Note**:
1. These functions were only tested in Mac.
2. These functions were built based on FreeSurfer 6.0, and therefore some may fail when earlier FreeSurfer versions are loaded (it seems to work on later versions).  
3. Some default parameters in the functions were set according to our data acquisition protocol, they may not be appropriate for others.

## Dependency
The following software and toolboxes should be installed properly before using this toolbox. Also, it is assumed that the user understands [the FS-FAST directory structure](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct) and the general steps (and commands) for performing fMRI data analysis in [FS-Fast](http://freesurfer.net/fswiki/FsFastTutorialV6.0).
- [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/);
- [NIfTI_20140122](https://www.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image);
- [CoSMoMVPA](http://www.cosmomvpa.org/) (for running multivariate pattern analysis);
- [knkutils](https://github.com/kendrickkay/knkutils.git) and [cvncode](https://github.com/kendrickkay/cvncode.git) (for visualizations in Matlab).

Check [here (to be added)]() for a full list of dependended toolboxs.


# Preparations
## Setup global environment
As most of the functions in this toolbox call FreeSurfer commands which are linux commands, the path to FreeSurfer needs to be added to the global environment `$PATH`. In addition, the matlab/ folder in FreeSurfer (`$FREESURFER_HOME/matlab/`) also needs to be added to Matlab path. These can be set up in two ways. 

- **Method 1**:
  1. Start a new terminal;
  2. Set all the necessary global environment variables (e.g., `$FREESURFER_HOME`, `$SUBJECTS_DIR` and `$FUNCTIONALS_DIR`) and set up FreeSurfer (the instruction is available on the [FreeSurfer website](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall#Setup.26Configuration));
  3. Start Matlab in the *same* terminal by running `path-to-matlab-folder/bin/matlab` in the terminal. [You may also add the `path-to-matlab-folder/bin` to `$PATH` by following [this instruction](https://apple.stackexchange.com/questions/358687/right-way-to-add-paths-to-path-in-mojave) and run `matlab` in the terminal].

- **Method 2**:
  1. Start Matlab and add all subdirectory of this toolbox to the Matlab `path`;  
  2. Run `fs_setup('path/to/freesurfer/home');` to set `'path/to/freesurfer/home'` as `$FREESURFER_HOME` and add necessary paths to `$PATH`;  
  3. Run `fs_subjdir('path/to/subjects/dir');` to set `'path/to/subjects/dir'` as `$SUBJECTS_DIR`;  

## Create files needed for FreeSurfer
  Make sure the following files have been created properly (at least before running the general linear model (GLM) in FreeSurfer).
  - create [paradigm files (parfiles)](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastParadigmFile);
  - run files (if needed): txt files containing the name of runs (folders) in a column. For example, you should have different run files for localizer and main runs.
  - subjectname: a txt file containing the subject name in `$SUBJECTS_DIR`; this links the functional data folder and the structural data folder for that subject (more see [here](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct#TheSUBJECTSDIRand.27subjectname.27File)).
  - sessID Files: a txt file containing the list of session names in that folder (more see [here](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct#SpecifyingMultipleSessionstoAnalyze.28SessIDFiles.29)).


# Pre-processing
Data can be pre-processed by FreeSurfer, [fMRIPrep](https://fmriprep.org/en/stable/) or [HCPpipeline](https://github.com/Washington-University/HCPpipelines). After pre-processing, there should be one folder consisting the functional data and a separate folder consisting structural data (i.e., the `recon-all` results).

## FreeSurfer
In terminal:
```shell
# structure
recon-all -s subjCode -i path/to/T1/image -T2 path/to/T2/image -all 

# functional
preproc-sess -sf sessFile -fsd bold -surface self lhrh -mni305 -fwhm 0 -per-run -force 
```
<br>
In Matlab:  

```matlab
% structure
fs_recon()

% functional
fs_preproc()
```

# First-level analysis

## Configure analysis, contrasts and perform the analysis
Steps  |  functions
-- | --
1.Configure analyses   |  `fs_mkanalysis()`
2.Configure contrasts  |  `fs_mkcontrast()`
3.Perform the analysis |  `fs_selxavg3()`
More information on configuring analyses and contrasts can be found [here](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastFirstLevel).

## Draw labels based on contrast
After performing the first level analysis, you may want to create ROI label files based on the contrast. Please check [How to draw ROI on surface?](documents/draw_surface_roi.md)


# Group level analysis

## 1. Group level analysis on fsaverage
More information can be found [here](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastGroupLevelPerm).
Steps  |  functions
-- | --
1.Concatenate first level results  |  `fs_isxconcat()`
2.Perform group level GLM          |  `fs_glmfit_osgm()`
3.Multiple comparison correction with *permutation* |  `fs_glmfit_perm()`

## 2. Univariate analysis of ROIs on self surface
To perform statistical analyses on self surface for different labels (ROIs) later, use `fs_cosmo_readdata()` to load the surface data as a table in Matlab.  

## 3. Classification/decoding with CoSMoMVPA
To perform N-fold cross-validation classification/decoding, use `fs_cosmo_cvdecode()`.

## 4. Searchlight with CoSMoMVPA
To perform N-fold cross-validation searchlight on the surface, use `fs_cosmo_sesssl()`.
(Multiple comparison corrections with TFCE will be added later.)

## Some suggestion for these analyses (or notes for myself)
Analysis | Template | Smooth | Runwise
-- | -- | -- | --
1.Group level analysis | fsaverage | sm5 | no
2.ROI (label) univariate | self | sm5 | no
3.ROI (label) decoding | self | sm0 | yes
4.Searchlight | fsaverage | sm0 | yes

# Data visualization
Visualize nifty files: [ITK-SNAP](http://www.itksnap.org/pmwiki/pmwiki.php).
Visualize surface data: FreeView or functions based on [knkutils](https://github.com/kendrickkay/knkutils.git) and [cvncode](https://github.com/kendrickkay/cvncode.git).

## Quality assurance of recon-all results
To check the recon-all results, use `fv_checkrecon('subjcode')`.
To check both the volumetric and surface data, use `fv_checkreg()`.
To check the volumetric data only, run `fv_vol('', subjCode)` .
To check the surface data only, run `fv_surf('', 'inflated')` and then select which participants to be displayed in FreeView.

## Check other results
Results for visualization |  functions
-- | --
first level results (i.e., the screenshots of contrasts)  |  `fs_cvn_print1st()`
second level results |  `fs_cvn_print2nd()`
overlapping between labels    |  `fs_labeloverlap()`
labels files | `fs_cvn_print1st()`

# How-to
- [How to set up FreeSurfer in the terminal?](documents/fs_setup.md)
- [How to draw ROI on surface?](documents/draw_surface_roi.md)
- [How to trim a label file with some restrictions (e.g., 100 vertices)?](documents/trim_label.md)
- [How to visualize label files (i.e., ROIs)?](documents/visual_label.md)
- [How to visualize activation maps?](documents/visual_activation.md)

# Future work
- [ ] Making videos.

# Q&A
- **How to run linux commands via Matlab?** \
For most cases, you can use the Matlab function [`system()`](https://www.mathworks.com/help/matlab/ref/system.html) to run linux commands (e.g., `system('linux commands')`). However, `system()` does not always do what you want to do. For example, for setting the global environment variable (e.g., `$FREESURFER_HOME`), the Matlab function `setenv()` has to be used (e.g., `setenv('FREESURFER_HOME', '/Applications/freesurfer/')`).  

- **Question** \
The answers.
