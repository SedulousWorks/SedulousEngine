using Win32.System.Com;
using Win32.Foundation;
using Win32.Media.DirectShow;
using Win32.Data.Xml.MsXml;
using System;

namespace Win32.Media.DirectShow.Xml;

#region Constants
public static
{
	public const Guid CLSID_XMLGraphBuilder = .(0x1bb05961, 0x5fbf, 0x11d2, 0xa5, 0x21, 0x44, 0xdf, 0x07, 0xc1, 0x00, 0x00);
}
#endregion

#region COM Types
[CRepr]struct IXMLGraphBuilder : IUnknown
{
	public new const Guid IID = .(0x1bb05960, 0x5fbf, 0x11d2, 0xa5, 0x21, 0x44, 0xdf, 0x07, 0xc1, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGraphBuilder* pGraph, IXMLElement* pxml) BuildFromXML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGraphBuilder* pGraph, BSTR* pbstrxml) SaveToXML;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IGraphBuilder* pGraph, PWSTR wszFileName, PWSTR wszBaseURL) BuildFromXMLFile;
	}


	public HRESULT BuildFromXML(IGraphBuilder* pGraph, IXMLElement* pxml) mut => VT.[Friend]BuildFromXML(&this, pGraph, pxml);

	public HRESULT SaveToXML(IGraphBuilder* pGraph, BSTR* pbstrxml) mut => VT.[Friend]SaveToXML(&this, pGraph, pbstrxml);

	public HRESULT BuildFromXMLFile(IGraphBuilder* pGraph, PWSTR wszFileName, PWSTR wszBaseURL) mut => VT.[Friend]BuildFromXMLFile(&this, pGraph, wszFileName, wszBaseURL);
}

#endregion
