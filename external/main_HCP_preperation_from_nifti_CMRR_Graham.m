
% script to convert Siemens DICOM images to NII format (including DWI data)
% expecting Osirix-exported sub-folders within the main parent directory
% for 1 patient
clear all
close all
clc

%% Users's input 
modality = '3T'; %specify source of data, 3T, MEG, etc

 % where is source nifti data located?
sourceFolder =            '/Volumes/mri/data/nifti_converted/OA:Brain imaging/Sub0001_Oa_Studyb_Language_Mapping_3_20190619'



subjectId='S1'; %desired Subject ID (can be different than what came from the MRI)
targetFolder=['/Volumes/mri/projects/HCP/' subjectId]; % where to save the data 
taskname = {'Production', 'Dialogue'}; %useful when you have multiple task names, can be a list
taskLookupString = '/*fMRI*'
mutiple_field_maps_flag = 'no'; % if "yes" then scan names have to contain time-stamp like ep2d_se_FieldMap_PA_18_142816 where time is 14h:28m:16s denotes start time
Field_Map_AP_name = 'SpinEchoFieldMap_AP_7_102243'; % manually specify the AP SE Field Map of interest
Field_Map_PA_name = 'SpinEchoFieldMap_PA_8_102317';%manually specify the PA SE Field Map of interest
commonSBREF_name = '';%' %for scans that don't have SBREF, use this common SBREF name
GRE_FieldMap_1 = '';%'gre_field_mapping_25_100939';
GRE_FieldMap_2 = '';%'gre_field_mapping_26_100939';
GRE_FieldMap_phase = '';%'gre_field_mapping_26_155139';
Diffusion_name = {'dir95','dir96', 'dir97'}; % various diffusion runs
%% convert what?
FunctionalFlag = 1;
SE_Flag =1;
StructrualFlag = 0;
GRE_Flag = 0;
DiffusionFlag = 0;
%% Making Directories in Target Folder
tasklist = dir([sourceFolder taskLookupString]); %find all fMRI data directories
fieldList = dir([sourceFolder '/*SpinEchoFieldMap*']); %find all Spin Echo Field maps
% fieldList = dir([sourceFolder '/*SpinEchoFieldMap*']); %find all Spin Echo Field maps

T1List = dir([sourceFolder '/*T1*']);
T2List = dir([sourceFolder '/*T2*']);
SBREF_List = dir([sourceFolder '/*SBREF*']); %contains SBREF scans for both fMRI and diffusion (if any)
% GREList = dir([sourceFolder '/*GRE_DISTORTION*'])
GREList = dir([sourceFolder '/*gre_field_mapping*'])
DiffusionList = dir([sourceFolder '/*dMRI*']);
mkdir(targetFolder)
cd(targetFolder)
mkdir('unprocessed')
cd('unprocessed')
mkdir(modality)
cd(modality)

tic
 %% create and populate task fmri folders
 %  convention for folder is fMRI_AP_TASKNAME 
 %  convention for BOLD time series is SubjectID_Modality_fMRI_AP_TASKNAME.nii.gz 
 if FunctionalFlag
     indA=1;
%      indP=1;
     for taskInd = 1:numel(tasklist) %to save fMRI BOLD time series
         for ii=1:numel(taskname)
             % ******************************** ALL Grahms's Acquisitions
             % are AP
             % *********************************************************
              if contains(tasklist(taskInd).name, 'AP') && ~contains(tasklist(taskInd).name, 'SBRef') && contains(tasklist(taskInd).name, taskname(ii))
                 origfile = dir([sourceFolder '/' tasklist(taskInd).name '/*.nii.gz'])
                 taskDir = ['fMRI_AP_' taskname{ii} '_' origfile.name(1:2)];
                 mkdir(taskDir);
