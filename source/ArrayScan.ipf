#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveScanProcs>

// Pending tasks:
// Top Priority:
// 1. Save cleaned data into clean waves
// 2. Create UI
////// I am assuming that the DAQ will automatically REUSE the raw waves.
// 3. Learn how to switch and reuse waves
// 4. Lookup how to write to files from SmartLitho

// Low Priority
// 1. Learn how to get some data into an existing ibw file. 
// 2. Get the data into an ibw file.

// Tips:
// MakePAnel("ARHack")

Function savePatternToDisk(ctrlname) : ButtonControl
	String ctrlname
	//String oldSaveFolder = GetDataFolder(1)
	// Grabbing the current Lithos that are being displayed to the user
	//setdatafolder root:packages:MFP3D:Litho
	
	//Also writing the length of the waves to make it easy to read
	//Make /O /N=1 wavelength
	//wavelength[0] = numpnts(XLitho)
	
	// O - overwrite ok, J - tab limted, W - save wave name, I - provides dialog
	//Save /O/J/W/I XLitho,YLitho,wavelength
	
	//killwaves wavelength
	//setdatafolder oldSaveFolder
End //SaveWavesToDisk



Function ArrayScan()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F ArrayScanPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:ArrayScan
	
	String basename = StrVarOrDefault(":gBaseName","Image_");
	String/G gBaseName = basename
	
	Variable baseSuffix = NumVarOrDefault(":gBaseSuffix",0);
	Variable/G gBaseSuffix = baseSuffix
	
	Variable avging = NumVarOrDefault(":gAveraging",1)
	Variable/G gAveraging = avging
	
	Variable displayCant = NumVarOrDefault(":gDisplayCant",1)
	Variable/G gDisplayCant = displayCant
	
	// Create the control panel.
	Execute "ArrayScanPanel()"
	//Reset the datafolder to the root / previous folder
	SetDataFolder dfSave

End


Window ArrayScanPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 667,473) as "Array Scan Panel"
	SetDrawLayer UserBack
	
	SetVariable sv_ImageBaseName,pos={27,42},size={115,25},title="Base Name"
	SetVariable sv_ImageBaseName, value=root:Packages:ArrayScan:gBaseName	
	
	SetVariable sv_ImageOffset,pos={27,67},size={115,25},title="Base Suffix", limits={0,100,1}
	SetVariable sv_ImageOffset,value=root:Packages:ArrayScan:gBaseSuffix	

	SetVariable sv_Averaging,pos={27,94},size={115,25},title="Averaging", limits={0,100,1}
	SetVariable sv_Averaging, value=root:Packages:ArrayScan:gAveraging
	
	SetVariable sv_DisplayCant,pos={27,121},size={115,25},title="Display Cantilever", limits={1,5,1}
	SetVariable sv_DisplayCant, value=root:Packages:ArrayScan:gDisplayCant

	//SetDrawEnv fsize= 13; SetDrawEnv fstyle= 4; DrawText 68,249, "Heating:"
	//Button but_start,pos={24,259},size={49,20},title="Start", fstyle=1, proc=startImaging
	//Button but_stop,pos={113,259},size={49,20},title="Stop", fstyle=1, proc=StopPID
		
	//ValDisplay vd_statusLED, value=str2num(root:packages:MFP3D:Main:PIDSLoop[%Status][5])
	//ValDisplay vd_statusLED, mode=2, limits={-1,1,0}, highColor= (0,65280,0), zeroColor= (65280,65280,16384)
	//ValDisplay vd_statusLED, lowColor= (65280,0,0), pos={87,262},size={15,15}, bodyWidth=15, barmisc={0,0}
		
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 14, 308, "Suhas Somnath, UIUC 2011"
End	


Function setupARCallbackHacks()

	// MakePanelProc("ARCallbackPanelButton_1")
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	ARCheckFunc("ARUserCallbackImageScanCheck_1",1)
	ARCheckFunc("ARUserCallbackImageDoneCheck_1",1)
	
	ARCallbackSetVarFunc("ARUserCallbackImageDoneSetVar_1",NaN,"ScanTerminateCallback","GeneralVariablesDescription[%ARUserCallbackImageDone][%Description]")
	ARCallbackSetVarFunc("ARUserCallbackImageScanSetVar_1",NaN,"ScanCompleteCallback","GeneralVariablesDescription[%ARUserCallbackImageScan][%Description]")
End

Function cleanupARHacks()
	ARCheckFunc("ARUserCallbackMasterCheck_1",0)
	ARCheckFunc("ARUserCallbackImageScanCheck_1",0)
	ARCheckFunc("ARUserCallbackImageDoneCheck_1",0)
End

Function ScanTerminateCallback()
	print "Last scan completed"
End

Function ScanCompleteCallback()
	print "Scan completed. Moving to next scan"
End

Function TwoChannelScan()

	Variable errorCode
	
	Wave scanmastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	
	Variable scanpoints = scanmastervariables[7]
	Variable scanlines = scanmastervariables[8]
	Variable scanrate = scanmastervariables[3]
	
	Variable SampleTime = 1/(ScanRate*2.5*ScanPoints)
	Variable SampleNum	= 2.5*ScanPoints
	
	String dfSave = getDataFolder(1)
	
	NewDataFolder/O/S root:Packages:ArrayScan
	
	// Don't know how necessary this is. But Killing waves might enable
	// scanning with (newly) reduced scan sizes
	//killWaves Wave0, Wave1
	
	Make/O/N=(SampleNum,ScanLines) Wave0, Wave1// /O overwrites existing waves
	//Make/O/N=(scanpoints,scanlines,2) Clean0, Clean1// Space to save the retrace and the trace
	
	SetScale/P x, 0,SampleTime, "s", Wave0, Wave1
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0; Wave1, 1;";AbortOnRTE
	
	SetDataFolder dfSave;
	
