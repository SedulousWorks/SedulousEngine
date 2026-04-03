using Win32.Foundation;
using System;

namespace Win32.NetworkManagement.InternetConnectionWizard;

#region Constants
public static
{
	public const String ICW_REGPATHSETTINGS = "Software\\Microsoft\\Internet Connection Wizard";
	public const String ICW_REGKEYCOMPLETED = "Completed";
	public const uint32 ICW_MAX_ACCTNAME = 256;
	public const uint32 ICW_MAX_PASSWORD = 256;
	public const uint32 ICW_MAX_LOGONNAME = 256;
	public const uint32 ICW_MAX_SERVERNAME = 64;
	public const uint32 ICW_MAX_RASNAME = 256;
	public const uint32 ICW_MAX_EMAILNAME = 64;
	public const uint32 ICW_MAX_EMAILADDR = 128;
	public const uint32 ICW_CHECKSTATUS = 1;
	public const uint32 ICW_LAUNCHFULL = 256;
	public const uint32 ICW_LAUNCHMANUAL = 512;
	public const uint32 ICW_USE_SHELLNEXT = 1024;
	public const uint32 ICW_FULL_SMARTSTART = 2048;
	public const uint32 ICW_FULLPRESENT = 1;
	public const uint32 ICW_MANUALPRESENT = 2;
	public const uint32 ICW_ALREADYRUN = 4;
	public const uint32 ICW_LAUNCHEDFULL = 256;
	public const uint32 ICW_LAUNCHEDMANUAL = 512;
	public const uint32 ICW_USEDEFAULTS = 1;
}
#endregion
#region Function Pointers
public function uint32 PFNCHECKCONNECTIONWIZARD(uint32 param0, uint32* param1);

public function uint32 PFNSETSHELLNEXT(PSTR param0);

#endregion
