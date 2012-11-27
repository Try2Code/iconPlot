#!/usr/bin/env ruby

require 'cdo'
require 'cdp'
require 'fileutils'
require 'jobqueue'
require 'socket'
require 'iconPlot'

#==============================================================================
def plot(ofile,experiment,secPlots,q,lock)
  plotFile = 'thingol' == Socket.gethostname \
           ? '/home/ram/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl' \
           : ENV['HOME'] +'/liz/icon/scripts/postprocessing/tools/icon_plot.ncl'
  plotter  = 'thingol' == Socket.gethostname \
           ? IconPlot.new(ENV['HOME']+'/local/bin/nclsh', plotFile, File.dirname(plotFile),'png','qiv',true,true) \
           : IconPlot.new("/home/zmaw/m300064/local/bin/nclsh", plotFile, File.dirname(plotFile), 'png','display',true,true)
  q.push {
    im = plotter.scalarPlot(ofile,'T_'+     File.basename(ofile,'.nc'),'T',
                            :tStrg => experiment, :bStrg => '" "',
                            :hov => true,
                            :minVar => -3.0,:maxVar => 3.0,:withLineLabels => true,
                            :numLevs => 20,:rStrg => 'Temperature', :colormap => "BlWhRe")
    lock.synchronize {(secPlots[experiment] ||= []) << im }
 #  im = plotter.scalarPlot(experimentFiles[experiment][-1],'T_200m'+     File.basename(ofile,'.nc'),'T',
 #                          :tStrg => experiment, :bStrg => '" "',:maskName => "wet_c",
 #                          :levIndex => 6,
 #                          :rStrg => 'Temperature')
 #  lock.synchronize {mapPlots << im }
 #  im = plotter.scalarPlot(experimentFiles[experiment][-1],'T_100m'+     File.basename(ofile,'.nc'),'T',
 #                          :tStrg => experiment, :bStrg => '" "',:maskName => "wet_c",
 #                          :levIndex => 12,
 #                          :rStrg => 'Temperature')
 #  lock.synchronize {mapPlots << im }
  }
  q.push {
    im =  plotter.scalarPlot(ofile,'S_'+     File.basename(ofile,'.nc'),'S',
                             :tStrg => experiment, :bStrg => '" "',
                             :hov => true,
                             :minVar => -0.2,:maxVar => 0.2,:withLineLabels => true,
                             :numLevs => 16,:rStrg => 'Salinity', :colormap => "BlWhRe")
    lock.synchronize {(secPlots[experiment] ||= []) << im }
  }
  q.push {
    im = plotter.scalarPlot(ofile,'rhopot_'+File.basename(ofile,'.nc'),'rhopot',
                            :tStrg => experiment, :bStrg => '"  "',
                            :hov => true,
                            :minVar => -0.6,:maxVar => 0.6,:withLineLabels => true,
                            :numLevs => 24,:rStrg => 'Pot.Density', :colormap => "BlWhRe")
    lock.synchronize {(secPlots[experiment] ||= []) << im }
  }
end
#==============================================================================
def cropPlots(secPlots)
  sq = SystemJobs.new
  cropfiles = []
  secPlots.each {|exp,files|
    files.each {|sp|
      cropfile = "crop_#{File.basename(sp)}"
      cmd      = "convert -resize 60%  -crop 650x560+50+50 #{sp} #{cropfile}"
      puts cmd
      sq.push(cmd)
      cropfiles << cropfile
    }
  }
  sq.run
  system("convert +append #{(cropfiles.grep(/crop_T/) + cropfiles.grep(/crop_S/) + cropfiles.grep(/crop_rho/)).join(' ')} exp.png") #if 'thingol' == Socket.gethostname
  #system("display #{cropfiles.join(' ')}") #if 'thingol' == Socket.gethostname
end
#==============================================================================
#==============================================================================
# check input
if ARGV[0].nil?
  warn "no input files given"
  exit(-1)
end

