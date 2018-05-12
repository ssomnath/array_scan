#pragma rtGlobals=1		// Use modern global access method.

Function insertDataIntoIBW()
	// 1. Cause a click in "Extract Layer"
	// Do the following 5 times
	//	a. Copy data into root:Images:LayerData (use code from SmartLitho)
	//	b. Cause a click on the "Do It" button in the Insert layer menu.
	
	String dfSave = getDataFolder(1)
	
	ExtractLayer();
	
	SetDataFolder root:Packages:ArrayScan
	Wave cleanedWave
	
	SetDataFolder root:Images
	
	//Replace LayerData with RawCant1
	Duplicate/O cleanedWave, LayerData
	
	//KillWaves cleanedWave
	
	//Insert the layer:
	//InsertLayerButtonProc("blah")
	InsertLayerChoose()
	
	SetDataFolder dfSave
End

Function OverwriteLayer(ctrlname): ButtonControl
	String ctrlname
	LoadWaveFromDisk()
	
	String dfSave = GetDataFolder(1)
	
	SetDataFolder root:packages:MFP3D:Main:Display
	
	SVAR LastTitle
	Variable index = strsearch(LastTitle, " ", 0)
	if(index < 0)
		DoAlert 0, "No such Image!"
		return 0;
	endif
	
	String imgname = LastTitle[0,index-1]
	Variable layernum = -1
	
	String GraphName = StringFromList(0,WinList(cOfflineBaseName+"*",";","WIN:1"))	//get the name of the top graph
	if (strlen(GraphName) == 0)		//anything there?
		DoAlert 0, "No such Image!"
		return 0							//nope
	endif
	
	String DataFolder, ImageName
	GetGraphData(GraphName,DataFolder,ImageName,LayerNum)
	
	SetDataFolder dfSave
	
	FilterImage(ImageName,Layernum)

End

Function LoadWaveFromDisk()
	String oldSaveFolder = GetDataFolder(1)
	setdatafolder root:packages:ArrayScan
	Variable refNum
	String outputPath
	Open /R /Z=2 /M="Select the text file containing the litho coordinates" refNum as ""
	if(refNum == 0)
		print "No file was open!"
		//return -1
	endif
	if (V_flag == -1)
		Print "Open cancelled by user."
		return -1
	endif
	if (V_flag != 0)
		DoAlert 0, "Error Opening file"
		return V_flag
	endif
	outputPath = S_fileName
	
	print outputPath
	
	//Unless there is no other wave, this should load the wave as "wave0"
	//J	Indicates that the file uses the delimited text format
	//D	Creates double precision waves
	//M	Loads data as matrix wave.
	//A	"Auto-name and go" option <- fine for now
	LoadWave/J/M/D/A=wave/K=0 outputPath
	
	SetDataFolder oldSaveFolder
End
	
Function FilterImage(ImgName,Layernum)
	String ImgName
	Variable LayerNum
	String dfSave = GetDataFolder(1)
	setdatafolder root:packages:ArrayScan
	
	// Assume wave to be loaded is  called "wave0"
	Wave wave0
	NVAR gAveraging
	Variable i, j, k, total, scanpoints, scanlines
	scanpoints = (DimSize(wave0, 0))/gAveraging
	scanlines = DimSize(wave0, 1)
	//Make/O/N=(scanpoints,scanlines) cleanedWave
	SetDataFolder root:Images
	Wave chosenCant = $(ImgName)
	for(j=0; j<scanlines; j=j+1)
		for(i=0; i<scanpoints*gAveraging; i=i+gAveraging)
			total = 0;
			for(k=i; k<(i+gAveraging); k=k+1)
				total = total + wave0[k][j]
			endfor
			//cleanedWave[i/gAveraging][j] = total/gAveraging
			chosenCant[i/gAveraging][j][LayerNum] = total/gAveraging
		endfor
	endfor
	
	KillWaves  wave0
	SetDataFolder dfSave
End

Window ArrayScanPanel(): Panel
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(485,145, 765,450) as "Array Scan Panel"
	SetDrawLayer UserBack
	
	SetVariable sv_PathName,pos={17,14},size={242,25},title="File Path"
	SetVariable sv_PathName, value=root:Packages:ArrayScan:gPathName	
	
	SetVariable sv_ImageBaseName,pos={17,46},size={242,25},title="Base Name"
	SetVariable sv_ImageBaseName, value=root:Packages:ArrayScan:gBaseName	
	
	SetVariable sv_ImageOffset,pos={17,78},size={115,25},title="Base Suffix", limits={0,100,1}
	SetVariable sv_ImageOffset,value=root:Packages:ArrayScan:gBaseSuffix
	
	SetVariable sv_DisplayCant,pos={17,109},size={151,25},title="Display Cantilever", limits={1,5,1}
	SetVariable sv_DisplayCant, value=root:Packages:ArrayScan:gDisplayCant

	SetVariable sv_Averaging,pos={17,140},size={115,25},title="Averaging", limits={0,100,1}
	SetVariable sv_Averaging, value=root:Packages:ArrayScan:gAveraging
	
	DrawText 16, 205, "Insert data into ibw:"
	
	SetVariable SV_name,pos={16,215},size={242,25},title="Image Name", disable=2
	SetVariable SV_name,value= root:packages:MFP3D:Main:Display:LastTitle,live= 1
	
	Button bt_overwrite,pos={17,246},size={242,25},title="Browse for txt file & overwrite Img layer", proc=OverwriteLayer
	
	SetDrawEnv fstyle= 1 
	SetDrawEnv textrgb= (0,0,65280)
	DrawText 102, 292, "Suhas Somnath, UIUC 2010"
End	


// Delete all this:

Menu "Macros"
	"Array Scan", ArrayScanDriver()
End

Function ArrayScanDriver()
	
	// If the panel is already created, just bring it to the front.
	DoWindow/F ArrayScanPanel
	if (V_Flag != 0)
		return 0
	endif
	
	String dfSave = GetDataFolder(1)
	
	// Create a data folder in Packages to store globals.
	NewDataFolder/O/S root:packages:ArrayScan
	
	String pathname = StrVarOrDefault(":gPathName","C:Documents and Settings:somnath2:Desktop:RealTimeDataCapture:");
	String/G gPathName = pathname
	
	String basename = StrVarOrDefault(":gBaseName","Image");
	String/G gBaseName = basename
	
	Variable baseSuffix = NumVarOrDefault(":gBaseSuffix",0);
	Variable/G gBaseSuffix = baseSuffix
	
	Variable avging = NumVarOrDefault(":gAveraging",1)
	Variable/G gAveraging = avging
	
	Variable displayCant = NumVarOrDefault(":gDisplayCant",1)
	Variable/G gDisplayCant = displayCant
	
	DoAlert 0, "Enable UserCalculated function: ArrayUserCalc"
	
	Execute "ArrayScanPanel()"
	
	SetDataFolder dfSave
End