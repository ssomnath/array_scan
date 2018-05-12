#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveScanProcs>

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////// VERSION LOG ////////////////////////////////////////////////////////////////////////////////

//-----version 2.1---------
// Cosmetic cleanup + comments + minor code upgrades
// variable number of channels
// Renamed name of panel. Affects Array Interfacer in ScanMaster
// Renamed instances of cantilever and array to DAQ specific
// Handed over to Juan for further improvements

//-----version 2.0---------
// Realtime display shows averaging
// Manual averaging of data offline (txt files) is required

//------version 1.9---------
// Optimized the callbacks and in-line calls
// Subsequent scans now being saved successfully
// Scan window does NOT show subsequent scan details unfortunately.
// ARCallbacks and Usercalculated automatically called on panel display.

//-------version 1.8---------
// Replaced the in-line scan end codes in scanmaster with image end callbacks.
// Still don't have a solution for subsequent scans or Stopped scans.

//-------version 1.7---------
// Took care of the data writing bug.
// Stable release. 
// Allows ONE scan only

//------- version 1.6---------
// allows five channels of information to be read from the DAQ
// has a GUI 
// well integrated with the Scan routines to start and stop the data acquisition along with the scans
// time lag between the DAQ data acquisition and the scan start has been eliminated.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////// PENDING TASKS   /////////////////////////////////////////////////////////////////////// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Top Priority:
// -------------------
// 1. Realtime window doesn't display after first scan. Data is still being saved just fine
// 2. If oversampling, write DECIMATED data to file
// 3. Check scan - DAQ acquisition timing. seems a bit off now. was fine before

// Medium Priority:
// -------------------
// 1. For safety, disable the Number of channels from being edited whie scanning
// 2. Display channel index must always <= number of channels to prevent outofBounds exception
// 3. Not tested for usecase of user not wanting to acquire data using DAQ. Should not be a problem since data
//	is probably acquired only if the Array Scan Panel is opened.

// Low Priority
// -------------------
// 1. Can provide a 16 row long list of channel configs for user: 1) DAQ port to which cable is connected, 2) Custom name for channel


// Tips:
// MakePanel("ARHack")

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Menu "UIUC"
	"NI DAQ Acquisition", NIDAQScanDriver()
End

Function NIDAQScanDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F NIDAQacqPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:NIDAQacq
	
	String pathname = StrVarOrDefault(":gPathName","C:Documents and Settings:somnath2:Desktop:RealTimeDataCapture:");
	String/G gPathName = pathname
	
	String basename = StrVarOrDefault(":gBaseName","Image");
	String/G gBaseName = basename
	
	Variable baseSuffix = NumVarOrDefault(":gBaseSuffix",0);
	Variable/G gBaseSuffix = baseSuffix
	
	Variable avging = NumVarOrDefault(":gAveraging",1)
	Variable/G gAveraging = avging
	
	Variable displayChan = NumVarOrDefault(":gDisplayChan",1)
	Variable/G gDisplayChan = displayChan
	
	Variable numChans = NumVarOrDefault(":gnumChans",5)
	Variable/G gnumChans = numChans
	
	setupARCallbackHacks()
	HackRealTimeNamePanel()
	
	DoAlert 0, "Uncomment relavent code in UserCalculated function: NIDAQRealTimeDisplay"
	
	DoAlert 0, "Make sure DAQ is plugged in"
	
	Execute "NIDAQacqPanel()"
	
	SetDataFolder dfSave
End

