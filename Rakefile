require 'rake/clean'
require 'thread'
require 'pp'
require 'cdo'
require 'iconPlot'
require 'jobqueue'
require 'tempfile'
require 'minitest/autorun'

#==============================================================================
def isLocal?; `hostname`.chomp == 'thingol'; end
#==============================================================================
@_FILES = {}
SRC                   = ["icon_plot.ncl","icon_plot_lib.ncl"]
HOSTS                 = ["m300064@blizzard.dkrz.de"]
DIR                   = '/pool/data/ICON/tools'
DST                   = HOSTS.map {|v| v + ':' + DIR}
CP                    = 'scp -p'
LS                    = 'ls -crtlh'
OFMT                  = 'png'
DEFAULT_VARNAME       = 'T'
PLOT_CMD              = isLocal? ? 'sxiv' : 'eog'
CDO                   = ENV['CDO'].nil? ? 'cdo' : ENV['CDO']
REMOTE_DATA_DIR       = '/home/zmaw/m300064/thunder/data/testing'

OCE_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/oce.nc'
OCE_R2B2              = ENV['HOME']+'/data/icon/oce_small.nc'
ICON_GRID             = ENV['HOME']+'/data/icon/iconGridR2b4.nc'
MPIOM_FILE            = ENV['HOME']+'/data/mpiom/mpiom_y50.nc'
OCELONG_PLOT_TEST_FILE= ENV['HOME']+'/data/icon/oceLong.nc'
OCELSM_PLOT_TEST_FILE = ENV['HOME']+'/data/icon/oce_lsm.nc'
OCE_HOV_FILE          = ENV['HOME']+'/data/icon/test_hov.nc'
ATM_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/atm.nc'
ICON_LONG_RUN         = ENV['HOME']+'/data/icon/icon-dailyOmip.nc'
OCE_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_oce.nc' #remapnn,r180x90
ATM_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_atm.nc' #remapnn,n63 (no sections), r180x90 (with sections)
TOPO_NONGLOBAL        = ENV['HOME']+'/data/icon/topo_2x2_00001.nc'
ICE_DATA              = ENV['HOME']+'/data/icon/dat.ice.r14716.def.2663-67.nc'
OCE_NML_OUTPUT        = ENV['HOME']+'/data/icon/oceNmlOutput.nc'
BOX_DATA              = ENV['HOME']+'/data/icon/AquaBox/AquaAtlanticBox_0079km_20041017T000000Z.nc'
NOCOORDS_DATA         = BOX_DATA
BOX_GRID              = ENV['HOME']+'/data/icon/AquaBox/AtlanticAquaBox_0079km.nc'
NOCOORDS_DATA_GRID    = BOX_GRID
# add files for being transferes to remote host for remote testing
[
  OCE_PLOT_TEST_FILE    ,
  OCE_R2B2              ,
  ICON_GRID             ,
  MPIOM_FILE            ,
  OCELONG_PLOT_TEST_FILE,
  OCELSM_PLOT_TEST_FILE ,
  OCE_HOV_FILE          ,
  ATM_PLOT_TEST_FILE    ,
  ICON_LONG_RUN         ,
  OCE_REGPLOT_TEST_FILE ,
  ATM_REGPLOT_TEST_FILE ,
  TOPO_NONGLOBAL        ,
  ICE_DATA              ,
  OCE_NML_OUTPUT        ,
  BOX_DATA              ,
  BOX_GRID              ,
].each {|f| @_FILES[f] = (`hostname`.chomp == 'thingol') ? f : [REMOTE_DATA_DIR,File.basename(f)].join(File::SEPARATOR) }

COMPARISON            = {:oce => @_FILES[OCE_PLOT_TEST_FILE], :atm => @_FILES[ATM_PLOT_TEST_FILE]}
COMPARISON_REG        = {:oce => @_FILES[OCE_REGPLOT_TEST_FILE], :atm => @_FILES[ATM_REGPLOT_TEST_FILE]}


CLEAN.add(*Dir.glob(["test_*.png","remapnn_*nc","zonmean_*.nc"]))

desc "check if all input files are available at the correct place"
task :checkInput do
  @_FILES.each {|_,file|
    puts "Search file:'#{file}' ............... #{File.exist?(file) ? '   found' : ' NOT found'}"
  }
end

