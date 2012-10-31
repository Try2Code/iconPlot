#!/usr/bin/env ruby

require 'cdo'
require 'cdp'
require 'fileutils'
require 'jobqueue'
require 'socket'
require 'iconPlot'

# check input
if ARGV[0].nil?
  warn "no input files given"
  exit(-1)
end

files     = ( ARGV.size > 1 ) ? ARGV : Dir.glob(ARGV[0])
# check files
files.each {|file|
  warn "Cannot read file '#{file}'" unless File.exist?(file)
}

q         = JobQueue.new([JobQueue.maxnumber_of_processors,8].min)
lock      = Mutex.new
#maskFile  = "mask-L40.nc"
maskFile  = "mask.nc"
diff2init = true

Cdp.setCDO

# compute the experiments from the data directories and link the corresponding files
gridfile, experimentFiles, experimentAnalyzedData = Cdp.splitFilesIntoExperiments(files)

# compute meaked weight
maskedAreaWeights = Cdp.manualMaskedAreaWeights("cell_area",gridfile,"wet_c",maskFile,"maskedAeraWeights.nc")

# process the files
#   start with selectiong the initial values from the first timestep
experimentFiles.each {|experiment, files|
  q.push {
    initFile    = "initial_#{experiment}.nc"
    # create a separate File with the initial values
    unless File.exist?(initFile)
      Cdo.selname('T,S',:in => "-seltimestep,1 #{files[0]}", :out => initFile,:options => '-r -f nc')
    end
    if File.exist?(initFile) and not Cdo.showname(:in => initFile).flatten.first.split(' ').include?("rhopot")
      initRhopot = Cdo.rhopot(0,:in => initFile)
      merged = Cdo.merge(:in => [initFile,initRhopot].join(' '))
      FileUtils.cp(merged,initFile)
    end
  }
}
q.run
#   process the experiments results
experimentFiles.each {|experiment, files|
  files.each {|file|
    q.push {
      maskedYMeanFile = "masked_yearmean_#{File.basename(file)}"
      fldmeanFile     = "fldmean_#{File.basename(file)}"
      rhopotFile      = "rhopot_#{File.basename(file)}"
      mergedFile      = "T-S-rhopot_#{File.basename(file)}"
      diffFile        = "T-S-rhopot_diff2init_#{File.basename(file)}"
      initFile        = "initial_#{experiment}.nc"

      unless File.exist?(maskedYMeanFile)
        Cdo.div(:in => " -yearmean -selname,T,S #{file} #{maskFile}",:out => maskedYMeanFile)
      end
      # compute rhopot
      unless File.exist?(rhopotFile)
        Cdo.rhopot(0,:in => maskedYMeanFile,:out => rhopotFile)
      end

      unless File.exist?(mergedFile)
        Cdo.merge(:in => [maskedYMeanFile,rhopotFile].join(' '), :out => mergedFile)
      end
      unless File.exist?(diffFile)
        Cdo.sub(:in => [mergedFile,initFile].join(' '),:out => diffFile)
      end
      unless File.exist?(fldmeanFile)
        Cdo.fldsum(:in => "-mul #{diffFile} #{maskedAreaWeights}", :out => fldmeanFile,:options => '-r -f nc')
      end
      lock.synchronize {experimentAnalyzedData[experiment] << fldmeanFile }
    }
  }
}
q.run

# merge all yearmean data (T,S,rhopot) into one file per experiment
q.clear
images = []
experimentAnalyzedData.each {|experiment,files|
  tag   = diff2init ? 'diff2init' : ''
  ofile = [experiment,'T-S-rhopot',tag].join('_') + '.nc'
  unless File.exist?(ofile)
    Cdo.cat(:in => files.sort.join(' '), :out => ofile, :options => '-r')
  end
  plotFile = 'thingol' == Socket.gethostname \
           ? '/home/ram/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl' \
           : '../../scripts/postprocessing/tools/icon_plot.ncl'
  plotter  = 'thingol' == Socket.gethostname \
           ? IconPlot.new(ENV['HOME']+'/local/bin/nclsh', plotFile, File.dirname(plotFile),'png','qiv',true,true) \
           : IconPlot.new('/sw/rhel55-x64/ncl-5.2.1/bin/ncl', plotFile, File.dirname(plotFile), 'ps','evince',true,true)
  q.push {
    im = plotter.scalarPlot(ofile,'T_'+     File.basename(ofile,'.nc'),'T',
                            :tStrg => experiment, :bStrg => '" a"',
                            :hov => true,
                            :minVar => -1.0,:maxVar => 5.0,
                            :numLevs => 24,:rStrg => 'Temperature', :colormap => "BlueDarkRed18")
    lock.synchronize {images << im }
  }
  q.push {
    im =  plotter.scalarPlot(ofile,'S_'+     File.basename(ofile,'.nc'),'S',
                             :tStrg => experiment, :bStrg => '"a "',
                             :hov => true,
                             :minVar => -0.2,:maxVar => 0.2,
                             :numLevs => 16,:rStrg => 'Salinity', :colormap => "BlueDarkRed18")
    lock.synchronize {images << im }
  }
  q.push {
    im = plotter.scalarPlot(ofile,'rhopot_'+File.basename(ofile,'.nc'),'rhopot',
                            :tStrg => experiment, :bStrg => '"  d"',
                            :hov => true,
                            :minVar => -0.6,:maxVar => 0.6,
                            :numLevs => 24,:rStrg => 'Pot.Density', :colormap => "BlueDarkRed18")
    lock.synchronize {images << im }
  }
}
q.run
system("eog #{images.join(' ')}")
