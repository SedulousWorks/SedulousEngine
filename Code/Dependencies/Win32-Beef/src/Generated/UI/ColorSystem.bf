using Win32.Graphics.Gdi;
using Win32.Foundation;
using Win32.System.Com;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.UI.ColorSystem;

#region Constants
public static
{
	public const Guid CATID_WcsPlugin = .(0xa0b402e0, 0x8240, 0x405f, 0x8a, 0x16, 0x8a, 0x5b, 0x4d, 0xf2, 0xf0, 0xdd);
	public const uint32 MAX_COLOR_CHANNELS = 8;
	public const uint32 INTENT_PERCEPTUAL = 0;
	public const uint32 INTENT_RELATIVE_COLORIMETRIC = 1;
	public const uint32 INTENT_SATURATION = 2;
	public const uint32 INTENT_ABSOLUTE_COLORIMETRIC = 3;
	public const uint32 FLAG_EMBEDDEDPROFILE = 1;
	public const uint32 FLAG_DEPENDENTONDATA = 2;
	public const uint32 FLAG_ENABLE_CHROMATIC_ADAPTATION = 33554432;
	public const uint32 ATTRIB_TRANSPARENCY = 1;
	public const uint32 ATTRIB_MATTE = 2;
	public const uint32 PROFILE_FILENAME = 1;
	public const uint32 PROFILE_MEMBUFFER = 2;
	public const uint32 PROFILE_READ = 1;
	public const uint32 PROFILE_READWRITE = 2;
	public const uint32 INDEX_DONT_CARE = 0;
	public const uint32 CMM_FROM_PROFILE = 0;
	public const uint32 ENUM_TYPE_VERSION = 768;
	public const uint32 ET_DEVICENAME = 1;
	public const uint32 ET_MEDIATYPE = 2;
	public const uint32 ET_DITHERMODE = 4;
	public const uint32 ET_RESOLUTION = 8;
	public const uint32 ET_CMMTYPE = 16;
	public const uint32 ET_CLASS = 32;
	public const uint32 ET_DATACOLORSPACE = 64;
	public const uint32 ET_CONNECTIONSPACE = 128;
	public const uint32 ET_SIGNATURE = 256;
	public const uint32 ET_PLATFORM = 512;
	public const uint32 ET_PROFILEFLAGS = 1024;
	public const uint32 ET_MANUFACTURER = 2048;
	public const uint32 ET_MODEL = 4096;
	public const uint32 ET_ATTRIBUTES = 8192;
	public const uint32 ET_RENDERINGINTENT = 16384;
	public const uint32 ET_CREATOR = 32768;
	public const uint32 ET_DEVICECLASS = 65536;
	public const uint32 ET_STANDARDDISPLAYCOLOR = 131072;
	public const uint32 ET_EXTENDEDDISPLAYCOLOR = 262144;
	public const uint32 PROOF_MODE = 1;
	public const uint32 NORMAL_MODE = 2;
	public const uint32 BEST_MODE = 3;
	public const uint32 ENABLE_GAMUT_CHECKING = 65536;
	public const uint32 USE_RELATIVE_COLORIMETRIC = 131072;
	public const uint32 FAST_TRANSLATE = 262144;
	public const uint32 PRESERVEBLACK = 1048576;
	public const uint32 WCS_ALWAYS = 2097152;
	public const uint32 SEQUENTIAL_TRANSFORM = 2155872256;
	public const uint32 RESERVED = 2147483648;
	public const uint32 CSA_A = 1;
	public const uint32 CSA_ABC = 2;
	public const uint32 CSA_DEF = 3;
	public const uint32 CSA_DEFG = 4;
	public const uint32 CSA_GRAY = 5;
	public const uint32 CSA_RGB = 6;
	public const uint32 CSA_CMYK = 7;
	public const uint32 CSA_Lab = 8;
	public const uint32 CMM_WIN_VERSION = 0;
	public const uint32 CMM_IDENT = 1;
	public const uint32 CMM_DRIVER_VERSION = 2;
	public const uint32 CMM_DLL_VERSION = 3;
	public const uint32 CMM_VERSION = 4;
	public const uint32 CMM_DESCRIPTION = 5;
	public const uint32 CMM_LOGOICON = 6;
	public const uint32 CMS_FORWARD = 0;
	public const uint32 CMS_BACKWARD = 1;
	public const uint32 COLOR_MATCH_VERSION = 512;
	public const uint32 CMS_DISABLEICM = 1;
	public const uint32 CMS_ENABLEPROOFING = 2;
	public const uint32 CMS_SETRENDERINTENT = 4;
	public const uint32 CMS_SETPROOFINTENT = 8;
	public const uint32 CMS_SETMONITORPROFILE = 16;
	public const uint32 CMS_SETPRINTERPROFILE = 32;
	public const uint32 CMS_SETTARGETPROFILE = 64;
	public const uint32 CMS_USEHOOK = 128;
	public const uint32 CMS_USEAPPLYCALLBACK = 256;
	public const uint32 CMS_USEDESCRIPTION = 512;
	public const uint32 CMS_DISABLEINTENT = 1024;
	public const uint32 CMS_DISABLERENDERINTENT = 2048;
	public const int32 CMS_MONITOROVERFLOW = -2147483648;
	public const int32 CMS_PRINTEROVERFLOW = 1073741824;
	public const int32 CMS_TARGETOVERFLOW = 536870912;
	public const int32 DONT_USE_EMBEDDED_WCS_PROFILES = 1;
	public const int32 WCS_DEFAULT = 0;
	public const int32 WCS_ICCONLY = 65536;
}
#endregion

