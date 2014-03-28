#!/usr/bin/env python
from cdo import *
from pylab import *
import os,sys
import matplotlib
import numpy as np
import matplotlib.cm as cm
import matplotlib.mlab as mlab
import matplotlib.pyplot as plt

cdo        = Cdo()
cdo.debug  = 'DEBUG' in os.environ

# USAGE =================================================================================
# ./calc_psi.py <ifile> <varname> <plotfile> <colormap>
#
# defaults are:
#   varname  = 'u_vint_acc'
#   plotfile = 'psi.png' (other output types:  png, pdf, ps, eps and svg)
#   colormap = 'RdBu' (see http://matplotlib.org/examples/color/colormaps_reference.html for more)
# =======================================================================================
# INPUT HANDLING ========================================================================
inputfile       = sys.argv[1]
varnameDefault  = 'u_vint_acc'
plotfileDefault = 'psi.png'
colormapDefault = 'RdBu'

if 'DEBUG' in os.environ:
    print(sys.argv)

if len(sys.argv) > 2:
    # varname is given on the command line
    varName = sys.argv[2]
else:
    # use default
    varName = varnameDefault

if len(sys.argv) > 3 :
    # output file given
    plotfile = sys.argv[3]
else:
    # use default
    plotfile = plotfileDefault

if len(sys.argv) > 4 :
    # colormap given
    colormap = sys.argv[4]
else:
    # use default
    colormap = colormapDefault

# stop if file cannot be read in
if not os.path.isfile(inputfile):
    print("Cannot read input: "+inputfile)
    exit(1)
# =======================================================================================
# DATA PREPARATION ======================================================================

# replace missing value with zero for later summation
ifile     = cdo.setmissval(0.0,input = inputfile)
file_h    = cdo.readCdf(ifile)
var       = file_h.variables[varName]
varData   = cdo.readArray(ifile,varName)
varDataMa = cdo.readMaArray(ifile,varName)
varDims   = file_h.variables[varName].dimensions
# read in dimensions: expectes is 2d with time axis (time,lat,lon)
a          = map(lambda x: file_h.variables[x][:], varDims)
#times, depth, lats, lons = a[0], a[1], a[2], a[3] # MPIOM psi input
times, lats, lons = a[0], a[1], a[2]

if 'DEBUG' in os.environ:
    print("# DEBUG ===================================================================")
    print(inputfile)
    print(varName)
    print(plotfile)
    print(colormap)
    print("#==========================================================================")
    print(varData)
    print(varData.shape)
    print(varDims)
    print(times)
    print(lons)
    print(lats)
    print("# DEBUG ===================================================================")

# use first timestep only
if times.size > 1: 
    print('Will only use the first timestep!!!!!!!!!')
#varData = varData[-1,0,:,:] # MPIOM psi input
varData = varData[-1,:,:]

# avoid longitude greater than 180
if lons.max() > 180.0:
    lons = lons - 360.0

# =======================================================================================
# CALC PSI ==============================================================================
psi = array(varData)
# parial sum from south to north
for lon in range(0,lons.size):
    for lat in range(0,lats.size):
        psi[lat,lon] = varData[0:lat,lon].sum()

erad = 6.371229e6
pi   = 3.141592653
dist = pi/lats.size*erad
psi  = -psi * dist * 1.0e-6
#psi  = psi * 1.0e-6 / 1025.0 # MPIOM psi input
# =======================================================================================
# PLOTTING ==============================================================================
# labeling
xlabel('lon [deg]')
ylabel('lat [deg]')
title('Bar. stream function')
tick_params(axis='x', labelsize=8)
tick_params(axis='y', labelsize=8)

if False:
# draw
    im = imshow(varData,
            origin='lower',
            interpolation='nearest',
            cmap=colormap,
            aspect='equal', # auto for fill
            extent=[lons.min(),lons.max(),lats.min(),lats.max()])
    cb = colorbar(im)
    cb.set_label('Transport [Sv]')
else:
    matplotlib.rcParams['contour.negative_linestyle'] = 'solid'
    plt.figure()
    X, Y = np.meshgrid(lons, lats)
    CS   = plt.contour(X, Y, psi, 20, cmap=colormap)
    plt.clabel(CS, fontsize=6, inline=1)
    plt.title("Bar. streamfunction form:\n"+inputfile,fontsize=10)

savefig(plotfile)
# =======================================================================================
