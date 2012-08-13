require 'rake/clean'
require 'thread'
require 'pp'
require 'cdo'
require 'iconPlot'
require 'jobqueue'
require 'test/unit/assertions'
include Test::Unit::Assertions

SRC                   = ["icon_plot.ncl","icon_plot_lib.ncl"]
HOSTS                 = ["m300064@blizzard.dkrz.de"]
DIR                   = '/pool/data/ICON/tools'
DST                   = HOSTS.map {|v| v + ':' + DIR}
CP                    = 'scp -p'
LS                    = 'ls -crtlh'
OCE_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/oce.nc'
OCELSM_PLOT_TEST_FILE = ENV['HOME']+'/data/icon/oce_lsm.nc'
ATM_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/atm.nc'
OCE_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_oce.nc' #remapnn,r180x90
ATM_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_atm.nc' #remapnn,n63 (no sections), r180x90 (with sections)
COMPARISON            = {:oce => OCE_PLOT_TEST_FILE, :atm => ATM_PLOT_TEST_FILE}
COMPARISON_REG        = {:oce => OCE_REGPLOT_TEST_FILE, :atm => ATM_REGPLOT_TEST_FILE}
OFMT                  = 'png'
DEFAULT_VARNAME       = 'T'
PLOT_CMD              = 'sxiv'
CDO                   = ENV['CDO'].nil? ? 'cdo' : ENV['CDO']


CLEAN.add(*Dir.glob(["test_*.png","remapnn_*nc","zonmean_*.nc"]))

@lock = Mutex.new

@plotter = IconPlot.new("contrib/nclsh","icon_plot.ncl",".",nil,nil,nil,true)

def show(*args)
  @plotter.show(*args)
end
def iconPlot(*args)
  @plotter.plot(*args)
end
def defaultPlot(*args)
  @plotter.defaultPlot(*args)
end
def scalarPlot(*args)
  @plotter.scalarPlot(*args)
end
def levelPlot(*args)
  @plotter.levelPlot(*args)
end
def scatterPlot(*args)
  @plotter.scatterPlot(*args)
end
def showVector(*args)
  @plotter.showVector(*args)
end
def del(*args)
  @plotter.del(*args)
end

def grepTests(pattern)
  tests = Rake::Task.tasks.find_all {|t| t.name =~ pattern}
end
def runTests(tests)
  pp tests.map(&:name)
  tests.each {|t|
    puts "################################################################################"
    puts "Running test #{t.name}:"
    t.execute
  }
end
# Checking/installing the script files
desc "check files on pool"
task :default => [:check]

desc "check files on pool"
task :check do
  SRC.each {|src| HOSTS.each {|host| sh ['ssh',host,['"',LS,DIR,'"'].join(' ')].join(' ') }}
end

desc "install plotting tools in /pool on blizzard"
task :install do
  SRC.each {|src| DST.each {|dst| sh [CP,src,dst].join(' ') }}
end

# -----------------------------------------------------------------------------
# PLOTTING FROM ICON GRID INPUT
# the basics
desc "perform simple oce plot from 3d var"
task :test_oce_3d do
  ofile          = 'test_icon_plot'
  varname        = 'T'
  scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:levIndex => 2)
  ofile          += '.' + OFMT
  show(ofile)
end
desc "perform simple oce plot from dd var"
task :test_oce_2d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'ELEV'
  scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname)
  show(ofile)
end
desc "select regions"
task :test_mapselect do
  ofile          = 'test_mapSelect'
  varname        = 'ELEV'
  show(scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:mapLLC => '-100.0,-15.0' ,:mapURC => '35.0,65.0'))
  show(scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:mapLLC => '-100.0,-15.0' ,:mapURC => '35.0,65.0',:maskName => 'wet_c'))
end
desc "masking with ocean's wet_c"
task :test_mask do
  ofile          = 'test_mask'
  varname        = 'ELEV'
  show(scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:maskName => 'wet_c'))
end
desc "perform simple atm plot from 3d var"
task :test_atm_3d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'T'
  scalarPlot(ATM_PLOT_TEST_FILE,ofile,varname)
  show(ofile)
end
desc "x11 test"
task :test_x11 do
  ofile          = 'test_x11'
  varname        = 'T'
  scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:oType => 'x11')
