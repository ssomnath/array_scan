#pragma rtGlobals=1		// Use modern global access method.

// This should be sitting in UserCalculated.ipf
Function Vcant(RowIndex, ColIndex)
	Variable RowIndex, ColIndex
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder("root:Packages:MFP3D:Main:")
	
	Wave VsenseWave = UserIn0Wave
	// For now use a BNC splitter and pipe in the total voltage into User In 1
	Wave VoutWave = UserIn1Wave
	
	Variable vtot = VoutWave[RowIndex][ColIndex]
	Variable vsense = VsenseWave[RowIndex][ColIndex]
	Variable vcant = vtot - vsense
	
	SetDataFolder root:packages:TemperatureControl
	NVAR gRsense
	
	// Can let a meter piggy back on this function.
	// Meter would require that Vtot be one of the acquired channels
	
	SetDataFolder root:packages:TemperatureControl:Meter
	NVAR GRcant,  GIcant, GPcant, GVcant
	
	if(Vcant != NaN)
	GVcant = Vcant//V
	GIcant = vsense/ gRsense // in mA
	GPcant = vcant * GIcant // in mW
	GRcant =vcant / GIcant // in k Ohms
	endif
	
	//Performing any control stuff here completely hangs Igor
	// DO NOT do anything else here	
		
	SetDataFolder(SavedDataFolder)
	// The whole point of this is to calculate a single V cant channel after all:
	return Vcant
End

// This should be sitting in UserCalculated.ipf
Function Vcant2(RowIndex, ColIndex)
	Variable RowIndex, ColIndex
	
	String SavedDataFolder = GetDataFolder(1)
	SetDataFolder("root:Packages:MFP3D:Main:")
	
	Wave VsenseWave = UserIn0Wave
	// For now use a BNC splitter and pipe in the total voltage into User In 1
	Wave VoutWave = UserIn1Wave
	
	SetDataFolder root:packages:MFPTempCont
	NVAR gRsense
	// Can let a meter piggy back on this function.
	// Meter would require that Vcant be one of the acquired channels
		
	Variable vtot = VoutWave[RowIndex][ColIndex]
	Variable vsense = VsenseWave[RowIndex][ColIndex]
	Variable vcant = vtot - vsense
	
	SetDataFolder root:packages:TempCont:Meter
	NVAR GRcant,  GIcant, GPcant, GVcant
	
	GVcant = vcant
	GIcant = vsense/ gRsense // in mA
	GPcant = vcant * GIcant // in mW
	GRcant = vcant / GIcant // in k Ohms
		
	SetDataFolder(SavedDataFolder)
	// The whole point of this is to calculate a single V cant channel after all:
	return Vcant
End

Function SingleChannelDisplay(RowIndex,ColIndex)
	
	Variable RowIndex, ColIndex
		
	Wave myinput = root:packages:ArrayScan:Wave0
	
	return myinput[RowIndex][ColIndex]

End // End function SingleChannel

//CAUTION: DO NOT MODIFY!
Function NIDAQRealTimeDisplay(RowIndex,ColIndex)
	
	Variable RowIndex, ColIndex
		
	return -1//UserCalcInterface(RowIndex,ColIndex)

End // End function ArrayUserCalc

Function ArrayMUX(RowIndex,ColIndex)
	
	Variable RowIndex, ColIndex
	// row index is actually the pixel index here
		
	return 1//CantStepAtLine(RowIndex,ColIndex)

End // End function 