;---------------------------------------------------------------
; This script makes contour/vector plots of general ICON data files
; For scalar variables the underlying grid can be used instead of automatic
; contour lines. Both modes are capable of masking the input files before
; plotting, see the command line options below for details.

 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;------- lib location from the command line ------------------------------------------------------------------
   loadscript("icon_plot_lib.ncl")
;------------------------------------------------------------------------------
undef("assert")
function assert(tag,givenResult,expectedResult,errorMessage)
begin
  retval = True
  if (any(givenResult .ne. expectedResult)) then
    print("ERROR found: ================================================")
    print(""+tag)
    print(errorMessage)
    print("Expected Result:"+expectedResult)
    print("Given    Result:"+givenResult)
    retval = False
  else
    print("No Error in "+tag)
    retval = True
  end if

  return retval
end
;------------------------------------------------------------------------------
; check version
;;ret = assert("NCL version",getNclVersion(),(/6,1,1/),"wrong version found")
;
; plot cells
undef("plotCells")
procedure plotCells()
begin
  File     = addfile( iFile+".nc", "r" )
  ResC     = setDefaultResource(True,True,False,"RasterFill")
  wks      = gsn_open_wks("ps","cells")

  varname  = "t"
  cellList = (/18481,18495, 18483, 18493, 18642, 18649, 18651, 18643, 19186, 19191 /) ; drake
; cellList = (/4543,4485/) ; gibraltar
; cellList = (/4690,4695/) ; denmark st.
  var      = selField(varname,File,0,0,"unstructured")
  x        = getCoordinates(var,File)
  y        = getCoordinates(var,File)
  bounds   = getBoundsOfCoordinates(var,File)
  boundslon = bounds(0,:,:)
  boundslat = bounds(1,:,:)
  plot = gsn_csm_contour_map(wks,var,ResC)
  print(File)

  do i=0,dimsizes(cellList)-1
    cell = cellList(i)
    print(boundslon(cell,:))
    print(boundslat(cell,:))
    gsn_polygon(wks,plot,boundslon(cell,:),boundslat(cell,:),ResC)
  end do
end
plotCells()
undef("plotVerts")
procedure plotVerts()
begin
  File     = addfile( iFile+".nc", "r" )
  ResC     = setDefaultResource(True,True,False,"RasterFill")
  wks      = gsn_open_wks("ps","verts")

  varname  = "vort"
  vertList = (/9285,9319,9321,9412,9414,9655/)  ; drake
; vertList = (/2371,2374/) ; gibraltar
; vertList = (/2436,2471/) ; denmark st.
  var      = selField(varname,File,0,0,"unstructured")
  x        = getCoordinates(var,File)
  y        = getCoordinates(var,File)
  bounds   = getBoundsOfCoordinates(var,File)
  boundslon = bounds(0,:,:)
  boundslat = bounds(1,:,:)
  plot = gsn_csm_contour_map(wks,var,ResC)

  print(dimsizes(boundslon))
  do i=0,dimsizes(vertList)-1
    vert = vertList(i)-1
    print(boundslon(vert,:))
    print(boundslat(vert,:))
    gsn_polygon(wks,plot,boundslon(vert,:),boundslat(vert,:),ResC)
  end do
end
plotVerts()
undef("plotEdges")
procedure plotEdges()
begin
  File     = addfile( iFile+".nc", "r" )
  ResC     = setDefaultResource(True,True,False,"RasterFill")
  wks      = gsn_open_wks("ps","edges")

  varname  = "vn"
  edgeList = (/27799,27803,28057,28058,28844/) ; drake
; edgeList = (/6861/); gibraltar
; edgeList = (/7168/)
  var      = selField(varname,File,0,0,"unstructured")
  x        = getCoordinates(var,File)
  y        = getCoordinates(var,File)
  bounds   = getBoundsOfCoordinates(var,File)
  boundslon = bounds(0,:,:)
  boundslat = bounds(1,:,:)
  plot = gsn_csm_contour_map(wks,var,ResC)

  print(dimsizes(boundslon))
  do i=0,dimsizes(edgeList)-1
    edge = edgeList(i)-1
    print(boundslon(edge,:))
    print(boundslat(edge,:))
    gsn_polygon(wks,plot,boundslon(edge,:),boundslat(edge,:),ResC)
  end do
end
plotEdges()
; vim:list
