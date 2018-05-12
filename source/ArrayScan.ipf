#pragma rtGlobals=1		// Use modern global access method.
#include <NIDAQmxWaveScanProcs>

// Notes to self:
// The user calculated function can be derived from :
// GetUserCalculatedFuncList()
// Use the code from the ThermalImaging window setup function for tips
// Updating the name will update the rest of the details automatically in the following function
// Name: UserChannelNameFunc("UserCalcName_0",NaN,"Vcant",GlobalStrings[%UserCalcName][%Value])

function My2DArray()
	Variable xx = 0
	Variable yy = 0
	Make/O /N=(3,3) /D mydata
	for(xx=0;xx<3;xx = xx+1)
		for(yy=0;yy<3;yy= yy+1)	
			mydata[xx][yy] = xx + yy
		endfor							
	endfor	
	Display mydata
end //End My2DArray






//Simplest version of a scan using the DAQ
//Requires an external function generator
Function MyScan_v1()

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
// Modification of v1: Instead of a 100 long wave, a 10 by 10 wave
// is chosen. The data was noted to be still being acquired
// filling COLUMNWISE contrary to common knowledge
Function MyScan_v3()

	Variable errorCode
	
	Wave scanmastervariables = root:Packages:MFP3D:Main:Variables:MasterVariablesWave
	
	Variable scanpoints = scanmastervariables[7]
	//Print ScanPoints
	Variable scanlines = scanmastervariables[8]
	//Print ScanLines
	Variable scanrate = scanmastervariables[3]
	//Print ScanRate
	
	Variable SampleTime = 1/(ScanRate*2.5*ScanPoints)
	print sampleTime
	Variable SampleNum	= 2.5*ScanPoints
	NewDataFolder/O/S root:Packages:ArrayScan
	Make/O/N=(SampleNum,ScanLines) Wave0// /O overwrites existing waves
	//SetScale/P x, 0,0.01, "s", Wave0 
	SetScale/P x, 0,SampleTime, "s", Wave0 
		
	DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0;";AbortOnRTE

	
	Display Wave0
	
End //MyScan_v3 end




// Execute body code until continue test is FALSE
// More robust scan mode using the protective try-catch block
Function MyScan_v2()

	Variable errorCode
	
	Make/O/N=100 Wave0// /O overwrites existing waves
	SetScale/P x, 0,0.1, "s", Wave0 
		
	try
		DAQmx_Scan/DEV="Dev1"/BKG WAVES="Wave0, 0;";AbortOnRTE
		errorCode = fDAQmx_ScanWait("device");AbortOnValue errorcode!=0, 1
		
	catch
	
		//if (V_AbortCode == -4)
			//print "Error starting scanning operation"
			//Variable dummy=GetRTError(1) // to clear the error condition
			
		//elseif (V_AbortCode == 1)
			//print "Error executing fDAQmx_ScanWait"
			
		//endif
		
		print fDAQmx_ErrorString()
		
	endtry
	
	Display Wave0
	
End //MyScan_v2 end