Window NIDAQacqPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 675,385) as "NI DAQ Acquisition"
	SetDrawLayer UserBack
	
	SetVariable sv_PathName,pos={17,14},size={160,25},title="File Path"
	SetVariable sv_PathName, value=root:Packages:NIDAQacq:gPathName	
	
	SetVariable sv_ImageBaseName,pos={17,46},size={160,25},title="Base Name"
	SetVariable sv_ImageBaseName, value=root:Packages:NIDAQacq:gBaseName	
	
	SetVariable sv_ImageOffset,pos={17,78},size={115,25},title="Base Suffix", limits={0,100,1}
	SetVariable sv_ImageOffset,value=root:Packages:NIDAQacq:gBaseSuffix
	
	SetVariable sv_numChans,pos={17,110},size={151,25},title="Number of Channels", limits={1,16,1}
	SetVariable sv_numChans, value=root:Packages:NIDAQacq:gNumChans
	
	SetVariable sv_DisplayChan,pos={17,143},size={151,25},title="Display Channel", limits={1,5,1}
	SetVariable sv_DisplayChan, value=root:Packages:NIDAQacq:gDisplayChan

	SetVariable sv_Averaging,pos={17,176},size={115,25},title="Averaging", limits={0,100,1}
	SetVariable sv_Averaging, value=root:Packages:NIDAQacq:gAveraging
	
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 16, 232, "Suhas Somnath, UIUC 2010"
End	

// These function calls allow our functions to be called upon an event / trigger - such as start of next scan, end of scan, etc.
// DONT touch these
Function setupARCallbackHacks()

	// MakePanelProc("ARCallbackPanelButton_1")
	
	ARCheckFunc("ARUserCallbackMasterCheck_1",1)
	//ARCheckFunc("ARUserCallbackImageGoCheck_1",1)
	ARCheckFunc("ARUserCallbackImageScanCheck_1",1)
	ARCheckFunc("ARUserCallbackImageDoneCheck_1",1)
	
	//ARCallbackSetVarFunc("ARUserCallbackImageGoSetVar_1",NaN,"StartDataAcquisition","GeneralVariablesDescription[%ARUserCallbackImageGo][%Description]")//IMAGE start
	ARCallbackSetVarFunc("ARUserCallbackImageScanSetVar_1",NaN,"ContinueScanning","GeneralVariablesDescription[%ARUserCallbackImageScan][%Description]")//Scan finish
	ARCallbackSetVarFunc("ARUserCallbackImageDoneSetVar_1",NaN,"StopAcquiringData","GeneralVariablesDescription[%ARUserCallbackImageDone][%Description]")//LastScan
End

// Here we stop asking our functions from being executed upon previously requested triggers.
// DONT touch these
Function cleanupARHacks()
	ARCheckFunc("ARUserCallbackMasterCheck_1",0)
	//ARCheckFunc("ARUserCallbackImageGoCheck_1",0)
	ARCheckFunc("ARUserCallbackImageScanCheck_1",0)
	ARCheckFunc("ARUserCallbackImageDoneCheck_1",0)
End

// No modification necessary here
Function ContinueScanning()
	WriteDataToFile()
	//print "files written! going to restart acquisition"
	restartAcquisition()
	
	//fDAQmx_ScanStop("Dev1")
	//StartDataAcquisition()
End

// Called for each subsequent frame of the scan
Function restartAcquisition()
	// Try restarting DAQ scan now
	// Scanning is supposed to be continuous so theoretically this is the right place
	// Matching accuracy or latency unknown / untested
	
	fDAQmx_ScanStop("Dev1")
	// StartDataAcquisition()
	//print "fDAQmx_ScanStop called"
	
	
	StartAcquiringData()
	

	print "End of RestartAcquisition() END of CALLBACK"
End

// No modification necessary here
Function StopAcquiringData()
	// Only after last scan.
	//print "DAQmx stopped acquiring data -> Last scan"
	fDAQmx_ScanStop("Dev1")
	WriteDataToFile()
End

Function StartAcquiringData()
	
	String dfSave = getDataFolder(1)
	SetDataFolder root:Packages:NIDAQacq
	
	NVAR gnumChans
	
	SetDataFolder dfSave;
	
	String waveAssignments = "";
	
	//Variable numWaves=5; // Replace with global: gNumChans
	Variable i;
	
	for(i=0;i<gnumChans;i=i+1)
		waveAssignments = waveAssignments+"RawChan"+num2str(i)+", " + num2str(i)+";";
	endfor
	
	// waveAssignments = "RawChan0, 0; RawChan1, 1;RawChan2, 2; RawChan3, 3;RawChan4, 4;"
	
	// This is the main DAQ command that starts a fresh data acquistion. 
	// DAQmx_Scan/Dev="device number - 1 for our case since we only use one DAQ
	// BKG WAVES = "WaveName, DAQchannelNumber;.......
	print "StartAcquiringData() called"
	//DAQmx_Scan/DEV="Dev1"/BKG WAVES="RawChan0, 0; RawChan1, 1;";AbortOnRTE
	DAQmx_Scan/DEV="Dev1"/BKG WAVES=waveAssignments;AbortOnRTE
	print "DAQmx_Scan called"

