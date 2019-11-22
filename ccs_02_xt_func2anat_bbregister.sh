#!/usr/bin/env bash
## Ting Xu modified
## Write the registration matrix into func/reg_fsbbr


##########################################################################################################################
## CCS SCRIPT TO DO SURFACE-BASED FUNCTIONAL IMAGE PREPROCESSING (FREESURFER)
##
## !!!!!*****ALWAYS CHECK YOUR REGISTRATIONS*****!!!!!
##
## Written by R-fMRI master: Xi-Nian Zuo. Dec. 07, 2010, Institute of Psychology, CAS.
##
## Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com.
##########################################################################################################################

## subject
subject=$1
## analysisdir
dir=$2
## name of functional directory
func_dir_name=$3
## name of the resting-state scan
rest=$4
## name the anatomica director
anat_dir_name=$5
## name of target average subject
fsaverage=$6
## if use the first epi image for registration
if_epi0=$7
## clean up the old and rerun registration
redo_reg=$8
## directory setup
anat_dir=${dir}/${subject}/${anat_dir_name}
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/reg_fsbbr
func_seg_dir=${func_dir}/segment
func_mask_dir=${func_dir}/mask
SUBJECTS_DIR=${dir}

anat_reg_dir=${anat_dir}/reg
highres=${anat_reg_dir}/highres.nii.gz