#region TypeDefs
typealias HCOLORSPACE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum ICM_COMMAND : uint32
{
	ICM_ADDPROFILE = 1,
	ICM_DELETEPROFILE = 2,
	ICM_QUERYPROFILE = 3,
	ICM_SETDEFAULTPROFILE = 4,
	ICM_REGISTERICMATCHER = 5,
	ICM_UNREGISTERICMATCHER = 6,
	ICM_QUERYMATCH = 7,
}


[AllowDuplicates]
public enum ICM_MODE : int32
{
	ICM_OFF = 1,
	ICM_ON = 2,
	ICM_QUERY = 3,
	ICM_DONE_OUTSIDEDC = 4,
}


[AllowDuplicates]
public enum COLOR_MATCH_TO_TARGET_ACTION : int32
{
	CS_ENABLE = 1,
	CS_DISABLE = 2,
	CS_DELETE_TRANSFORM = 3,
}


[AllowDuplicates]
public enum COLORTYPE : int32
{
	COLOR_GRAY = 1,
	COLOR_RGB = 2,
	COLOR_XYZ = 3,
	COLOR_Yxy = 4,
	COLOR_Lab = 5,
	COLOR_3_CHANNEL = 6,
	COLOR_CMYK = 7,
	COLOR_5_CHANNEL = 8,
	COLOR_6_CHANNEL = 9,
	COLOR_7_CHANNEL = 10,
	COLOR_8_CHANNEL = 11,
	COLOR_NAMED = 12,
}


[AllowDuplicates]
public enum COLORPROFILETYPE : int32
{
	CPT_ICC = 0,
	CPT_DMP = 1,
	CPT_CAMP = 2,
	CPT_GMMP = 3,
}


[AllowDuplicates]
public enum COLORPROFILESUBTYPE : int32
{
	CPST_PERCEPTUAL = 0,
	CPST_RELATIVE_COLORIMETRIC = 1,
	CPST_SATURATION = 2,
	CPST_ABSOLUTE_COLORIMETRIC = 3,
	CPST_NONE = 4,
	CPST_RGB_WORKING_SPACE = 5,
	CPST_CUSTOM_WORKING_SPACE = 6,
	CPST_STANDARD_DISPLAY_COLOR_MODE = 7,
	CPST_EXTENDED_DISPLAY_COLOR_MODE = 8,
}


[AllowDuplicates]
public enum COLORDATATYPE : int32
{
	COLOR_BYTE = 1,
	COLOR_WORD = 2,
	COLOR_FLOAT = 3,
	COLOR_S2DOT13FIXED = 4,
	COLOR_10b_R10G10B10A2 = 5,
	COLOR_10b_R10G10B10A2_XR = 6,
	COLOR_FLOAT16 = 7,
}


[AllowDuplicates]
public enum BMFORMAT : int32
{
	BM_x555RGB = 0,
	BM_x555XYZ = 257,
	BM_x555Yxy = 258,
	BM_x555Lab = 259,
	BM_x555G3CH = 260,
	BM_RGBTRIPLETS = 2,
	BM_BGRTRIPLETS = 4,
	BM_XYZTRIPLETS = 513,
	BM_YxyTRIPLETS = 514,
	BM_LabTRIPLETS = 515,
	BM_G3CHTRIPLETS = 516,
	BM_5CHANNEL = 517,
	BM_6CHANNEL = 518,
	BM_7CHANNEL = 519,
	BM_8CHANNEL = 520,
	BM_GRAY = 521,
	BM_xRGBQUADS = 8,
	BM_xBGRQUADS = 16,
	BM_xG3CHQUADS = 772,
	BM_KYMCQUADS = 773,
	BM_CMYKQUADS = 32,
	BM_10b_RGB = 9,
	BM_10b_XYZ = 1025,
	BM_10b_Yxy = 1026,
	BM_10b_Lab = 1027,
	BM_10b_G3CH = 1028,
	BM_NAMED_INDEX = 1029,
	BM_16b_RGB = 10,
	BM_16b_XYZ = 1281,
	BM_16b_Yxy = 1282,
	BM_16b_Lab = 1283,
	BM_16b_G3CH = 1284,
	BM_16b_GRAY = 1285,
	BM_565RGB = 1,
	BM_32b_scRGB = 1537,
	BM_32b_scARGB = 1538,
	BM_S2DOT13FIXED_scRGB = 1539,
	BM_S2DOT13FIXED_scARGB = 1540,
	BM_R10G10B10A2 = 1793,
	BM_R10G10B10A2_XR = 1794,
	BM_R16G16B16A16_FLOAT = 1795,
}


[AllowDuplicates]
public enum WCS_PROFILE_MANAGEMENT_SCOPE : int32
{
	WCS_PROFILE_MANAGEMENT_SCOPE_SYSTEM_WIDE = 0,
	WCS_PROFILE_MANAGEMENT_SCOPE_CURRENT_USER = 1,
}


[AllowDuplicates]
public enum WCS_DEVICE_CAPABILITIES_TYPE : int32
{
	VideoCardGammaTable = 1,
	MicrosoftHardwareColorV2 = 2,
}

#endregion

#region Function Pointers
public function int32 ICMENUMPROCA(PSTR param0, LPARAM param1);

public function int32 ICMENUMPROCW(PWSTR param0, LPARAM param1);

public function BOOL LPBMCALLBACKFN(uint32 param0, uint32 param1, LPARAM param2);

public function BOOL PCMSCALLBACKW(COLORMATCHSETUPW* param0, LPARAM param1);

public function BOOL PCMSCALLBACKA(COLORMATCHSETUPA* param0, LPARAM param1);

#endregion

#region Structs
[CRepr]
public struct LOGCOLORSPACEA
{
	public uint32 lcsSignature;
	public uint32 lcsVersion;
	public uint32 lcsSize;
	public int32 lcsCSType;
	public int32 lcsIntent;
	public CIEXYZTRIPLE lcsEndpoints;
	public uint32 lcsGammaRed;
	public uint32 lcsGammaGreen;
	public uint32 lcsGammaBlue;
	public CHAR[260] lcsFilename;
}