End

Function StartDataAcquisition()

	Variable errorCode
	
	Wave scanmastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	
	Variable scanpoints = scanmastervariables[7]
	Variable scanlines = scanmastervariables[8]
	Variable scanrate = scanmastervariables[3]
	
	String dfSave = getDataFolder(1)
	
	SetDataFolder root:Packages:NIDAQacq
	NVAR gAveraging, gnumChans
	
	if(gAveraging > 100 || gAveraging < 0)
		gAveraging = 1;
	endif;
	
	Variable SampleTime = 1/(ScanRate*2.5*ScanPoints*gAveraging)
	// When Averaging is enabled, the sampleNum will be multiplied by that.
	Variable SampleNum	= 2.5*ScanPoints*gAveraging
	
	//Make/O/N=(SampleNum,ScanLines) RawChan0, RawChan1, RawChan2, RawChan3, RawChan4
	//SetScale/P x, 0,SampleTime, "s", RawChan0, RawChan1, RawChan2, RawChan3, RawChan4
	
	Variable i;
	for(i=0;i<gnumChans;i=i+1)
		Make/O/N=(SampleNum,ScanLines) $("RawChan"+num2str(i));
		SetScale/P x, 0,SampleTime, "s", $("RawChan"+num2str(i));
	endfor
	
	StartAcquiringData()
		
	//print "DAQmx Data acquisition started"
	
	SetDataFolder dfSave;
	
End



// This function will be called by the UserCalculated.ipf function
// Gives a little more freedom in portability of the data filtering code
// Do minimal work in this function
Function UserCalcInterface(RowIndex,ColIndex)
	
	Variable RowIndex, ColIndex
		
	String dfSave = getDataFolder(1)
	
	SetDataFolder root:Packages:NIDAQacq
	NVAR gDisplayChan, gAveraging, gnumChans
	
	// Very ineligant: 
	// This should run only once per user change in either variables not once per pixel
	// Use a function for the setvars to ensure that the display channel will always be < gNumChans
	gDisplayChan = min(gDisplayChan,gnumChans);
	
	Wave chosenChan= $("RawChan"+num2str(gDisplayChan-1))
	
	// Average here:
	// This is slow because it has to be done in realtime
	// Perhaps realtime display can be disabled when not required.
	Variable i=0;
	Variable total = 0;
	for(i=gAveraging*Rowindex; i<gAveraging*(RowIndex+1); i=i+1)
		total = total + chosenChan[i][ColIndex]
	endfor
	
	Variable retValue = total/gAveraging
	
	SetDataFolder dfSave;
	
	return retValue;//chosenChan[Rowindex][ColIndex]

End // End function UserCalcInterface


// This function sets up the software to display one channel of information in realtime
Function HackRealTimeNamePanel()

	Variable popnum = WhichListItem("NIDAQRealTimeDisplay", GetUserCalculatedFuncList())

	if(popnum < 0)
		// Such a function does not exist or is already chosen?
		DoAlert 0, "NIDAQRealTimeDisplay funciton not found in UserCalculated.ipf";
		return -1;
	endif
	
	// Select NIDAQRealTimeDisplay:
	ChannelPopFunc("UserCalcFuncPop_0",PopNum+1,"NIDAQRealTimeDisplay")
	
	UserChannelNameFunc("UserCalcName_0",NaN,"NIDAQ","GlobalStrings[%UserCalcName][%Value]")
	
	//Set the Units to Volts:
	PS(ARConvertVarName2ParmName("GlobalStrings[%UserCalcUnit][%Value]"),"V")
		
	//Now set up the UserCalcWindow
	setUpNIDAQacqWindow()
	
	// Was annoying and popped up each time
	KillWindow RealTimeNamePanel

