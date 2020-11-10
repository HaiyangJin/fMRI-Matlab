For example, if you would like to only keep the vertices around a global maxima and their area size is say 100 mm<sup>2</sup>, you may use `fs_updatelabel()` to update the label of interests.

### The general procedures for updating the label file with maximum of 100 mm<sup>2</sup> are as followings:
1. Identify a global maxima (more detailed information can be found in the next slide).
2. Identify the global maxima’s neighbor vertices, i.e., the vertices that are next to the global maxima.
3. Sort these neighbor vertices by their p-values and only the first 50% of them (i.e., vertices whose p-values are smaller) will be included as ROI vertices for this iteration.
4. The updated ROI vertices are the global maxima plus the vertices kept in step 3.
5. Then the vertices that are next to the updated ROI are identified.
6. Repeat 3-5 until the label area reaches 100mm2.

### The global maxima
The global maxima (maybe I should call it local maxima) is defined as the vertex whose log10(p-value) is larger than its neighbors after applying certain p-value threshold.
For example, when the blue threshold is applied, only B is identified as the global maxima. When the green threshold is applied, both A and B are global maxima. By default, only B will be taken as a global maxima.
<img src="img/update_label_globalmaxima.png" width="500" style="vertical-align:middle">

The steps for using `fs_updatelabel()` as followings:
1. run `fs_updatelabel(labelFn, sessCode, outPath, ‘method’, ‘maxresp’)`;
   - a screenshot (dispalys the gobal the global maxima (only one vertex) as a yellow circle on the inflated brain (highlighted in the red circle here);
   <img src="img/update_label_screenshots1.png" width="500" style="vertical-align:middle">
   <br>
   - The information of this global maxima (and its corresponding updated label) is displayed in Matlab command window (the below figure). The first row displays the information of the “old” label (before updated); the second row displays the information for the global maxima.
   <img src="img/update_label_screenshots2.png" width="750" style="vertical-align:middle">
   <br>
2. (a) If you **are** happy with this global maxima, you can type in the name of the updated label. This label will be same in the same folder as the “old” label; (Then you finished updating this label.)
   - **Note**: *if you type in the same name as the ”old” label, the ”old” label will be overwritten and cannot be recovered unless you re-create it with ‘tksurfer-sess’.*
2. (b) If you **are not** happy with this global maxima, type in ‘remove’ and this updated label file will be removed (please check the next slide). Then continue.
<br>
3. By default, `fs_updatelabel()` only tries to identify one global maxima. If you are not happy with it, you may ask it to identify 2 global maxima (if there are more than two available) by adding `‘ncluster’, 2`.
   - run `fs_updatelabel(labelFn, sessCode, outPath, ‘method’, ‘maxresp’, ‘ncluster’, 2)`
   - Matlab will displays a preview of the two clusters, if you are still not happy with both of them, please type in ‘skip’ to skip these two clusters. (Maybe increase `‘ncluster’` further).
   <img src="img/update_label_overlap.png" width="500" style="vertical-align:middle">
   <br>
   - Otherwise, click ‘OK‘ to continue (it will continue as long as the strings in the input box is not ‘skip’). You will get a warning if the two clusters overlaps, just click ‘OK’. Next, it will repeat the previous steps to check the two clusters sequentially.