desc "move test input to remote machine"
task :syncInput => [:checkInput] do
  if `hostname`.chomp == 'thingol' then
    user, host, port, remoteDir = 'm300064','localhost',40022,REMOTE_DATA_DIR
    jq = JobQueue.new
    # use scp for file copy
    @_FILES.each {|file,_| 
      if File.exist?(file) then
        jq.push {sh "rsync -avz  -e 'ssh -p #{port}' #{file} #{user}@#{host}:#{remoteDir}" }
      else
        warn "Cannot find file #{file}"
        exit
      end
    }
    jq.run
  else
    warn "You're already on a remote host!"
  end

end
@lock = Mutex.new

@plotter = IconPlot.new("#{isLocal? ? "contrib/nclsh" : "nclsh"}","icon_plot.ncl",".",nil,PLOT_CMD,nil,true)
#=============================================================================== 
# put some plotter methods into main context
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
#=============================================================================== 
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
def runNclTest(routine,parameters: [],arguments: '')
  argList = []
  argList = parameters.map {|parameter|
    parameter.respond_to?(:join) ? '(/'+parameter.join(',')+'/)' : ['"',parameter.to_s,'"'].join
  }.join(',')
  cmdlargList  = arguments.to_s

  iconLibFile  = 'icon_plot_lib.ncl'
  iconTestFile = 'icon_plot_test.ncl'
  nclScript    = Tempfile.new("runNclTest")
#  nclScript    = File.open("runNclTest_#{routine}.ncl","w")
  nclScript.write(<<-EOF

    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
    load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

    loadscript("icon_plot_lib.ncl")
    loadscript("icon_plot_test.ncl")

    #{routine}(#{argList})
   EOF
  )
  nclScript.close

  puts IO.popen("cat #{nclScript.path}").read
  puts "nclsh #{nclScript.path} #{cmdlargList}"
  puts IO.popen("nclsh #{nclScript.path} #{cmdlargList}").read
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
  scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile,varname,:levIndex => 2)
  ofile          += '.' + OFMT
  show(ofile)
end
desc "perform simple oce plot from dd var"
task :test_oce_2d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'ELEV'
  scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile,varname)
  show(ofile)