end
desc "perform halflog plot"
task :test_halflog do
  ofile          = 'test_halflog'
  varname        = 'T'
  Cdo.debug=true
  tfile = Cdo.mulc(100,:in => "-subc,5 -abs -selname,T #{OCE_PLOT_TEST_FILE}")
  image = scalarPlot(tfile,ofile,varname,:selMode =>'halflog',:minVar =>-1, :maxVar => 1000, :atmLe => 'm',
                                                :mapLLC => '-10.0,-80.0' ,:mapURC =>'100.0,-10.0')
  show(image)

  varname='W'
  ifile = "#{ENV['HOME']}/data/icon/issues/2352/TC33_iconR2B04-ocean_etopo40_planet_0001.nc"
  image = scalarPlot(ifile,ofile,varname,:selMode =>'halflog',:minVar =>-0.5, :maxVar => 0.5, :scaleLimit => 3,:timeStep => 36)
  show(image)
  image = scalarPlot(ifile,ofile,varname,:selMode =>'halflog',:timeStep => 36)
  show(image)
end
desc "test isIcon switch"
task :test_isIcon do
  ofile          = 'test_icon_plot'
  varname        = 'T'
  tstart = Time.new
  image = scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:levIndex => 2)
  tdiff = Time.new - tstart
  show(image)
  tstart = Time.new
  image = scalarPlot(OCE_PLOT_TEST_FILE,ofile,varname,:levIndex => 2,:isIcon => "True")
  tdiffisIcon = Time.new - tstart
  show(image)
  #assert(tdiffisIcon < tdiff,"setting isIcon seems to slow down the plotting")
  # assert is switched off because iconPlot sets isIcon be default
end
desc "test setting of min/maxVar"
task :test_minmax do
  images = []
  images << scalarPlot(OCE_PLOT_TEST_FILE,'test_minmax_3d','T',:levIndex => 2,:maxVar => 16, :minVar => 10)
  images << scalarPlot(OCE_PLOT_TEST_FILE,'test_minmax_2d','ELEV', :maxVar => 0.4, :minVar => -0.4)
  images.each {|image| show(image)}
end
desc "perform simple atm plot from 2d var"
task :test_atm_2d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'SKT'
  scalarPlot(ATM_PLOT_TEST_FILE,ofile,varname)
  show(ofile)
end

# selecting levels
desc "plot different levels of an ocean file"
task :test_plotlevels_oce do
  varname         = 'T'
  maxlev          = 10
  images, threads = [],[]
  (0...maxlev).each {|lev|
    otag          = "test_icon_oce_plotlevel_#{lev}"
    threads << Thread.new(otag,varname,lev) {|ofile,varname,lev|
      ofile = scalarPlot(OCE_PLOT_TEST_FILE,otag,varname,:levIndex =>lev)
      @lock.synchronize{ images << ofile }
    }
  }
  threads.map(&:join)
  show(*images)
end
desc "plot different levels of an atmosphere file"
task :test_plotlevels_atm do
  varname         = 'T'
  maxlev          = 10
  images, threads = [],[]
  (0...maxlev).each {|lev|
    otag          = "test_icon_atm_plotlevel_#{lev}"
    threads << Thread.new(otag,varname,lev) {|ofile,varname,lev|
      ofile = scalarPlot(ATM_PLOT_TEST_FILE,otag,varname,:levIndex => lev,:atmLev =>'m')
      @lock.synchronize{ images << ofile }
    }
  }
  threads.map(&:join)
  show(*images)
end

# vertical cross sections
desc "Try to plot vertical section of ocean model output"
desc "plot section of ocean and atmosphere (height, pressure and model level)"
task :test_sections do
  images = []
  secopts = {
    :secLC      => '0,80',
    :secRC      => '0,-80',
    :secLC      => '-45,-70',
    :secRC      =>  '30,80',
    :showSecMap => "True",
    :secPoints  => 100
  }
  COMPARISON.each {|itype,ifile|
    ofile = "test_section_#{itype.to_s}"
    if itype == :atm
      scalarPlot(ifile,ofile+'h',DEFAULT_VARNAME,secopts.merge(:atmLev => "h",:tStrg => "atm: height levels"));images << ofile+'h'
      scalarPlot(ifile,ofile+'p',DEFAULT_VARNAME,secopts.merge(:atmLev => "p",:tStrg => "atm: pressure levels"));images << ofile+'p'
      scalarPlot(ifile,ofile+'m',DEFAULT_VARNAME,secopts.merge(:atmLev => "m",:tStrg => "atm: model levels"));images << ofile+'m'
    else
      scalarPlot(ifile,ofile,DEFAULT_VARNAME,secopts.merge(:tStrg => 'oce: ocean depth')); images << ofile
    end
  }
  images.map! {|i| i+= ".#{OFMT}"}
  show(*images)
