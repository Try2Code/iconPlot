require 'fileutils'
require 'cdo'
require 'extcsv'
require 'shellwords'

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
  def levelPlot(ifile,ofile,varname,opts={})
    Cdo.setCdo('/home/ram/src/cdo/trunk/cdo/build/bin/cdo')
    operation = opts[:operation].nil? ? 'fldmin' : opts[:operation]

    data = createData(ifile,varname,operation)
    icon = ExtCsv.new("array","plain",data.transpose)
    setDatetime(icon)

    # Plot data with automatic splitting by depth
    unless icon.datacolumns.include?(varname)
      warn "Variable cannot be found!"
      exit -1
    end
    Cdo.debug = true
    unit = Cdo.showunit(:in => "-selname,#{varname} #{ifile}").first
    ExtCsvDiagram.plot_xy(icon,"datetime",varname,
                          "ICON: #{operation} on #{varname} (file:#{ifile})", # Change title here
    :label_position => 'below',:skipColumnCheck => true,
      :type => 'lines',:groupBy => ["depth"], :onlyGroupTitle => true,
      #                     :addSettings => ["logscale y"],     # Commend theses out for large scale values like Vert_Mixing_V
      #                     :yrange => '[0.0001:10]',           # Otherwise you'll see nothing reasonable
      :terminal => true ? 'png' : 'x11',
      :ylabel => "#{varname} [#{Shellwords.escape(unit)}]",     # Correct the label if necessary
      :input_time_format => "'%Y%m%d %H:%M:%S'",
        :filename => ofile,
        :output_time_format => '"%d.%m.%y \n %H:%M"',:size => "1600,600")
      return "#{ofile}.png"
  end
  def scatterPlot(ifile,ofile,xVarname,yVarname,opts={})
    # is there a variable which discribes different regions in the ocean
    regionVar = opts[:regionVar].nil? ? 'rregio_c' : opts[:regionVar]
    hasRegion = Cdo.showname(:in => ifile).join.split.include?(regionName)
    unless hasRegion
      warn "Variable '#{regionName}' for showing regions is NOT found in the input '#{ifile}'!"
      warn "Going on without plotting regions!"
      varnames = varnames[0,2]
      groupBy = []
    else
      groupBy = [regionName]
    end
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

  def createData(ifile,varname,operation)
    # Temporal file for text output
    dataFile = MyTempfile.path

    # read the date
    IO.popen("echo 'date|time|depth|#{varname}' > #{dataFile}")
    Cdo.debug = true
    Cdo.outputkey('date,time,level,value', 
                  :in => "-#{operation} -selname,#{varname} #{ifile} >>#{dataFile} 2>&1")

    # postprocessing for correct time values
    data = []
    File.open(dataFile).each_with_index {|line,lineIndex|
      next if line.chomp.empty?
      _t = line.chomp.gsub(/ +/,'|').split('|')
      if 0 == lineIndex then
        data << _t
        next
      end
      if "0" == _t[1] then
        _t[1] = '00:00:00'
      else
        time = _t[1].reverse
        timeStr = ''
        while time.size > 2 do
          timeStr << time[0,2] << ':'
          time = time[2..-1]
        end
        timeStr << time.ljust(2,'0') unless time.size == 0
        _t[1] = timeStr.reverse
      end
      data << _t
    }
    data
  end

  def setDatetime(extcsvObj)
    unless (extcsvObj.respond_to?(:date) and extcsvObj.respond_to?(:time))
      warn "Cannot set datetime due to missing date and time attributes"
      raise ArgumentError
    end
    # Create datetime column for timeseries plot
    extcsvObj.datetime = []
    extcsvObj.date.each_with_index{|date,i| extcsvObj.datetime << [date,extcsvObj.time[i]].join(' ') }
    extcsvObj.datacolumns << "datetime"
  end
end