End //TwoChannelScan end

Function HackRealTimeNamePanel()
	// Notes to self:
// The user calculated function can be derived from :
// 
	Variable popnum = WhichListItem("ArrayUserCalc", GetUserCalculatedFuncList())

	if(popnum < 0)
		// Such a function does not exist or is already chosen?
		DoAlert 0, "ArrayUserCalc funciton not found in UserCalculated.ipf";
		return -1;
	endif
	
	// Select ArrayUserCalc:
	ChannelPopFunc("UserCalcFuncPop_0",PopNum+1,"ArrayUserCalc")
	
	//Set the Units to Volts:
	SetChannelUnitSetVarFunc("UserCalcUnitSetVar_0",NaN,"V","GlobalStrings[%UserCalcUnit][%Value]")
	
	//Give this a Name
	UserChannelNameFunc("UserCalcName_0",NaN,"Array","GlobalStrings[%UserCalcName][%Value]")
	
	//Now set up the UserCalcWindow
	popnum = WhichListItem("Array", DataTypeFunc(5))
	if(popnum < 0)
		// Array already being displayed
		// dont bother
		return -1
	endif
	SetDataTypePopupFunc("Channel5DataTypePopup_5",popNum,"Array") // sets the channel acquired into the graph:
	SetPlanefitPopupFunc("Channel5RealPlanefitPopup_5",4,"Masked Line") // for the live flatten
	SetPlanefitPopupFunc("Channel5SavePlanefitPopup_5",4,"Flatten 0") // for the save flatten
	//ShowWhatPopupFunc("Channel5CapturePopup_5",4,"Both")

End

// Thus function will be called by the UserCalculated.ipf function
// Gives a little more freedom in portability of the data filtering code
Function UserCalcInterface(RowIndex,ColIndex)
	
	Variable RowIndex, ColIndex
	
	//Here we can grab the important data from the raw waves 
	// and place it in the waves
	// One obvious problem is how the subsequent frames are going to be stored
	// Need to think about using Wave handles and indices and naming waves on the go
	
	String dfSave = getDataFolder(1)
	
	SetDataFolder root:Packages:ArrayScan
		
	Wave Wave0, Wave1
	
	// Currently not saving the truncated data in any new waves
	
	Variable retValue = Wave1[RowIndex][ColIndex]
	
	SetDataFolder dfSave;
	
	return retValue

End // End function UserCalcInterface

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////// ANCILLARY FUNCTIONS   /////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function TransfertoNewWaves(newname)
	String NewName
	
	Wave mydata
	Duplicate/O mydata, $(newname)
	killwaves mydata
End

function My2DArray()
	Variable xx = 0
	Variable yy = 0
	Make/O /N=(3,3) /D mydata
	for(xx=0;xx<3;xx = xx+1)
		for(yy=0;yy<3;yy= yy+1)	
			mydata[xx][yy] = xx + yy
		endfor							
	endfor	
end

//Simplest version of a scan using the DAQ
//Requires an external function generator
Function DAQTestScan()

	Variable errorCode
	
	Make/O/N=1000 Wave0// /O overwrites existing waves
	SetScale/P x, 0,0.001, "s", Wave0 
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0;";AbortOnRTE

	// keep this sting ready in the command window:
	//fDAQmx_ScanStop("Dev1")
	
	Display Wave0
	
End //MyScan end


//Single Channel Scan setup
Function SingleChannelScan()

	Variable errorCode
	
	Wave scanmastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	
	Variable scanpoints = scanmastervariables[7]
	//Print ScanPoints
	Variable scanlines = scanmastervariables[8]
	//Print ScanLines
	Variable scanrate = scanmastervariables[3]
	//Print ScanRate
	
	Variable SampleTime = 1/(ScanRate*2.5*ScanPoints)
	//print sampleTime
	Variable SampleNum	= 2.5*ScanPoints
	NewDataFolder/O/S root:Packages:ArrayScan
	Make/O/N=(SampleNum,ScanLines) Wave0// /O overwrites existing waves
	//SetScale/P x, 0,0.01, "s", Wave0 
	SetScale/P x, 0,SampleTime, "s", Wave0 
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0;";AbortOnRTE
	
	//Display Wave0
	
End //SingleChannelScan end

Function insertDataIntoIBW()
	// 1. Cause a click in "Extract Layer"
	// Do the following 5 times
	//	a. Copy data into root:Images:LayerData (use code from SmartLitho)
	//	b. Cause a click on the "Do It" button in the Insert layer menu.
	
	String dfSave = getDataFolder(1)
	
	//ExtractLayer();
	
	SetDataFolder root:Packages:ArrayScan
	Wave Wave1
	
	SetDataFolder root:Images
	
	//Replace LayerData with Wave1
	Duplicate/O Wave1, LayerData
	
	//Insert the layer:
	InsertLayerButtonProc("blah")
	//InsertLayerChoose()
	
	SetDataFolder dfSave
End