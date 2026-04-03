using Win32.System.Com;
using Win32.Foundation;
using Win32.Web.MsHtml;
using Win32.System.Diagnostics.Debug;
using System;

namespace Win32.System.Diagnostics.Debug.WebApp;
#region Function Pointers
public function HRESULT RegisterAuthoringClientFunctionType(IWebApplicationAuthoringMode* authoringModeObject, IWebApplicationHost* host);

public function HRESULT UnregisterAuthoringClientFunctionType(IWebApplicationHost* host);

#endregion

#region COM Types
[CRepr]struct IWebApplicationScriptEvents : IUnknown
{
	public new const Guid IID = .(0x7c3f6998, 0x1567, 0x4bba, 0xb5, 0x2b, 0x48, 0xd3, 0x21, 0x41, 0xd6, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow) BeforeScriptExecute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow, IActiveScriptError* scriptError, PWSTR url, BOOL errorHandled) ScriptError;
	}


	public HRESULT BeforeScriptExecute(IHTMLWindow2* htmlWindow) mut => VT.[Friend]BeforeScriptExecute(&this, htmlWindow);

	public HRESULT ScriptError(IHTMLWindow2* htmlWindow, IActiveScriptError* scriptError, PWSTR url, BOOL errorHandled) mut => VT.[Friend]ScriptError(&this, htmlWindow, scriptError, url, errorHandled);
}

[CRepr]struct IWebApplicationNavigationEvents : IUnknown
{
	public new const Guid IID = .(0xc22615d2, 0xd318, 0x4da2, 0x84, 0x22, 0x1f, 0xca, 0xf7, 0x7b, 0x10, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow, PWSTR url, uint32 navigationFlags, PWSTR targetFrameName) BeforeNavigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow, PWSTR url) NavigateComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow, PWSTR url, PWSTR targetFrameName, uint32 statusCode) NavigateError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLWindow2* htmlWindow, PWSTR url) DocumentComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DownloadBegin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DownloadComplete;
	}


	public HRESULT BeforeNavigate(IHTMLWindow2* htmlWindow, PWSTR url, uint32 navigationFlags, PWSTR targetFrameName) mut => VT.[Friend]BeforeNavigate(&this, htmlWindow, url, navigationFlags, targetFrameName);

	public HRESULT NavigateComplete(IHTMLWindow2* htmlWindow, PWSTR url) mut => VT.[Friend]NavigateComplete(&this, htmlWindow, url);

	public HRESULT NavigateError(IHTMLWindow2* htmlWindow, PWSTR url, PWSTR targetFrameName, uint32 statusCode) mut => VT.[Friend]NavigateError(&this, htmlWindow, url, targetFrameName, statusCode);

	public HRESULT DocumentComplete(IHTMLWindow2* htmlWindow, PWSTR url) mut => VT.[Friend]DocumentComplete(&this, htmlWindow, url);

	public HRESULT DownloadBegin() mut => VT.[Friend]DownloadBegin(&this);

	public HRESULT DownloadComplete() mut => VT.[Friend]DownloadComplete(&this);
}

[CRepr]struct IWebApplicationUIEvents : IUnknown
{
	public new const Guid IID = .(0x5b2b3f99, 0x328c, 0x41d5, 0xa6, 0xf7, 0x74, 0x83, 0xed, 0x8e, 0x71, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 securityProblem, HRESULT* result) SecurityProblem;
	}


	public HRESULT SecurityProblem(uint32 securityProblem, HRESULT* result) mut => VT.[Friend]SecurityProblem(&this, securityProblem, result);
}

[CRepr]struct IWebApplicationUpdateEvents : IUnknown
{
	public new const Guid IID = .(0x3e59e6b7, 0xc652, 0x4daf, 0xad, 0x5e, 0x16, 0xfe, 0xb3, 0x50, 0xcd, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnPaint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnCssChanged;
	}


	public HRESULT OnPaint() mut => VT.[Friend]OnPaint(&this);

	public HRESULT OnCssChanged() mut => VT.[Friend]OnCssChanged(&this);
}

[CRepr]struct IWebApplicationHost : IUnknown
{
	public new const Guid IID = .(0xcecbd2c3, 0xa3a5, 0x4749, 0x96, 0x81, 0x20, 0xe9, 0x16, 0x1c, 0x67, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* hwnd) get_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHTMLDocument2** htmlDocument) get_Document;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid interfaceId, IUnknown* callback, uint32* cookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) Unadvise;
	}


	public HRESULT get_HWND(HWND* hwnd) mut => VT.[Friend]get_HWND(&this, hwnd);

	public HRESULT get_Document(IHTMLDocument2** htmlDocument) mut => VT.[Friend]get_Document(&this, htmlDocument);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Advise(in Guid interfaceId, IUnknown* callback, uint32* cookie) mut => VT.[Friend]Advise(&this, interfaceId, callback, cookie);

	public HRESULT Unadvise(uint32 cookie) mut => VT.[Friend]Unadvise(&this, cookie);
}

[CRepr]struct IWebApplicationActivation : IUnknown
{
	public new const Guid IID = .(0xbcdcd0de, 0x330e, 0x481b, 0xb8, 0x43, 0x48, 0x98, 0xa6, 0xa8, 0xeb, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelPendingActivation;
	}


	public HRESULT CancelPendingActivation() mut => VT.[Friend]CancelPendingActivation(&this);
}

[CRepr]struct IWebApplicationAuthoringMode : IServiceProvider
{
	public new const Guid IID = .(0x720aea93, 0x1964, 0x4db0, 0xb0, 0x05, 0x29, 0xeb, 0x9e, 0x2b, 0x18, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IServiceProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* designModeDllPath) get_AuthoringClientBinary;
	}


	public HRESULT get_AuthoringClientBinary(BSTR* designModeDllPath) mut => VT.[Friend]get_AuthoringClientBinary(&this, designModeDllPath);
}

#endregion
