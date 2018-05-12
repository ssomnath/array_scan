#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveScanProcs>

// Pending tasks:
// Top Priority:
// 1. Save cleaned data into clean waves
// 2. Create UI
// 3. Figure out when a new wave needs to be created for next frame (regular / frame up / down)

// Second Priority
// 1. Learn how to get some data into an existing ibw file. 
// 2. Get the data into an ibw file.

// Tips:
// MakePAnel("ARHack")

// Saving subsequent images:
// Make /N=(wavesize) wave0
// Duplicate/O wave0, $("Y"+name), $("X"+name)
//Wave Ywave = $("Y"+name)
//	killwaves wave0

Function setupARCallbackHacks()
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

End // End function TwoChannelDisplayA