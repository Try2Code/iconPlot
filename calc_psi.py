from cdo import *
from pylab import *
import os,sys

cdo        = Cdo()
cdo.debug  = 'DEBUG' in os.environ

# INPUT HANDLING ========================================================================
inputfile       = sys.argv[1]
varnameDefault  = 'u_vint_acc'
plotfileDefault = 'psi.png'

if len(sys.argv) > 2:
    # varname is given on the command line
    varName = sys.argv[2]
else:
    # use default
    varName = varnameDefault

if len(sys.argv) == 4:
    # output file given
    plotfile = sys.argv[3]
else:
    # use default
    plotfile = plotfileDefault

# stop if file cannot be read in
if not os.path.isfile(inputfile):
    print("Cannot read input: "+inputfiles[0])
    exit(1)
# =======================================================================================
# DATA PREPARATION ======================================================================

# replace missing value with zero for later summation
ifile   = cdo.setmissval(0.0,input=inputfile)
file_h  = cdo.readCdf(ifile)
var     = file_h.variables[varName]
varData = cdo.readArray(ifile,varName)
varDims = file_h.variables[varName].dimensions

# read in dimensions: expectes is 2d with time axis (time,lat,lon)
a          = map(lambda x: file_h.variables[x][:], varDims)
times, lats, lons = a[0], a[1], a[2]

# use first timestep only
if times.size > 1: 
    print('Will only use the first timestep!!!!!!!!!')
varData = varData[1,:,:]

# avoid longitude greater than 180
if lons.max() > 180.0:
    lons = lons - 360.0

if 'DEBUG' in os.environ:
    print(varData)
    print(varData.shape)
    print(varDims)
    print(times)
    print(lons)
    print(lats)
# =======================================================================================
# CALC PSI ==============================================================================
psi = array(varData)
# parial sum from south to north
psi = sin(varData)
for lon in range(0,lons.size):
    for lat in range(0,lats.size):
        psi[lat,lon] = varData[0:lat,lon].sum()

erad = 6.371229e6
pi   = 3.141592653
dist = pi/lats.size*erad
psi  = -psi * dist * 1.0e-6
# =======================================================================================
# PLOTTING ==============================================================================
xlabel('lon [deg]')
ylabel('lat [deg]')
title('Bar. stream function')
grid(True)
im = imshow(varData,
        origin='lower',
        interpolation='nearest',
        extent=[lons.min(),lons.max(),lats.min(),lats.max()])
cb = colorbar(im)
tick_params(axis='x', labelsize=8)
tick_params(axis='y', labelsize=8)
cb.set_label('Transport [Sv]')
savefig(plotfile)
# =======================================================================================
