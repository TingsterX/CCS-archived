#!/usr/bin/env bash

##########################################################################################################################
## Computational Connectome System (CCS)
## R-fMRI master: Xi-Nian Zuo at the Institute of Psychology, CAS. 
## Email: zuoxn@psych.ac.cn.
## Email: ting.xu@childmind.org
## 
## The analyisdirectory should be organized as follow:
## analysisdirectory
## |--sub001
## |  |--anat
## |  |    |--T1w.nii.gz
## |  |--func_1
## |  |    |--rest.nii.gz
## |  |--func_2
## |  |    |--rest.nii.gz
## |--sub002
## ...
##
## If more than one T1w and prefer to average all together, organized data as follow:
## analysisdirectory
## |--sub001
## |  |--anat
## |  |    |--T1w1.nii.gz
## |  |    |--T1w2.nii.gz
## |  |    |--T1w3.nii.gz
##########################################################################################################################


##########################################################################################################################
## PARAMETERS
###########################################################################################################################

## directory where scripts are located
scripts_dir=CCS_CODE_PATH
## full/path/to/site
analysisdirectory=WORKING_DIR
## full/path/to/site/subject_list
#subject_list=${analysisdirectory}/scripts/subjects.list
## name of anatomical scan (no extension)
anat_name=T1w
## name of resting-state scan (no extension)
rest_name=func
## anat_dir_name
anat_dir_name=anat
## func_dir_name
func_dir_name=func
## TR
TR=2.0
## Drop the first few volumes 
numDropping=5
## Slice timing order using AFNI 3dTshift pattern: e.g. alt+z (alternating in the plus direction)
## Check: https://afni.nimh.nih.gov/pub/dist/doc/program_help/3dTshift.html
sliceOrder=alt+z
## High-pass and Low-pass filter (Hz)
hp=0.01
lp=0.1
## Use the first epi for the registration
use_epi0=false
## func registration directory
func_reg_dir_name=reg
## anatomical registration directory name
anat_reg_dir_name=reg 
## refine the registration using the study-specific template
anat_reg_refine=false
## if use svd to extract the mean ts
svd=false
## standard brain
standard_head=${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz
standard_brain=${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz
standard_template=${scripts_dir}/templates/MNI152_T1_3mm_brain.nii.gz
fsaverage=fsaverage5

##########################################################################################################################
## Get subjects to run
subject=$1

##########################################################################################################################
##---START OF SCRIPT----------------------------------------------------------------------------------------------------##
##########################################################################################################################

## Preprocessing functional images
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "running ccs_01_funcpreproc.sh ..."
echo "-------------------------------"
${scripts_dir}/ccs_01_funcpreproc.sh ${subject} ${analysisdirectory} ${rest_name} ${numDropping} ${TR} ${anat_dir_name} ${func_dir_name} ${sliceOrder}


## Registering functional images
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "-------------------------------"
echo "running bbregistration ..."
${scripts_dir}/ccs_02_xt_funcbbregister.sh ${subject} ${analysisdirectory} ${func_dir_name} ${rest_name} ${use_epi0} ${fsaverage} ${func_reg_dir_name} true
echo "running registration to MNI template..."
${scripts_dir}/ccs_02_xt_funcregister.sh ${subject} ${analysisdirectory} ${anat_dir_name} ${func_dir_name} ${rest_name} ${standard_template} ${anat_reg_dir_name} ${func_reg_dir_name} ${fsaverage} ${scripts_dir} false

## Segmenting functional images
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "running functional segmentation ..."
echo "-------------------------------"
${scripts_dir}/ccs_03_funcsegment.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name} ${func_reg_dir_name}

## Nuisance Regression on functional images
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "running nuisance regression: wm, csf, Friston's 24..."
echo "-------------------------------"
${scripts_dir}/ccs_04_funcnuisance.sh ${subject} ${analysisdirectory} ${rest_name} ${func_dir_name} ${func_reg_dir_name} ${svd}

## Final steps of band-pass filtering, detrending and projecting 4D images onto fsaverage surfaces as well as spatial smoothing in both volume and surface spaces
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "running band-pass filtering, detrending, volume to surface projection, smoothing"
echo "-------------------------------"
${scripts_dir}/ccs_05_funcpreproc_final.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name} ${anat_reg_refine} ${standard_template} ${fsaverage} ${hp} ${lp} ${anat_reg_dir_name} ${func_reg_dir_name}

## Final steps of band-pass filtering, detrending and projecting 4D images onto fsaverage surfaces as well as spatial smoothing in both volume and surface spaces
echo "-------CCS preprocessing-------"
echo "${subject}"
echo "No filtering, detrending, volume to surface projection, smoothing"
echo "-------------------------------"
${scripts_dir}/ccs_05_funcpreproc_final_nofilt.sh ${subject} ${analysisdirectory} ${rest_name} ${anat_dir_name} ${func_dir_name} ${anat_reg_refine} ${standard_template} ${fsaverage} ${anat_reg_dir_name} ${func_reg_dir_name}


