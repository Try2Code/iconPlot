require "minitest/autorun"
require 'parallelQueue'
$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require "iconPlot"

class TestIconPlot < Minitest::Test

  CALLER                 = "/home/ram/src/iconPlot/contrib/nclsh"
  PLOTTER                = "/home/ram/src/iconPlot/icon_plot.ncl"
  PLOTLIB                = "/home/ram/src/iconPlot"
  LS                     = 'ls -crtlh'
  OCE_PLOT_TEST_FILE     = ENV['HOME']+'/local/data/icon/oce.nc'
  OCELSM_PLOT_TEST_FILE  = ENV['HOME']+'/local/data/icon/oce_lsm.nc'
  OCELONG_PLOT_TEST_FILE = ENV['HOME']+'/local/data/icon/oceLong.nc'
  ATM_PLOT_TEST_FILE     = ENV['HOME']+'/local/data/icon/atm.nc'
  OCE_REGPLOT_TEST_FILE  = ENV['HOME']+'/local/data/icon/regular_oce.nc' #remapnn,r180x90
  ATM_REGPLOT_TEST_FILE  = ENV['HOME']+'/local/data/icon/regular_atm.nc' #remapnn,n63 (no sections), r180x90 (with sections)
  OFMT                   = 'png'
  PLOT_CMD               = 'sxiv'
  CDO                    = ENV['CDO'].nil? ? 'cdo' : ENV['CDO']
  if 'luthien' == `hostname`.chomp
    def test_simple
      ip = IconPlot.new(CALLER,PLOTTER,PLOTLIB,OFMT,PLOT_CMD,CDO,true)
      ip.debug = true
      ofile          = 'test_icon_plot'
      q = ParallelQueue.new
      q.push {ip.scalarPlot(OCE_PLOT_TEST_FILE,   ofile+'_00',"T",:levIndex => 0) }
      q.push {ip.scalarPlot(OCE_PLOT_TEST_FILE,   ofile+'_01',"T",:levIndex => 2) }
      q.push {ip.vectorPlot(OCE_PLOT_TEST_FILE,   ofile+'_02',"u-veloc v-veloc",:levIndex => 2) }
      q.push {ip.scalarPlot(OCE_PLOT_TEST_FILE,   ofile+'_03',"T",:vecVars => "u-veloc,v-veloc",:levIndex => 2,:mapType => "ortho") }
      q.push {ip.scalarPlot(OCE_PLOT_TEST_FILE,   ofile+'_04',"T",:vecVars => "u-veloc,v-veloc",:levIndex => 2,:secLC => "-20,-60", :secRC => "-20,60") }
      q.push {ip.scalarPlot(OCELSM_PLOT_TEST_FILE,ofile+'_05',"T",:vecVars => "u,v",:levIndex => 2,:secLC => "-20,-60", :secRC => "-20,60",:maskName => 'wet_c') }
      q.push {ip.scalarPlot(OCELSM_PLOT_TEST_FILE,ofile+'_05',"T",:vecVars => "u,v",:levIndex => 2,:secLC => "-50,-60", :secRC => "0,60",:maskName => 'wet_c',:secMode => 'circle') }
      q.push {ip.scalarPlot(OCELSM_PLOT_TEST_FILE,ofile+'_06',"T",:vecVars => "u,v",:levIndex => 2,:maskName => 'wet_c') }
      q.push {ip.scalarPlot(OCELSM_PLOT_TEST_FILE,ofile+'_07',"T",:levIndex => 2,:maskName => 'wet_c') }

      images = q.run

      ip.show(*images)
    end
  end
  def _test_defaults
    p = IconPlot.new
    assert_includes(p.caller.split(File::SEPARATOR),'gems')
    assert_includes(p.plotter.split(File::SEPARATOR),'gems')
    assert_includes(p.libdir.split(File::SEPARATOR),'gems')
  end
  def _test_levelPlot
    p = IconPlot.new
    p.show( p.levelPlot(OCELONG_PLOT_TEST_FILE,'test_levelPlot_00','T',:operation => :fldmax))
  end
end
