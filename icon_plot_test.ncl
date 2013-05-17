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
procedure assert(tag,givenResult,expectedResult,errorMessage)
begin
  if (any(givenResult .ne. expectedResult)) then
    print("ERROR found: ================================================")
    print(""+tag)
    print(errorMessage)
    print("Expected Result:"+expectedResult)
    print("Given    Result:"+givenResult)
  else
    print("No Error in "+tag)
  end if
end
;------------------------------------------------------------------------------
; check version
assert("NCL version",getNclVersion(),(/6,1,1/),"wrong version found")

;
; vim:list