end
desc "check for white means zero"
task :test_zeroEQwhite do
  ofile          = 'test_whiteEQzero'
  del(ofile)
  varname        = 'v'
  show(scalarPlot(@_FILES[OCELONG_PLOT_TEST_FILE],ofile,varname,:levIndex => 1))
  show(scalarPlot(@_FILES[OCELONG_PLOT_TEST_FILE],ofile,varname,:levIndex => 1, :mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0'))
  show(scalarPlot(@_FILES[OCELONG_PLOT_TEST_FILE],ofile,varname,:levIndex => 1, :mapLLC => '-100.0,30.0' ,:mapURC => '35.0,65.0'))
end
desc "select regions"
task :test_mapselect do
  ofile          = 'test_mapSelect_'
  varname        = 'ELEV'
  jq = JobQueue.new
  jq.push {show(scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile+rand.to_s,varname,:mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0'))}
  jq.push {show(scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile+rand.to_s,varname,:mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0',:maskName => 'wet_c'))}
  jq.push {show(scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile+rand.to_s,varname,:mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0',:maskName => 'wet_c',:showGrid => true))}
  jq.run
end
desc "masking with ocean's wet_c"
task :test_mask_internal do
  ifile,ofile,varname          = @_FILES[OCE_PLOT_TEST_FILE],'test_mask','ELEV'
  ifile,ofile,varname          = @_FILES[OCE_R2B2],'test_mask','t_acc'

  q = JobQueue.new
  q.push { show(scalarPlot(ifile,ofile+"_maskOnly",varname,:maskName => 'wet_c'))  }
  q.push { show(scalarPlot(ifile,ofile+"_maskPlusGrid",varname,:maskName => 'wet_c',:showGrid => true))  }
  q.push { show(scalarPlot(ifile,ofile+"_ortho",varname,:maskName => 'wet_c',:showGrid => true,:mapType => 'ortho',:centerLon => 0.0, :centerLat => 90.0))  }
  q.push { show(scalarPlot(ifile,ofile+"_NHps", varname,:maskName => 'wet_c',:showGrid => true,:mapType => 'NHps'))  }
  q.run
end
desc "masking with real missing values /_FillValue"
task :test_mask_by_division do
  ifile,ofile,varname          = @_FILES[OCE_PLOT_TEST_FILE],'test_mask','ELEV'
  ifile,ofile,varname          = @_FILES[OCE_R2B2],'test_mask','t_acc'

  q = JobQueue.new
  ifile = Cdo.div(input: " -selname,#{varname} #{ifile} #{%w[h h_acc ELEV].include?(varname) ? "-sellevidx,1" : ''} -selname,wet_c #{ifile}",output: "test_mask_by_div.nc")
  q.push { show(scalarPlot(ifile,ofile+"_byDiv_maskOnly",varname,))  }
  q.push { show(scalarPlot(ifile,ofile+"_byDiv_maskPlusGrid",varname,:showGrid => true))  }
  q.push { show(scalarPlot(ifile,ofile+"_byDiv_ortho",varname,:showGrid => true,:mapType => 'ortho',:centerLon => 0.0, :centerLat => 90.0))  }
  q.push { show(scalarPlot(ifile,ofile+"_byDiv_NHps", varname,:showGrid => true,:mapType => 'NHps'))  }
  q.run
end
desc "All masking tests"
task :test_mask => [:test_mask_internal, :test_mask_by_division]
desc "perform simple atm plot from 3d var"
task :test_atm_3d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'T'
  scalarPlot(@_FILES[ATM_PLOT_TEST_FILE],ofile,varname)
  show(ofile)
end
desc "x11 test"
task :test_x11 do
  ofile          = 'test_x11'
  varname        = 'T'
  scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile,varname,:oType => 'x11',:noConfig => true)
end
desc "perform halflog plot"
task :test_halflog do
  ofile          = 'test_halflog'
  varname        = 'T'
  Cdo.debug=true
  tfile = Cdo.mulc(100,:input => "-subc,5 -abs -selname,T #{@_FILES[OCE_PLOT_TEST_FILE]}")
  image = scalarPlot(tfile,ofile,varname,:selMode =>'halflog',:minVar =>-1, :maxVar => 1000, :atmLe => 'm',
                                                :mapLLC => '-10.0,-80.0' ,:mapURC =>'100.0,-10.0')
  show(image)

  varname='W'
  ifile = @_FILES[ICON_LONG_RUN]
  image = scalarPlot(ifile,ofile,varname,:selMode =>'halflog',
                     :minVar =>-1.0e-6, :maxVar => 1.0e-6, :mapLLC => '-10.0,-80.0' ,:mapURC =>'100.0,-10.0',
                     :scaleLimit => 3,:timeStep => 11)
  show(image)
  image = scalarPlot(ifile,ofile,varname,:selMode =>'halflog',
                     :mapLLC => '-10.0,-80.0' ,:mapURC =>'100.0,-10.0',
                     :timeStep => 11)
  show(image)
end
desc "test isIcon switch"
task :test_isIcon do
  ofile          = 'test_icon_plot'
  varname        = 'T'
  tstart = Time.new
  image = scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile,varname,:levIndex => 2)
  tdiff = Time.new - tstart
  show(image)
  tstart = Time.new
  image = scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],ofile,varname,:levIndex => 2,:isIcon => "True")
  tdiffisIcon = Time.new - tstart
  show(image)
  #assert(tdiffisIcon < tdiff,"setting isIcon seems to slow down the plotting")
  # assert is switched off because iconPlot sets isIcon be default
end
desc "test setting of min/maxVar"
task :test_minmax do
  images = []
  images << scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],'test_minmax_3d','T',:levIndex => 2,:maxVar => 16, :minVar => 10)
  images << scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],'test_minmax_2d','ELEV', :maxVar => 0.4, :minVar => -0.4)
  images.each {|image| show(image)}
