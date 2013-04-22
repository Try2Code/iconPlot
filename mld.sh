#/bin/bash

#The sigma-t (density) criterion used in Levitus (1982) uses the depth at which a change from the surface sigma-t of 0.125 has occurred.
#sigma-t is defined as rhopot(s,t,0)-1000 kg m-3
if [ ! -z "${DEBUG}" ]; then
  set -x
fi
#=============================================================================
# plotting setup
ICONPLOT=/pool/data/ICON/tools/icon_plot.ncl
 ICONLIB=/pool/data/ICON/tools
case "$(hostname)" in
  thingol)
    ICONPLOT=$HOME/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl
     ICONLIB=$HOME/src/git/icon/scripts/postprocessing/tools
    ;;
esac
PLOT="${ICONPLOT} -altLibDir=${ICONLIB}"

#=============================================================================
# CDO setup
# check if the module command is available
module >/dev/null 2>&1
if [ $? -eq 0 ]; then #sucessfull run
  module load cdo
fi

#=============================================================================
# input setup, names for intermediate files
# icon input
if [ -z "$1" ]; then
  echo "No input file given"
  exit 1
else
  ifile=$1
fi
      RHOPOT=rhopot.nc
RHOPOT_DELTA=rhopot_deltaToSurface.nc
         MLD=icon_mld.nc

#=============================================================================
# output meta data
cat > partab<<EOF
&PARAMETER
  CODE=18
  NAME=mixed_layer_depth
  STANDARD_NAME=mixed_layer_depth
  LONG_NAME="Mixed layer depth"
  UNITS="m"
/
EOF

# select T and S, set code to -1 to be ignored by rhopot/adisit
# ONLY USE MARCH FOR NORTHERN HEMISPHERE
cdo -f nc4 -z zip -rhopot,0 -adisit -setcode,-1 -selname,T,S -div -selmon,3 $ifile -selname,wet_c $ifile $RHOPOT

# substracto the surface value
cdo sub $RHOPOT -sellevidx,1 $RHOPOT $RHOPOT_DELTA
# compute the depth if the iso surface for a value of 0.125
cdo -setpartab,partab -isosurface,0.125 $RHOPOT_DELTA $MLD

#=============================================================================
# plot each timestep
   ntime=$(cdo ntime $MLD)
# select north atlantic
  select='-mapLLC=-60,30 -mapURC=30,85'
colormap='-colormap=testcmap'

for i in $(seq -w 0 $((ntime-1))); do
  # select north atlantic
  select='-mapLLC=-60,30 -mapURC=30,85'
  colormap='-colormap=testcmap'
  nclsh $PLOT -iFile=$MLD \
    -varName=mixed_layer_depth -oFile=mld_$i \
    -isIcon -timeStep=$i \
    ${select} ${colormap}
done