[CRepr]
public struct LOGCOLORSPACEW
{
	public uint32 lcsSignature;
	public uint32 lcsVersion;
	public uint32 lcsSize;
	public int32 lcsCSType;
	public int32 lcsIntent;
	public CIEXYZTRIPLE lcsEndpoints;
	public uint32 lcsGammaRed;
	public uint32 lcsGammaGreen;
	public uint32 lcsGammaBlue;
	public char16[260] lcsFilename;
}

[CRepr]
public struct EMRCREATECOLORSPACE
{
	public EMR emr;
	public uint32 ihCS;
	public LOGCOLORSPACEA lcs;
}

[CRepr]
public struct EMRCREATECOLORSPACEW
{
	public EMR emr;
	public uint32 ihCS;
	public LOGCOLORSPACEW lcs;
	public uint32 dwFlags;
	public uint32 cbData;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct XYZColorF
{
	public float X;
	public float Y;
	public float Z;
}

[CRepr]
public struct JChColorF
{
	public float J;
	public float C;
	public float h;
}

[CRepr]
public struct JabColorF
{
	public float J;
	public float a;
	public float b;
}

[CRepr]
public struct GamutShellTriangle
{
	public uint32[3] aVertexIndex;
}

[CRepr]
public struct GamutShell
{
	public float JMin;
	public float JMax;
	public uint32 cVertices;
	public uint32 cTriangles;
	public JabColorF* pVertices;
	public GamutShellTriangle* pTriangles;
}

[CRepr]
public struct PrimaryJabColors
{
	public JabColorF red;
	public JabColorF yellow;
	public JabColorF green;
	public JabColorF cyan;
	public JabColorF blue;
	public JabColorF magenta;
	public JabColorF black;
	public JabColorF white;
}

[CRepr]
public struct PrimaryXYZColors
{
	public XYZColorF red;
	public XYZColorF yellow;
	public XYZColorF green;
	public XYZColorF cyan;
	public XYZColorF blue;
	public XYZColorF magenta;
	public XYZColorF black;
	public XYZColorF white;
}

[CRepr]
public struct GamutBoundaryDescription
{
	public PrimaryJabColors* pPrimaries;
	public uint32 cNeutralSamples;
	public JabColorF* pNeutralSamples;
	public GamutShell* pReferenceShell;
	public GamutShell* pPlausibleShell;
	public GamutShell* pPossibleShell;
}

[CRepr]
public struct BlackInformation
{
	public BOOL fBlackOnly;
	public float blackWeight;
}

[CRepr]
public struct NAMED_PROFILE_INFO
{
	public uint32 dwFlags;
	public uint32 dwCount;
	public uint32 dwCountDevCoordinates;
	public int8[32] szPrefix;
	public int8[32] szSuffix;
}

[CRepr]
public struct GRAYCOLOR
{
	public uint16 gray;
}

[CRepr]
public struct RGBCOLOR
{
	public uint16 red;
	public uint16 green;
	public uint16 blue;
}

[CRepr]
public struct CMYKCOLOR
{
	public uint16 cyan;
	public uint16 magenta;
	public uint16 yellow;
	public uint16 black;
}

[CRepr]
public struct XYZCOLOR
{
	public uint16 X;
	public uint16 Y;
	public uint16 Z;
}

[CRepr]
public struct YxyCOLOR
{
	public uint16 Y;
	public uint16 x;
	public uint16 y;
}

[CRepr]
public struct LabCOLOR
{
	public uint16 L;
	public uint16 a;
	public uint16 b;
}

[CRepr]
public struct GENERIC3CHANNEL
{
	public uint16 ch1;
	public uint16 ch2;
	public uint16 ch3;
}

[CRepr]
public struct NAMEDCOLOR
{
	public uint32 dwIndex;
}

[CRepr]
public struct HiFiCOLOR
{
	public uint8[8] channel;
}

[CRepr, Union]
public struct COLOR
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public uint32 reserved1;
		public void* reserved2;
	}
	public GRAYCOLOR gray;
	public RGBCOLOR rgb;
	public CMYKCOLOR cmyk;
	public XYZCOLOR XYZ;
	public YxyCOLOR Yxy;
	public LabCOLOR Lab;
	public GENERIC3CHANNEL gen3ch;
	public NAMEDCOLOR named;
	public HiFiCOLOR hifi;
	public using _Anonymous_e__Struct Anonymous;
}

[CRepr]
public struct PROFILEHEADER
{
	public uint32 phSize;
	public uint32 phCMMType;
	public uint32 phVersion;
	public uint32 phClass;
	public uint32 phDataColorSpace;
	public uint32 phConnectionSpace;
	public uint32[3] phDateTime;
	public uint32 phSignature;
	public uint32 phPlatform;
	public uint32 phProfileFlags;
	public uint32 phManufacturer;
	public uint32 phModel;
	public uint32[2] phAttributes;
	public uint32 phRenderingIntent;
	public CIEXYZ phIlluminant;
	public uint32 phCreator;
	public uint8[44] phReserved;
}

[CRepr]
public struct PROFILE
{
	public uint32 dwType;
	public void* pProfileData;
	public uint32 cbDataSize;
}

[CRepr]
public struct ENUMTYPEA
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFields;
	public PSTR pDeviceName;
	public uint32 dwMediaType;
	public uint32 dwDitheringMode;
	public uint32[2] dwResolution;
	public uint32 dwCMMType;
	public uint32 dwClass;
	public uint32 dwDataColorSpace;
	public uint32 dwConnectionSpace;
	public uint32 dwSignature;
	public uint32 dwPlatform;
	public uint32 dwProfileFlags;
	public uint32 dwManufacturer;
	public uint32 dwModel;
	public uint32[2] dwAttributes;
	public uint32 dwRenderingIntent;
	public uint32 dwCreator;
	public uint32 dwDeviceClass;
}