%                  newfilename = [targetFolder '/unprocessed/' modality '/' taskDir '/' subjectId '_' modality '_' 'fMRI_AP_' taskname{ii} num2str(indA) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                 newfilename = [targetFolder '/unprocessed/' modality '/' taskDir '/' subjectId '_' modality '_' 'fMRI_AP_' taskname{ii}  '_' origfile.name(1:2) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                 copyfile([origfile.folder '/' origfile.name], newfilename);
                 % identifyt associated SBREF
                 SBref_new_file_name_AP{indA} = [targetFolder '/unprocessed/' modality '/' taskDir '/' subjectId '_' modality '_' 'fMRI_AP_' taskname{ii}  '_' origfile.name(1:2) '_SBRef.nii.gz'];
                 fMRI_scan_number = str2num(tasklist(taskInd).name(end-8:end-7))
                 SBref_original_file_name_AP{indA} = [tasklist(taskInd).name(1:end-9) 'SBRef_' num2str(fMRI_scan_number-1)];
                 indA = indA + 1; %advance index

             end
% % %              if  ~contains(tasklist(taskInd).name, 'SBRef') 
% % %                  taskDir = ['fMRI_PA_' taskname{ii} num2str(indP)];
% % %                  mkdir(taskDir);
% % %                  newfilename = [targetFolder '/unprocessed/' modality '/' taskDir '/' subjectId '_' modality '_' 'fMRI_PA_' taskname{ii} num2str(indP) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
% % %                  origfile = dir([sourceFolder '/' tasklist(taskInd).name '/*.nii.gz'])
% % %                  copyfile([origfile.folder '/' origfile.name], newfilename);
% % %                  % identifyt associated SBREF
% % %                  SBref_new_file_name_PA{indP} = [targetFolder '/unprocessed/' modality '/' taskDir '/' subjectId '_' modality '_' 'fMRI_PA_' taskname{ii} num2str(indP) '_SBRef.nii.gz'];
% % %                  fMRI_scan_number = str2num(tasklist(taskInd).name(end-8:end-7))
% % %                  SBref_original_file_name_PA{indP} = [tasklist(taskInd).name(1:end-9) 'SBRef_' num2str(fMRI_scan_number-1)];
% % %                  indP = indP + 1; %advance index
% % % 
% % %              end
         end
         
     end
  
% %      % copy SBREF to task fMRI folders (assumes all task fMRI folders were created already)
% %      % convention SubjectID_Modality_tfMRI_TASKNAME_AP_SBREF.nii.gz
% %     %      indA = 1;
% %     %      indP = 1;

    if exist('SBref_new_file_name_AP')
         for taskInd = 1:numel(tasklist) %to save fMRI BOLD time series
             tasklist(taskInd).name
             for indA = 1:numel(SBref_original_file_name_AP)
                 if contains(tasklist(taskInd).name, SBref_original_file_name_AP{indA})
                     SBref_full_original_name = [tasklist(taskInd).folder '/' tasklist(taskInd).name];
                     f = dir([SBref_full_original_name '/*.nii.gz'])
                     SBref_full_original_name = [f.folder '/' f.name];
                     copyfile(SBref_full_original_name,  SBref_new_file_name_AP{indA});
                 end
             end

%              for indP = 1:numel(SBref_original_file_name_PA)
%                  if contains(tasklist(taskInd).name, SBref_original_file_name_PA{indP})
%                      SBref_full_original_name = [tasklist(taskInd).folder '/' tasklist(taskInd).name];
%                      f = dir([SBref_full_original_name '/*.nii.gz'])
%                      SBref_full_original_name = [f.folder '/' f.name];
%                      copyfile(SBref_full_original_name,  SBref_new_file_name_PA{indP});
%                  end
%              end

         end
    else %copy common SBREF to each folder
                SBref_full_original_name = [sourceFolder '/' commonSBREF_name];
                f = dir([SBref_full_original_name '/*.nii.gz'])
                SBref_full_original_name = [f.folder '/' f.name];
                
                for taskInd = 1:numel(tasklist) %to save fMRI BOLD time series
                   copyfile(SBref_full_original_name,  SBref_new_file_name_PA{taskInd});
                 end
    end
 
end

 
 %% copy SE Field Maps  
  % convention SubjectID_Modality_SpinEchoFieldMap_AP.nii.gz and SubjectID_Modality_SpinEchoFieldMap_PA.nii.gz

 if SE_Flag
     taskSearchString = ['/*' taskname{1} '*'];
     listfmriDir = dir([targetFolder '/unprocessed/' modality '/' taskSearchString]); %actual tfMRI folders already converted
     if isempty(listfmriDir)
         error('Could not find any tfMRI folders, create the tfMRI folders by running the tfMRI section prior to running this section')
     end
     
     if mutiple_field_maps_flag == "no" %user has to select specific field maps
         for fieldInd = 1:numel(fieldList) %loop from the Source Directory containing fMRI folders,
             fieldList(fieldInd).name
             if contains(fieldList(fieldInd).name, Field_Map_AP_name) && contains(fieldList(fieldInd).name, 'AP') %search for FieldMap in AP (taskInd Loops in Source Folder)
                 for targetInd = 1:numel(listfmriDir) % copy FieldMap_AP to all tfMRI folders in the unprocessed/3T folder (targetInd Loops in Target folder)
                     newfilename = [targetFolder '/unprocessed/' modality '/' listfmriDir(targetInd).name '/' subjectId '_' modality '_SpinEchoFieldMap_AP.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                     origfile = dir([sourceFolder '/' fieldList(fieldInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
                     copyfile([origfile.folder '/' origfile.name], newfilename);
                 end
                 
             end
             
             if contains(fieldList(fieldInd).name, Field_Map_PA_name) && contains(fieldList(fieldInd).name, 'PA') %search for FieldMap in AP (taskInd Loops in Source Folder)
                 for targetInd = 1:numel(listfmriDir) % copy FieldMap_AP to all tfMRI folders in the unprocessed/3T folder (targetInd Loops in Target folder)
                     newfilename = [targetFolder '/unprocessed/' modality '/' listfmriDir(targetInd).name '/' subjectId '_' modality '_SpinEchoFieldMap_PA.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                     origfile = dir([sourceFolder '/' fieldList(fieldInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
                     copyfile([origfile.folder '/' origfile.name], newfilename);
                 end
                 
             end
         end
         
     elseif mutiple_field_maps_flag == "yes"
         Display('this capability not developed yet');
         error('No Field Maps were exported');
     else
         error('unknown option: either use "no" or "yes" case sensetive');
         
     end
    
 end
 
  %% Create Structrual T1w and T2w folders
  if StructrualFlag
      for T1Ind = 1:2:numel(T1List) %skip every other folder to skip the "intensity corrected" images
          T1Dir = ['T1w_MPR' num2str(T1Ind)];
          mkdir(T1Dir);
          newfilename = [targetFolder '/unprocessed/' modality '/' T1Dir '/' subjectId '_' modality '_T1w_MPR' num2str(T1Ind) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
          origfile = dir([sourceFolder '/' T1List(T1Ind).name '/*.nii.gz']); %returns a structure with folder and name of the file
          copyfile([origfile.folder '/' origfile.name], newfilename);
         
      end
      
      for T2Ind = 1:2:numel(T2List) %skip every other folder to skip the "intensity corrected" images
          T2Dir = ['T2w_SPC' num2str(T2Ind)];
          mkdir(T2Dir);
          newfilename = [targetFolder '/unprocessed/' modality '/' T2Dir '/' subjectId '_' modality '_T2w_SPC' num2str(T1Ind) '.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
          origfile = dir([sourceFolder '/' T2List(T2Ind).name '/*.nii.gz']); %returns a structure with folder and name of the file
          copyfile([origfile.folder '/' origfile.name], newfilename);
          
      end
  end
 %% GRE Field Map perperation 
 %Convention requires SubjectID_Modality_FieldMap_Magnitude.nii.gz and SubjectID_Modality_FieldMap_Phase.nii
 % note the magnitude images contains 2 volumes at different TEs
if GRE_Flag 
if size(GREList,1) == 3
    GREList1 = dir(fullfile(GREList(1).folder, GREList(1).name, '*.nii.gz')); %dir([sourceFolder '/' GRE_FieldMap_1 '/*gre*.nii.gz']);
    GREList2 = dir(fullfile(GREList(2).folder, GREList(2).name, '*.nii.gz'));
    GREList_phase = dir(fullfile(GREList(3).folder, GREList(3).name, '*.nii.gz'));
elseif  size(GREList,1) == 2
    GREmag = dir(fullfile(GREList(1).folder, GREList(1).name, '*.nii.gz')); %dir([sourceFolder '/' GRE_FieldMap_1 '/*gre*.nii.gz']);
    GREList1 = GREmag(1);
    GREList2 = GREmag(2);
    GREList_phase = dir(fullfile(GREList(2).folder, GREList(2).name, '*.nii.gz'));
else
    
    error('No GRE Field maps found')
end
magFileName = [subjectId '_' modality '_FieldMap_Magnitude.nii.gz'];
phaseFileName = [subjectId '_' modality '_FieldMap_Phase.nii.gz'];

   magn = load_untouch_nii([GREList1.folder '/' GREList1(1).name]);
   magn2 = load_untouch_nii([GREList2.folder '/' GREList2(1).name]);
   magn.img(:,:,:,2) = magn2.img;
   magn.hdr.dime.dim(5) = 2;
   magn.hdr.dime.dim(1) = 4;
   save_untouch_nii(magn, [targetFolder '/unprocessed/' modality '/T1w_MPR1/' magFileName])
   copyfile([GREList_phase(1).folder '/' GREList_phase(1).name], [targetFolder '/unprocessed/' modality '/T1w_MPR1/' phaseFileName]);
   save_untouch_nii(magn, [targetFolder '/unprocessed/' modality '/T2w_SPC1/' magFileName])
   copyfile([GREList_phase(1).folder '/' GREList_phase(1).name], [targetFolder '/unprocessed/' modality '/T2w_SPC1/' phaseFileName]);

   % For Quality Assurance, verify correct images were saved
   figure,
   phs = load_untouch_nii([GREList_phase.folder '/' GREList_phase(1).name]);
   subplot(1,3,1), imagesc(magn.img(:,:,round(magn.hdr.dime.dim(4)/2),1)), colormap gray, axis image,  title('First Mag Image')
   subplot(1,3,2), imagesc(magn.img(:,:,round(magn.hdr.dime.dim(4)/2),2)),  colormap gray, axis image,title('Second Mag Image')
   subplot(1,3,3), imagesc(phs.img(:,:,round(phs.hdr.dime.dim(4)/2),1)),  colormap gray, axis image,title('Phase Difference Image')
  

% if mutiple_field_maps_flag == "no" %user has to select specific field maps
%     listfmriDir = dir([targetFolder '/unprocessed/' modality '/*fmri*']); %actual tfMRI folders already converted
%     if isempty(listfmriDir)
%         error('Could not find any fMRI folders, create the tfMRI folders by running the fMRI section prior to running this section')
%     end
%     for targetInd = 1:numel(listfmriDir) % copy FieldMap_AP to all tfMRI folders in the unprocessed/3T folder (targetInd Loops in Target folder)
%         newfilename = [targetFolder '/unprocessed/' modality '/' listfmriDir(targetInd).name '/' subjectId '_' modality '_SpinEchoFieldMap_AP.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
%         origfile = dir([sourceFolder '/' fieldList(fieldInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
%         copyfile([origfile.folder '/' origfile.name], newfilename);
%     end
%     
%     
%     
%     if contains(fieldList(fieldInd).name, Field_Map_PA_name) && contains(fieldList(fieldInd).name, 'PA') %search for FieldMap in AP (taskInd Loops in Source Folder)
%         for targetInd = 1:numel(listfmriDir) % copy FieldMap_AP to all tfMRI folders in the unprocessed/3T folder (targetInd Loops in Target folder)
%             newfilename = [targetFolder '/unprocessed/' modality '/' listfmriDir(targetInd).name '/' subjectId '_' modality '_SpinEchoFieldMap_PA.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
%             origfile = dir([sourceFolder '/' fieldList(fieldInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
%             copyfile([origfile.folder '/' origfile.name], newfilename);
%         end
%         
%     end
% end
end
    %% Create Diffusion Folders
  if DiffusionFlag 
      if ~isempty(DiffusionList)
         mkdir('Diffusion');
      else
          error('No Diffusion folders found -- OA')
      end
      
      for DiffInd = 1:numel(DiffusionList) % search for diffusion DWI datafiles
          for DiffNameInd = 1:numel(Diffusion_name) %search for the specified Diffusion directories in the begiing of this code
              if contains(DiffusionList(DiffInd).name, Diffusion_name(DiffNameInd)) && contains(DiffusionList(DiffInd).name, 'AP') && ~contains(DiffusionList(DiffInd).name, 'SBRef') && ~contains(DiffusionList(DiffInd).name, 'SBREF') && ~contains(DiffusionList(DiffInd).name, 'FA') && ~contains(DiffusionList(DiffInd).name, 'ADC') && ~contains(DiffusionList(DiffInd).name, 'TRACE')
              newfilename = [targetFolder '/unprocessed/' modality '/' 'Diffusion' '/' subjectId '_' modality '_DWI_' Diffusion_name{DiffNameInd} '_AP']; %subjectID_modality_pulseSequence according to HCP convention
              origfile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
              copyfile([origfile.folder '/' origfile.name], [newfilename '.nii.gz']);%DWI data
              bvecFile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.bvec']);
              bvalFile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.bval']);
              copyfile([bvecFile.folder '/' bvecFile.name], [newfilename '.bvec']);%bvec file
              copyfile([bvalFile.folder '/' bvalFile.name], [newfilename '.bval']);%bvec file
              end
              if contains(DiffusionList(DiffInd).name, Diffusion_name(DiffNameInd)) && contains(DiffusionList(DiffInd).name, 'PA') && ~contains(DiffusionList(DiffInd).name, 'SBRef') && ~contains(DiffusionList(DiffInd).name, 'SBREF') && ~contains(DiffusionList(DiffInd).name, 'FA') && ~contains(DiffusionList(DiffInd).name, 'ADC') && ~contains(DiffusionList(DiffInd).name, 'TRACE')
              newfilename = [targetFolder '/unprocessed/' modality '/' 'Diffusion' '/' subjectId '_' modality '_DWI_' Diffusion_name{DiffNameInd} '_PA']; %subjectID_modality_pulseSequence according to HCP convention
              origfile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
              copyfile([origfile.folder '/' origfile.name], [newfilename '.nii.gz']);%DWI data
              bvecFile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.bvec']);
              bvalFile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.bval']);
              copyfile([bvecFile.folder '/' bvecFile.name], [newfilename '.bvec']);%bvec file
              copyfile([bvalFile.folder '/' bvalFile.name], [newfilename '.bval']);%bvec file
              end
          end
      end
      
      for DiffInd = 1:numel(DiffusionList) %Search for Single-Band B0 Referenes
          if  contains(DiffusionList(DiffInd).name, 'AP') && contains(DiffusionList(DiffInd).name, 'SBRef') 
             for DiffNameInd = 1:numel(Diffusion_name)
                 newfilename = [targetFolder '/unprocessed/' modality '/' 'Diffusion' '/' subjectId '_' modality '_DWI_' Diffusion_name{DiffNameInd} '_AP_SBRef.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                 origfile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
                 copyfile([origfile.folder '/' origfile.name], newfilename);
             end
          end
          if  contains(DiffusionList(DiffInd).name, 'PA') && contains(DiffusionList(DiffInd).name, 'SBRef') 
             for DiffNameInd = 1:numel(Diffusion_name)
                 newfilename = [targetFolder '/unprocessed/' modality '/' 'Diffusion' '/' subjectId '_' modality '_DWI_' Diffusion_name{DiffNameInd} '_PA_SBRef.nii.gz']; %subjectID_modality_pulseSequence according to HCP convention
                 origfile = dir([sourceFolder '/' DiffusionList(DiffInd).name '/*.nii.gz']); %returns a structure with folder and name of the file
                 copyfile([origfile.folder '/' origfile.name], newfilename);
             end
          end
      end
  % to run Eddy in FSL, no b=0 is allowed in the bval file! Need to fix:
  
   
  end
if ~exist(' matlab_conversion.mat')
    save matlab_conversion.mat
else
    c=strcat(num2str(date));
    save(strcat('matlab_conversion', c, '.mat'));
end



t = toc/60; 
% save(experiment_name, 'tasklist')