End

// This function sets up the actual window that will be used to dispaly the data
Function setUpNIDAQacqWindow()

	Variable chanIndx = 1;
	Variable freeChan = 6;
	for(chanIndx =1; chanIndx<6; chanIndx=chanIndx+1)
		if( WhichListItem("NIDAQ", DataTypeFunc(chanindx))==0)
			//print "Channel for NIDAQ found on channel number " + num2str(chanindx)
			break;
		elseif( WhichListItem("Off", DataTypeFunc(chanindx))==0)
			//print "NIDAQ not set up but Channel #" + num2str(chanindx) + " is available"
			freeChan = min(freeChan, chanIndx)
		endif
	Endfor
	// Case 1 - NIDAQ already present. chanIndx already set. Don't do anything now
	
	if(chanIndx > 5)
		// Case 2 - Userin0 NOT already present but empty channel available
		if(freeChan < 5)
			chanIndx = freeChan
		else
		// Case 3 - NIDAQ NOT present and all channels taken. FORCE last channel with message (Unlikely)
			chanIndx = 5;
			DoAlert 0,"No empty channels found\nOverriding Channel 5 to display NIDAQ"
		endif
	endif
	
	// By now, a channel has been decided for NIDAQ. Just configure it.
	Variable popnum = WhichListItem("NIDAQ", DataTypeFunc(5))
	
	SetDataTypePopupFunc("Channel" + num2str(chanIndx) + "DataTypePopup_" + num2str(chanIndx) ,popNum,"NIDAQ") // sets the channel acquired into the graph:
	SetPlanefitPopupFunc("Channel" + num2str(chanIndx) + "RealPlanefitPopup_" + num2str(chanIndx),4,"Masked Line") // for the live flatten
	SetPlanefitPopupFunc("Channel" + num2str(chanIndx) + "SavePlanefitPopup_" + num2str(chanIndx),1,"None") // for the save flatten
	ShowWhatPopupFunc("Channel" + num2str(chanIndx) + "CapturePopup_" + num2str(chanIndx),4,"Both")
	//SetChannelColorMap("Channel" + num2str(chanIndx) + "1ColorMapPopup_" + num2str(chanIndx),29,"VioletOrangeYellow")

End

//Here we write ten files for each scan relieving the raw waves for acquiring new data.
// You need to make this dynamic such that you write as many files as the user requests.
Function WriteDataToFile()
	//print  "scan completed. Writing DAQmx data to file"
	//Call - save data
	
	// Increase the scan index
	String dfSave = getDataFolder(1)
	SetDataFolder root:Packages:NIDAQacq
	NVAR gBaseSuffix, gNumChans
	SetDataFolder dfSave;

	Variable i=0;
	
	for(i=0; i<gNumChans; i=i+1)
		WriteImageToDisk(i)	
	endfor
	
	
	gBaseSuffix = gBaseSuffix+1;

End

