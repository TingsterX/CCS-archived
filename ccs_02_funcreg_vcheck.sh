##########################################################################################################################
## CCS SCRIPT TO DO QUALITY ASSURANCE OF FUNCTIONAL IMAGE REGISTRATION
##########################################################################################################################
## - visualize the registration output

## full/path/to/site
dir=$1
## subject
subject=$2
## name of anatomical directory
func_dir_name=$3
## name of func registratino directory
func_reg_dir_name=$4
## standard template
standard=$5

if [ $# -lt 5 ];
then
        echo -e "\033[47;35m Usage: $0 analysis_dir subject_list func_dir_name func_reg_dir_name standard \033[0m"
        exit
fi

# define the plot function
vcheck(){
  overlay=$1
  underlay=$2
  figout=$3
  workdir=`dirname ${figout}`
  pushd ${workdir}
  minImage=`fslstats ${overlay} -P 5`
  maxImage=`fslstats ${overlay} -P 95`
  slicer ${overlay} ${underlay} -i ${minImage} ${maxImage} -s 2 \
    -x 0.30 sla.png -x 0.40 slb.png -x 0.55 slc.png -x 0.65 sld.png -x 0.70 sle.png -x 0.80 slf.png \
    -y 0.22 slg.png -y 0.30 slh.png -y 0.40 sli.png -y 0.50 slj.png -y 0.60 slk.png -y 0.68 sll.png \
    -z 0.45 slm.png -z 0.53 sln.png -z 0.60 slo.png -z 0.68 slp.png -z 0.75 slq.png -z 0.83 slr.png 
    pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png render_vcheck1.png 
    pngappend slg.png + slh.png + sli.png + slj.png + slk.png + sll.png render_vcheck2.png
    pngappend slm.png + sln.png + slo.png + slp.png + slq.png + slr.png render_vcheck3.png
    pngappend render_vcheck1.png - render_vcheck2.png - render_vcheck3.png ${figout}
  rm sl?.png render_*.png
  popd
}

## Start scripts
echo "Processing ${subject} ..."
func_dir=${dir}/${subject}/${func_dir_name}
func_reg_dir=${func_dir}/${func_reg_dir_name}
mkdir -p ${func_reg_dir}/vcheck
cd ${func_reg_dir}
vcheck ${func_reg_dir}/fnirt_example_func2standard.nii.gz ${standard} ${func_reg_dir}/vcheck/fnirt_example_func2standard.png
vcheck ${func_reg_dir}/


done

