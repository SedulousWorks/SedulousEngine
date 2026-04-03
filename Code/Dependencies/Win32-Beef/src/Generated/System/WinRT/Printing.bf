using Win32.System.WinRT;
using Win32.Foundation;
using Win32.System.Com;
using Win32.Storage.Xps;
using Win32.Graphics.Printing;
using System;

namespace Win32.System.WinRT.Printing;

#region COM Types
[CRepr]struct IPrinting3DManagerInterop : IInspectable
{
	public new const Guid IID = .(0x9ca31010, 0x1484, 0x4587, 0xb2, 0x6b, 0xdd, 0xdf, 0x9f, 0x9c, 0xae, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** printManager) GetForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** asyncOperation) ShowPrintUIForWindowAsync;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** printManager) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, printManager);

	public HRESULT ShowPrintUIForWindowAsync(HWND appWindow, in Guid riid, void** asyncOperation) mut => VT.[Friend]ShowPrintUIForWindowAsync(&this, appWindow, riid, asyncOperation);
}

[CRepr]struct IPrintManagerInterop : IInspectable
{
	public new const Guid IID = .(0xc5435a42, 0x8d43, 0x4e7b, 0xa6, 0x8a, 0xef, 0x31, 0x1e, 0x39, 0x20, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInspectable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** printManager) GetForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** asyncOperation) ShowPrintUIForWindowAsync;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** printManager) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, printManager);

	public HRESULT ShowPrintUIForWindowAsync(HWND appWindow, in Guid riid, void** asyncOperation) mut => VT.[Friend]ShowPrintUIForWindowAsync(&this, appWindow, riid, asyncOperation);
}

[CRepr]struct IPrintWorkflowXpsReceiver : IUnknown
{
	public new const Guid IID = .(0x04097374, 0x77b8, 0x47f6, 0x81, 0x67, 0xaa, 0xe2, 0x9d, 0x4c, 0xf8, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* documentSequencePrintTicket) SetDocumentSequencePrintTicket;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR documentSequenceUri) SetDocumentSequenceUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 documentId, IStream* documentPrintTicket, PWSTR documentUri) AddDocumentData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 documentId, uint32 pageId, IXpsOMPageReference* pageReference, PWSTR pageUri) AddPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT SetDocumentSequencePrintTicket(IStream* documentSequencePrintTicket) mut => VT.[Friend]SetDocumentSequencePrintTicket(&this, documentSequencePrintTicket);

	public HRESULT SetDocumentSequenceUri(PWSTR documentSequenceUri) mut => VT.[Friend]SetDocumentSequenceUri(&this, documentSequenceUri);

	public HRESULT AddDocumentData(uint32 documentId, IStream* documentPrintTicket, PWSTR documentUri) mut => VT.[Friend]AddDocumentData(&this, documentId, documentPrintTicket, documentUri);

	public HRESULT AddPage(uint32 documentId, uint32 pageId, IXpsOMPageReference* pageReference, PWSTR pageUri) mut => VT.[Friend]AddPage(&this, documentId, pageId, pageReference, pageUri);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IPrintWorkflowXpsReceiver2 : IPrintWorkflowXpsReceiver
{
	public new const Guid IID = .(0x023bcc0c, 0xdfab, 0x4a61, 0xb0, 0x74, 0x49, 0x0c, 0x69, 0x95, 0x58, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPrintWorkflowXpsReceiver.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT XpsError) Failed;
	}


	public HRESULT Failed(HRESULT XpsError) mut => VT.[Friend]Failed(&this, XpsError);
}

[CRepr]struct IPrintWorkflowObjectModelSourceFileContentNative : IUnknown
{
	public new const Guid IID = .(0x68c9e477, 0x993e, 0x4052, 0x8a, 0xc6, 0x45, 0x4e, 0xff, 0x58, 0xdb, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrintWorkflowXpsReceiver* receiver) StartXpsOMGeneration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMObjectFactory1** value) get_ObjectFactory;
	}


	public HRESULT StartXpsOMGeneration(IPrintWorkflowXpsReceiver* receiver) mut => VT.[Friend]StartXpsOMGeneration(&this, receiver);

	public HRESULT get_ObjectFactory(IXpsOMObjectFactory1** value) mut => VT.[Friend]get_ObjectFactory(&this, value);
}

[CRepr]struct IPrintWorkflowXpsObjectModelTargetPackageNative : IUnknown
{
	public new const Guid IID = .(0x7d96bc74, 0x9b54, 0x4ca1, 0xad, 0x3a, 0x97, 0x9c, 0x3d, 0x44, 0xdd, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsDocumentPackageTarget** value) get_DocumentPackageTarget;
	}


	public HRESULT get_DocumentPackageTarget(IXpsDocumentPackageTarget** value) mut => VT.[Friend]get_DocumentPackageTarget(&this, value);
}

[CRepr]struct IPrintWorkflowConfigurationNative : IUnknown
{
	public new const Guid IID = .(0xc056be0a, 0x9ee2, 0x450a, 0x98, 0x23, 0x96, 0x4f, 0x00, 0x06, 0xf2, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterQueue** value) get_PrinterQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterPropertyBag** value) get_DriverProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPrinterPropertyBag** value) get_UserProperties;
	}


	public HRESULT get_PrinterQueue(IPrinterQueue** value) mut => VT.[Friend]get_PrinterQueue(&this, value);

	public HRESULT get_DriverProperties(IPrinterPropertyBag** value) mut => VT.[Friend]get_DriverProperties(&this, value);

	public HRESULT get_UserProperties(IPrinterPropertyBag** value) mut => VT.[Friend]get_UserProperties(&this, value);
}

#endregion
