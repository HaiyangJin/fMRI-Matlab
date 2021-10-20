
# Identifying functional ROI with restricted area size


  - [General intro to the methods](#general-intro-to-the-methods)
    - [The general procedures for updating the label file with maximum of 100 mm<sup>2</sup> are as followings:](#the-general-procedures-for-updating-the-label-file-with-maximum-of-100-mmsup2sup-are-as-followings)
    - [The local maxima](#the-local-maxima)
  - [Practical instruction](#practical-instruction)
    - [All data were processed with FreeSurfer](#all-data-were-processed-with-freesurfer)
    - [Only structural data were processed with FreeSurfer](#only-structural-data-were-processed-with-freesurfer)
    - [No data were processed in FreeSurfer](#no-data-were-processed-in-freesurfer)

<br>

If you would like to identify functional ROI (label file in FreeSurfer) with the criteria that its area size is just under certain size (e.g., 100 mm<sup>2</sup>), you may use [`fs_trimlabel()`](../freesurfer/fs_trimlabel.m) to trim the label.

## General intro to the methods

### The general procedures for updating the label file with maximum of 100 mm<sup>2</sup> are as followings:
1. Identify a local maxima (with reference coordinates from previous literature).
2. Identify the local maxima’s neighbor vertices, i.e., the vertices that are next to the local maxima.
3. Sort these neighbor vertices by their functional results (e.g., p-values) and only the first 50% of them (i.e., vertices whose p-values are smaller) will be included as ROI vertices for this iteration.
4. The trimmed ROI vertices are the local maxima plus the vertices kept in step 3.
5. Then the vertices that are next to the trimmed ROI are identified.
6. Repeat step 3-5 until the label area reaches 100mm<sup>2</sup>.

### The local maxima
The local maxima is defined as the vertex whose -log10(p-value) is larger than its neighbors after applying certain p-value threshold.
For example, when **<span style="color:#2F6FBA"> the blue threshold </span>** is applied, only B is identified as the local maxima. When **<span style="color:#4EAE5B"> the green threshold </span>** is applied, both A and B are local maxima. By default, only B is taken as a local maxima.
<img src="img/trim_label_globalmaxima.png" width="500" style="vertical-align:middle">


## Practical instruction

Note: `fs_trimlabel()` was initially developed to work with (both structural and functional) data processed with FreeSurfer. Some options were added later to extend its usage/coverage but it may not work well.

### All data were processed with FreeSurfer

The instruction in this section is applicable when both structural and functional data are processed by FreeSurfer.

The steps for using [`fs_trimlabel()`](../freesurfer/fs_trimlabel.m) as followings:

0. Make sure `$SUBJECTS_DIR` AND `$FUNCTIONALS_DIR` are set up properly ([`fs_subjdir`](../freesurfer/fs_subjdir.m) and [`fs_funcdir`](../fsfast/fs_funcdir.m) may help.)
1. run `fs_trimlabel(labelFn, sessCode, outPath, ‘method’, ‘maxresp’)`;
   - `sessCode` refers to the session code in `$FUNCTIONALS_DIR`.
   - a screenshot (dispalys the local maxima (only one vertex) as a yellow circle on the inflated brain (highlighted in the red circle here);
   <img src="img/trim_label_screenshots1.png" width="500" style="vertical-align:middle">
   <br>
   - The information of this local maxima (and its corresponding trimmed label) is displayed in Matlab command window (the below figure). The first row displays the information of the “old” label (before trimmed); the second row displays the information of the local maxima.
   <img src="img/trim_label_screenshots2.png" width="750" style="vertical-align:middle">
   <br>
2. (a) If you **are** happy with this local maxima, you can type in the name of the trimmed label file. This label will be saved in the same folder as the “old” label; (Then you are finished trimming this label.)
   - **Note**: *if you type in the same name as the ”old” label, the ”old” label will be overwritten and cannot be recovered unless you re-create it with ‘tksurfer-sess’.*
3. (b) If you **are not** happy with this local maxima, type in ‘remove’ and this trimmed label file will be removed. Then continue.<br>
4. By default, `fs_trimlabel()` only tries to identify one local maxima. If you are not happy with it, you may set it to identify 2 local maxima (if there are more than one available) by adding `‘ncluster’, 2`.
   - run `fs_trimlabel(labelFn, sessCode, outPath, ‘method’, ‘maxresp’, ‘ncluster’, 2)`
   - Matlab will displays a preview of the two clusters. if you are still not happy with both of them, please type in `‘skip’` to skip these two clusters. (Maybe increase `‘ncluster’` further).
   <img src="img/trim_label_overlap.png" width="500" style="vertical-align:middle">
   <br>
   - Otherwise, click ‘OK‘ to continue (it will continue as long as the strings in the input box is not ‘skip’). You will get a warning if the two clusters overlaps, just click ‘OK’. Next, it will repeat the previous steps to check the two clusters sequentially.

### Only structural data were processed with FreeSurfer

If only the structural data were processed with FreeSurfer (and the functional data were processed with other software), additional options are needed.

0. Make sure `$SUBJECTS_DIR` is set up properly ([`fs_subjdir`](../freesurfer/fs_subjdir.m) may help.)
1. run `fs_trimlabel(labelFn, subjCode, outPath, ‘method’, ‘maxresp’, 'overlay', statData)`;
   - `subjCode` refers to the session code in `$SUBJECTSS_DIR`.

The rest steps are similar to when all data were processed by FreeSurfer.

Note: if your ROI is not a label file in FreeSurfer. You have to convert it into a label file first. (Some information about label files in FreeSurfer can be found [here](https://surfer.nmr.mgh.harvard.edu/fswiki/LabelsClutsAnnotationFiles#Label).) [`fs_mklabel`](../freesurfer/fs_mklabel.m) may help.

### No data were processed in FreeSurfer
You may try [`sf_trimroi`](../surf/sf_trimroi.m). But there is no visualization available.