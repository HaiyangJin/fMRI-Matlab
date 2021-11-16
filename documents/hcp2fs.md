
## Preprocessed by HCP

Structural and functional data could also be pre-processed by [HCPpipeline](https://github.com/Washington-University/HCPpipelines) and then converted into FreeSurfer functional direcotr
Please check [the HCP website](https://www.humanconnectome.org/) or [this paper](https://www.sciencedirect.com/science/article/pii/S1053811913005053?via%3Dihub) for more information about the pre-processing.

To further analyze the HCP pre-processed data in FreeSurfer, we need to re-arrange the files to [the FS-FAST directory structure](https://surfer.nmr.mgh.harvard.edu/fswiki/FsFastTutorialV6.0/FsFastDirStruct). `fs_hcp_preproc()` can help.

Then first- and group-level analyses can be performed in FreeSurfer