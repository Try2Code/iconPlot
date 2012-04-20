#!/usr/bin/env ruby
require 'extcsv'
require 'cdo'
require 'jobqueue'
require 'pp'

# Usage
#
# ./levelPlot.rb <inputICONfile> <variableName> <operation:optional> <plotfile:optional>
#
#
# operations can be operators file fldmin (default), fldmax, fldavg, ... (everything that has only one input and one output stream)

ifile      = ARGV[0]
varnames   = ARGV[1].split(',')
timestep   = ARGV[2].nil? ? '1' : ARGV[2]
plotfile   = ARGV[3]
createPlot = (not ARGV[3].nil?)

if varnames.size > 2
  warn "Please provide only to variable names"
  exit -1
end

# Temporal file for text output
dataFile  = MyTempfile.path
dataFileX = MyTempfile.path
dataFileY = MyTempfile.path

# queue for parallel processing
jq = JobQueue.new

$files = []
[dataFileX,dataFileY,dataFile].each {|f| $files << f}

outX,outY = [],[]

varnames.each_with_index {|varname,i| 
  jq.push {
    file = [dataFileX,dataFileY][i]
    out  = [outX,outY][i]
    IO.popen("echo '#{varname}' > #{file}")
    out << Cdo.outputkey('value', :in => "-selname,#{varname} -seltimestep,#{timestep} #{ifile}")
  }
}
jq.run

icon = ExtCsv.new("hash","plain",{varnames[0].to_sym => outX[0],varnames[1].to_sym => outY[0]})

#remove salinity values smaller than 1
[:s, :sal, :salinity].each {|col|
  if icon.datacolumns.include?(col.to_s)
    icon = icon.selectBy(col => "> 1")
    break
  end
  if icon.datacolumns.include?(col.to_s.upcase)
    icon = icon.selectBy(col.to_s.upcase.to_sym => "> 1")
    break
  end
}

# Plot data with automatic splitting by depth
ExtCsvDiagram.plot_xy(icon,varnames.first,varnames.last,
                      "ICON: Scatterplot on #{varnames.join(' and ')}", # Change title here
                      :label_position => 'below',:skipColumnCheck => true,
                      :type => 'points', :onlyGroupTitle => true,
                      :terminal => createPlot ? 'png' : 'x11',
                      :ylabel => "#{varnames[1]}",     # Correct the label if necessary
                      :xlabel => "#{varnames[0]}",     # Correct the label if necessary
                      :filename => plotfile,
                      :size => "800,600")