end

desc "Section with different types of masking"
task :test_masked_section do
  secopts = {
    :secLC      => '-45,-70',
    :secRC      =>  '30,80',
    :showSecMap => "True",
    :secPoints  => 201,
    :maskName   => 'wet_c',
    :secMode    => 'straight'
  }
  # enable regular grided data
  @plotter.isIcon = false
  @plotter.debug  = true
  %w[r90x45 r180x90 r360x180].each {|resolution|
    #next unless resolution == 'r360x180'
    show(scalarPlot(OCELSM_PLOT_TEST_FILE,'test_masked_section_' + resolution,'T',secopts.merge(:resolution => resolution)))
    remappedFile = "remapnn_#{resolution}_"+File.basename(OCELSM_PLOT_TEST_FILE)
    unless File.exist?(remappedFile)
      warn "file #{remappedFile} does not exist!!!!!"
      next
    end
    ofile = 'test_showMask_' + resolution
    #show(scalarPlot(remappedFile,ofile,'wet_c',:mapLLC => "0,30",:mapURC => "40,90",:withLines => false,:fillMode => "CellFill"))
  }
end

desc "Compare sections on great circle and straight lines"
task :test_secmode do
  q = JobQueue.new

  {
    :atlantic      => [-45,-70,30,80],
    :merdidian_20W => [-20,-70,-20,70],
    :merdidian_20E => [20,-70,20,70],
    :acc           => [-100,-65,100,-45],
    :sohth         => [0,-30,360,-30],
    :equator       => [-100,0,100,0]
  }.each {|sec,corners|
   #next unless sec == :acc
    startLat,startLon,endLat,endLon = corners
    secopts = {
      :secLC      => [startLat,startLon].join(','),
      :secRC      => [endLat,endLon].join(','),
      :showSecMap => "True",
      :secPoints  => 201,
      :maskName   => 'wet_c',
      :resolution => 'r360x180'
    }
    # enable regular grided data
    @plotter.isIcon = true
    @plotter.debug  = true
    %w[straight circle].each {|secmode|
      q.push {
        show(scalarPlot(OCELSM_PLOT_TEST_FILE,
                      ['test_secMode',secmode,sec].join("_"),
                      'T',
                      secopts.merge(:secMode => secmode,
                                    :tStrg => 'secMode - '+secmode,
                                    :rStrg =>"'s|#{[startLat,startLon].join(',')}||e|#{[endLat,endLon].join(',')}|'" )))
      }
    }
  }
  q.run
end

# vector plots from ICON input
desc "plot vectors of ocean input"
task :test_vector_oce do
  jq = JobQueue.new
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_vector_oce','u-veloc v-veloc') }
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_vector_oce','u-veloc v-veloc',:mapType     => 'ortho') }
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_stream_oce','u-veloc v-veloc',:streamLine  => 'True') }
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_stream_oce','u-veloc v-veloc',:streamLine  => 'True',:mapType => 'ortho') }
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_vector_oce','u-veloc v-veloc',:vecColByLen => 'True') }
  jq.push { showVector(OCE_PLOT_TEST_FILE,'test_stream_oce','u-veloc v-veloc',:streamLine  => 'True',:vecColByLen =>'True') }
  jq.run
end
desc "plot vectors of atm input"
task :test_vector_atm do
  ofile = 'test_vector_atm'
  images  =  []

  images << vectorPlot(ATM_PLOT_TEST_FILE,ofile+'0','U V',        :vecRefLength => 0.01)
  images << vectorPlot(ATM_PLOT_TEST_FILE,ofile+'1','U V',        :vecRefLength => 0.01,:mapType => 'NHps')
  images << vectorPlot(ATM_PLOT_TEST_FILE,ofile+'_stream_0','U V',:streamLine   => "True")
  images << vectorPlot(ATM_PLOT_TEST_FILE,ofile+'_stream_1','U V',:streamLine   => "True",:mapType => 'NHps')

  pp images
  show(images)
end

# orthographic projections
COMPARISON.each {|itype,ifile|
  itypeS = itype.to_s
  desc "orthographic plot (#{itypeS})"
  task "test_ortho_#{itypeS}".to_sym do
    defaultPlot(ifile,"ortho_#{itypeS}",:mapType => 'ortho')
  end
}

