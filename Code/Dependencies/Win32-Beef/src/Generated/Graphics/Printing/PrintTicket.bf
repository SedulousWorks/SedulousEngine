using Win32.Foundation;
using Win32.Storage.Xps;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using System;

namespace Win32.Graphics.Printing.PrintTicket;

#region Constants
public static
{
	public const uint32 PRINTTICKET_ISTREAM_APIS = 1;
	public const uint32 S_PT_NO_CONFLICT = 262145;
	public const uint32 S_PT_CONFLICT_RESOLVED = 262146;
	public const uint32 E_PRINTTICKET_FORMAT = 2147745795;
	public const uint32 E_PRINTCAPABILITIES_FORMAT = 2147745796;
	public const uint32 E_DELTA_PRINTTICKET_FORMAT = 2147745797;
	public const uint32 E_PRINTDEVICECAPABILITIES_FORMAT = 2147745798;
}
#endregion

#region Enums

[AllowDuplicates]
public enum EDefaultDevmodeType : int32
{
	kUserDefaultDevmode = 0,
	kPrinterDefaultDevmode = 1,
}


[AllowDuplicates]
public enum EPrintTicketScope : int32
{
	kPTPageScope = 0,
	kPTDocumentScope = 1,
	kPTJobScope = 2,
}

#endregion


#region Functions
public static
{
	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTQuerySchemaVersionSupport(PWSTR pszPrinterName, uint32* pMaxVersion);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTOpenProvider(PWSTR pszPrinterName, uint32 dwVersion, HPTPROVIDER* phProvider);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTOpenProviderEx(PWSTR pszPrinterName, uint32 dwMaxVersion, uint32 dwPrefVersion, HPTPROVIDER* phProvider, uint32* pUsedVersion);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTCloseProvider(HPTPROVIDER hProvider);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTReleaseMemory(void* pBuffer);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTGetPrintCapabilities(HPTPROVIDER hProvider, IStream* pPrintTicket, IStream* pCapabilities, BSTR* pbstrErrorMessage);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTGetPrintDeviceCapabilities(HPTPROVIDER hProvider, IStream* pPrintTicket, IStream* pDeviceCapabilities, BSTR* pbstrErrorMessage);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTGetPrintDeviceResources(HPTPROVIDER hProvider, PWSTR pszLocaleName, IStream* pPrintTicket, IStream* pDeviceResources, BSTR* pbstrErrorMessage);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTMergeAndValidatePrintTicket(HPTPROVIDER hProvider, IStream* pBaseTicket, IStream* pDeltaTicket, EPrintTicketScope @scope, IStream* pResultTicket, BSTR* pbstrErrorMessage);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTConvertPrintTicketToDevMode(HPTPROVIDER hProvider, IStream* pPrintTicket, EDefaultDevmodeType baseDevmodeType, EPrintTicketScope @scope, uint32* pcbDevmode, DEVMODEA** ppDevmode, BSTR* pbstrErrorMessage);

	[Import("prntvpt.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PTConvertDevModeToPrintTicket(HPTPROVIDER hProvider, uint32 cbDevmode, DEVMODEA* pDevmode, EPrintTicketScope @scope, IStream* pPrintTicket);

}
#endregion
