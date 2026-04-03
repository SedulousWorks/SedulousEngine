using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Shell;
using System;

namespace Win32.System.WinRT.Shell;

#region Enums

[AllowDuplicates]
public enum CreateProcessMethod : int32
{
	CpCreateProcess = 0,
	CpCreateProcessAsUser = 1,
	CpAicLaunchAdminProcess = 2,
}

#endregion


#region COM Types
[CRepr]struct IDDEInitializer : IUnknown
{
	public new const Guid IID = .(0x30dc931f, 0x33fc, 0x4ffd, 0xa1, 0x68, 0x94, 0x22, 0x58, 0xcf, 0x3c, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileExtensionOrProtocol, CreateProcessMethod method, PWSTR currentDirectory, IShellItem* execTarget, IUnknown* site, PWSTR application, PWSTR targetFile, PWSTR arguments, PWSTR verb) Initialize;
	}


	public HRESULT Initialize(PWSTR fileExtensionOrProtocol, CreateProcessMethod method, PWSTR currentDirectory, IShellItem* execTarget, IUnknown* site, PWSTR application, PWSTR targetFile, PWSTR arguments, PWSTR verb) mut => VT.[Friend]Initialize(&this, fileExtensionOrProtocol, method, currentDirectory, execTarget, site, application, targetFile, arguments, verb);
}

#endregion
