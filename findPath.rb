#!/usr/bin/env ruby
require 'pp'
require 'facets/array/nonuniq'
require 'numru/netcdf'
include NumRu

module IconPathsAlongCells
  # R2B04: list of cellsof which their common edge define the path
  CellPairsLists= {
    :gibraltar      => [[4543,4485]],
    :denmarkStrait  => [[4690,4695]],
    :drakePassage   => [
      [18481,18495],
      [18483,18493],
      [18642,18649],
      [18651,18643],
      [19186,19191]],
      :indonesianThroughflow => [
        [6864,6866],
        [6868,6869],
        [6872,6875],
        [12064,12067],
        [12072,12073],
        [12152,12154]],
  }

  def IconPathsAlongCells.getEdgesAndVerts(ifile)
    ifileHandle  = NetCDF.open(ifile,"r")
    cellEdges    = ifileHandle.var('edge_of_cell').get
    cellVertices = ifileHandle.var('vertex_of_cell').get
    edgeVertices = ifileHandle.var('edge_vertices').get
    puts '#==========================================================================='
    CellPairsLists.each {|location,cellPairs|
      puts '============================================================================='
      puts location
      puts ["cells: ", cellPairs.join(' ')].join

      verts = []
      cellPairs.each {|cellpair|
        cellpair.each {|cell| verts << cellVertices[cell,0..-1].to_a }
      }
      puts ["common verts: ", verts.flatten.nonuniq.join(',')].join

      # get the corresponding edges
      edges = []
      cellPairs .each {|cellpair|
        cellpair.each {|cell| edges << cellEdges[cell,0..-1].to_a }
      }
      puts ["common edges: ", edges.flatten.nonuniq.join(',')].join
    }
    puts '============================================================================='
  end
end

if $0 == __FILE__ then
  # = MAIN =======================================================================
  ifile = ARGV[0]

  if ifile.nil? or not File.exist?(ifile) 
    warn "Cound not read input file '#{ifile}'!"
    warn "Usage:\n\t./findEdges.rb <icon-grid-file>"
    exit(1)
  end

  IconPathsAlongCells.getEdgesAndVerts(ifile)
ifileHandle  = NetCDF.open(ifile,"r")
cellEdges    = ifileHandle.var('edge_of_cell').get
cellVertices = ifileHandle.var('vertex_of_cell').get
edgeVertices = ifileHandle.var('edge_vertices').get
end