end
desc "perform simple atm plot from 2d var"
task :test_atm_2d do
  ofile          = 'test_icon_plot.' + OFMT
  del(ofile)
  varname        = 'SKT'
  scalarPlot(@_FILES[ATM_PLOT_TEST_FILE],ofile,varname)
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
      ofile = scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],otag,varname,:levIndex =>lev)
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
      ofile = scalarPlot(@_FILES[ATM_PLOT_TEST_FILE],otag,varname,:levIndex => lev,:atmLev =>'m')
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
    show(scalarPlot(@_FILES[OCELSM_PLOT_TEST_FILE],'test_masked_section_' + resolution,'T',secopts.merge(:resolution => resolution)))
    remappedFile = "remapnn_#{resolution}_"+File.basename(@_FILES[OCELSM_PLOT_TEST_FILE])
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
  # create missing values
  maskedInput = Cdo.div(input: " -selname,T #{@_FILES[OCELSM_PLOT_TEST_FILE]} -selname,wet_c -seltimestep,1 #{@_FILES[OCELSM_PLOT_TEST_FILE]}",
                        output: "test_secmode_maskedInput.nc")
  q = JobQueue.new

  {
    :atlantic      => [-45,-70,30,80],
    :merdidian_20W => [-20,-70,-20,70],
    :merdidian_20E => [20,-70,20,70],
    :acc           => [-100,-65,100,-45],
    :sohth         => [0,-30,360,-30],
    :equator       => [-100,0,100,0]
  }.each {|sec,corners|
   #next unless sec == :atlantic
    startLat,startLon,endLat,endLon = corners
    secopts = {
      :secLC      => [startLat,startLon].join(','),
      :secRC      => [endLat,endLon].join(','),
      :showSecMap => "True",
      :secPoints  => 201,
      :resolution => 'r180x90'
    }
    # enable regular grided data
    @plotter.isIcon = true
    @plotter.debug  = true
    %w[straight circle].each {|secmode|
      q.push {
        ofile = [sec,secmode,maskedInput].join('_')
        FileUtils.cp(maskedInput,ofile)
        show(scalarPlot(ofile,
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
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_vector_oce_0', 'u-veloc v-veloc') }
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_vector_oce_1', 'u-veloc v-veloc',:mapType     => 'ortho') }
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_stream_oce_2', 'u-veloc v-veloc',:streamLine  => 'True') }
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_stream_oce_3', 'u-veloc v-veloc',:streamLine  => 'True',:mapType => 'ortho') }
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_vector_oce_4', 'u-veloc v-veloc',:vecColByLen => 'True') }
  jq.push { showVector(@_FILES[OCE_PLOT_TEST_FILE],'test_stream_oce_5', 'u-veloc v-veloc',:streamLine  => 'True',:vecColByLen =>'True') }
  jq.run
end
desc "plot vectors of atm input"
task :test_vector_atm do
  ofile = 'test_vector_atm'
  images  =  []

  jq = JobQueue.new
  jq.push { showVector(@_FILES[ATM_PLOT_TEST_FILE],ofile+'0','U V',        :vecRefLength => 0.01) }
  jq.push { showVector(@_FILES[ATM_PLOT_TEST_FILE],ofile+'1','U V',        :vecRefLength => 0.01,:mapType => 'NHps') }
  jq.push { showVector(@_FILES[ATM_PLOT_TEST_FILE],ofile+'_stream_0','U V',:streamLine   => "True") }
  jq.push { showVector(@_FILES[ATM_PLOT_TEST_FILE],ofile+'_stream_1','U V',:streamLine   => "True",:mapType => 'NHps') }
  jq.run
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
    defaultPlot(ifile,"test_overlay_stream_3d_#{itypeS}",
                :vecVars => vecvars,
                :mapType => "ortho",
                :atmLev => "m",
                :maskName => 'wet_c',
                :levIndex => levIndex,
                :streamLine => "True") if :oce == itype
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
  @plotter.isIcon = false
  ofile = 'test_oce_reg_3d'
  scalarPlot(@_FILES[OCE_REGPLOT_TEST_FILE],ofile,'T')
  show(ofile+'.'+OFMT)
  ofile = 'test_atm_reg_3d'
  scalarPlot(@_FILES[ATM_REGPLOT_TEST_FILE],ofile,'T')
  show(ofile+'.'+OFMT)
  @plotter.isIcon = true
end
# vectors
desc "Plot vector from regular grid"
task :test_reg_vector do
  @plotter.isIcon = false
  showVector(@_FILES[OCE_REGPLOT_TEST_FILE],'test_reg_vec_oce','u-veloc v-veloc')
  showVector(@_FILES[ATM_REGPLOT_TEST_FILE],'test_reg_vec_oce','U V')
  @plotter.isIcon = true
end
# orthographic projections
COMPARISON_REG.each {|itype,ifile|
  itypeS = itype.to_s
  desc "orthographic plot (#{itypeS}) from regular grid"
  task "test_reg_ortho_#{itypeS}".to_sym do
    @plotter.isIcon = false
    defaultPlot(ifile,"ortho_#{itypeS}",:mapType => "ortho")
    @plotter.isIcon = true
  end
}
# overlay plots
COMPARISON_REG.each {|itype,ifile|
  vecvars = {:oce => 'u-veloc,v-veloc',:atm => "U,V"}[itype]
  itypeS = itype.to_s
  desc "overlay plot (#{itypeS}) from regular grid"
  task "test_reg_overlay_#{itypeS}".to_sym do
    puts "RUN TEST: test_reg_overlay_#{itypeS}"
    @plotter.isIcon = false
    defaultPlot(ifile,"overlay_#{itypeS}",
                :vecVars => vecvars,
                :mapType => "ortho",
                :atmLev => "m",:varName => 'T',
                :centerLon => 120,
                :centerLat => -50)
    @plotter.isIcon = true
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
  show(scalarPlot(@_FILES[OCE_REGPLOT_TEST_FILE],ofile,DEFAULT_VARNAME,secopts))
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
  ifile = @_FILES[OCE_REGPLOT_TEST_FILE]
  ofile = "test_scatter"
  image = iconPlot(ifile,ofile,'T S','scatter')
  show(image)
end
desc "Level plots"
task :test_levelPlot do
  ifile = @_FILES[OCE_REGPLOT_TEST_FILE]
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
    defaultPlot(@_FILES[ATM_PLOT_TEST_FILE],maptype,:mapType => maptype,:atmLev => "m")
  }
end

desc "test cell markers"
task :test_markers do
  show(scalarPlot(@_FILES[OCE_PLOT_TEST_FILE],'test_markers','T',:markCells => true,:mapLLC => '-10.0,-80.0' ,:mapURC =>'100.0,-10.0'))
end

if 'thingol' == `hostname`.chomp
  desc "test show grid plot with ocean, atmosphere, regular grid and ortho. projection"
  task :test_show_grid do
    require 'jobqueue'
    jq = JobQueue.new
    jq.push(@plotter,:defaultPlot,@_FILES[OCE_PLOT_TEST_FILE]   ,'test_show_grid_oce',:showGrid => "True",
                     :mapLLC => '-10.0,-40.0' ,:mapURC =>'10.0,-10.0')
    jq.push(@plotter,:defaultPlot,@_FILES[OCE_PLOT_TEST_FILE]   ,'test_show_grid_oce_ortho',:showGrid => "True",:mapType => "ortho")
    jq.push(@plotter,:scalarPlot,@_FILES[ICE_DATA],'test_show_grid_ice_ortho','hi',:showGrid => "True")
    jq.push(@plotter,:defaultPlot,@_FILES[ATM_PLOT_TEST_FILE]   ,'test_show_grid_atm',:showGrid => "True",:atmLev => "m")
    jq.run
  end
end
desc "Try out different colormaps"
task :test_colors do
  colors = %w|white black firebrick peachpuff orangered navyblue peru yellow wheat1 gray55 thistle coral dodgerblue seagreen maroon gold turquoise mediumorchid|
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE]   ,'test_colors',
                                   :colormap => colors.reverse.join(','))
  colormap = 'BlGrYeOrReVi200'
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE]   ,'test_colors',
                                   :colormap => colormap,:mapType => 'ortho')
  colormap = 'testcmap'
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE]   ,'test_colors',
                                   :colormap => colormap,:mapType => 'ortho')