if [ $# -lt 8 ];
then
        echo -e "\033[47;35m Usage: $0 subject analysis_dir func_dir_name rest_name if_epi0 fsaverage clean_up_reRun \033[0m"
        exit
fi

if [ $# -eq 7 ];then
redo_reg=true
fi


if [ ! -d ${SUBJECTS_DIR}/${fsaverage} ]
then
        ln -s ${FREESURFER_HOME}/subjects/${fsaverage} ${SUBJECTS_DIR}/${fsaverage}
fi

cwd=$( pwd )
#if [ -f ${SUBJECTS_DIR}/${subject}/scripts/recon-all.done ]
if [ -f ${SUBJECTS_DIR}/${subject}/mri/wm.mgz ]
then
	## 1. Performing bbregister
	if [ ${redo_reg} = 'true' ]; then
		rm -r ${func_reg_dir};  
        fi
                mkdir -p ${func_reg_dir} ; cd ${func_reg_dir}
		if [ ${if_epi0} = 'true' ]
		then
			fslroi ${func_dir}/${rest}.nii.gz ${func_dir}/epi_t0.nii.gz 0 1
			3dresample -orient RPI -inset ${func_dir}/epi_t0.nii.gz -prefix ${func_dir}/epi_t0_rpi.nii.gz
			fslmaths ${func_dir}/epi_t0_rpi.nii.gz -mas ${func_dir}/${rest}_pp_mask.nii.gz ${func_dir}/epi_t0_brain.nii.gz
			mov=${func_dir}/epi_t0_brain.nii.gz
		else
			mov=${func_dir}/example_func_brain_bc.nii.gz
		fi
                ## convert the example_func to RSP orient
                3dresample -orient RSP -prefix ${func_reg_dir}/tmp_example_func_brain_rsp.nii.gz -inset ${mov}
                fslreorient2std ${func_reg_dir}/tmp_example_func_brain_rsp.nii.gz > ${func_reg_dir}/rsp2rpi.mat
                convert_xfm -omat ${func_reg_dir}/rpi2rsp.mat -inverse ${func_reg_dir}/rsp2rpi.mat
                ## do fs bbregist
                mov1=${func_reg_dir}/tmp_example_func_brain_rsp.nii.gz
		bbregister --s ${subject} --mov ${mov1} --reg bbregister_rsp2rsp.dof6.init.dat --init-fsl --bold --fslmat flirt_rsp2rsp.init.mtx
		bb_init_mincost=`cut -c 1-8 bbregister_rsp2rsp.dof6.init.dat.mincost`
		comp=`expr ${bb_init_mincost} \> 0.55`
		if [ "$comp" -eq "1" ];
		then
			bbregister --s ${subject} --mov ${mov1} --reg bbregister_rsp2rsp.dof6.dat --init-reg bbregister_rsp2rsp.dof6.init.dat --bold --fslmat flirt_rsp2rsp.mtx
			bb_mincost=`cut -c 1-8 bbregister_rsp2rsp.dof6.dat.mincost`
	                comp=`expr ${bb_mincost} \> 0.55`
			if [ "$comp" -eq "1" ];
               	then
				echo "BBregister seems still problematic, needs a posthoc visual inspection!" >> warnings.bbregister
			fi
		else
                cp ${func_reg_dir}/bbregister_rsp2rsp.dof6.init.dat ${func_reg_dir}/bbregister_rsp2rsp.dof6.dat ; 
                cp ${func_reg_dir}/flirt_rsp2rsp.init.mtx ${func_reg_dir}/flirt_rsp2rsp.mtx
                fi
                convert_xfm -omat ${func_reg_dir}/flirt.mtx -concat ${func_reg_dir}/flirt_rsp2rsp.mtx ${func_reg_dir}/rpi2rsp.mat
                # write the fs registratio matrix from rpi func to rsp anat 
                tkregister2 --mov ${mov} --targ ${highres} --fsl ${func_reg_dir}/flirt.mtx --noedit --s ${subject} --reg ${func_reg_dir}/bbregister.dof6.dat			
        ## 2. write the registration to fsl format
	echo $subject
        cd ${func_reg_dir}
        
	cp flirt.mtx example_func2highres.mat
	## Create mat file for conversion from subject's anatomical to functional
	convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat
        convert_xfm -omat example_func2highres_rpi.mat -concat ${anat_reg_dir}/reorient2rpi.mat example_func2highres.mat
        flirt -in ${mov} -ref ${anat_reg_dir}/highres_rpi.nii.gz -applyxfm -init example_func2highres_rpi.mat -out example_func2highres_rpi.nii.gz
        rm ${mov1}
        3dedge3 -input ${anat_reg_dir}/highres_rpi.nii.gz -prefix ${anat_reg_dir}/highres_rpi_3dedge3.nii.gz

        ## 3. visual check 
        mkdir -p ${func_reg_dir}/vcheck
        cd ${func_reg_dir}
        ## vcheck of the functional registration
        echo "-----visual check of the functional registration-----"
        bg_min=`fslstats example_func2highres_rpi.nii.gz -P 20`
        bg_max=`fslstats example_func2highres_rpi.nii.gz -P 98`
        overlay 1 1 example_func2highres_rpi.nii.gz ${bg_min} ${bg_max} ${anat_reg_dir}/highres_rpi_3dedge3.nii.gz 1 1 vcheck/render_vcheck
        slicer vcheck/render_vcheck -s 2 \
           -x 0.30 sla.png -x 0.40 slb.png -x 0.50 slc.png -x 0.60 sld.png -x 0.70 sle.png \
           -y 0.30 slg.png -y 0.40 slh.png -y 0.50 sli.png -y 0.60 slj.png -y 0.70 slk.png \
           -z 0.30 slm.png -z 0.40 sln.png -z 0.50 slo.png -z 0.60 slp.png -z 0.70 slq.png 
        pngappend sla.png + slb.png + slc.png + sld.png  +  sle.png render_vcheck1.png 
        pngappend slg.png + slh.png + sli.png + slj.png  + slk.png render_vcheck2.png
        pngappend slm.png + sln.png + slo.png + slp.png  + slq.png render_vcheck3.png
        pngappend render_vcheck1.png - render_vcheck2.png - render_vcheck3.png example_func2highres_rpi.png
        mv example_func2highres_rpi.png vcheck/
        title=${subject}.${func_dir_name}.ccs.func.reg_fsbbr
        convert -font helvetica -fill white -pointsize 36 -draw "text 30,50 '$title'" vcheck/example_func2highres_rpi.png vcheck/example_func2highres_rpi.png
        rm -f sl?.png render_vcheck?.png vcheck/render_vcheck*

else
       	echo "Please run recon-all for this subject first!"
fi

## Back to the directory
cd ${cwd}
