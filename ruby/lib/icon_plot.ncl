;---------------------------------------------------------------
; This script makes contour/vector plots of general ICON data files
; For scalar variables the underlying grid can be used instead of automatic
; contour lines. Both modes are capable of masking the input files before
; plotting, see the command line options below for details.

 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
 load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;------- config ---------------------------------------------------------------
  ; default settings from user file
  CONFIGFILE = getenv("HOME")+"/.icon_plot.rc"
  if (isfilepresent(CONFIGFILE)) then
    print("Found configfile:"+CONFIGFILE)
    loadscript(CONFIGFILE)
  end if

  if ( .not. isvar("altLibDir") )  then
    print("load default library from /pool/data/ICON/tools")
    loadscript("/pool/data/ICON/tools/icon_plot_lib.ncl")
  else
    print("Load library: "+altLibDir+"/icon_plot_lib.ncl")
    loadscript(altLibDir +"/icon_plot_lib.ncl")
  end if
;--- end config ---------------------------------------------------------------
;==============================================================================
;----- MAIN PROGRAM -----------------------------------------------------------
  if (isvar("help")) then
    dq = str_get_dq()
    print(";---------------------------------------------------------------")
    print("; Basic Usage:")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "path/file.nc" + dq + "' 'varName=" + dq + "ELEV" + dq + "' 'oFile=" + dq + "test" + dq + "' timeStep=1 levIndex=1")
    print(";")
    print("; Select an special area of the globe with mapLLC (LowerLeftCorner) and mapURC (UpperRightCorner)   ")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "path/file.nc" + dq + "' 'varName=" + dq + "W" + dq + "'    'mapLLC=(/35.0, -8/)' 'mapURC=(/55, 8/)'")
    print(";")
    print("; Masking:")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "oce_aqua_planet_O.R2B04L4_0001.nc" + dq + "' 'varName=" + dq + "ELEV" + dq + "' 'maskName=" + dq + "wet_c" + dq + "' ")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "oce.nc" + dq + "' 'varName=" + dq + "W" + dq + "' 'maskName=" + dq + "topo" + dq + "' 'maskFile=" + dq + "icon_mask.nc" + dq + "' ")
    print(";")
    print("; Vectorplot:")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "oce.nc" + dq + "' 'vecVars=" + dq + "u-veloc v-veloc" + dq + "' 'oFile=" + dq + "test" + dq + "'")
    print(";")
    print("; Vertical cross section:")
    print(";   ncl icon_plot.ncl 'iFile=" + dq + "iconOutput.nc" + dq + "' 'secLC=(/ 0.0,-90.0 /)' 'secRC=(/ 0.0,90.0/)' 'oType=" + dq + "png" + dq + "' 'rStrg=" + dq + "" + dq + "' 'tStrg=" + dq + "ICON coupled aqual planet" + dq + "'")
    print(";")
    print("; Overlay plot (vectors over contour plot)")
    print(";   ncl icon_plot.ncl  'iFile=" + dq + "iconOutput.nc" + dq + "' 'varName=" + dq + "T" + dq + "' 'vecVars=" + dq + "u-veloc v-veloc" + dq + "'")
    print("; same for current atmo input")
    print(";   ncl icon_plot.ncl  'iFile=" + dq + "atm.nc" + dq + "' 'varName=" + dq + "T" + dq + "' 'vecVars=" + dq + "U V" + dq + "'")
    print(";")
    print("; Atmosphere input plotted on the 3rd height level")
    print(";   ncl icon_plot.ncl  'iFile=" + dq + "atm.nc" + dq + "' 'varName=" + dq + "T" + dq + "' 'atmLev=" + dq + "h" + dq + "' levIndex=2")
    print("; Same but on pressure level")
    print(";   ncl icon_plot.ncl  'iFile=" + dq + "atm.nc" + dq + "' 'varName=" + dq + "T" + dq + "' 'atmLev=" + dq + "p" + dq + "' levIndex=2")
    print("; Options can be combined execept showGrid=True with vector and overlay plots")
    print(";---------------------------------------------------------------")
    print(";")
    print("; Required Parameter:")
    print("; iFile         : input file (based in ICON horizonal Grid or regular lonlat grid)")
    print("; oFile         : plot file wihtout extension (it set by the output type: oType)")
    print("; varName       : name of the variable to (contour) plot")
    print("; vecVars       : space separated string of the 2 vector components u and v to")
    print(";                 draw a vector plot, array notation is also possible:")
    print(";                 vecVars='" + dq + "u v" + dq + "' or vecVars='(/" + dq + "u" + dq + "," + dq + "v" + dq + "/)'")
    print(";")
    print("; Optional Parameter:")
    print("; oType         : output graphics format (ps, eps, png, default: eps)")
    print("; resolution    : resolution string whish is used for remapping the icon data")
    print(";                 to regular grid (default: r90x45)")
    print("; vecRefLength  : reference vector length (default: 8.0)")
    print("; vecColByLen   : should vectors get coloured according to their lengths (default:False)")
    print("; vecMinDist    : minimal distance between vectors (default:0.017)")
    print("; streamLine    : display streamlines instead of vectors")
    print("; timeStep      : no of timestep (default:0)")
    print("; levIndex      : vertical level index (default:0)")
    print("; isIcon        : input is horiz. ICON style netcdf data (default:false), ")
    print(";                 manually set this to prevent from checks")
    print("; minVar/maxVar : set the lower/upper limit of the labelbar")
    print("; mapLLC        : (lon,lat) value array of the Lower Left Corner of the map")
    print("; mapURC        : (lon,lat) ------- || ------- Upper Right Corner of the map")
    print(";                  use -180 to 180 for longitude !")
    print("; secLC, secRC  : start and and point of a vertical section (no default value)")
    print(";                 section is plotted it secLC and secRC are present")
    print("; showSecMap    : display the location of the vertical section in an additional map (default:true)")
    print("; centerLon     : center longitute for satelite view (default:30.)")
    print("; centerLat     : center latitude for satelite view (default:20.)")
    print("; satDist       : satelite distance (default:20.0)")
    print("; scaleFactor   : optional scale factor")
    print("; selMode       : mode for level spacing of the plot:")
    print(";                 halflog (uses half logarythmic levels,i.e. 1,2,5 per decade), ")
    print(";                 manual (automatic linear spacing with usage of minVar and maxVar)")
    print(";                 auto (default: let do ncl the spacing)")
    print("; scaleLimit    : Limits the number of decades for levels in selMode-halflog")
    print("; minVar/maxVar : min/maximal Value to plot for selMode=manual or halflog")
    print("; numLevs       : set a number of labels for manual selMode only. NumCol=numLevs+2")
    print(";                 (Not set directly, but used for computing the contour level spacing. default=10)")
    print("; contLevs      : set individual contour levels (not yet)")
    print("; mapType       : projection type (default: lonlat), other: ortho (not compatible with showGrid), NHps")
    print(";                 and SHps (polar stereographic projections centered at the north and south pole respectively),")
    print(";                 sat (satelite view, use option centerLat, centerLon and satDist)")
    print("; mapLine       : (logical) draws continent lines on the plot (foreground/transparent)")
    print("; maskName      : variable to mask with. maskName is expected NOT to have time dimension")
    print(";                  'maskName=" + dq + "none" + dq + "' is same as default (no mask variable)")
    print("; maskFile      : optional Filename of the mask variable maskName")
    print(";                  it's only taken into account, if maskName is given")
    print("; lonCo/latCo   : default coordinate variables (default: clon/clat)")
    print("; gridFile      : use the given file for reading the coordintes (comming from lonCo and latCo)")
    print("; lStrg         : left string")
    print("; rStrg         : right string")
    print("; tStrg         : title string")
    print("; bStrg         : base string - default is prgr name and time stamp only")
    print("; maxView       : (logical) maximize plot area on paper (not for buildbot -> convert to png)")
    print("; colormap      : string for predefined colormaps of the plot (e.g. 'colormap=" + dq + "BlAqGrYeOrReVi200" + dq + "')")
    print("; showGrid      : display polygon lines with filled colors instead of contour plot")
    print("; showNcd       : display NDC Grid to find Normalized Device Coordinates on the plot")
    print("; k2c           : if True, perform Kelvin2Celsius shift (default:True)")
    print(";")
    print("; ATMOSPEHRE STUFF:")
    print("; atmLev        : chooses vertical plot levels for atmosphere input (h: height,p:pressure,m:modellevel,default:p)")
    print(";---------------------------------------------------------------")
    print("; altLibDir     : Alternative directory for loading icon_plot_lib.ncl")
    print("; cdo           : Path to an alternative cdo version")
    print(";---------------------------------------------------------------")
    print("; Authors       : Ralf Mueller (ralf.mueller@zmaw.de)")
    print(";                 Stephan Lorenz (stephan.lorenz@zmaw.de)")
    print("; VERSION       : r8012 (2012-01-26)")
    print(";---------------------------------------------------------------")
    exit()
  end if