files     = ( ARGV.size > 1 ) ? ARGV : Dir.glob(ARGV[0])
maskFile  = ENV["MASK"].nil? ? "mask.nc" : ENV["MASK"]
# check files
files.each {|file|
  warn "Cannot read file '#{file}'" unless File.exist?(file)
}
unless File.exist?(maskFile) 
  warn "Cannot open maskfile '#{maskFile}'"
  exit -1
end
#==============================================================================
q         = JobQueue.new([JobQueue.maxnumber_of_processors,16].min)
lock      = Mutex.new

Cdp.setCDO
Cdp.setDebug
Cdo.forceOutput = false
Cdo.debug       = true
diff2init       = true
def plot?
  'thingol' == Socket.gethostname
end
#==============================================================================

# compute the experiments from the data directories and link the corresponding files
gridfile, experimentFiles, experimentAnalyzedData = Cdp.splitFilesIntoExperiments(files)

# process the files
#   start with selectiong the initial values from the first timestep
experimentFiles.each {|experiment, files|
  q.push {
    initFile    = "initial_#{experiment}.nc"
    puts "Computing initial value file: #{initFile}"
    # create a separate File with the initial values
    if not File.exist?(initFile) or not Cdo.showname(:input => initFile).flatten.first.split(' ').include?("rhopot")
      initTS     = Cdo.selname('T,S',:input => "-seltimestep,1 #{files[0]}",:options => '-r -f nc')
      initRhopot = Cdo.rhopot(0,:input => initTS)
      merged = Cdo.merge(:input => [initTS,initRhopot].join(' '))
      FileUtils.cp(merged,initFile)
    end
  }
}
q.run
# compute meaked weight
maskedAreaWeights = Cdp.maskedAreaWeights("cell_area",gridfile,"wet_c",maskFile,"maskedAeraWeightsFrom#{File.basename(maskFile)}")

#   process the experiments results
experimentFiles.each {|experiment, files|
  files.each {|file|
    q.push {
      maskedYMeanFile = "masked_#{File.basename(file)}"
      fldmeanFile     = "fldmean_#{File.basename(file)}"
      rhopotFile      = "rhopot_#{File.basename(file)}"
      mergedFile      = "T-S-rhopot_#{File.basename(file)}"
      diffFile        = "T-S-rhopot_diff2init_#{File.basename(file)}"
      initFile        = "initial_#{experiment}.nc"

      unless File.exist?(maskedYMeanFile)
        Cdo.div(:input => " -selname,T,S #{file} #{maskFile}",:output => maskedYMeanFile)
      end
      # compute rhopot
      unless File.exist?(rhopotFile)
        Cdo.rhopot(0,:input => maskedYMeanFile,:output => rhopotFile)
      end

      unless File.exist?(mergedFile)
        Cdo.merge(:input => [maskedYMeanFile,rhopotFile].join(' '), :output => mergedFile)
      end
      unless File.exist?(diffFile)
        Cdo.sub(:input => [mergedFile,initFile].join(' '),:output => diffFile)
      end
      unless File.exist?(fldmeanFile)
        Cdo.fldsum(:input => "-mul #{diffFile} #{maskedAreaWeights}", :output => fldmeanFile,:options => '-r -f nc')
      end
      lock.synchronize {experimentAnalyzedData[experiment] << fldmeanFile }
    }
  }
}
q.run

# merge all yearmean data (T,S,rhopot) into one file per experiment
q.clear
secPlots = {}
experimentAnalyzedData.each {|experiment,files|
  tag      = diff2init ? 'diff2init' : ''
  ofile    = [experiment,'T-S-rhopot',tag].join('_') + '.nc'

  yearmean = "yearmean"
  ymfile   = [yearmean,ofile].join("_")

  Cdo.cat(:input => files.sort.join(' '), :output => ofile, :force => true)
  Cdo.settunits('years',:input => "-yearmean #{ofile}", :output => ymfile,:force => true)

  ofile = ymfile
  plot(ofile,experiment,secPlots,q,lock) if plot?
}
q.run
cropPlots(secPlots) if plot?
