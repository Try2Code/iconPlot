#!/usr/bin/env ruby

require 'cdo'
require 'fileutils'
require 'jobqueue'
require 'socket'
require 'iconPlot'

# check input
if ARGV[0].nil?
  warn "no input files given"
  exit(-1)
else
  puts 'Please remember, that the lat file in the list is expected to be an ICON grid file'
  sleep 1
end
files     = ( ARGV.size > 1 ) ? ARGV : Dir.glob(ARGV[0])
# check files
files.each {|file|
  warn "Cannot read file '#{file}'" unless File.exist?(file)
}

q         = JobQueue.new([JobQueue.maxnumber_of_processors,20].min)
lock      = Mutex.new

#=============================================================================== 
# setup of CDO on different machines
hostname = Socket.gethostname
case hostname
when /thingol/
  Cdo.setCdo(ENV['HOME']+"/local/bin/cdo-dev")
when /lizard/
  Cdo.setCdo(ENV['HOME']+"/local/rhel55-x64/bin/cdo")
when /blizzard/
  Cdo.setCdo(ENV['HOME']+"/local/bin/cdo")
else
  puts "Use default Cdo:#{Cdo.getCdo} (version:#{Cdo.version})"
end

Cdo.checkCdo
Cdo.debug = true unless ENV['DEBUG'].nil?

#=============================================================================== 
# compute the experiments from the data directories and link the corresponding files
def splitFilesIntoExperiments(files)
  gridFile = files.pop
  experiments = files.map {|f| File.basename(File.dirname(f))}.uniq.sort_by {|f| f.length}.reverse
  # take the larges part of the filenames as experiment name if the files are in
  # the current directory
  if experiments == ["."] then
    n = files.map(&:size).min.times.map {|i| 
      if files.map {|f| f[0,i-1]}.uniq.size == 1
        1
      else
        nil
      end 
    }.find_all {|v| not v.nil?}.size-1
    uniqName = files[0][0,n]
    experiments = [uniqName]
  end
  experimentFiles, experimentAnalyzedData = {},{}
  experiments.each {|experiment|
    experimentFiles[experiment] = files.grep(/#{experiment}/)
      experimentFiles[experiment].each {|file| files.delete(file)}
    experimentFiles[experiment].sort!

    experimentAnalyzedData[experiment] = []
  }

  [gridFile,experimentFiles,experimentAnalyzedData]
end
#=============================================================================== 
# MAIN
gridfile, experimentFiles, experimentAnalyzedData = splitFilesIntoExperiments(files)
iceHeight                                         = 'p_ice_hi'
iceConcentration                                  = 'p_ice_concSum'
#   process the experiments results
experimentFiles.each {|experiment, files|
  files.each {|file|
    q.push {
      volumeFile = "iceVolume_#{File.basename(file)}"
      unless File.exist?(volumeFile)
        Cdo.setname('ice_volume',:in => " -divc,1e9 -mul -mul -selname,#{iceHeight} #{file}  -selname,cell_area #{gridfile}  -selname,#{iceConcentration} #{file}",
                   :out => volumeFile)
      end
      lock.synchronize {experimentAnalyzedData[experiment] << volumeFile }
    }
  }
}
q.run
# merge all yearmean data (T,S,rhopot) into one file per experiment
q.clear
experimentAnalyzedData.each {|experiment,files|
  q.push {
  tag   = ''
  ofile = [experiment,'iceVolume',tag].join('_') + '.nc'
  unless File.exist?(ofile)
    Cdo.cat(:in => files.sort.join(' '), :out => ofile, :options => '-r')
  end
# plotFile = 'thingol' == Socket.gethostname \
#          ? '/home/ram/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl' \
#          : '../../scripts/postprocessing/tools/icon_plot.ncl'
# plotter  = 'thingol' == Socket.gethostname \
#          ? IconPlot.new(ENV['HOME']+'/local/bin/nclsh', plotFile, File.dirname(plotFile),'png','qiv',true,true) \
#          : IconPlot.new('/sw/rhel55-x64/ncl-5.2.1/bin/ncl', plotFile, File.dirname(plotFile), 'ps','evince',true,true)
# images = []
# images << plotter.scalarPlot(ofile,'T_'+     File.basename(ofile,'.nc'),'T',     :tStrg => "#{experiment}", :bStrg => ' ',:hov => true,:minVar => -1.0,:maxVar => 5.0,:numLevs => 24,:rStrg => 'Temperature')
# images << plotter.scalarPlot(ofile,'S_'+     File.basename(ofile,'.nc'),'S',     :tStrg => "#{experiment}", :bStrg => ' ',:hov => true,:minVar => -0.2,:maxVar => 0.2,:numLevs => 16,:rStrg => 'Salinity')
# images << plotter.scalarPlot(ofile,'rhopot_'+File.basename(ofile,'.nc'),'rhopot',:tStrg => "#{experiment}", :bStrg => ' ',:hov => true,:minVar => -0.6,:maxVar => 0.6,:numLevs => 24,:rStrg => 'Pot.Density')
# images.each {|im| plotter.show(im) }
  }
}
q.run