// This function writes each channel's trace and retrace to text files
Function WriteImageToDisk(index)
	Variable index
	
	String dfSave = GetDataFolder(1)
	SetDataFolder root:packages:NIDAQacq
	
	SVAR gBaseName, gPathName
	NVAR gBaseSuffix//, gAveraging
		
	Wave chosenChan = $("RawChan"+num2str(index))
	
	
	//1. Copy the correct contents of the raw wave into the trace and retrace waves
	Variable scanpoints = DimSize(chosenChan, 0)/(2.5)//*gAveraging);
	Variable scanlines = DimSize(chosenChan, 1)
	
	Make/O/N=(scanpoints,scanlines) Trace, Retrace
	
	Duplicate/O/R=[0.125*scanpoints,1.125*scanpoints-1]chosenChan, Trace
	Duplicate/O/R=[1.375*scanpoints,2.375*scanpoints-1] chosenChan, Retrace
		
	//2. Get the correct name of the file
	String filesuffix =""
	if(gBaseSuffix < 10)
		filesuffix = "000" + num2str(gBaseSuffix)
	else
		filesuffix = "00" + num2str(gBaseSuffix);
	endif
	String basefilename = gBaseName + "_" + filesuffix + "_C" + num2str(index+1) + "_";
		
	//3. write to file
	// It is faster to perform post processing of data offline than averaging before write.
		//Flags:
		// /C:	The folder specified by "path" is created if it does not already exist.
		// /O	Overwrites the symbolic path if it exists.
		// /Q	Suppresses printing path information in the history
		// /Z	Doesn't generate an error if the folder does not exist.
	NewPath/O/Q/C Path1, gPathName+ gBaseName + "_" + filesuffix + ":"

		// O - overwrite ok, J - tab limted
	Save /O/J/P=Path1 Trace as (basefilename + "T.txt")
	Save /O/J/P=Path1 Retrace as (basefilename + "R.txt")
	
	//4. Wipe out the old raw wave and create a fresh one in its place
		// probably is unnecessary
	Redimension /N=(0) chosenChan
	Redimension /N=(scanpoints*2.5, scanlines) chosenChan
	
	// 5. Kill the trace and retrace temporary waves:
	killwaves Trace, Retrace
	
	SetDataFolder dfSave
End 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////// ANCILLARY FUNCTIONS   /////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// This function creates a user-requested number of  waves
// It also generates a string that can be used for the DAQ setup
// Using this, it should be possible to provide:
// 1. custom names to each channel (may be of use when writing to file so that the user know what each file corresponds to)
// 2. random placement of channels (don't have to be sequantial or continuous)
// 3. any number of channels dynamically
Function VarNumWaves(numWaves)
	Variable numWaves;
	
	String waveAssignments = "";
	
	Variable i;
	for(i=0;i<numWaves;i=i+1)
		Make/O/N=(2,2) $("TestWave"+num2str(i));
		waveAssignments = waveAssignments+"TestWave"+num2str(i)+", " + num2str(i*5)+";";
		//BKG WAVES="RawChan0, 0; RawChan1, 1;RawChan2, 2; RawChan3, 3;RawChan4, 4;";AbortOnRTE
	endfor
	print waveAssignments;
	
	for(i=0;i<numWaves;i=i+1)
		Wave Temp = $("TestWave"+num2str(i));
		killwaves Temp
	endfor
End

Function CopyMyWave(newname)
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

function MakeFakeImage()
	Variable xx = 0
	Variable yy = 0
	Make/O /N=(256*2.5,256) /D RawChan4
	for(xx=0;xx<256*2.5;xx = xx+1)
		for(yy=0;yy<256;yy= yy+1)	
			RawChan4[xx][yy] = xx + yy
		endfor							
	endfor	
end

//Simplest version of a scan using the DAQ
//Requires an external function generator
Function DAQTestScan()

	Variable errorCode
	
	Make/O/N=1000 RawChan0// /O overwrites existing waves
	SetScale/P x, 0,0.001, "s", RawChan0 
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="RawChan0, 0;";AbortOnRTE

	// keep this sting ready in the command window:
	//fDAQmx_ScanStop("Dev1")
	
	Display RawChan0
	
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
	Make/O/N=(SampleNum,ScanLines) RawCant0// /O overwrites existing waves
	//SetScale/P x, 0,0.01, "s", RawCant0 
	SetScale/P x, 0,SampleTime, "s", RawCant0 
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="RawCant0, 0;";AbortOnRTE
	
	//Display RawCant0
	
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
	//killWaves RawCant0, RawCant1
	
	Make/O/N=(SampleNum,ScanLines) RawCant0, RawCant1// /O overwrites existing waves
	//Make/O/N=(scanpoints,scanlines,2) Clean0, Clean1// Space to save the retrace and the trace
	
	SetScale/P x, 0,SampleTime, "s", RawCant0, RawCant1
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="RawCant0, 0; RawCant1, 1;";AbortOnRTE
	
	SetDataFolder dfSave;
	
End //TwoChannelScan end