[CRepr]
public struct ENUMTYPEW
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFields;
	public PWSTR pDeviceName;
	public uint32 dwMediaType;
	public uint32 dwDitheringMode;
	public uint32[2] dwResolution;
	public uint32 dwCMMType;
	public uint32 dwClass;
	public uint32 dwDataColorSpace;
	public uint32 dwConnectionSpace;
	public uint32 dwSignature;
	public uint32 dwPlatform;
	public uint32 dwProfileFlags;
	public uint32 dwManufacturer;
	public uint32 dwModel;
	public uint32[2] dwAttributes;
	public uint32 dwRenderingIntent;
	public uint32 dwCreator;
	public uint32 dwDeviceClass;
}

[CRepr]
public struct COLORMATCHSETUPW
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFlags;
	public HWND hwndOwner;
	public PWSTR pSourceName;
	public PWSTR pDisplayName;
	public PWSTR pPrinterName;
	public uint32 dwRenderIntent;
	public uint32 dwProofingIntent;
	public PWSTR pMonitorProfile;
	public uint32 ccMonitorProfile;
	public PWSTR pPrinterProfile;
	public uint32 ccPrinterProfile;
	public PWSTR pTargetProfile;
	public uint32 ccTargetProfile;
	public DLGPROC lpfnHook;
	public LPARAM lParam;
	public PCMSCALLBACKW lpfnApplyCallback;
	public LPARAM lParamApplyCallback;
}

[CRepr]
public struct COLORMATCHSETUPA
{
	public uint32 dwSize;
	public uint32 dwVersion;
	public uint32 dwFlags;
	public HWND hwndOwner;
	public PSTR pSourceName;
	public PSTR pDisplayName;
	public PSTR pPrinterName;
	public uint32 dwRenderIntent;
	public uint32 dwProofingIntent;
	public PSTR pMonitorProfile;
	public uint32 ccMonitorProfile;
	public PSTR pPrinterProfile;
	public uint32 ccPrinterProfile;
	public PSTR pTargetProfile;
	public uint32 ccTargetProfile;
	public DLGPROC lpfnHook;
	public LPARAM lParam;
	public PCMSCALLBACKA lpfnApplyCallback;
	public LPARAM lParamApplyCallback;
}

[CRepr]
public struct WCS_DEVICE_VCGT_CAPABILITIES
{
	public uint32 Size;
	public BOOL SupportsVcgt;
}

[CRepr]
public struct WCS_DEVICE_MHC2_CAPABILITIES
{
	public uint32 Size;
	public BOOL SupportsMhc2;
	public uint32 RegammaLutEntryCount;
	public uint32 CscXyzMatrixRows;
	public uint32 CscXyzMatrixColumns;
}

#endregion

#region COM Types
[CRepr]struct IDeviceModelPlugIn : IUnknown
{
	public new const Guid IID = .(0x1cd63475, 0x07c4, 0x46fe, 0xa9, 0x03, 0xd6, 0x55, 0x31, 0x6d, 0x11, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXml, uint32 cNumModels, uint32 iModelPosition) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNumChannels) GetNumChannels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cColors, uint32 cChannels, float* pDeviceValues, XYZColorF* pXYZColors) DeviceToColorimetricColors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cColors, uint32 cChannels, XYZColorF* pXYZColors, float* pDeviceValues) ColorimetricToDeviceColors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cColors, uint32 cChannels, XYZColorF* pXYZColors, BlackInformation* pBlackInformation, float* pDeviceValues) ColorimetricToDeviceColorsWithBlack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iModelPosition, IDeviceModelPlugIn* pIDeviceModelOther) SetTransformDeviceModelInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PrimaryXYZColors* pPrimaryColor) GetPrimarySamples;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNumVertices, uint32* pNumTriangles) GetGamutBoundaryMeshSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cChannels, uint32 cVertices, uint32 cTriangles, float* pVertices, GamutShellTriangle* pTriangles) GetGamutBoundaryMesh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcColors) GetNeutralAxisSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cColors, XYZColorF* pXYZColors) GetNeutralAxis;
	}


	public HRESULT Initialize(BSTR bstrXml, uint32 cNumModels, uint32 iModelPosition) mut => VT.[Friend]Initialize(&this, bstrXml, cNumModels, iModelPosition);

	public HRESULT GetNumChannels(uint32* pNumChannels) mut => VT.[Friend]GetNumChannels(&this, pNumChannels);

	public HRESULT DeviceToColorimetricColors(uint32 cColors, uint32 cChannels, float* pDeviceValues, XYZColorF* pXYZColors) mut => VT.[Friend]DeviceToColorimetricColors(&this, cColors, cChannels, pDeviceValues, pXYZColors);

	public HRESULT ColorimetricToDeviceColors(uint32 cColors, uint32 cChannels, XYZColorF* pXYZColors, float* pDeviceValues) mut => VT.[Friend]ColorimetricToDeviceColors(&this, cColors, cChannels, pXYZColors, pDeviceValues);

	public HRESULT ColorimetricToDeviceColorsWithBlack(uint32 cColors, uint32 cChannels, XYZColorF* pXYZColors, BlackInformation* pBlackInformation, float* pDeviceValues) mut => VT.[Friend]ColorimetricToDeviceColorsWithBlack(&this, cColors, cChannels, pXYZColors, pBlackInformation, pDeviceValues);

	public HRESULT SetTransformDeviceModelInfo(uint32 iModelPosition, IDeviceModelPlugIn* pIDeviceModelOther) mut => VT.[Friend]SetTransformDeviceModelInfo(&this, iModelPosition, pIDeviceModelOther);

	public HRESULT GetPrimarySamples(PrimaryXYZColors* pPrimaryColor) mut => VT.[Friend]GetPrimarySamples(&this, pPrimaryColor);

	public HRESULT GetGamutBoundaryMeshSize(uint32* pNumVertices, uint32* pNumTriangles) mut => VT.[Friend]GetGamutBoundaryMeshSize(&this, pNumVertices, pNumTriangles);

	public HRESULT GetGamutBoundaryMesh(uint32 cChannels, uint32 cVertices, uint32 cTriangles, float* pVertices, GamutShellTriangle* pTriangles) mut => VT.[Friend]GetGamutBoundaryMesh(&this, cChannels, cVertices, cTriangles, pVertices, pTriangles);

	public HRESULT GetNeutralAxisSize(uint32* pcColors) mut => VT.[Friend]GetNeutralAxisSize(&this, pcColors);

	public HRESULT GetNeutralAxis(uint32 cColors, XYZColorF* pXYZColors) mut => VT.[Friend]GetNeutralAxis(&this, cColors, pXYZColors);
}