;- options handling + checking
  wcStrt    = systemfunc("date")

  print("+++++ "+wcStrt)

  Model     = "Icon: explicit ocean test"

  if(.not. isvar("iFile")) then
    print("Input file is required! Use iFile option.")
    print(ABORTMSG)
    exit
  else
    if ( .not. isfilepresent(iFile) )
      print("Could not read from input file: "+iFile+"!")
      print(ABORTMSG)
      exit
    end if
  end if
  if(.not. isvar("iType")) iType = "oce" end if

  if(.not. isvar("oType")) oType = "eps" end if
  if(.not. isvar("oFile")) then
    ext      = get_file_suffix(iFile,0)
    oFile    = ext@fBase
  end if
  print("Outputfile '"+str_concat((/oFile,".",oType/))+"' will be created in "+systemfunc("dirname "+iFile))

  if(.not. isvar("numLevs")) then
    numLevs  = NUMLEVS
  else
    if (numLevs .lt. 1) then
      print("WARNING: numLevs must be >= 1")
      print(ABORTMSG)
      exit
    end if
  end if

  if (.not. isvar("DEBUG"))       DEBUG       = False           end if
  if (.not. isvar("showGrid"))    showGrid    = False           end if
  if (.not. isvar("showNdc"))     showNdc     = False           end if
  if (.not. isvar("maxView"))     maxView     = False           end if
  if (.not. isvar("scaleLimit"))  scaleLimit  = 2               end if
  if (.not. isvar("selMode"))     selMode     = "auto"          end if
  if (.not. isvar("plotMode"))    plotMode   = "scalar"         end if
  if (.not. isvar("timeStep"))    timeStep    = 0               end if
  if (.not. isvar("levIndex"))    levIndex    = 0               end if
  if (.not. isvar("scaleFactor")) scaleFactor = 1               end if
  if (.not. isvar("colormap"))    colormap    = "BlueDarkRed18" end if
  if (.not. isvar("k2c"))         k2c         = True            end if
  if (.not. isvar("isIcon"))      isIcon      = False           end if

  if (.not.isvar("mapType"))      mapType      = "lonlat"        end if
  if ( mapType .eq. "NHps" .and. .not.isvar("mapLLC")) mapLLC = (/-45., 45./)  end if
  if ( mapType .eq. "NHps" .and. .not.isvar("mapURC")) mapURC = (/135., 45./)  end if
  if ( mapType .eq. "SHps" .and. .not.isvar("mapLLC")) mapLLC = (/-45.,-45./)  end if
  if ( mapType .eq. "SHps" .and. .not.isvar("mapURC")) mapURC = (/135.,-45./)  end if

  if (.not.isvar("mapLLC"))       mapLLC       = (/-180.,-90./)  end if
  if (.not.isvar("mapURC"))       mapURC       = (/180.0,90.0/)  end if
  if (.not.isvar("centerLon"))    centerLon    = -30.            end if
  if (.not.isvar("centerLat"))    centerLat    =  20.            end if
  if (.not.isvar("satDist"))      satDist      =  20.            end if
  if (.not.isvar("mapLine"))      mapLine      = True            end if
  if (.not.isvar("resolution"))   resolution   = "r90x45"        end if
  if (.not.isvar("vecRefLength")) vecRefLength = 8.0             end if
  if (.not.isvar("vecColByLen"))  vecColByLen  = False           end if
  if (.not.isvar("vecMinDist"))   vecMinDist   = 0.017           end if
  if (.not.isvar("streamLine"))   streamLine   = False           end if
  if (.not.isvar("secPoints"))    secPoints    = 20              end if
  ; default + optional coordinates
  if (.not.isvar("lonCo"))         lonCo       =  DEFAULTLON     end if
  if (.not.isvar("latCo"))         latCo       =  DEFAULTLAT     end if

  if (.not.isvar("showSecMap")) showSecMap     =  True           end if
  ; ATMOSPEHRE SETUP ----------------------------------------------------------
  if (.not.isvar("atmLev"))     atmLev         =  "p"           end if
  if (.not.isvar("atmPLevs")) then
    atmPLevSetup = (/10000,100000,2500/); unit: Pa
    atmPLevs     = ispan(atmPLevSetup(0),atmPLevSetup(1),atmPLevSetup(2))*1.0
  end if
  if (.not.isvar("atmHLevs")) then
    atmHLevSetup = (/0,100000,2000/);     unit: m
    atmHLevs     = ispan(atmHLevSetup(0),atmHLevSetup(1),atmHLevSetup(2))*1.0
  end if
  ; CDO settings --------------------------------------------------------------
  if (.not.isvar("cdo")) cdo                   =  "cdo"          end if
  setCDO(cdo)
  ;----------------------------------------------------------------------------

  ; MASK HANDLING -------------------------------------------------------------
  if (.not.isvar("maskName"))
    useMask     = False
  else
    if ( .not.isstring(maskName)) then
      print("Parameter 'maskName' has to be a string!")
      exit
    else
      useMask  = True
      if (.not.isvar("maskFile"))
        if (maskName.eq."none") then
          useMask = False
        else
          if (DEBUG) then
            print("Use internal mask variable " +maskName)
          end if
        end if
      else
        if (DEBUG) then
          print("Use external mask file " + maskFile)
        end if
      end if
    end if
  end if
  ;----------------------------------------------------------------------------


  ; DETERMINE INPUT TYPE ------------------------------------------------------
  if (isvar("varName")) then
    ivarname = varName
  else
    if (isvar("vecVars")) then
      size  = dimsizes(vecVars)
      if (1.lt.size) then
        ivarname = vecVars(0)
      else
        if (isstring(vecVars)) then
        vecs = str_split(vecVars," ")
        ivarname = vecs(0)
        else
          print("Cannot determinte input variable! Please provide varName or vecVars.")
          exit
        end if
      end if
      delete(size)
    else
      print("Cannot determinte input variable! Please provide varName or vecVars.")
      exit
    end if
  end if
  if (getVarLevelType(iFile,ivarname) .eq. "hybrid") then ;atm input
    iType              = "atm"; oce otherwise
    if (atmLev .ne. "m" ) then
      atmPreProcFilename = preProc4Atm(iFile,atmLev,atmPLevs,atmHLevs,DEBUG)
      iFile              = atmPreProcFilename
    end if
  end if
  ; DETERMINE HORIZONTAL GRID -------------------------------------------------
  horizonalGridType = getHorizGridType(iFile,ivarname,isIcon)
  ;----------------------------------------------------------------------------

  ; DETERMINE THE PLOTMODE ----------------------------------------------------
  if (isvar("vecVars")) then
    ; expectes is a string or an array of size 2: "u-veloc v-veloc" or (/"u-veloc","v-veloc"/)
    if (1 .eq. dimsizes(vecVars)) then
      if (isstring(vecVars)) then
        vecVars_ = str_split(vecVars," ")
        delete(vecVars)
        vecVars = vecVars_
      else
        print("Please provide a valid description of vector variables")
        exit
      end if
    end if
    if (plotMode .ne. "scatter") then
      plotMode = "vector"
      if (isvar("varName")) plotMode = "overlay" end if
    end if
  else
    if (isvar("scatVars")) then
      plotMode = "scatter"
    else
      plotMode = "scalar"
    end if
  end if

  if ( (isvar("secLC").or.isvar("secRC")).ne.(isvar("secLC").and.isvar("secRC"))) then
    print("Please provide secLC AND secRC for generatin a section plot!")
    exit
  end if
  if (isvar("secLC").and.isvar("secRC")) plotMode = "section" end if
  if (isvar("hoff")) plotMode = "hoffmueller" end if

  if (plotMode.eq."vector" .or. plotMode.eq."overlay" .or. plotMode.eq."section" .or. plotMode .eq. "hoffmueller") then
    if (horizonalGridType .ne. "unstructured") then ; regular grid expected, i.e. remappgin is NOT required
      rFile = addfile(iFile+".nc","r")
    else
      ; performe some remapping to a regular grid because ncl cannot draw vector
      ; from unstructured grids
      ; TODO addVars=(/ "PS","PHIS"/)
      remapFilename = setRemapFilename(iFile,iType,atmLev)
      print("remapFilename:"+remapFilename)
      if (.not. checkRemappedFile(iFile,remapFilename,ivarname,iType,atmLev,atmPLevs,atmHLevs) ) then
        addVars=(/""/)
        print("PERFORM remapnn again!")
        remapForVecPlot(iFile,remapFilename,resolution,useMask,plotMode,DEBUG,addVars)
      end if
      rFile = addfile( remapFilename+".nc", "r" )
    end if
    if (plotMode .eq. "hoffmueller") then ; perform zonmean
      zonmeanFilename = setZonmeanFilename(remapFilename,ivarname,atmLev)
      zonmean4HoffmuellerPlot(remapFilename,ivarname,zonmeanFilename)
    end if
  end if
  File  = addfile( iFile+".nc", "r" )

  if (DEBUG) printVarNames(File) end if

  ;Read mask variable
  if( useMask ) then
    mFile = File
    if (isvar("maskFile")) then
      maskVar = getMaskVar(maskName,File,True,maskFile,timeStep,levIndex,plotMode,horizonalGridType)
    else
      if (plotMode.eq."vector" .or. plotMode.eq."section") then
        maskVar = getMaskVar(maskName,rFile,False,"",timeStep,levIndex,plotMode,horizonalGridType)
      else
        maskVar = getMaskVar(maskName,File,False,"",timeStep,levIndex,plotMode,horizonalGridType)
      end if
    end if
  end if

  if (plotMode.eq."vector") then
    print("Plot vector variables: " + vecVars)
  else
    if (plotMode.eq."overlay") then
      print("Plot vector variables: " + vecVars)
      print("Plot variable: " + varName)
    end if
    if (plotMode.eq."section") then
      print("Plot variable: " + varName)
    end if
  end if
  ;---------------------------------------------------------------
  if (DEBUG) then
    print("iFile       = "+iFile)
    print("oFile       = "+oFile)
    print("Graphics format is " +oType)
    print("plotMode    = "+plotMode)

    if (plotMode.eq."scalar" .or. plotMode.eq."section") then
      print("varName     = "+varName)
    else
      print("vecVars     = "+vecVars)
      if (plotMode.eq."overlay") then print("varName     = "+varName) end if
    end if

    print("timeStep    = "+timeStep)
    print("mapLLC(lon) = "+mapLLC(0))
    print("mapLLC(lat) = "+mapLLC(1))
    print("mapURC(lon) = "+mapURC(0))
    print("mapURC(lat) = "+mapURC(1))
    if (useMask) then
    print("maskName    = "+maskName)
    end if
    print("#==== END OF DEBUG OUTPUT =====================================")
  end if
  ;---------------------------------------------------------------


  ; Reading data variables =====================================================
  if (plotMode.eq."scalar" .or. plotMode.eq."overlay") then ; scalar mode ======

    printVar(varName, File)

    var = selField(varName,File,timeStep,levIndex,horizonalGridType)

    if (horizonalGridType .eq. "unstructured") then
      if (isvar("gridFile")) then
        x      = getCoordinateFromFile(lonCo,gridFile)
        y      = getCoordinateFromFile(latCo,gridFile)
        if (showGrid) then
          bounds = getBoundsFromFile(lonCo,latCo,gridFile)
        end if
      else
        lonlatSizes = getCoordSizes(var,File)
        x           = new(lonlatSizes(0),double)
        y           = new(lonlatSizes(1),double)
        getLonLats(var,File,x,y)
        if (showGrid) then
          bounds  = getBoundsOfCoordinates(var,File)
        end if
      end if
    end if

    scaleVar(var,scaleFactor)

    ; set selMode automatically
    if (isvar("minVar") .and. isvar("maxVar"))  then
      if (selMode .eq. "auto") then
        selMode = "manual"
      end if
    end if
    ; set minVar_maxVar for plotting
    if(.not. isvar("minVar")) minVar = min(var) end if
    if(.not. isvar("maxVar")) maxVar = max(var) end if
    checkMinMaxVar(minVar,maxVar)

    if ( useMask ) then
      ; set variable var to missing, where var is not equal mvalue (3rd
      ; parameter)
      var = mask(var,maskVar,1)
      ;slm = maskVar - 0.5
      ;var = mask ( var, slm, 0.5)
    end if
  end if
  if (plotMode.eq."vector" .or. plotMode.eq."overlay") then; vector mode =======
    uvarname = vecVars(0)
    vvarname = vecVars(1)

    if (has_var(rFile,uvarname) .and. has_var(rFile,vvarname)) then
      checkDimsOfVars(uvarname,vvarname,rFile)
    else
      print("Remapped file does not have variables "+uvarname+" or "+vvarname+"!")
      exit
    end if

    uvar = selRegularField(uvarname,rFile,timeStep,levIndex)
    vvar = selRegularField(vvarname,rFile,timeStep,levIndex)

    scaleVar(uvar,scaleFactor)
    scaleVar(vvar,scaleFactor)

    if ( useMask ) then
      uvar = mask(uvar,maskVar,1)
      vvar = mask(vvar,maskVar,1)
    end if

    velocity = sqrt(uvar*uvar + vvar*vvar)
    ; set minVar/maxVar for plotting
    if(.not. isvar("minVar")) minVar = min(velocity) end if
    if(.not. isvar("maxVar")) maxVar = max(velocity) end if
    checkMinMaxVar(minVar,maxVar)
  end if
  if (plotMode.eq."scatter") then; scatter plot ================================
    xvarname = vecVars(0)
    yvarname = vecVars(1)
    xvar = selField(xvarname,File,timeStep,levIndex,horizonalGridType)
    yvar = selField(yvarname,File,timeStep,levIndex,horizonalGridType)
    scaleVar(xvar,scaleFactor)
    scaleVar(yvar,scaleFactor)
    if ( useMask ) then
      xvar = mask(xvar,maskVar,1)
      yvar = mask(yvar,maskVar,1)
    end if
  end if
  if (plotMode.eq."section") then; section mode ================================
    print(rFile)
    var = selRegularVar(varName,rFile,timeStep)
    if(.not. isvar("minVar")) minVar = min(var) end if
    if(.not. isvar("maxVar")) maxVar = max(var) end if
    checkMinMaxVar(minVar,maxVar)
    ; masking before computing the cross section
    if ( useMask ) then
      ; set variable var to missing, where var is not equal mvalue (3rd
      ; parameter)
      var = mask(var,maskVar,1)
    end if
  end if ; Reading data variables =============================================
  if (plotMode .eq. "hoffmueller") then ; create hoffmuelle diagram
    ; select the whole time series
    ; and plot it with
    ; plot = gsn_csm_lat_time(wks, shov(0,{-80:80},:), res)
  end if
  if (iType .eq. "atm" .and. ivarname .eq. "T" .and. k2c) var = var - 273.15 end if ;atmosphere used to write out Kelvin

  ;---------------------------------------------------------------
  ; make the plot
  ;---------------------------------------------------------------
  ; preparations
  wks = gsn_open_wks(oType,oFile)

  gsn_define_colormap(wks,colormap)

  if (showNdc)
    drawNDCGrid(wks)
  end if

  ResC = True

  setDefaultResource(ResC,True)

  if (maxView) ResC@gsnMaximize = True end if

  if (useMask) setMaskColor(wks,ResC) end if



  if (getHorizGridType(iFile,ivarname,isIcon) .eq. "unstructured") then
    if (plotMode.eq."scalar" .or. plotMode.eq."overlay")
      setCoordinates(ResC,x,y)
      ;setBounds(ResC,File,x,y,DEBUG)
    end if
  end if

  if (plotMode.eq."vector") then
    setAutomaticPlotCaptions(ResC,plotMode,vecVars(0),File,iFile,timeStep,levIndex,iType,atmLev,k2c)
  else
    setAutomaticPlotCaptions(ResC,plotMode,varName,File,iFile,timeStep,levIndex,iType,atmLev,k2c)
  end if

  if (plotMode.eq."section") then
    if ( ismissing(getVertDim(File,var)) ) then
      print("Cannot plot vertical section of a 2D variable: "+varName)
      exit
    end if
    trans           = setSection(secLC,secRC,secPoints,var)
    vertdim         = getVertDim(File,var)
    trans!0         = vertdim
    trans&$vertdim$ = var&$vertdim$
  end if

  setAutomaticBaseString(wks,plotMode)

  setLevels(selMode,ResC,minVar,maxVar,scaleLimit,numLevs,DEBUG)

  setMapType(ResC,mapType,centerLon,centerLat,satDist)

  selMapCut(ResC,mapLLC,mapURC)

  setMapVisibility(ResC,mapLine)

  if (DEBUG) showMapInfo(ResC,mapType,mapLine) end if

  ; MAIN PLOT CALLS ===========================================================
  if (plotMode .eq. "vector") then ; vector plot ==============================
    if (showGrid) then
      print("#= WARNING =============================================")
      print("Display Vectors and the underlying grid is not usefull, ")
      print("because original data is interpolated to a regular grid for vector representation.")
      print(ABORTMSG)
      exit
    else
      setDefaultVectorPlot(ResC,5.0,vecRefLength,"CurlyVector",vecMinDist)

      vc = plotVecOrStream(vecColByLen,streamLine,uvar,vvar,velocity,ResC,wks,True)
    end if
  end if
  if (plotMode.eq."overlay") then
   ;reset the second resource
    ResC2                    = ResC
    setDefaultOverlayResource(ResC2)
    setPlotCaptions(ResC2,"","","","")
    selMapCut(ResC2,mapLLC,mapURC)
    setDefaultVectorPlot(ResC2,5.0,vecRefLength,"CurlyVector",vecMinDist)

    ResC@gsnDraw             = False
    ResC@gsnFrame            = False
    vc   = plotVecOrStream(vecColByLen,streamLine,uvar,vvar,velocity,ResC2,wks,False)

    plot = gsn_csm_contour_map(wks,var,ResC)
    if (showGrid) then
      print("plotting GRID in overlay mode is not supported")
      exit
    end if

    overlay(plot,vc)
    draw(plot)
  end if
  if (plotMode.eq."scalar") then
    if (DEBUG .and. horizonalGridType.eq."unstructured") print("Gridtype is "+getGridType(var)) end if
    plot = gsn_csm_contour_map(wks,var,ResC)

    if (showGrid) then
      if ( horizonalGridType .ne. "unstructured") then
        print("#=====================================================================")
        print("Grid representation is only implemented for the unstructured ICON grid")
        exit
      end if
      plotGrid(wks,plot,var,x,bounds,File,ResC,DEBUG)
    end if
  end if
  if (plotMode.eq."scatter") then
    plot = gsn_csm_xy(wks,xvar,yvar,ResC)
  end if
  if (plotMode.eq."section") then

    if (showSecMap) then
      plot = new(2,graphic)
    else
      plot = new(1,graphic)
    end if
    points   = ispan(0,secPoints-1,1)*1.0

    res  = setDefaultSectionResource(points,secPoints,secLC,secRC)
    setAutomaticPlotCaptions(res,plotMode,varName,File,iFile,timeStep,levIndex,iType,atmLev,k2c)
    setLevels(selMode,res,minVar,maxVar,scaleLimit,numLevs,DEBUG)
    setSectionVertLabel(res,iType,atmLev)

   if (showSecMap) then
     shift4SecMap(res)
   end if

   plot(0) = gsn_csm_contour(wks,trans,res);   create plot
   draw(plot(0))

   if (showSecMap) then
     ; map with section polygon
     mres                  = True
     mres@gsnFrame         = False;                don't turn page yet
     mres@gsnDraw          = False;                don't draw yet
     mres@vpWidthF         = 0.8;          set width of plot
     mres@vpHeightF        = 0.3;          set height of plot
     mres@vpXF             = 0.1
     mres@vpYF             = 0.4
     plot(1)               = gsn_csm_map_ce(wks,mres)
     pres                  = True;            polyline mods desired
     pres@gsnFrame         = False;                don't turn page yet
     pres@gsnDraw          = False;                don't draw yet
     pres@gsLineColor      = "black";           color of lines
     pres@gsLineThicknessF = 2.0;             line thickness
     dummy = gsn_add_polyline(wks,plot(1),(/ secLC(0),secRC(0) /),(/ secLC(1),secRC(1) /),pres)

     draw(plot(1))
   end if
  end if

  if (DEBUG) print(ResC) end if

  frame(wks)
;
; vim:list