# overlay plots
COMPARISON.each {|itype,ifile|
  vecvars  = {:oce => 'u-veloc,v-veloc', :atm => "U,V"}[itype]
  levIndex = {:oce => 0                , :atm => 40   }[itype]
  var2d    = {:oce => "ELEV"           , :atm => "SKT"}[itype]
  itypeS = itype.to_s
  desc "overlay plot form 3d variable (#{itypeS})"
  task "test_overlay_3d_#{itypeS}".to_sym do
    defaultPlot(ifile,"test_overlay_3d_#{itypeS}",
                :vecVars => vecvars,
                :mapType => 'ortho',
                :atmLev => "m",
                :levIndex => levIndex,
                :centerLat => 90)
    defaultPlot(ifile,"test_overlay_stream_3d_#{itypeS}",
                :vecVars => vecvars,
                :mapType => "ortho",
                :atmLev => "m",
                :levIndex => levIndex,
                :centerLat => -90,
                :streamLine => "True")
  end
  desc "overlay plot from 2d variable (#{itypeS})"
  task "test_overlay_2d_#{itypeS}".to_sym do
    ofile = "test_overlay_2d_#{itypeS}"
    image = iconPlot(ifile,ofile,var2d,'scalar',
                     :vecVars => vecvars,
                     :mapType => "ortho",
                     :atmLev => "m",
                     :levIndex => levIndex,
                     :centerLon => 120,
                     :vecRefLength => 0.04)
    show(image)
    ofile = "test_overlay_stream_2d_#{itypeS}"
    image = iconPlot(ifile,ofile,var2d,'scalar',
                     :vecVars => vecvars,
                     :mapType => "ortho",
                     :atmLev => "m",
                     :levIndex => levIndex,
                     :centerLon => 120,
                     :streamLine => "True")
    show(image)
  end
}
# hoffmueller diagrams
COMPARISON.each {|itype,ifile|
  itypeS = itype.to_s
  desc "hoffmueller diagram plot (#{itypeS})"
  tag = "test_hoffm_#{itypeS}"
  task tag.to_sym do
    defaultPlot(ifile,tag,:hoff => '-50,50')
  end
} if false # functionality not implemented yet

# -----------------------------------------------------------------------------
# PLOTTING FROM REGULAR GRID INPUT
desc "Plot dat from a regular grid"
task :test_reg_3d do
  ofile = 'test_oce_reg_3d'
  scalarPlot(OCE_REGPLOT_TEST_FILE,ofile,'T')
  show(ofile+'.'+OFMT)
  ofile = 'test_atm_reg_3d'
  scalarPlot(ATM_REGPLOT_TEST_FILE,ofile,'T')
  show(ofile+'.'+OFMT)
end
# vectors
desc "Plot vector from regular grid"
task :test_reg_vector do
  showVector(OCE_REGPLOT_TEST_FILE,'test_reg_vec_oce','u-veloc v-veloc')
  showVector(ATM_REGPLOT_TEST_FILE,'test_reg_vec_oce','U V')
end
# orthographic projections
COMPARISON_REG.each {|itype,ifile|
  itypeS = itype.to_s
  desc "orthographic plot (#{itypeS}) from regular grid"
  task "test_reg_ortho_#{itypeS}".to_sym do
    defaultPlot(ifile,"ortho_#{itypeS}",:mapType => "ortho")
  end
}
# overlay plots
COMPARISON_REG.each {|itype,ifile|
  vecvars = {:oce => 'u-veloc,v-veloc',:atm => "U,V"}[itype]
  itypeS = itype.to_s
  desc "overlay plot (#{itypeS}) from regular grid"
  task "test_reg_overlay_#{itypeS}".to_sym do
    defaultPlot(ifile,"overlay_#{itypeS}",
                :vecVars => vecvars,
                :mapType => "ortho",
                :atmLev => "m",
                :centerLon => 120,
                :centerLat => -50)
  end
}
# vertical cross sections
desc "Try to plot vertical section of ocean model output"
task :test_reg_section_oce do
  images = []
  secopts = {
    :secLC => '0,80',
    :secRC => '0,-80',
    :showSecMap => "False",
    :secPoints => 100
  }
  ofile = "test_reg_section_oce"
  show(scalarPlot(OCE_REGPLOT_TEST_FILE,ofile,DEFAULT_VARNAME,secopts))
