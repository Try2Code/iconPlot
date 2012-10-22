#!/bin/sh
#


# plot T,S and potential density variation to initial values from a list of ICON input files

#  updates
#   - ncl (icon_plot) with dozens of errors on blizzard, but okay on workstation
#   - cdo -r cat necessary - done
#
# ==============================================================================
   DEBUG='TRUE'
  CDOOPT='-O'
#  An updated version of cdo is necessary with a working rhopot operator:
#    CDO="cdo-dev $CDOOPT"  #
#ICONPLOT=$HOME/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl
     CDO="cdo-1.5.8rc4 $CDOOPT"  # compiled and located at $HOME/bin
ICONPLOT=/pool/data/ICON/tools/icon_plot.ncl
 ICONLIB=/pool/data/ICON/tools
ICONPLOT=./icon_plot.ncl
 ICONLIB=.

# ==============================================================================
# little helper function for debugging
#  - set -x does the same
function call {
  if [ ! -z "$DEBUG" ];then
    echo "CALLING:'$@'"
  fi
  $@
}
# ==============================================================================
# ==============================================================================
# we supppose, that all files belong to the same experiment
     fileListPath='/work/mh0287/users/stephan/Icon/icon-dev.tst/experiments/xmpiom.bliz.r10130.NAtl'
  fileListPattern='xmpiom.bliz.r10130.NAtl_icon*_000[1-3].nc'
     Temp_VarName='T'
 Salinity_VarName='S'
PotDensityVarName='rhopot'
      MaskVarName='wet_c'
   outputDataFile='out.TSrhopot.fldm.nc'

# ==============================================================================
#declare -a fileListArray
fileList=$(ls $fileListPath/$fileListPattern)
i=0
for file in $fileList; do
  fileListArray[$i]=$file
  i=$((i+1))
done
numberOfFiles=$i
echo "$numberOfFiles number of files"
echo $fileList
# ==============================================================================
# handing of the initial values
# 1) get the initial values before any averading is done
initFile='initValues.nc'
call "$CDO -selname,$Temp_VarName,$Salinity_VarName -seltimestep,1 ${fileListArray[0]} $initFile"

# 2) compute rhopot and add it to the initial values file
    initRhopotFile='initRhopot.nc'
call "$CDO rhopot,0 $initFile $initRhopotFile"
initWithPotDensity='initValuesWithPotDensity.nc'
call "$CDO merge $initFile $initRhopotFile $initWithPotDensity"

# ==============================================================================
# creating a mask file
maskFile='mask.nc'
call "$CDO -selname,$MaskVarName -seltimestep,1 ${fileListArray[0]} $maskFile"

# ==============================================================================
# Loop over all files in serial
for file in $fileList; do
  baseFilename=$(basename $file)
  # compute yearmean of temperature and salinity and then maskout the land points
  call "$CDO -div -yearmean -selname,$Temp_VarName,$Salinity_VarName $file $maskFile ${Temp_VarName}-${Salinity_VarName}_${baseFilename}"
  # compute the corresponding potential density
  call "$CDO rhopot,0 ${Temp_VarName}-${Salinity_VarName}_${baseFilename} ${PotDensityVarName}_${baseFilename}"
  # merge boith together
  call "$CDO merge ${Temp_VarName}-${Salinity_VarName}_${baseFilename} ${PotDensityVarName}_${baseFilename} merged_${baseFilename}"
  # substract the initial values from it
  call "$CDO sub merged_${baseFilename} $initWithPotDensity diff2init_${baseFilename}"
  # compute the fldmean
  call "$CDO fldmean diff2init_${baseFilename} fldmean_${baseFilename}"
done

# ==============================================================================
# Cat the files together
call "$CDO -r cat fldmean_${fileListPattern}  $outputDataFile"

# ==============================================================================
# Plot a  hovmoeller type graph
for varname in $Temp_VarName $Salinity_VarName $PotDensityVarName; do 
  call "nclsh $ICONPLOT  -altLibDir=$ICONLIB -varName=$varname -iFile=$outputDataFile
  -oFile=$(basename $outputDataFile .nc)_$varname -oType=png -isIcon -DEBUG -hov=true"
done
