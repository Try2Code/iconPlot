#!/usr/bin/env ruby

require 'cdo'
require 'jobqueue'

def dbg(msg); pp msg unless ENV['DEBUG'].nil? ; end
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
@q            = JobQueue.new

#=============================================================================
# plotting setup
@iconplot = '/pool/data/ICON/tools/icon_plot.ncl'
@iconlib  = '/pool/data/ICON/tools'
case `hostname`.chomp 
  when /thingol/
    @iconplot = "#{ENV['HOME']}/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl"
    @iconlib  = "#{ENV['HOME']}/src/git/icon/scripts/postprocessing/tools"
end
@plot="#@iconplot #@iconlib"

#=============================================================================
# CDO setup
Cdo.forceOutput, Cdo.debug = !ENV['FORCE'].nil?, !ENV['DEBUG'].nil?
@cdoOptions = '-f nc4 -z zip -v'

#=============================================================================
# output meta data
File.open("partab","w") {|f|
  f << "&PARAMETER
  CODE=18
  NAME=mixed_layer_depth
  STANDARD_NAME=mixed_layer_depth
  LONG_NAME='Mixed layer depth'
  UNITS='m'
/"
}

# select T and S, set code to -1 to be ignored by rhopot/adisit
# ONLY USE MARCH FOR NORTHERN HEMISPHERE
unless Cdo.showmon(:input => @ifile)[0].split.include?('3')
  warn "Could not find march in input data!"
  exit(1)
end unless ENV['CHECK'].nil?
Cdo.rhopot(0,
           :input => "-adisit -setcode,-1 -div -selname,T,S -selmon,3 #@ifile -selname,wet_c #@ifile",
           :output => @rhopot,
           :options => @cdoOptions)

# substracto the surface value
Cdo.sub(:input => "#@rhopot -sellevidx,1 #@rhopot",
        :output => @rhopot_delta)
# compute the depth if the iso surface for a value of 0.125
Cdo.setpartab('partab',
              :input => "-isosurface,0.125 #@rhopot_delta",
              :output => @mld)
#=============================================================================
# plot each timestep
ntime    = Cdo.ntime(:input => @mld)[0].to_i
# select north atlantic
select   = '-mapLLC=-60,30 -mapURC=30,85'
colormap = '-colormap=testcmap'
(0...ntime).each {|t|
  @q.push {
    system("nclsh #@plot -iFile=#@mld " +
           "-varName=mixed_layer_depth -oFile=mld_#{t.to_s.rjust(2,'0')} " +
           "-isIcon -timeStep=#{t} #{select} #{colormap}\n")
  }
}
@q.run
