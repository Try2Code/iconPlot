#!/usr/bin/env ruby

require 'cdo'

def dbg(msg); pp msg unless ENV['DEBUG'].nil? ; end

#=============================================================================
# plotting setup
@iconplot = '/pool/data/ICON/tools/icon_plot.ncl'
@iconlib  = '/pool/data/ICON/tools'
case `hostname`.chomp 
  when /thingol/
    @iconplot = "#{ENV['HOME']}/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl"
    @iconlib  = "#{ENV['HOME']}/src/git/icon/scripts/postprocessing/tools"
end

#=============================================================================
# CDO setup
Cdp.setCDO
Cdp.setDebug
Cdo.forceOutput = !ENV['FORCE'].nil?
Cdo.debug       = true
@cdoOptions = '-f nc4 -z zip'

#=============================================================================
# input setup, names for intermediate files
# icon input
if ARGV[0].nil? then
  warn "No input file given"
  exit(1)
else
  @ifile=ARGV[0]
end
@rhopot       = 'rhopot.nc'
@rhopot_delta = 'rhopot_deltaToSurface.nc'
@mld          = 'icon_mld.nc'

#=============================================================================
# output meta data
system("cat > partab<<EOF
&PARAMETER
  CODE=18
  NAME=mixed_layer_depth
  STANDARD_NAME=mixed_layer_depth
  LONG_NAME='Mixed layer depth'
  UNITS='m'
/
EOF")

# select T and S, set code to -1 to be ignored by rhopot/adisit
# ONLY USE MARCH FOR NORTHERN HEMISPHERE
Cdo.rhopot(0,
           :input => "-adisit -setcode,-1 -div -selname,T,S -selmon,3 #@ifile -selname,wet_c #@ifile",
           :output => @rhopot)

# substracto the surface value
Cdo.sub(:input => "#@rhopot -sellevidx,1 #@rhopot",
        :output => @rhopot_delta)
# compute the depth if the iso surface for a value of 0.125
Cdo.setpartab('partab',
              :input => "-isosurface,0.125 #@rhopot_delta #@mld")
#=============================================================================
# plot each timestep
ntime=Cdo.ntime(:input => @mld)
# select north atlantic
  select='-mapLLC=-60,30 -mapURC=30,85'
colormap='-colormap=testcmap'

(0..ntime).each {|t|
  # select north atlantic
  select='-mapLLC=-60,30 -mapURC=30,85'
  colormap='-colormap=testcmap'
  system("nclsh #@plot -iFile=#@mld " +
         "-varName=mixed_layer_depth -oFile=mld_#{t.rjust(2,'0')} " + 
         "-isIcon -timeStep=#{i} #{select} #{colormap}")
}