end

desc "test for labeled contour lines"
task :test_line_labels do
  colormap = 'testcmap'
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE] ,'test_withLines',     :mapType => "ortho",:colormap => "test_cmap",:withLines => false)
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE] ,'test_withoutLines',  :mapType => "ortho",:colormap => "test_cmap",:withLines => true)
  defaultPlot(@_FILES[OCE_PLOT_TEST_FILE] ,'test_withLineLabels',:mapType => "ortho",:colormap => "test_cmap",:withLineLabels => true)
end

desc "test for hovmoeller diagramm"
task :test_hov do
  show(scalarPlot(@_FILES[OCE_HOV_FILE],'test_hov','T',:hov => true,:withLineLabels => true,:DEBUG => true))
  show(scalarPlot(@_FILES[OCE_HOV_FILE],'test_hov','T',:hov => true,:withLines => false))
end

desc "test with data on a non-global grid"
task :test_non_global do
  q  = JobQueue.new(2)
  ifile = @_FILES[TOPO_NONGLOBAL]
  q.push { system("qiv #{(scalarPlot(ifile,'test_non_global','topo',:DEBUG => true,:isIcon => false))}") }
  q.push { system("ncview #{ifile}") }
  q.run
end

desc "test netcdf4 input (compressed, non compresses"
task :test_nc4 do
  nc   = Cdo.topo(:options => '-f nc',:output => 'topo_nc.nc')
  nc4  = Cdo.topo(:options => '-f nc4',:output => 'topo_nc4.nc')
  nc4z = Cdo.topo(:options => '-f nc4 -z zip',:output => 'topo_nc4z.nc')
  oceanNC4Z = Cdo.copy(:options => '-f nc4 -z zip',:input => @_FILES[OCELSM_PLOT_TEST_FILE], :output => 'oceanNC4Z.nc')

