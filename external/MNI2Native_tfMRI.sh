#!/bin/sh

#  MNI2Native_tfMRI.sh
#  
#
#  Created by osama abdullah on 9/9/18.

FSLDIR=/Applications/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
PATH=${FSLDIR}/bin:${PATH}
export FSLDIR PATH
workDir=$1 #e.g., "/Volumes/mri/projects/HCP/S43_retinotopy"

subjID=$2 #e.g., "S43_retinotopy"

# downsample T2w in native space to fMRI resolution

flirt -in "$workDir"/T1w/T2w_acpc_dc_restore_brain -ref "$workDir"/T1w/T2w_acpc_dc_restore_brain -applyisoxfm 2 -out "$workDir"/T1w/T2w_acpc_dc_restore_brain_2mm


# transform BOLD data from MNI space to Native Space, loop insude the results folder

cd "$workDir"/MNINonLinear/Results
for fmri in $(ls); do echo "transforming from MNI to Native: " $fmri;
applywarp --rel --interp=trilinear -i $fmri/"$fmri" -r "$workDir"/T1w/T2w_acpc_dc_restore_brain_2mm -w "$workDir"/MNINonLinear/xfms/standard2acpc_dc -o "$fmri"_native.nii.gz ; done

cd "$workDir"/MNINonLinear/Results
for fmri; do echo "transforming from MNI to Native: " $fmri;
applywarp --rel --interp=trilinear -i $fmri/"$fmri"_SBRef -r "$workDir"/T1w/T2w_acpc_dc_restore_brain_2mm -w "$workDir"/MNINonLinear/xfms/standard2acpc_dc -o "$fmri"_SBRef_native.nii.gz ; done





# in case you need to transform the non-bias-corrected to Native Space

# first copy the files named fMRI_bla_bla_nonlin.nii.gz from each fMRI folder to a common directory, then run:

# cd "$workDir"


#for fmri in $(ls *_nonlin.nii.gz); do echo "transforming from MNI to Native: " $fmri;
#/Applications/fsl/bin/applywarp --rel --interp=trilinear -i $fmri -r "$workDir"/T1w/T2w_acpc_dc_restore_brain_2mm -w "$workDir"/MNINonLinear/xfms/standard2acpc_dc -o "$fmri"_noBC_native.nii.gz ;
#done


#for fmri in $(ls); do echo "transforming from MNI to Native: " $fmri;
#/Applications/fsl/bin/applywarp --rel --interp=trilinear -i $fmri/"$fmri"_nonlin -r "$workDir"/T1w/T2w_acpc_dc_restore_brain_2mm -w "$workDir"/MNINonLinear/xfms/standard2acpc_dc -o "$fmri"_noBC_native.nii.gz ;
#done
