#!/usr/bin/env ruby

require 'cdo'
require 'cdp'
require 'fileutils'
require 'jobqueue'

# check input
if ARGV[0].nil?
  warn "no input files given"
  exit(-1)
else
  puts 'Please remember, that the last file in the list is expected to be an ICON grid file'
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
Cdp.setCDO
Cdp.setDebug

#=============================================================================== 
# compute the experiments from the data directories and link the corresponding files
#=============================================================================== 
# MAIN
gridfile, experimentFiles, experimentAnalyzedData = Cdp.splitFilesIntoExperiments(files)
iceHeight                                         = 'p_ice_hi'
iceConcentration                                  = 'p_ice_concSum'
#   process the experiments results
experimentFiles.each {|experiment, files|
  files.each {|file|
    q.push {
      iceDiagFile = "iceDiag_#{File.basename(file)}"
      volumeFile  = "iceVolume_#{File.basename(file)}"
      extentFile  = "iceExtent_#{File.basename(file)}"
      Cdo.setname('ice_volume',
                  :in => " -divc,1e9 -mul -mul -selname,#{iceHeight} #{file}  -selname,cell_area #{gridfile}  -selname,#{iceConcentration} #{file}",
                  :out => volumeFile) unless File.exist?(volumeFile)

      Cdo.setname('ice_extent',
                  :in => " -divc,1e6 -mul -selname,cell_area #{gridfile}  -selname,#{iceConcentration} #{file}",
                  :out => extentFile) unless File.exist?(extentFile)

      Cdo.merge(:in => [volumeFile,extentFile].join(' '),
                :out => iceDiagFile) unless File.exist?(iceDiagFile)

      lock.synchronize {experimentAnalyzedData[experiment] << iceDiagFile }
    }
  }
}
q.run
# merge all yearmean data (T,S,rhopot) into one file per experiment
q.clear
experimentAnalyzedData.each {|experiment,files|
  q.push {
  tag   = ''
  ofile = [experiment,'iceDiagnostics',tag].join('_') + '.nc'
  unless File.exist?(ofile)
    Cdo.cat(:in => files.sort.join(' '), :out => ofile, :options => '-r')
  end
  }
}
q.run