# show(scalarPlot(nc ,'test_nc_TOPO',   'topo',:isIcon => false))
# show(scalarPlot(nc4,'test_nc4_TOPO',  'topo',:isIcon => false))
# show(scalarPlot(nc4z,'test_nc4z_TOPO','topo',:isIcon => false))
# show(scalarPlot(oceanNC4Z,'test_nc4z_OCEAN','T',:isIcon => true))
  defaultPlot(oceanNC4Z ,'test_nc4_withLines', :mapType => "ortho",
              :colormap => "test_cmap",:withLines => false,:showGrid => false,:maskName => 'wet_c')
#  system("ncview #{nc4z}")
end

desc "check plot with mpiom input"
task :test_mpiom do
  @plotter.isIcon = false
  show(scalarPlot(@_FILES[MPIOM_FILE],'test_mpiom'     ,'s',:DEBUG => true,:mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0'))
  show(scalarPlot(@_FILES[MPIOM_FILE],'test_mpiom_grid','s',:DEBUG => true,:mapLLC => '-100.0,0.0' ,:mapURC => '35.0,65.0',:showGrid => true))
end

desc "check icon_plot_test.ncl"
task :test_paths ,:loc do |t,args|
  require './findPath'
  q                    = JobQueue.new
  lock                 = Mutex.new
  paths                = IconPathsAlongCells.getEdgesAndVerts(@_FILES[ICON_GRID])
  ofiles, allPathsFile = [], 'test_paths.pdf'
  paths.each {|location,_paths|
    if args[:loc] then
      next unless location.to_s == args[:loc]
    end
    _paths.each {|pathType,locList|
      q.push {
        ofile = ["test_#{location.to_s}_at_#{pathType.to_s}",".pdf"]
        runNclTest('plot_'+pathType.to_s, parameters: [locList, ofile[0], @_FILES[OCE_NML_OUTPUT]],)
        ofiles << ofile.join
      }
    }
  }
  q.run
  IO.popen("pdftk #{ofiles.sort.join(' ')} cat output #{allPathsFile}").read
  IO.popen("evince #{allPathsFile}").read
end

desc "Check plots for data with non-given coordinates attribute, but given gridFile"
task :test_no_coordinates do
  ntime = Cdo.ntime(input: @_FILES[NOCOORDS_DATA])[0].to_i
  show(scalarPlot(@_FILES[NOCOORDS_DATA],'test_no_coords','t_acc',
                  :DEBUG => true,:timeStep => ntime - 1,:gridFile => @_FILES[NOCOORDS_DATA_GRID]))
  show(scalarPlot(@_FILES[NOCOORDS_DATA],'test_no_coords','t_acc',
                  :DEBUG => true,:timeStep => ntime - 1,:gridFile => @_FILES[NOCOORDS_DATA_GRID],
                  :limitMap => true,:rStrg => ' ',:bStrg => @_FILES[NOCOORDS_DATA]))
  show(scalarPlot(@_FILES[NOCOORDS_DATA],'test_no_coords_showGrid','t_acc',
                  :DEBUG => true,:timeStep => ntime - 1,:gridFile => @_FILES[NOCOORDS_DATA_GRID],
                  :limitMap => true,:showGrid => true,:rStrg => ' ',:bStrg => @_FILES[NOCOORDS_DATA]))
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
