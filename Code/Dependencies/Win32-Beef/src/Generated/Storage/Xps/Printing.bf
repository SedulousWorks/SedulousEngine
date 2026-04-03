using Win32.Foundation;
using Win32.System.Com;
using Win32.Storage.Xps;
using System;

namespace Win32.Storage.Xps.Printing;

#region Constants
public static
{
	public const Guid ID_DOCUMENTPACKAGETARGET_MSXPS = .(0x9cae40a8, 0xded1, 0x41c9, 0xa9, 0xfd, 0xd7, 0x35, 0xef, 0x33, 0xae, 0xda);
	public const Guid ID_DOCUMENTPACKAGETARGET_OPENXPS = .(0x0056bb72, 0x8c9c, 0x4612, 0xbd, 0x0f, 0x93, 0x01, 0x2a, 0x87, 0x09, 0x9d);
	public const Guid ID_DOCUMENTPACKAGETARGET_OPENXPS_WITH_3D = .(0x63dbd720, 0x8b14, 0x4577, 0xb0, 0x74, 0x7b, 0xb1, 0x1b, 0x59, 0x6d, 0x28);
}
#endregion

#region Enums

[AllowDuplicates]
public enum XPS_JOB_COMPLETION : int32
{
	XPS_JOB_IN_PROGRESS = 0,
	XPS_JOB_COMPLETED = 1,
	XPS_JOB_CANCELLED = 2,
	XPS_JOB_FAILED = 3,
}


[AllowDuplicates]
public enum PrintDocumentPackageCompletion : int32
{
	PrintDocumentPackageCompletion_InProgress = 0,
	PrintDocumentPackageCompletion_Completed = 1,
	PrintDocumentPackageCompletion_Canceled = 2,
	PrintDocumentPackageCompletion_Failed = 3,
}

#endregion


#region Structs
[CRepr]
public struct XPS_JOB_STATUS
{
	public uint32 jobId;
	public int32 currentDocument;
	public int32 currentPage;
	public int32 currentPageTotal;
	public XPS_JOB_COMPLETION completion;
	public HRESULT jobStatus;
}

[CRepr]
public struct PrintDocumentPackageStatus
{
	public uint32 JobId;
	public int32 CurrentDocument;
	public int32 CurrentPage;
	public int32 CurrentPageTotal;
	public PrintDocumentPackageCompletion Completion;
	public HRESULT PackageStatus;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_PrintDocumentPackageTarget = .(0x4842669e, 0x9947, 0x46ea, 0x8b, 0xa2, 0xd8, 0xcc, 0xe4, 0x32, 0xc2, 0xca);


	public const Guid CLSID_PrintDocumentPackageTargetFactory = .(0x348ef17d, 0x6c81, 0x4982, 0x92, 0xb4, 0xee, 0x18, 0x8a, 0x43, 0x86, 0x7a);


}
#endregion

#region COM Types
[CRepr]struct IXpsPrintJobStream : ISequentialStream
{
	public new const Guid IID = .(0x7a77dc5f, 0x45d6, 0x4dff, 0x93, 0x07, 0xd8, 0xcb, 0x84, 0x63, 0x47, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISequentialStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IXpsPrintJob : IUnknown
{
	public new const Guid IID = .(0x5ab89b06, 0x8194, 0x425f, 0xab, 0x3b, 0xd7, 0xa9, 0x6e, 0x35, 0x01, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_JOB_STATUS* jobStatus) GetJobStatus;
	}


	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT GetJobStatus(XPS_JOB_STATUS* jobStatus) mut => VT.[Friend]GetJobStatus(&this, jobStatus);
}

[CRepr]struct IPrintDocumentPackageTarget : IUnknown
{
	public new const Guid IID = .(0x1b8efec4, 0x3019, 0x4c27, 0x96, 0x4e, 0x36, 0x72, 0x02, 0x15, 0x69, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* targetCount, Guid** targetTypes) GetPackageTargetTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidTargetType, in Guid riid, void** ppvTarget) GetPackageTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT GetPackageTargetTypes(uint32* targetCount, Guid** targetTypes) mut => VT.[Friend]GetPackageTargetTypes(&this, targetCount, targetTypes);

	public HRESULT GetPackageTarget(in Guid guidTargetType, in Guid riid, void** ppvTarget) mut => VT.[Friend]GetPackageTarget(&this, guidTargetType, riid, ppvTarget);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPrintDocumentPackageStatusEvent : IDispatch
{
	public new const Guid IID = .(0xed90c8ad, 0x5c34, 0x4d05, 0xa1, 0xec, 0x0e, 0x8a, 0x9b, 0x3a, 0xd7, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrintDocumentPackageStatus* packageStatus) PackageStatusUpdated;
	}


	public HRESULT PackageStatusUpdated(PrintDocumentPackageStatus* packageStatus) mut => VT.[Friend]PackageStatusUpdated(&this, packageStatus);
}

[CRepr]struct IPrintDocumentPackageTargetFactory : IUnknown
{
	public new const Guid IID = .(0xd2959bf7, 0xb31b, 0x4a3d, 0x96, 0x00, 0x71, 0x2e, 0xb1, 0x33, 0x5b, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR printerName, PWSTR jobName, IStream* jobOutputStream, IStream* jobPrintTicketStream, IPrintDocumentPackageTarget** docPackageTarget) CreateDocumentPackageTargetForPrintJob;
	}


	public HRESULT CreateDocumentPackageTargetForPrintJob(PWSTR printerName, PWSTR jobName, IStream* jobOutputStream, IStream* jobPrintTicketStream, IPrintDocumentPackageTarget** docPackageTarget) mut => VT.[Friend]CreateDocumentPackageTargetForPrintJob(&this, printerName, jobName, jobOutputStream, jobPrintTicketStream, docPackageTarget);
}

#endregion

#region Functions
public static
{
	[Import("XPSPRINT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StartXpsPrintJob(PWSTR printerName, PWSTR jobName, PWSTR outputFileName, HANDLE progressEvent, HANDLE completionEvent, uint8* printablePagesOn, uint32 printablePagesOnCount, IXpsPrintJob** xpsPrintJob, IXpsPrintJobStream** documentStream, IXpsPrintJobStream** printTicketStream);

	[Import("XPSPRINT.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StartXpsPrintJob1(PWSTR printerName, PWSTR jobName, PWSTR outputFileName, HANDLE progressEvent, HANDLE completionEvent, IXpsPrintJob** xpsPrintJob, IXpsOMPackageTarget** printContentReceiver);

}
#endregion
