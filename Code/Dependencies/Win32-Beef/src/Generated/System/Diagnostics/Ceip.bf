using Win32.Foundation;
using System;

namespace Win32.System.Diagnostics.Ceip;

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CeipIsOptedIn();

}
#endregion
