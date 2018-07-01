#!/bin/bash

# Purpose: Rename fields in EAM/CAM SE regional input file

# Usage:
# rgn_rnm.sh rnm_sng fl_in.nc fl_out.nc
# where rnm_sng is region string that EAM constructs from namelist and appends to variables, e.g.,
# ~/nco/data/rgn_rnm.sh _128e_to_134e_9s_to_16s ~/rgn_in.nc ~/rgn_in_rnm.nc

# Namelist specifications/format for regional output are not crystal clear
# Multiple regions requested with namelist entries like (per Wuyin Lin)
# fincl3 = 'T','PRECT','CLDTOT','LWCF'
# fincl3lonlat = '120e_2n','262e_35n','120e:130e_2n:5n'
# Above example outputs variables for two single columns and one region
# Regional output file contains variables with CDL definition like
# lat_128e_to_134e_9s_to_16s(ncol_128e_to_134e_9s_to_16s),
# lon_128e_to_134e_9s_to_16s(ncol_128e_to_134e_9s_to_16s), 
# PRECL_128e_to_134e_9s_to_16s(time,ncol_128e_to_134e_9s_to_16s)
# NB: Suffix-string coordinate order is (or can be) WENS (insanity!) while NCO prefers WESN (auxiliary hyperslab bounding-box (-X) format requires WESN though grid-generator also accepts SNWE)
# NB: Same format applies to FV regional files and...
# FV regional data may be directly regridded without dual-grid gymnastics!
# 'ncremap -i dat_rgn_rnm -g grd_dst -o dat_rgr' approach works on FV regional files fxm: verify
# because ncremap infers regional FV grids from rectangular data files (http://nco.sf.net/nco.html#infer) 
# FV output must still be renamed first as below

function ncvarlst { ncks --trd -m ${1} | grep -E ': type' | cut -f 1 -d ' ' | sed 's/://' | sort ; }
function ncdmnlst { ncks --cdl -m ${1} | cut -d ':' -f 1 | cut -d '=' -s -f 1 ; }

dbg_lvl=0 # [nbr] Debugging level
fl_idx=0 # [idx] File index
rnm_sng=${1}
fl_in=${2}
fl_out=${3}

var_lst=`ncvarlst ${fl_in} | grep ${rnm_sng}`
dmn_lst=`ncdmnlst ${fl_in} | grep ${rnm_sng}`

# Parse suffix for SNWE coordinates
if [[ "${rnm_sng}" =~ ^(.*)([0-9][0-9][0-9][0-9][01][0-9].nc.?)$ ]]; then

dmn_sng=''
if [ -n "${dmn_lst}" ]; then
    for dmn in ${dmn_lst} ; do
	dmn_sng="${dmn_sng} -d ${dmn},${dmn/${rnm_sng}/}"
    done # !dmn
fi # !dmn_lst

var_sng=''
if [ -n "${var_lst}" ]; then
    for var in ${var_lst} ; do
	var_sng="${var_sng} -v ${var},${var/${rnm_sng}/}"
    done # !dmn_lst
fi # !dmn_lst

cmd_rnm[${fl_idx}]="ncrename -O ${dmn_sng} ${var_sng} ${fl_in} ${fl_out}"
if [ ${dbg_lvl} -ne 2 ]; then
    eval ${cmd_rnm[${fl_idx}]}
    if [ $? -ne 0 ]; then
	printf "${spt_nm}: ERROR Failed to rename regional input file. Debug this:\n${cmd_rnm[${fl_idx}]}\n"
	exit 1
    fi # !err
fi # !dbg

exit 0
