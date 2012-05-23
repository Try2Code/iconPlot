require 'fileutils'

class IconPlot < Struct.new(:caller,:plotter,:libdir,:otype,:display,:cdo,:debug)
  def IconPlot.gemPath
    gemSearcher = Gem::GemPathSearcher.new
    gemspec     = gemSearcher.find('iconPlot')
    gemspec.gem_dir
  end
  def initialize(*args)
    super(*args)

    gempath = IconPlot.gemPath
    defaults = {
      :caller  => [gempath,'contrib','nclsh'].join(File::SEPARATOR),
      :plotter => [gempath,'lib','icon_plot.ncl'].join(File::SEPARATOR),
      :libdir  => [gempath,'lib'].join(File::SEPARATOR),
      :otype   => 'png',
      :display => 'sxiv',
      :cdo     => ENV['CDO'].nil? ? 'cdo' : ENV['CDO'],
      :debug   => false
    }
    self.each_pair {|k,v| self[k] = defaults[k] if v.nil? }
  end
  def plot(ifile,ofile,varname,vartype='scalar',opts={})
    unless File.exists?(ifile)
      warn "Input file #{ifile} dows NOT exist!"
      exit
    end
    varIdent = case vartype.to_s
               when 'scalar'  then "-varName=#{varname}"
               when 'vector'  then "-vecVars=#{varname.split(' ').join(',')}"
               when 'scatter' then "-plotMode=scatter -vecVars#{varname.split(' ').join(',')}"
               else
                 warn "Wrong variable type #{vartype}"
                 raise ArgumentError
               end

    opts[:tStrg] =ofile

    cmd   = [self.caller,self.plotter].join(' ')
    cmd << " -altLibDir=#{self.libdir} #{varIdent} -iFile=#{ifile} -oFile=#{ofile} -oType=#{self.otype} -isIcon -DEBUG"
    opts.each {|k,v| cmd << " -"<< [k,v].join('=') }
    puts cmd if self.debug
    out = IO.popen(cmd).read
    puts out if self.debug

    return [FileUtils.pwd,"#{ofile}.#{self.otype}"].join(File::SEPARATOR)
  end
  def scalarPlot(ifile,ofile,varname,opts={})
    plot(ifile,ofile,varname,'scalar',opts)
  end
  def vectorPlot(ifile,ofile,varname,opts={})
    plot(ifile,ofile,varname,'vector',opts)
  end

  def del(file)
    FileUtils.rm(file) if File.exists?(file)
  end
  def show(*files)
    files.flatten.each {|file| IO.popen("#{self.display} #{file} &") }
  end
  def defaultPlot(ifile,ofile,opts={})
    show(scalarPlot(ifile,ofile,DEFAULT_VARNAME,opts))
  end
  def showVector(ifile,ofile,vars,opts={})
    show(vectorPlot(ifile,ofile,vars,opts))
  end
end