end
desc "plot section of ocean and atmosphere (height, pressure and model level)"
task :test_reg_sections do
  images = []
  secopts = {
    :secLC => '0,80',
    :secRC => '0,-80',
    :showSecMap => "False",
    :secPoints => 100
  }
  COMPARISON_REG.each {|itype,ifile|
    ofile = "test_section_#{itype.to_s}"
    if itype == :atm
      scalarPlot(ifile,ofile+'h',DEFAULT_VARNAME,secopts.merge(:atmLev => "h"));images << ofile+'h'
      scalarPlot(ifile,ofile+'p',DEFAULT_VARNAME,secopts.merge(:atmLev => "p"));images << ofile+'p'
      scalarPlot(ifile,ofile+'m',DEFAULT_VARNAME,secopts.merge(:atmLev => "m"));images << ofile+'m'
    else
      scalarPlot(ifile,ofile,DEFAULT_VARNAME,secopts); images << ofile
    end
  }
  images.map! {|i| i+= ".#{OFMT}"}
  show(*images)
end

desc "Scatter plots"
task :test_scatter do
  ifile = OCE_REGPLOT_TEST_FILE
  ofile = "test_scatter"
  image = iconPlot(ifile,ofile,'T S','scatter')
  show(image)
end
desc "Level plots"
task :test_levelPlot do
  ifile = OCE_REGPLOT_TEST_FILE
  ofile = "test_levelPlot"
  image = levelPlot(ifile,ofile,'T')
  show(image)
end


# -----------------------------------------------------------------------------
# uncategoriesed tests on
# * maptype
desc "test misc mpaTypes"
task :test_misc_maptypes do
  %w[SHps NHps sat lambert].each {|maptype|
    defaultPlot(ATM_PLOT_TEST_FILE,maptype,:mapType => maptype,:atmLev => "m")
  }
end

if 'thingol' == `hostname`.chomp
  desc "test show grid plot with ocean, atmosphere, regular grid and ortho. projection"
  task :test_show_grid do
    require 'jobqueue'
    jq = JobQueue.new
    jq.push(@plotter,:defaultPlot,OCE_PLOT_TEST_FILE   ,'test_show_grid_oce',:showGrid => "True")
    jq.push(@plotter,:defaultPlot,OCE_PLOT_TEST_FILE   ,'test_show_grid_oce_ortho',:showGrid => "True",:mapType => "ortho")
    jq.push(@plotter,:defaultPlot,ATM_PLOT_TEST_FILE   ,'test_show_grid_atm',:showGrid => "True",:atmLev => "m")
    jq.push(@plotter,:defaultPlot,OCE_REGPLOT_TEST_FILE,'test_show_reg_grid',:showGrid => "True")
    jq.run
  end
end
desc "Try out different colormaps"
task :test_colors do
  colors = %w|white black firebrick peachpuff orangered navyblue peru yellow wheat1 gray55 thistle coral dodgerblue seagreen maroon gold turquoise mediumorchid|
  defaultPlot(OCE_PLOT_TEST_FILE   ,'test_colors',
                                   :colormap => colors.reverse.join(','))
  colormap = 'BlGrYeOrReVi200'
  defaultPlot(OCE_PLOT_TEST_FILE   ,'test_colors',
                                   :colormap => colormap,:mapType => 'ortho')
  colormap = 'testcmap'
  defaultPlot(OCE_PLOT_TEST_FILE   ,'test_colors',
                                   :colormap => colormap,:mapType => 'ortho')
end

desc "test for labeled contour lines"
task :test_line_labels do
  colormap = 'testcmap'
  defaultPlot(OCE_PLOT_TEST_FILE ,'test_withLines',     :mapType => "ortho",:colormap => "test_cmap",:withLines => false)
  defaultPlot(OCE_PLOT_TEST_FILE ,'test_withoutLines',  :mapType => "ortho",:colormap => "test_cmap",:withLines => true)
  defaultPlot(OCE_PLOT_TEST_FILE ,'test_withLineLabels',:mapType => "ortho",:colormap => "test_cmap",:withLineLabels => true)
end
#==============================================================================
# Test collections
desc "Run all tests"
task :all_tests do
  tests = grepTests(/^test/)
  runTests(tests)
end
%w[oce atm 2d 3d reg vector section overlay].each {|category|
desc "Run #{category} tests"
task "#{category}_tests".to_sym do
  tests = grepTests(/_#{category}/)
  runTests(tests)
end
}

# vim:ft=ruby
