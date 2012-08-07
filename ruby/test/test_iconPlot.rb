$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require "test/unit"
require "iconPlot"

class TestIconPlot < Test::Unit::TestCase

  CALLER = "/home/ram/src/git/icon/scripts/postprocessing/tools/contrib/nclsh"
  PLOTTER= "/home/ram/src/git/icon/scripts/postprocessing/tools/icon_plot.ncl"
  PLOTLIB = "/home/ram/src/git/icon/scripts/postprocessing/tools"
  LS                    = 'ls -crtlh'
  OCE_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/oce.nc'
  OCELONG_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/oceLong.nc'
  ATM_PLOT_TEST_FILE    = ENV['HOME']+'/data/icon/atm.nc'
  OCE_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_oce.nc' #remapnn,r180x90
  ATM_REGPLOT_TEST_FILE = ENV['HOME']+'/data/icon/regular_atm.nc' #remapnn,n63 (no sections), r180x90 (with sections)
  OFMT                  = 'png'
  PLOT_CMD              = 'sxiv'
  CDO                   = ENV['CDO'].nil? ? 'cdo' : ENV['CDO']
  if 'thingol' == `hostname`.chomp
    def test_simple
      ip = IconPlot.new(CALLER,PLOTTER,PLOTLIB,OFMT,PLOT_CMD,CDO,true)
      ofile          = 'test_icon_plot'
      ip.show(ip.scalarPlot(OCE_PLOT_TEST_FILE,ofile,"T",:levIndex => 0))
      ip.show(ip.scalarPlot(OCE_PLOT_TEST_FILE,ofile,"T",:levIndex => 2))
      ip.show(ip.vectorPlot(OCE_PLOT_TEST_FILE,ofile,"u-veloc v-veloc",:levIndex => 2))
    end
  end
  def test_defaults
    p = IconPlot.new
    assert_includes(p.caller.split(File::SEPARATOR),'gems')
    assert_includes(p.plotter.split(File::SEPARATOR),'gems')
    assert_includes(p.libdir.split(File::SEPARATOR),'gems')
  end
  def test_levelPlot
    p = IconPlot.new
    p.show( p.levelPlot(OCELONG_PLOT_TEST_FILE,'test_levelPlot_00','T',:operation => :fldmax))
  end
end