[CRepr]struct IGamutMapModelPlugIn : IUnknown
{
	public new const Guid IID = .(0x2dd80115, 0xad1e, 0x41f6, 0xa2, 0x19, 0xa4, 0xf4, 0xb5, 0x83, 0xd1, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXml, IDeviceModelPlugIn* pSrcPlugIn, IDeviceModelPlugIn* pDestPlugIn, GamutBoundaryDescription* pSrcGBD, GamutBoundaryDescription* pDestGBD) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cColors, JChColorF* pInputColors, JChColorF* pOutputColors) SourceToDestinationAppearanceColors;
	}


	public HRESULT Initialize(BSTR bstrXml, IDeviceModelPlugIn* pSrcPlugIn, IDeviceModelPlugIn* pDestPlugIn, GamutBoundaryDescription* pSrcGBD, GamutBoundaryDescription* pDestGBD) mut => VT.[Friend]Initialize(&this, bstrXml, pSrcPlugIn, pDestPlugIn, pSrcGBD, pDestGBD);

	public HRESULT SourceToDestinationAppearanceColors(uint32 cColors, JChColorF* pInputColors, JChColorF* pOutputColors) mut => VT.[Friend]SourceToDestinationAppearanceColors(&this, cColors, pInputColors, pOutputColors);
}

#endregion

