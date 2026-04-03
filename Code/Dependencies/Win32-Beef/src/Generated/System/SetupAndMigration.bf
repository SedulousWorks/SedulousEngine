using Win32.Foundation;
using System;

namespace Win32.System.SetupAndMigration;
#region Function Pointers
public function void OOBE_COMPLETED_CALLBACK(void* CallbackContext);

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL OOBEComplete(BOOL* isOOBEComplete);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterWaitUntilOOBECompleted(OOBE_COMPLETED_CALLBACK OOBECompletedCallback, void* CallbackContext, void** WaitHandle);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterWaitUntilOOBECompleted(void* WaitHandle);

}
#endregion
