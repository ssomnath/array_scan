#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveScanProcs>

// Notes to self:
// The user calculated function can be derived from :
// GetUserCalculatedFuncList()
// Use the code from the ThermalImaging window setup function for tips
// Updating the name will update the rest of the details automatically in the following function
// Name: UserChannelNameFunc("UserCalcName_0",NaN,"Vcant",GlobalStrings[%UserCalcName][%Value])


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




//Simplest version of a scan using the DAQ
//Requires an external function generator
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
	
	NewDataFolder/O/S root:Packages:ArrayScan
	
	Make/O/N=(SampleNum,ScanLines) Wave0, Wave1// /O overwrites existing waves
	SetScale/P x, 0,SampleTime, "s", Wave0, Wave1
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0; Wave1, 1;";AbortOnRTE
	
End //TwoChannelScan end