#region Functions
public static
{
	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetICMMode(HDC hdc, ICM_MODE mode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckColorsInGamut(HDC hdc, RGBTRIPLE* lpRGBTriple, void* dlpBuffer, uint32 nCount);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCOLORSPACE GetColorSpace(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogColorSpaceA(HCOLORSPACE hColorSpace, LOGCOLORSPACEA* lpBuffer, uint32 nSize);
	public static BOOL GetLogColorSpace(HCOLORSPACE hColorSpace, LOGCOLORSPACEA* lpBuffer, uint32 nSize) => GetLogColorSpaceA(hColorSpace, lpBuffer, nSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetLogColorSpaceW(HCOLORSPACE hColorSpace, LOGCOLORSPACEW* lpBuffer, uint32 nSize);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCOLORSPACE CreateColorSpaceA(LOGCOLORSPACEA* lplcs);
	public static HCOLORSPACE CreateColorSpace(LOGCOLORSPACEA* lplcs) => CreateColorSpaceA(lplcs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCOLORSPACE CreateColorSpaceW(LOGCOLORSPACEW* lplcs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HCOLORSPACE SetColorSpace(HDC hdc, HCOLORSPACE hcs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteColorSpace(HCOLORSPACE hcs);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetICMProfileA(HDC hdc, uint32* pBufSize, uint8* pszFilename);
	public static BOOL GetICMProfile(HDC hdc, uint32* pBufSize, uint8* pszFilename) => GetICMProfileA(hdc, pBufSize, pszFilename);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetICMProfileW(HDC hdc, uint32* pBufSize, char16* pszFilename);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetICMProfileA(HDC hdc, PSTR lpFileName);
	public static BOOL SetICMProfile(HDC hdc, PSTR lpFileName) => SetICMProfileA(hdc, lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetICMProfileW(HDC hdc, PWSTR lpFileName);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDeviceGammaRamp(HDC hdc, void* lpRamp);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetDeviceGammaRamp(HDC hdc, void* lpRamp);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ColorMatchToTarget(HDC hdc, HDC hdcTarget, COLOR_MATCH_TO_TARGET_ACTION action);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumICMProfilesA(HDC hdc, ICMENUMPROCA proc, LPARAM param2);
	public static int32 EnumICMProfiles(HDC hdc, ICMENUMPROCA proc, LPARAM param2) => EnumICMProfilesA(hdc, proc, param2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EnumICMProfilesW(HDC hdc, ICMENUMPROCW proc, LPARAM param2);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateICMRegKeyA(uint32 reserved, PSTR lpszCMID, PSTR lpszFileName, ICM_COMMAND command);
	public static BOOL UpdateICMRegKey(uint32 reserved, PSTR lpszCMID, PSTR lpszFileName, ICM_COMMAND command) => UpdateICMRegKeyA(reserved, lpszCMID, lpszFileName, command);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateICMRegKeyW(uint32 reserved, PWSTR lpszCMID, PWSTR lpszFileName, ICM_COMMAND command);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ColorCorrectPalette(HDC hdc, HPALETTE hPal, uint32 deFirst, uint32 num);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OpenColorProfileA(PROFILE* pProfile, uint32 dwDesiredAccess, uint32 dwShareMode, uint32 dwCreationMode);
	public static int OpenColorProfile(PROFILE* pProfile, uint32 dwDesiredAccess, uint32 dwShareMode, uint32 dwCreationMode) => OpenColorProfileA(pProfile, dwDesiredAccess, dwShareMode, dwCreationMode);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int OpenColorProfileW(PROFILE* pProfile, uint32 dwDesiredAccess, uint32 dwShareMode, uint32 dwCreationMode);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CloseColorProfile(int hProfile);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorProfileFromHandle(int hProfile, uint8* pProfile, uint32* pcbProfile);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsColorProfileValid(int hProfile, BOOL* pbValid);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProfileFromLogColorSpaceA(LOGCOLORSPACEA* pLogColorSpace, uint8** pProfile);
	public static BOOL CreateProfileFromLogColorSpace(LOGCOLORSPACEA* pLogColorSpace, uint8** pProfile) => CreateProfileFromLogColorSpaceA(pLogColorSpace, pProfile);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateProfileFromLogColorSpaceW(LOGCOLORSPACEW* pLogColorSpace, uint8** pProfile);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetCountColorProfileElements(int hProfile, uint32* pnElementCount);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorProfileHeader(int hProfile, PROFILEHEADER* pHeader);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorProfileElementTag(int hProfile, uint32 dwIndex, uint32* pTag);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsColorProfileTagPresent(int hProfile, uint32 tag, BOOL* pbPresent);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorProfileElement(int hProfile, uint32 tag, uint32 dwOffset, uint32* pcbElement, void* pElement, BOOL* pbReference);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetColorProfileHeader(int hProfile, PROFILEHEADER* pHeader);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetColorProfileElementSize(int hProfile, uint32 tagType, uint32 pcbElement);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetColorProfileElement(int hProfile, uint32 tag, uint32 dwOffset, uint32* pcbElement, void* pElement);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetColorProfileElementReference(int hProfile, uint32 newTag, uint32 refTag);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPS2ColorSpaceArray(int hProfile, uint32 dwIntent, uint32 dwCSAType, uint8* pPS2ColorSpaceArray, uint32* pcbPS2ColorSpaceArray, BOOL* pbBinary);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPS2ColorRenderingIntent(int hProfile, uint32 dwIntent, uint8* pBuffer, uint32* pcbPS2ColorRenderingIntent);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetPS2ColorRenderingDictionary(int hProfile, uint32 dwIntent, uint8* pPS2ColorRenderingDictionary, uint32* pcbPS2ColorRenderingDictionary, BOOL* pbBinary);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetNamedProfileInfo(int hProfile, NAMED_PROFILE_INFO* pNamedProfileInfo);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertColorNameToIndex(int hProfile, int8** paColorName, uint32* paIndex, uint32 dwCount);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ConvertIndexToColorName(int hProfile, uint32* paIndex, int8** paColorName, uint32 dwCount);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CreateDeviceLinkProfile(int* hProfile, uint32 nProfiles, uint32* padwIntent, uint32 nIntents, uint32 dwFlags, uint8** pProfileData, uint32 indexPreferredCMM);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CreateColorTransformA(LOGCOLORSPACEA* pLogColorSpace, int hDestProfile, int hTargetProfile, uint32 dwFlags);
	public static int CreateColorTransform(LOGCOLORSPACEA* pLogColorSpace, int hDestProfile, int hTargetProfile, uint32 dwFlags) => CreateColorTransformA(pLogColorSpace, hDestProfile, hTargetProfile, dwFlags);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CreateColorTransformW(LOGCOLORSPACEW* pLogColorSpace, int hDestProfile, int hTargetProfile, uint32 dwFlags);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CreateMultiProfileTransform(int* pahProfiles, uint32 nProfiles, uint32* padwIntent, uint32 nIntents, uint32 dwFlags, uint32 indexPreferredCMM);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteColorTransform(int hxform);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TranslateBitmapBits(int hColorTransform, void* pSrcBits, BMFORMAT bmInput, uint32 dwWidth, uint32 dwHeight, uint32 dwInputStride, void* pDestBits, BMFORMAT bmOutput, uint32 dwOutputStride, LPBMCALLBACKFN pfnCallBack, LPARAM ulCallbackData);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckBitmapBits(int hColorTransform, void* pSrcBits, BMFORMAT bmInput, uint32 dwWidth, uint32 dwHeight, uint32 dwStride, uint8* paResult, LPBMCALLBACKFN pfnCallback, LPARAM lpCallbackData);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL TranslateColors(int hColorTransform, COLOR* paInputColors, uint32 nColors, COLORTYPE ctInput, COLOR* paOutputColors, COLORTYPE ctOutput);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CheckColors(int hColorTransform, COLOR* paInputColors, uint32 nColors, COLORTYPE ctInput, uint8* paResult);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetCMMInfo(int hColorTransform, uint32 param1);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterCMMA(PSTR pMachineName, uint32 cmmID, PSTR pCMMdll);
	public static BOOL RegisterCMM(PSTR pMachineName, uint32 cmmID, PSTR pCMMdll) => RegisterCMMA(pMachineName, cmmID, pCMMdll);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RegisterCMMW(PWSTR pMachineName, uint32 cmmID, PWSTR pCMMdll);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterCMMA(PSTR pMachineName, uint32 cmmID);
	public static BOOL UnregisterCMM(PSTR pMachineName, uint32 cmmID) => UnregisterCMMA(pMachineName, cmmID);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnregisterCMMW(PWSTR pMachineName, uint32 cmmID);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SelectCMM(uint32 dwCMMType);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorDirectoryA(PSTR pMachineName, PSTR pBuffer, uint32* pdwSize);
	public static BOOL GetColorDirectory(PSTR pMachineName, PSTR pBuffer, uint32* pdwSize) => GetColorDirectoryA(pMachineName, pBuffer, pdwSize);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetColorDirectoryW(PWSTR pMachineName, PWSTR pBuffer, uint32* pdwSize);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InstallColorProfileA(PSTR pMachineName, PSTR pProfileName);
	public static BOOL InstallColorProfile(PSTR pMachineName, PSTR pProfileName) => InstallColorProfileA(pMachineName, pProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InstallColorProfileW(PWSTR pMachineName, PWSTR pProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UninstallColorProfileA(PSTR pMachineName, PSTR pProfileName, BOOL bDelete);
	public static BOOL UninstallColorProfile(PSTR pMachineName, PSTR pProfileName, BOOL bDelete) => UninstallColorProfileA(pMachineName, pProfileName, bDelete);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UninstallColorProfileW(PWSTR pMachineName, PWSTR pProfileName, BOOL bDelete);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumColorProfilesA(PSTR pMachineName, ENUMTYPEA* pEnumRecord, uint8* pEnumerationBuffer, uint32* pdwSizeOfEnumerationBuffer, uint32* pnProfiles);
	public static BOOL EnumColorProfiles(PSTR pMachineName, ENUMTYPEA* pEnumRecord, uint8* pEnumerationBuffer, uint32* pdwSizeOfEnumerationBuffer, uint32* pnProfiles) => EnumColorProfilesA(pMachineName, pEnumRecord, pEnumerationBuffer, pdwSizeOfEnumerationBuffer, pnProfiles);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL EnumColorProfilesW(PWSTR pMachineName, ENUMTYPEW* pEnumRecord, uint8* pEnumerationBuffer, uint32* pdwSizeOfEnumerationBuffer, uint32* pnProfiles);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetStandardColorSpaceProfileA(PSTR pMachineName, uint32 dwProfileID, PSTR pProfilename);
	public static BOOL SetStandardColorSpaceProfile(PSTR pMachineName, uint32 dwProfileID, PSTR pProfilename) => SetStandardColorSpaceProfileA(pMachineName, dwProfileID, pProfilename);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetStandardColorSpaceProfileW(PWSTR pMachineName, uint32 dwProfileID, PWSTR pProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStandardColorSpaceProfileA(PSTR pMachineName, uint32 dwSCS, PSTR pBuffer, uint32* pcbSize);
	public static BOOL GetStandardColorSpaceProfile(PSTR pMachineName, uint32 dwSCS, PSTR pBuffer, uint32* pcbSize) => GetStandardColorSpaceProfileA(pMachineName, dwSCS, pBuffer, pcbSize);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetStandardColorSpaceProfileW(PWSTR pMachineName, uint32 dwSCS, PWSTR pBuffer, uint32* pcbSize);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AssociateColorProfileWithDeviceA(PSTR pMachineName, PSTR pProfileName, PSTR pDeviceName);
	public static BOOL AssociateColorProfileWithDevice(PSTR pMachineName, PSTR pProfileName, PSTR pDeviceName) => AssociateColorProfileWithDeviceA(pMachineName, pProfileName, pDeviceName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AssociateColorProfileWithDeviceW(PWSTR pMachineName, PWSTR pProfileName, PWSTR pDeviceName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DisassociateColorProfileFromDeviceA(PSTR pMachineName, PSTR pProfileName, PSTR pDeviceName);
	public static BOOL DisassociateColorProfileFromDevice(PSTR pMachineName, PSTR pProfileName, PSTR pDeviceName) => DisassociateColorProfileFromDeviceA(pMachineName, pProfileName, pDeviceName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DisassociateColorProfileFromDeviceW(PWSTR pMachineName, PWSTR pProfileName, PWSTR pDeviceName);

	[Import("ICMUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupColorMatchingW(COLORMATCHSETUPW* pcms);

	[Import("ICMUI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupColorMatchingA(COLORMATCHSETUPA* pcms);
	public static BOOL SetupColorMatching(COLORMATCHSETUPA* pcms) => SetupColorMatchingA(pcms);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsAssociateColorProfileWithDevice(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR pProfileName, PWSTR pDeviceName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsDisassociateColorProfileFromDevice(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR pProfileName, PWSTR pDeviceName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsEnumColorProfilesSize(WCS_PROFILE_MANAGEMENT_SCOPE @scope, ENUMTYPEW* pEnumRecord, uint32* pdwSize);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsEnumColorProfiles(WCS_PROFILE_MANAGEMENT_SCOPE @scope, ENUMTYPEW* pEnumRecord, uint8* pBuffer, uint32 dwSize, uint32* pnProfiles);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsGetDefaultColorProfileSize(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR pDeviceName, COLORPROFILETYPE cptColorProfileType, COLORPROFILESUBTYPE cpstColorProfileSubType, uint32 dwProfileID, uint32* pcbProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsGetDefaultColorProfile(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR pDeviceName, COLORPROFILETYPE cptColorProfileType, COLORPROFILESUBTYPE cpstColorProfileSubType, uint32 dwProfileID, uint32 cbProfileName, PWSTR pProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsSetDefaultColorProfile(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR pDeviceName, COLORPROFILETYPE cptColorProfileType, COLORPROFILESUBTYPE cpstColorProfileSubType, uint32 dwProfileID, PWSTR pProfileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsSetDefaultRenderingIntent(WCS_PROFILE_MANAGEMENT_SCOPE @scope, uint32 dwRenderingIntent);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsGetDefaultRenderingIntent(WCS_PROFILE_MANAGEMENT_SCOPE @scope, uint32* pdwRenderingIntent);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsGetUsePerUserProfiles(PWSTR pDeviceName, uint32 dwDeviceClass, BOOL* pUsePerUserProfiles);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsSetUsePerUserProfiles(PWSTR pDeviceName, uint32 dwDeviceClass, BOOL usePerUserProfiles);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsTranslateColors(int hColorTransform, uint32 nColors, uint32 nInputChannels, COLORDATATYPE cdtInput, uint32 cbInput, void* pInputData, uint32 nOutputChannels, COLORDATATYPE cdtOutput, uint32 cbOutput, void* pOutputData);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsCheckColors(int hColorTransform, uint32 nColors, uint32 nInputChannels, COLORDATATYPE cdtInput, uint32 cbInput, void* pInputData, uint8* paResult);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCheckColors(int hcmTransform, COLOR* lpaInputColors, uint32 nColors, COLORTYPE ctInput, uint8* lpaResult);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCheckRGBs(int hcmTransform, void* lpSrcBits, BMFORMAT bmInput, uint32 dwWidth, uint32 dwHeight, uint32 dwStride, uint8* lpaResult, LPBMCALLBACKFN pfnCallback, LPARAM ulCallbackData);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMConvertColorNameToIndex(int hProfile, int8** paColorName, uint32* paIndex, uint32 dwCount);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMConvertIndexToColorName(int hProfile, uint32* paIndex, int8** paColorName, uint32 dwCount);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCreateDeviceLinkProfile(int* pahProfiles, uint32 nProfiles, uint32* padwIntents, uint32 nIntents, uint32 dwFlags, uint8** lpProfileData);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CMCreateMultiProfileTransform(int* pahProfiles, uint32 nProfiles, uint32* padwIntents, uint32 nIntents, uint32 dwFlags);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCreateProfileW(LOGCOLORSPACEW* lpColorSpace, void** lpProfileData);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CMCreateTransform(LOGCOLORSPACEA* lpColorSpace, void* lpDevCharacter, void* lpTargetDevCharacter);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CMCreateTransformW(LOGCOLORSPACEW* lpColorSpace, void* lpDevCharacter, void* lpTargetDevCharacter);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CMCreateTransformExt(LOGCOLORSPACEA* lpColorSpace, void* lpDevCharacter, void* lpTargetDevCharacter, uint32 dwFlags);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCheckColorsInGamut(int hcmTransform, RGBTRIPLE* lpaRGBTriple, uint8* lpaResult, uint32 nCount);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMCreateProfile(LOGCOLORSPACEA* lpColorSpace, void** lpProfileData);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMTranslateRGB(int hcmTransform, COLORREF ColorRef, uint32* lpColorRef, uint32 dwFlags);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMTranslateRGBs(int hcmTransform, void* lpSrcBits, BMFORMAT bmInput, uint32 dwWidth, uint32 dwHeight, uint32 dwStride, void* lpDestBits, BMFORMAT bmOutput, uint32 dwTranslateDirection);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int CMCreateTransformExtW(LOGCOLORSPACEW* lpColorSpace, void* lpDevCharacter, void* lpTargetDevCharacter, uint32 dwFlags);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMDeleteTransform(int hcmTransform);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CMGetInfo(uint32 dwInfo);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMGetNamedProfileInfo(int hProfile, NAMED_PROFILE_INFO* pNamedProfileInfo);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMIsProfileValid(int hProfile, int32* lpbValid);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMTranslateColors(int hcmTransform, COLOR* lpaInputColors, uint32 nColors, COLORTYPE ctInput, COLOR* lpaOutputColors, COLORTYPE ctOutput);

	[Import("ICM32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CMTranslateRGBsExt(int hcmTransform, void* lpSrcBits, BMFORMAT bmInput, uint32 dwWidth, uint32 dwHeight, uint32 dwInputStride, void* lpDestBits, BMFORMAT bmOutput, uint32 dwOutputStride, LPBMCALLBACKFN lpfnCallback, LPARAM ulCallbackData);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int WcsOpenColorProfileA(PROFILE* pCDMPProfile, PROFILE* pCAMPProfile, PROFILE* pGMMPProfile, uint32 dwDesireAccess, uint32 dwShareMode, uint32 dwCreationMode, uint32 dwFlags);
	public static int WcsOpenColorProfile(PROFILE* pCDMPProfile, PROFILE* pCAMPProfile, PROFILE* pGMMPProfile, uint32 dwDesireAccess, uint32 dwShareMode, uint32 dwCreationMode, uint32 dwFlags) => WcsOpenColorProfileA(pCDMPProfile, pCAMPProfile, pGMMPProfile, dwDesireAccess, dwShareMode, dwCreationMode, dwFlags);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int WcsOpenColorProfileW(PROFILE* pCDMPProfile, PROFILE* pCAMPProfile, PROFILE* pGMMPProfile, uint32 dwDesireAccess, uint32 dwShareMode, uint32 dwCreationMode, uint32 dwFlags);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int WcsCreateIccProfile(int hWcsProfile, uint32 dwOptions);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsGetCalibrationManagementState(BOOL* pbIsEnabled);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WcsSetCalibrationManagementState(BOOL bIsEnabled);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileAddDisplayAssociation(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR profileName, LUID targetAdapterID, uint32 sourceID, BOOL setAsDefault, BOOL associateAsAdvancedColor);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileRemoveDisplayAssociation(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR profileName, LUID targetAdapterID, uint32 sourceID, BOOL dissociateAdvancedColor);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileSetDisplayDefaultAssociation(WCS_PROFILE_MANAGEMENT_SCOPE @scope, PWSTR profileName, COLORPROFILETYPE profileType, COLORPROFILESUBTYPE profileSubType, LUID targetAdapterID, uint32 sourceID);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileGetDisplayList(WCS_PROFILE_MANAGEMENT_SCOPE @scope, LUID targetAdapterID, uint32 sourceID, PWSTR** profileList, uint32* profileCount);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileGetDisplayDefault(WCS_PROFILE_MANAGEMENT_SCOPE @scope, LUID targetAdapterID, uint32 sourceID, COLORPROFILETYPE profileType, COLORPROFILESUBTYPE profileSubType, PWSTR* profileName);

	[Import("mscms.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ColorProfileGetDisplayUserScope(LUID targetAdapterID, uint32 sourceID, WCS_PROFILE_MANAGEMENT_SCOPE* @scope);

}
#endregion
