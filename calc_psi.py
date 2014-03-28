#!/usr/bin/env python
from cdo import *
from pylab import *
import os,sys,math
import matplotlib
import netCDF4 as Cdf
import mpl_toolkits.basemap as bm
import numpy as np
import matplotlib.cm as cm
import matplotlib.mlab as mlab
import matplotlib.pyplot as plt

cdo        = Cdo()
cdo.debug  = 'DEBUG' in os.environ

# USAGE =================================================================================
#   ./calc_psi.py <ifile> VAR=<varname> PLOT=<plotfile> CMAP=<colormap>
#
# defaults are:
#   varname  = 'u_vint_acc'
#   plotfile = 'psi.png'    (other output types:  png, pdf, ps, eps and svg)
#   colormap = 'jet'        (see http://matplotlib.org/examples/color/colormaps_reference.html for more)
# =======================================================================================
# INPUT HANDLING ========================================================================
inputfile = sys.argv[1]
# stop if file cannot be read in
if not os.path.isfile(inputfile):
    print("Cannot read input: "+inputfile)
    exit(1)

options = {'VAR': 'u_vint_acc','PLOT': 'psi.png','CMAP': 'jet'}

optsGiven = sys.argv[2:]
for optVal in optsGiven:
    key,value = optVal.split('=')
    options[key] = value

varName  = options['VAR']
plotfile = options['PLOT']
colormap = options['CMAP']
# =======================================================================================
# DATA PREPARATION ======================================================================

# replace missing value with zero for later summation
ifile     = cdo.setmisstoc(0.0,input = inputfile)
file_h    = cdo.readCdf(ifile)
var       = file_h.variables[varName]
varData   = cdo.readArray(ifile,varName)
varDataMa = cdo.readMaArray(cdo.div(input = '%s -sellevidx,1 -selname,wet_c %s'%(inputfile,inputfile)),varName)
varDims   = file_h.variables[varName].dimensions
# read in dimensions: expectes is 2d with time axis (time,lat,lon)
a         = map(lambda x: file_h.variables[x][:], varDims)
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
psi      = np.array(varData)
psi[:,:] = varData[:,:]
# parial sum from south to north
for lat in range(lats.size-2,-1,-1):
    psi[lat,:] = psi[lat,:] + psi[lat+1,:]

erad = 6.371229e6
pi   = 3.141592653
dist = (pi/lats.size)*erad
psi  = -psi * dist * 1.0e-6
#psi  = psi * 1.0e-6 / 1025.0 # MPIOM psi input
# =======================================================================================
# PLOTTING ==============================================================================
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
    lon2d, lat2d = np.meshgrid(lons, lats)
    mapproj = bm.Basemap(projection='cyl', 
                       llcrnrlat=math.floor(lats.min()), 
                       llcrnrlon=math.floor(lons.min()),
                       urcrnrlat=math.floor(lats.max()),
                       urcrnrlon=math.floor(lons.max()))
#   mapproj = bm.Basemap(projection='cyl', 
#                      llcrnrlat=-90, 
#                      llcrnrlon=-180,
#                      urcrnrlat=90,
#                      urcrnrlon=180)
    mapproj.drawcoastlines(linewidth=.2)
    mapproj.drawmapboundary(fill_color='0.99')
    mapproj.drawparallels(np.array([-80,-60,-40,-20, 0, 20,40,60,80]), labels=[1,0,0,0],fontsize=8)
    mapproj.drawmeridians(range(0,360,30), labels=[0,0,0,1],fontsize=8)
    lonsPlot, latsPlot = mapproj(lon2d, lat2d)

    plt.grid(True)
#   CS   = plt.contourf(lonsPlot, latsPlot, psi, 20, cmap=colormap)
    CS   = plt.contourf(lonsPlot, latsPlot, psi, 20, cmap=colormap)
#   CS   = plt.contourf(lonsPlot, latsPlot, psi, 20, color='black')
    CSBar = plt.contour(lonsPlot,
                        latsPlot,
                        psi,
                        CS.levels[::2],
                        colors = ('k',),
                        linewidths = (1,),
                        origin = 'lower')
    plt.title('Listed colors (3 masked regions)')
    plt.clabel(CSBar, fmt = '%2.1f', colors = 'w', fontsize=10)
    CSBar.cmap.set_under('yellow')
    CSBar.cmap.set_over('cyan')

# labeling
xlabel('lon [deg]')
ylabel('lat [deg]')
title('Bar. stream function')
tick_params(axis='x', labelsize=8)
tick_params(axis='y', labelsize=8)

# Notice that the colorbar command gets all the information it
# needs from the ContourSet object, CS3.
plt.colorbar(CS)
#   mapproj.drawlsmask(land_color='coral')
plt.title("Bar. streamfunction form:\n"+inputfile,fontsize=10)

savefig(plotfile)
# =======================================================================================
