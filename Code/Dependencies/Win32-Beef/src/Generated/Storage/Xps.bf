using Win32.Foundation;
using Win32.Graphics.Gdi;
using Win32.System.Com;
using Win32.Storage.Packaging.Opc;
using Win32.Security;
using Win32.Security.Cryptography;
using System;

namespace Win32.Storage.Xps;

#region Constants
public static
{
	public const HRESULT XPS_E_SIGREQUESTID_DUP = -2142108795;
	public const HRESULT XPS_E_PACKAGE_NOT_OPENED = -2142108794;
	public const HRESULT XPS_E_PACKAGE_ALREADY_OPENED = -2142108793;
	public const HRESULT XPS_E_SIGNATUREID_DUP = -2142108792;
	public const HRESULT XPS_E_MARKUP_COMPATIBILITY_ELEMENTS = -2142108791;
	public const HRESULT XPS_E_OBJECT_DETACHED = -2142108790;
	public const HRESULT XPS_E_INVALID_SIGNATUREBLOCK_MARKUP = -2142108789;
	public const HRESULT XPS_E_INVALID_NUMBER_OF_POINTS_IN_CURVE_SEGMENTS = -2142108160;
	public const HRESULT XPS_E_ABSOLUTE_REFERENCE = -2142108159;
	public const HRESULT XPS_E_INVALID_NUMBER_OF_COLOR_CHANNELS = -2142108158;
	public const HRESULT XPS_E_INVALID_LANGUAGE = -2142109696;
	public const HRESULT XPS_E_INVALID_NAME = -2142109695;
	public const HRESULT XPS_E_INVALID_RESOURCE_KEY = -2142109694;
	public const HRESULT XPS_E_INVALID_PAGE_SIZE = -2142109693;
	public const HRESULT XPS_E_INVALID_BLEED_BOX = -2142109692;
	public const HRESULT XPS_E_INVALID_THUMBNAIL_IMAGE_TYPE = -2142109691;
	public const HRESULT XPS_E_INVALID_LOOKUP_TYPE = -2142109690;
	public const HRESULT XPS_E_INVALID_FLOAT = -2142109689;
	public const HRESULT XPS_E_UNEXPECTED_CONTENT_TYPE = -2142109688;
	public const HRESULT XPS_E_INVALID_FONT_URI = -2142109686;
	public const HRESULT XPS_E_INVALID_CONTENT_BOX = -2142109685;
	public const HRESULT XPS_E_INVALID_MARKUP = -2142109684;
	public const HRESULT XPS_E_INVALID_XML_ENCODING = -2142109683;
	public const HRESULT XPS_E_INVALID_CONTENT_TYPE = -2142109682;
	public const HRESULT XPS_E_INVALID_OBFUSCATED_FONT_URI = -2142109681;
	public const HRESULT XPS_E_UNEXPECTED_RELATIONSHIP_TYPE = -2142109680;
	public const HRESULT XPS_E_UNEXPECTED_RESTRICTED_FONT_RELATIONSHIP = -2142109679;
	public const HRESULT XPS_E_MISSING_NAME = -2142109440;
	public const HRESULT XPS_E_MISSING_LOOKUP = -2142109439;
	public const HRESULT XPS_E_MISSING_GLYPHS = -2142109438;
	public const HRESULT XPS_E_MISSING_SEGMENT_DATA = -2142109437;
	public const HRESULT XPS_E_MISSING_COLORPROFILE = -2142109436;
	public const HRESULT XPS_E_MISSING_RELATIONSHIP_TARGET = -2142109435;
	public const HRESULT XPS_E_MISSING_RESOURCE_RELATIONSHIP = -2142109434;
	public const HRESULT XPS_E_MISSING_FONTURI = -2142109433;
	public const HRESULT XPS_E_MISSING_DOCUMENTSEQUENCE_RELATIONSHIP = -2142109432;
	public const HRESULT XPS_E_MISSING_DOCUMENT = -2142109431;
	public const HRESULT XPS_E_MISSING_REFERRED_DOCUMENT = -2142109430;
	public const HRESULT XPS_E_MISSING_REFERRED_PAGE = -2142109429;
	public const HRESULT XPS_E_MISSING_PAGE_IN_DOCUMENT = -2142109428;
	public const HRESULT XPS_E_MISSING_PAGE_IN_PAGEREFERENCE = -2142109427;
	public const HRESULT XPS_E_MISSING_IMAGE_IN_IMAGEBRUSH = -2142109426;
	public const HRESULT XPS_E_MISSING_RESOURCE_KEY = -2142109425;
	public const HRESULT XPS_E_MISSING_PART_REFERENCE = -2142109424;
	public const HRESULT XPS_E_MISSING_RESTRICTED_FONT_RELATIONSHIP = -2142109423;
	public const HRESULT XPS_E_MISSING_DISCARDCONTROL = -2142109422;
	public const HRESULT XPS_E_MISSING_PART_STREAM = -2142109421;
	public const HRESULT XPS_E_UNAVAILABLE_PACKAGE = -2142109420;
	public const HRESULT XPS_E_DUPLICATE_RESOURCE_KEYS = -2142109184;
	public const HRESULT XPS_E_MULTIPLE_RESOURCES = -2142109183;
	public const HRESULT XPS_E_MULTIPLE_DOCUMENTSEQUENCE_RELATIONSHIPS = -2142109182;
	public const HRESULT XPS_E_MULTIPLE_THUMBNAILS_ON_PAGE = -2142109181;
	public const HRESULT XPS_E_MULTIPLE_THUMBNAILS_ON_PACKAGE = -2142109180;
	public const HRESULT XPS_E_MULTIPLE_PRINTTICKETS_ON_PAGE = -2142109179;
	public const HRESULT XPS_E_MULTIPLE_PRINTTICKETS_ON_DOCUMENT = -2142109178;
	public const HRESULT XPS_E_MULTIPLE_PRINTTICKETS_ON_DOCUMENTSEQUENCE = -2142109177;
	public const HRESULT XPS_E_MULTIPLE_REFERENCES_TO_PART = -2142109176;
	public const HRESULT XPS_E_DUPLICATE_NAMES = -2142109175;
	public const HRESULT XPS_E_STRING_TOO_LONG = -2142108928;
	public const HRESULT XPS_E_TOO_MANY_INDICES = -2142108927;
	public const HRESULT XPS_E_MAPPING_OUT_OF_ORDER = -2142108926;
	public const HRESULT XPS_E_MAPPING_OUTSIDE_STRING = -2142108925;
	public const HRESULT XPS_E_MAPPING_OUTSIDE_INDICES = -2142108924;
	public const HRESULT XPS_E_CARET_OUTSIDE_STRING = -2142108923;
	public const HRESULT XPS_E_CARET_OUT_OF_ORDER = -2142108922;
	public const HRESULT XPS_E_ODD_BIDILEVEL = -2142108921;
	public const HRESULT XPS_E_ONE_TO_ONE_MAPPING_EXPECTED = -2142108920;
	public const HRESULT XPS_E_RESTRICTED_FONT_NOT_OBFUSCATED = -2142108919;
	public const HRESULT XPS_E_NEGATIVE_FLOAT = -2142108918;
	public const HRESULT XPS_E_XKEY_ATTR_PRESENT_OUTSIDE_RES_DICT = -2142108672;
	public const HRESULT XPS_E_DICTIONARY_ITEM_NAMED = -2142108671;
	public const HRESULT XPS_E_NESTED_REMOTE_DICTIONARY = -2142108670;
	public const HRESULT XPS_E_INDEX_OUT_OF_RANGE = -2142108416;
	public const HRESULT XPS_E_VISUAL_CIRCULAR_REF = -2142108415;
	public const HRESULT XPS_E_NO_CUSTOM_OBJECTS = -2142108414;
	public const HRESULT XPS_E_ALREADY_OWNED = -2142108413;
	public const HRESULT XPS_E_RESOURCE_NOT_OWNED = -2142108412;
	public const HRESULT XPS_E_UNEXPECTED_COLORPROFILE = -2142108411;
	public const HRESULT XPS_E_COLOR_COMPONENT_OUT_OF_RANGE = -2142108410;
	public const HRESULT XPS_E_BOTH_PATHFIGURE_AND_ABBR_SYNTAX_PRESENT = -2142108409;
	public const HRESULT XPS_E_BOTH_RESOURCE_AND_SOURCEATTR_PRESENT = -2142108408;
	public const HRESULT XPS_E_BLEED_BOX_PAGE_DIMENSIONS_NOT_IN_SYNC = -2142108407;
	public const HRESULT XPS_E_RELATIONSHIP_EXTERNAL = -2142108406;
	public const HRESULT XPS_E_NOT_ENOUGH_GRADIENT_STOPS = -2142108405;
	public const HRESULT XPS_E_PACKAGE_WRITER_NOT_CLOSED = -2142108404;
}
#endregion

#region TypeDefs
typealias HPTPROVIDER = int;

#endregion


#region Enums

[AllowDuplicates]
public enum PRINT_WINDOW_FLAGS : uint32
{
	PW_CLIENTONLY = 1,
}


[AllowDuplicates]
public enum DEVICE_CAPABILITIES : uint16
{
	DC_BINNAMES = 12,
	DC_BINS = 6,
	DC_COLLATE = 22,
	DC_COLORDEVICE = 32,
	DC_COPIES = 18,
	DC_DRIVER = 11,
	DC_DUPLEX = 7,
	DC_ENUMRESOLUTIONS = 13,
	DC_EXTRA = 9,
	DC_FIELDS = 1,
	DC_FILEDEPENDENCIES = 14,
	DC_MAXEXTENT = 5,
	DC_MEDIAREADY = 29,
	DC_MEDIATYPENAMES = 34,
	DC_MEDIATYPES = 35,
	DC_MINEXTENT = 4,
	DC_ORIENTATION = 17,
	DC_NUP = 33,
	DC_PAPERNAMES = 16,
	DC_PAPERS = 2,
	DC_PAPERSIZE = 3,
	DC_PERSONALITY = 25,
	DC_PRINTERMEM = 28,
	DC_PRINTRATE = 26,
	DC_PRINTRATEPPM = 31,
	DC_PRINTRATEUNIT = 27,
	DC_SIZE = 8,
	DC_STAPLE = 30,
	DC_TRUETYPE = 15,
	DC_VERSION = 10,
}


[AllowDuplicates]
public enum PSINJECT_POINT : uint16
{
	PSINJECT_BEGINSTREAM = 1,
	PSINJECT_PSADOBE = 2,
	PSINJECT_PAGESATEND = 3,
	PSINJECT_PAGES = 4,
	PSINJECT_DOCNEEDEDRES = 5,
	PSINJECT_DOCSUPPLIEDRES = 6,
	PSINJECT_PAGEORDER = 7,
	PSINJECT_ORIENTATION = 8,
	PSINJECT_BOUNDINGBOX = 9,
	PSINJECT_DOCUMENTPROCESSCOLORS = 10,
	PSINJECT_COMMENTS = 11,
	PSINJECT_BEGINDEFAULTS = 12,
	PSINJECT_ENDDEFAULTS = 13,
	PSINJECT_BEGINPROLOG = 14,
	PSINJECT_ENDPROLOG = 15,
	PSINJECT_BEGINSETUP = 16,
	PSINJECT_ENDSETUP = 17,
	PSINJECT_TRAILER = 18,
	PSINJECT_EOF = 19,
	PSINJECT_ENDSTREAM = 20,
	PSINJECT_DOCUMENTPROCESSCOLORSATEND = 21,
	PSINJECT_PAGENUMBER = 100,
	PSINJECT_BEGINPAGESETUP = 101,
	PSINJECT_ENDPAGESETUP = 102,
	PSINJECT_PAGETRAILER = 103,
	PSINJECT_PLATECOLOR = 104,
	PSINJECT_SHOWPAGE = 105,
	PSINJECT_PAGEBBOX = 106,
	PSINJECT_ENDPAGECOMMENTS = 107,
	PSINJECT_VMSAVE = 200,
	PSINJECT_VMRESTORE = 201,
}


[AllowDuplicates]
public enum XPS_TILE_MODE : int32
{
	XPS_TILE_MODE_NONE = 1,
	XPS_TILE_MODE_TILE = 2,
	XPS_TILE_MODE_FLIPX = 3,
	XPS_TILE_MODE_FLIPY = 4,
	XPS_TILE_MODE_FLIPXY = 5,
}


[AllowDuplicates]
public enum XPS_COLOR_INTERPOLATION : int32
{
	XPS_COLOR_INTERPOLATION_SCRGBLINEAR = 1,
	XPS_COLOR_INTERPOLATION_SRGBLINEAR = 2,
}


[AllowDuplicates]
public enum XPS_SPREAD_METHOD : int32
{
	XPS_SPREAD_METHOD_PAD = 1,
	XPS_SPREAD_METHOD_REFLECT = 2,
	XPS_SPREAD_METHOD_REPEAT = 3,
}


[AllowDuplicates]
public enum XPS_STYLE_SIMULATION : int32
{
	XPS_STYLE_SIMULATION_NONE = 1,
	XPS_STYLE_SIMULATION_ITALIC = 2,
	XPS_STYLE_SIMULATION_BOLD = 3,
	XPS_STYLE_SIMULATION_BOLDITALIC = 4,
}


[AllowDuplicates]
public enum XPS_LINE_CAP : int32
{
	XPS_LINE_CAP_FLAT = 1,
	XPS_LINE_CAP_ROUND = 2,
	XPS_LINE_CAP_SQUARE = 3,
	XPS_LINE_CAP_TRIANGLE = 4,
}


[AllowDuplicates]
public enum XPS_DASH_CAP : int32
{
	XPS_DASH_CAP_FLAT = 1,
	XPS_DASH_CAP_ROUND = 2,
	XPS_DASH_CAP_SQUARE = 3,
	XPS_DASH_CAP_TRIANGLE = 4,
}


[AllowDuplicates]
public enum XPS_LINE_JOIN : int32
{
	XPS_LINE_JOIN_MITER = 1,
	XPS_LINE_JOIN_BEVEL = 2,
	XPS_LINE_JOIN_ROUND = 3,
}


[AllowDuplicates]
public enum XPS_IMAGE_TYPE : int32
{
	XPS_IMAGE_TYPE_JPEG = 1,
	XPS_IMAGE_TYPE_PNG = 2,
	XPS_IMAGE_TYPE_TIFF = 3,
	XPS_IMAGE_TYPE_WDP = 4,
	XPS_IMAGE_TYPE_JXR = 5,
}


[AllowDuplicates]
public enum XPS_COLOR_TYPE : int32
{
	XPS_COLOR_TYPE_SRGB = 1,
	XPS_COLOR_TYPE_SCRGB = 2,
	XPS_COLOR_TYPE_CONTEXT = 3,
}


[AllowDuplicates]
public enum XPS_FILL_RULE : int32
{
	XPS_FILL_RULE_EVENODD = 1,
	XPS_FILL_RULE_NONZERO = 2,
}


[AllowDuplicates]
public enum XPS_SEGMENT_TYPE : int32
{
	XPS_SEGMENT_TYPE_ARC_LARGE_CLOCKWISE = 1,
	XPS_SEGMENT_TYPE_ARC_LARGE_COUNTERCLOCKWISE = 2,
	XPS_SEGMENT_TYPE_ARC_SMALL_CLOCKWISE = 3,
	XPS_SEGMENT_TYPE_ARC_SMALL_COUNTERCLOCKWISE = 4,
	XPS_SEGMENT_TYPE_BEZIER = 5,
	XPS_SEGMENT_TYPE_LINE = 6,
	XPS_SEGMENT_TYPE_QUADRATIC_BEZIER = 7,
}


[AllowDuplicates]
public enum XPS_SEGMENT_STROKE_PATTERN : int32
{
	XPS_SEGMENT_STROKE_PATTERN_ALL = 1,
	XPS_SEGMENT_STROKE_PATTERN_NONE = 2,
	XPS_SEGMENT_STROKE_PATTERN_MIXED = 3,
}


[AllowDuplicates]
public enum XPS_FONT_EMBEDDING : int32
{
	XPS_FONT_EMBEDDING_NORMAL = 1,
	XPS_FONT_EMBEDDING_OBFUSCATED = 2,
	XPS_FONT_EMBEDDING_RESTRICTED = 3,
	XPS_FONT_EMBEDDING_RESTRICTED_UNOBFUSCATED = 4,
}


[AllowDuplicates]
public enum XPS_OBJECT_TYPE : int32
{
	XPS_OBJECT_TYPE_CANVAS = 1,
	XPS_OBJECT_TYPE_GLYPHS = 2,
	XPS_OBJECT_TYPE_PATH = 3,
	XPS_OBJECT_TYPE_MATRIX_TRANSFORM = 4,
	XPS_OBJECT_TYPE_GEOMETRY = 5,
	XPS_OBJECT_TYPE_SOLID_COLOR_BRUSH = 6,
	XPS_OBJECT_TYPE_IMAGE_BRUSH = 7,
	XPS_OBJECT_TYPE_LINEAR_GRADIENT_BRUSH = 8,
	XPS_OBJECT_TYPE_RADIAL_GRADIENT_BRUSH = 9,
	XPS_OBJECT_TYPE_VISUAL_BRUSH = 10,
}


[AllowDuplicates]
public enum XPS_THUMBNAIL_SIZE : int32
{
	XPS_THUMBNAIL_SIZE_VERYSMALL = 1,
	XPS_THUMBNAIL_SIZE_SMALL = 2,
	XPS_THUMBNAIL_SIZE_MEDIUM = 3,
	XPS_THUMBNAIL_SIZE_LARGE = 4,
}


[AllowDuplicates]
public enum XPS_INTERLEAVING : int32
{
	XPS_INTERLEAVING_OFF = 1,
	XPS_INTERLEAVING_ON = 2,
}


[AllowDuplicates]
public enum XPS_DOCUMENT_TYPE : int32
{
	XPS_DOCUMENT_TYPE_UNSPECIFIED = 1,
	XPS_DOCUMENT_TYPE_XPS = 2,
	XPS_DOCUMENT_TYPE_OPENXPS = 3,
}


[AllowDuplicates]
public enum XPS_SIGNATURE_STATUS : int32
{
	XPS_SIGNATURE_STATUS_INCOMPLIANT = 1,
	XPS_SIGNATURE_STATUS_INCOMPLETE = 2,
	XPS_SIGNATURE_STATUS_BROKEN = 3,
	XPS_SIGNATURE_STATUS_QUESTIONABLE = 4,
	XPS_SIGNATURE_STATUS_VALID = 5,
}


[AllowDuplicates]
public enum XPS_SIGN_POLICY : int32
{
	XPS_SIGN_POLICY_NONE = 0,
	XPS_SIGN_POLICY_CORE_PROPERTIES = 1,
	XPS_SIGN_POLICY_SIGNATURE_RELATIONSHIPS = 2,
	XPS_SIGN_POLICY_PRINT_TICKET = 4,
	XPS_SIGN_POLICY_DISCARD_CONTROL = 8,
	XPS_SIGN_POLICY_ALL = 15,
}


[AllowDuplicates]
public enum XPS_SIGN_FLAGS : int32
{
	XPS_SIGN_FLAGS_NONE = 0,
	XPS_SIGN_FLAGS_IGNORE_MARKUP_COMPATIBILITY = 1,
}

#endregion

#region Function Pointers
public function BOOL ABORTPROC(HDC param0, int32 param1);

#endregion

#region Structs
[CRepr]
public struct DRAWPATRECT
{
	public POINT ptPosition;
	public POINT ptSize;
	public uint16 wStyle;
	public uint16 wPattern;
}

[CRepr]
public struct PSINJECTDATA
{
	public uint32 DataBytes;
	public PSINJECT_POINT InjectionPoint;
	public uint16 PageNumber;
}

[CRepr]
public struct PSFEATURE_OUTPUT
{
	public BOOL bPageIndependent;
	public BOOL bSetPageDevice;
}

[CRepr]
public struct PSFEATURE_CUSTPAPER
{
	public int32 lOrientation;
	public int32 lWidth;
	public int32 lHeight;
	public int32 lWidthOffset;
	public int32 lHeightOffset;
}

[CRepr]
public struct DOCINFOA
{
	public int32 cbSize;
	public PSTR lpszDocName;
	public PSTR lpszOutput;
	public PSTR lpszDatatype;
	public uint32 fwType;
}

[CRepr]
public struct DOCINFOW
{
	public int32 cbSize;
	public PWSTR lpszDocName;
	public PWSTR lpszOutput;
	public PWSTR lpszDatatype;
	public uint32 fwType;
}

[CRepr]
public struct XPS_POINT
{
	public float x;
	public float y;
}

[CRepr]
public struct XPS_SIZE
{
	public float width;
	public float height;
}

[CRepr]
public struct XPS_RECT
{
	public float x;
	public float y;
	public float width;
	public float height;
}

[CRepr]
public struct XPS_DASH
{
	public float length;
	public float gap;
}

[CRepr]
public struct XPS_GLYPH_INDEX
{
	public int32 index;
	public float advanceWidth;
	public float horizontalOffset;
	public float verticalOffset;
}

[CRepr]
public struct XPS_GLYPH_MAPPING
{
	public uint32 unicodeStringStart;
	public uint16 unicodeStringLength;
	public uint32 glyphIndicesStart;
	public uint16 glyphIndicesLength;
}

[CRepr]
public struct XPS_MATRIX
{
	public float m11;
	public float m12;
	public float m21;
	public float m22;
	public float m31;
	public float m32;
}

[CRepr]
public struct XPS_COLOR
{
	[CRepr, Union]
	public struct XPS_COLOR_VALUE
	{
		[CRepr]
		public struct _scRGB_e__Struct
		{
			public float alpha;
			public float red;
			public float green;
			public float blue;
		}
		[CRepr]
		public struct _sRGB_e__Struct
		{
			public uint8 alpha;
			public uint8 red;
			public uint8 green;
			public uint8 blue;
		}
		[CRepr]
		public struct _context_e__Struct
		{
			public uint8 channelCount;
			public float[9] channels;
		}
		public _sRGB_e__Struct sRGB;
		public _scRGB_e__Struct scRGB;
		public _context_e__Struct context;
	}
	public XPS_COLOR_TYPE colorType;
	public XPS_COLOR_VALUE value;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_XpsOMObjectFactory = .(0xe974d26d, 0x3d9b, 0x4d47, 0x88, 0xcc, 0x38, 0x72, 0xf2, 0xdc, 0x35, 0x85);


	public const Guid CLSID_XpsOMThumbnailGenerator = .(0x7e4a23e2, 0xb969, 0x4761, 0xbe, 0x35, 0x1a, 0x8c, 0xed, 0x58, 0xe3, 0x23);


	public const Guid CLSID_XpsSignatureManager = .(0xb0c43320, 0x2315, 0x44a2, 0xb7, 0x0a, 0x09, 0x43, 0xa1, 0x40, 0xa8, 0xee);


}
#endregion

#region COM Types
[CRepr]struct IXpsOMShareable : IUnknown
{
	public new const Guid IID = .(0x7137398f, 0x2fc1, 0x454d, 0x8c, 0x6a, 0x2c, 0x31, 0x15, 0xa1, 0x6e, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_OBJECT_TYPE* type) COM_GetType;
	}


	public HRESULT GetOwner(IUnknown** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetType(XPS_OBJECT_TYPE* type) mut => VT.[Friend]COM_GetType(&this, type);
}

[CRepr]struct IXpsOMVisual : IXpsOMShareable
{
	public new const Guid IID = .(0xbc3e7333, 0xfb0b, 0x4af3, 0xa8, 0x19, 0x0b, 0x4e, 0xaa, 0xd0, 0xd2, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMShareable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** matrixTransform) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** matrixTransform) GetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform* matrixTransform) SetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** clipGeometry) GetClipGeometry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** clipGeometry) GetClipGeometryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry* clipGeometry) SetClipGeometryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetClipGeometryLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetClipGeometryLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* opacity) GetOpacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float opacity) SetOpacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** opacityMaskBrush) GetOpacityMaskBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** opacityMaskBrush) GetOpacityMaskBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush* opacityMaskBrush) SetOpacityMaskBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetOpacityMaskBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetOpacityMaskBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isHyperlink) GetIsHyperlinkTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isHyperlink) SetIsHyperlinkTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri** hyperlinkUri) GetHyperlinkNavigateUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri* hyperlinkUri) SetHyperlinkNavigateUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* language) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR language) SetLanguage;
	}


	public HRESULT GetTransform(IXpsOMMatrixTransform** matrixTransform) mut => VT.[Friend]GetTransform(&this, matrixTransform);

	public HRESULT GetTransformLocal(IXpsOMMatrixTransform** matrixTransform) mut => VT.[Friend]GetTransformLocal(&this, matrixTransform);

	public HRESULT SetTransformLocal(IXpsOMMatrixTransform* matrixTransform) mut => VT.[Friend]SetTransformLocal(&this, matrixTransform);

	public HRESULT GetTransformLookup(PWSTR* key) mut => VT.[Friend]GetTransformLookup(&this, key);

	public HRESULT SetTransformLookup(PWSTR key) mut => VT.[Friend]SetTransformLookup(&this, key);

	public HRESULT GetClipGeometry(IXpsOMGeometry** clipGeometry) mut => VT.[Friend]GetClipGeometry(&this, clipGeometry);

	public HRESULT GetClipGeometryLocal(IXpsOMGeometry** clipGeometry) mut => VT.[Friend]GetClipGeometryLocal(&this, clipGeometry);

	public HRESULT SetClipGeometryLocal(IXpsOMGeometry* clipGeometry) mut => VT.[Friend]SetClipGeometryLocal(&this, clipGeometry);

	public HRESULT GetClipGeometryLookup(PWSTR* key) mut => VT.[Friend]GetClipGeometryLookup(&this, key);

	public HRESULT SetClipGeometryLookup(PWSTR key) mut => VT.[Friend]SetClipGeometryLookup(&this, key);

	public HRESULT GetOpacity(float* opacity) mut => VT.[Friend]GetOpacity(&this, opacity);

	public HRESULT SetOpacity(float opacity) mut => VT.[Friend]SetOpacity(&this, opacity);

	public HRESULT GetOpacityMaskBrush(IXpsOMBrush** opacityMaskBrush) mut => VT.[Friend]GetOpacityMaskBrush(&this, opacityMaskBrush);

	public HRESULT GetOpacityMaskBrushLocal(IXpsOMBrush** opacityMaskBrush) mut => VT.[Friend]GetOpacityMaskBrushLocal(&this, opacityMaskBrush);

	public HRESULT SetOpacityMaskBrushLocal(IXpsOMBrush* opacityMaskBrush) mut => VT.[Friend]SetOpacityMaskBrushLocal(&this, opacityMaskBrush);

	public HRESULT GetOpacityMaskBrushLookup(PWSTR* key) mut => VT.[Friend]GetOpacityMaskBrushLookup(&this, key);

	public HRESULT SetOpacityMaskBrushLookup(PWSTR key) mut => VT.[Friend]SetOpacityMaskBrushLookup(&this, key);

	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT SetName(PWSTR name) mut => VT.[Friend]SetName(&this, name);

	public HRESULT GetIsHyperlinkTarget(BOOL* isHyperlink) mut => VT.[Friend]GetIsHyperlinkTarget(&this, isHyperlink);

	public HRESULT SetIsHyperlinkTarget(BOOL isHyperlink) mut => VT.[Friend]SetIsHyperlinkTarget(&this, isHyperlink);

	public HRESULT GetHyperlinkNavigateUri(IUri** hyperlinkUri) mut => VT.[Friend]GetHyperlinkNavigateUri(&this, hyperlinkUri);

	public HRESULT SetHyperlinkNavigateUri(IUri* hyperlinkUri) mut => VT.[Friend]SetHyperlinkNavigateUri(&this, hyperlinkUri);

	public HRESULT GetLanguage(PWSTR* language) mut => VT.[Friend]GetLanguage(&this, language);

	public HRESULT SetLanguage(PWSTR language) mut => VT.[Friend]SetLanguage(&this, language);
}

[CRepr]struct IXpsOMPart : IUnknown
{
	public new const Guid IID = .(0x74eb2f0b, 0xa91e, 0x4486, 0xaf, 0xac, 0x0f, 0xab, 0xec, 0xa3, 0xdf, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** partUri) GetPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri) SetPartName;
	}


	public HRESULT GetPartName(IOpcPartUri** partUri) mut => VT.[Friend]GetPartName(&this, partUri);

	public HRESULT SetPartName(IOpcPartUri* partUri) mut => VT.[Friend]SetPartName(&this, partUri);
}

[CRepr]struct IXpsOMGlyphsEditor : IUnknown
{
	public new const Guid IID = .(0xa5ab8616, 0x5b16, 0x4b9f, 0x96, 0x29, 0x89, 0xb3, 0x23, 0xed, 0x79, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ApplyEdits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* unicodeString) GetUnicodeString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR unicodeString) SetUnicodeString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* indexCount) GetGlyphIndexCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* indexCount, XPS_GLYPH_INDEX* glyphIndices) GetGlyphIndices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 indexCount, XPS_GLYPH_INDEX* glyphIndices) SetGlyphIndices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* glyphMappingCount) GetGlyphMappingCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) GetGlyphMappings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) SetGlyphMappings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* prohibitedCaretStopCount) GetProhibitedCaretStopCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count, uint32* prohibitedCaretStops) GetProhibitedCaretStops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 count, uint32* prohibitedCaretStops) SetProhibitedCaretStops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* bidiLevel) GetBidiLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 bidiLevel) SetBidiLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isSideways) GetIsSideways;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isSideways) SetIsSideways;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* deviceFontName) GetDeviceFontName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR deviceFontName) SetDeviceFontName;
	}


	public HRESULT ApplyEdits() mut => VT.[Friend]ApplyEdits(&this);

	public HRESULT GetUnicodeString(PWSTR* unicodeString) mut => VT.[Friend]GetUnicodeString(&this, unicodeString);

	public HRESULT SetUnicodeString(PWSTR unicodeString) mut => VT.[Friend]SetUnicodeString(&this, unicodeString);

	public HRESULT GetGlyphIndexCount(uint32* indexCount) mut => VT.[Friend]GetGlyphIndexCount(&this, indexCount);

	public HRESULT GetGlyphIndices(uint32* indexCount, XPS_GLYPH_INDEX* glyphIndices) mut => VT.[Friend]GetGlyphIndices(&this, indexCount, glyphIndices);

	public HRESULT SetGlyphIndices(uint32 indexCount, XPS_GLYPH_INDEX* glyphIndices) mut => VT.[Friend]SetGlyphIndices(&this, indexCount, glyphIndices);

	public HRESULT GetGlyphMappingCount(uint32* glyphMappingCount) mut => VT.[Friend]GetGlyphMappingCount(&this, glyphMappingCount);

	public HRESULT GetGlyphMappings(uint32* glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) mut => VT.[Friend]GetGlyphMappings(&this, glyphMappingCount, glyphMappings);

	public HRESULT SetGlyphMappings(uint32 glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) mut => VT.[Friend]SetGlyphMappings(&this, glyphMappingCount, glyphMappings);

	public HRESULT GetProhibitedCaretStopCount(uint32* prohibitedCaretStopCount) mut => VT.[Friend]GetProhibitedCaretStopCount(&this, prohibitedCaretStopCount);

	public HRESULT GetProhibitedCaretStops(uint32* count, uint32* prohibitedCaretStops) mut => VT.[Friend]GetProhibitedCaretStops(&this, count, prohibitedCaretStops);

	public HRESULT SetProhibitedCaretStops(uint32 count, uint32* prohibitedCaretStops) mut => VT.[Friend]SetProhibitedCaretStops(&this, count, prohibitedCaretStops);

	public HRESULT GetBidiLevel(uint32* bidiLevel) mut => VT.[Friend]GetBidiLevel(&this, bidiLevel);

	public HRESULT SetBidiLevel(uint32 bidiLevel) mut => VT.[Friend]SetBidiLevel(&this, bidiLevel);

	public HRESULT GetIsSideways(BOOL* isSideways) mut => VT.[Friend]GetIsSideways(&this, isSideways);

	public HRESULT SetIsSideways(BOOL isSideways) mut => VT.[Friend]SetIsSideways(&this, isSideways);

	public HRESULT GetDeviceFontName(PWSTR* deviceFontName) mut => VT.[Friend]GetDeviceFontName(&this, deviceFontName);

	public HRESULT SetDeviceFontName(PWSTR deviceFontName) mut => VT.[Friend]SetDeviceFontName(&this, deviceFontName);
}

[CRepr]struct IXpsOMGlyphs : IXpsOMVisual
{
	public new const Guid IID = .(0x819b3199, 0x0a5a, 0x4b64, 0xbe, 0xc7, 0xa9, 0xe1, 0x7e, 0x78, 0x0d, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMVisual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* unicodeString) GetUnicodeString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* indexCount) GetGlyphIndexCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* indexCount, XPS_GLYPH_INDEX* glyphIndices) GetGlyphIndices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* glyphMappingCount) GetGlyphMappingCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) GetGlyphMappings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* prohibitedCaretStopCount) GetProhibitedCaretStopCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* prohibitedCaretStopCount, uint32* prohibitedCaretStops) GetProhibitedCaretStops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* bidiLevel) GetBidiLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isSideways) GetIsSideways;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* deviceFontName) GetDeviceFontName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_STYLE_SIMULATION* styleSimulations) GetStyleSimulations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_STYLE_SIMULATION styleSimulations) SetStyleSimulations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* origin) GetOrigin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* origin) SetOrigin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* fontRenderingEmSize) GetFontRenderingEmSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float fontRenderingEmSize) SetFontRenderingEmSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMFontResource** fontResource) GetFontResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMFontResource* fontResource) SetFontResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* fontFaceIndex) GetFontFaceIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fontFaceIndex) SetFontFaceIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** fillBrush) GetFillBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** fillBrush) GetFillBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush* fillBrush) SetFillBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetFillBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetFillBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGlyphsEditor** editor) GetGlyphsEditor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGlyphs** glyphs) Clone;
	}


	public HRESULT GetUnicodeString(PWSTR* unicodeString) mut => VT.[Friend]GetUnicodeString(&this, unicodeString);

	public HRESULT GetGlyphIndexCount(uint32* indexCount) mut => VT.[Friend]GetGlyphIndexCount(&this, indexCount);

	public HRESULT GetGlyphIndices(uint32* indexCount, XPS_GLYPH_INDEX* glyphIndices) mut => VT.[Friend]GetGlyphIndices(&this, indexCount, glyphIndices);

	public HRESULT GetGlyphMappingCount(uint32* glyphMappingCount) mut => VT.[Friend]GetGlyphMappingCount(&this, glyphMappingCount);

	public HRESULT GetGlyphMappings(uint32* glyphMappingCount, XPS_GLYPH_MAPPING* glyphMappings) mut => VT.[Friend]GetGlyphMappings(&this, glyphMappingCount, glyphMappings);

	public HRESULT GetProhibitedCaretStopCount(uint32* prohibitedCaretStopCount) mut => VT.[Friend]GetProhibitedCaretStopCount(&this, prohibitedCaretStopCount);

	public HRESULT GetProhibitedCaretStops(uint32* prohibitedCaretStopCount, uint32* prohibitedCaretStops) mut => VT.[Friend]GetProhibitedCaretStops(&this, prohibitedCaretStopCount, prohibitedCaretStops);

	public HRESULT GetBidiLevel(uint32* bidiLevel) mut => VT.[Friend]GetBidiLevel(&this, bidiLevel);

	public HRESULT GetIsSideways(BOOL* isSideways) mut => VT.[Friend]GetIsSideways(&this, isSideways);

	public HRESULT GetDeviceFontName(PWSTR* deviceFontName) mut => VT.[Friend]GetDeviceFontName(&this, deviceFontName);

	public HRESULT GetStyleSimulations(XPS_STYLE_SIMULATION* styleSimulations) mut => VT.[Friend]GetStyleSimulations(&this, styleSimulations);

	public HRESULT SetStyleSimulations(XPS_STYLE_SIMULATION styleSimulations) mut => VT.[Friend]SetStyleSimulations(&this, styleSimulations);

	public HRESULT GetOrigin(XPS_POINT* origin) mut => VT.[Friend]GetOrigin(&this, origin);

	public HRESULT SetOrigin(XPS_POINT* origin) mut => VT.[Friend]SetOrigin(&this, origin);

	public HRESULT GetFontRenderingEmSize(float* fontRenderingEmSize) mut => VT.[Friend]GetFontRenderingEmSize(&this, fontRenderingEmSize);

	public HRESULT SetFontRenderingEmSize(float fontRenderingEmSize) mut => VT.[Friend]SetFontRenderingEmSize(&this, fontRenderingEmSize);

	public HRESULT GetFontResource(IXpsOMFontResource** fontResource) mut => VT.[Friend]GetFontResource(&this, fontResource);

	public HRESULT SetFontResource(IXpsOMFontResource* fontResource) mut => VT.[Friend]SetFontResource(&this, fontResource);

	public HRESULT GetFontFaceIndex(int16* fontFaceIndex) mut => VT.[Friend]GetFontFaceIndex(&this, fontFaceIndex);

	public HRESULT SetFontFaceIndex(int16 fontFaceIndex) mut => VT.[Friend]SetFontFaceIndex(&this, fontFaceIndex);

	public HRESULT GetFillBrush(IXpsOMBrush** fillBrush) mut => VT.[Friend]GetFillBrush(&this, fillBrush);

	public HRESULT GetFillBrushLocal(IXpsOMBrush** fillBrush) mut => VT.[Friend]GetFillBrushLocal(&this, fillBrush);

	public HRESULT SetFillBrushLocal(IXpsOMBrush* fillBrush) mut => VT.[Friend]SetFillBrushLocal(&this, fillBrush);

	public HRESULT GetFillBrushLookup(PWSTR* key) mut => VT.[Friend]GetFillBrushLookup(&this, key);

	public HRESULT SetFillBrushLookup(PWSTR key) mut => VT.[Friend]SetFillBrushLookup(&this, key);

	public HRESULT GetGlyphsEditor(IXpsOMGlyphsEditor** editor) mut => VT.[Friend]GetGlyphsEditor(&this, editor);

	public HRESULT Clone(IXpsOMGlyphs** glyphs) mut => VT.[Friend]Clone(&this, glyphs);
}

[CRepr]struct IXpsOMDashCollection : IUnknown
{
	public new const Guid IID = .(0x081613f4, 0x74eb, 0x48f2, 0x83, 0xb3, 0x37, 0xa9, 0xce, 0x2d, 0x7d, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, XPS_DASH* dash) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, XPS_DASH* dash) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, XPS_DASH* dash) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DASH* dash) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, XPS_DASH* dash) mut => VT.[Friend]GetAt(&this, index, dash);

	public HRESULT InsertAt(uint32 index, XPS_DASH* dash) mut => VT.[Friend]InsertAt(&this, index, dash);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, XPS_DASH* dash) mut => VT.[Friend]SetAt(&this, index, dash);

	public HRESULT Append(XPS_DASH* dash) mut => VT.[Friend]Append(&this, dash);
}

[CRepr]struct IXpsOMMatrixTransform : IXpsOMShareable
{
	public new const Guid IID = .(0xb77330ff, 0xbb37, 0x4501, 0xa9, 0x3e, 0xf1, 0xb1, 0xe5, 0x0b, 0xfc, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMShareable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_MATRIX* matrix) GetMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_MATRIX* matrix) SetMatrix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** matrixTransform) Clone;
	}


	public HRESULT GetMatrix(XPS_MATRIX* matrix) mut => VT.[Friend]GetMatrix(&this, matrix);

	public HRESULT SetMatrix(XPS_MATRIX* matrix) mut => VT.[Friend]SetMatrix(&this, matrix);

	public HRESULT Clone(IXpsOMMatrixTransform** matrixTransform) mut => VT.[Friend]Clone(&this, matrixTransform);
}

[CRepr]struct IXpsOMGeometry : IXpsOMShareable
{
	public new const Guid IID = .(0x64fcf3d7, 0x4d58, 0x44ba, 0xad, 0x73, 0xa1, 0x3a, 0xf6, 0x49, 0x20, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMShareable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometryFigureCollection** figures) GetFigures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_FILL_RULE* fillRule) GetFillRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_FILL_RULE fillRule) SetFillRule;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform* transform) SetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lookup) GetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lookup) SetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** geometry) Clone;
	}


	public HRESULT GetFigures(IXpsOMGeometryFigureCollection** figures) mut => VT.[Friend]GetFigures(&this, figures);

	public HRESULT GetFillRule(XPS_FILL_RULE* fillRule) mut => VT.[Friend]GetFillRule(&this, fillRule);

	public HRESULT SetFillRule(XPS_FILL_RULE fillRule) mut => VT.[Friend]SetFillRule(&this, fillRule);

	public HRESULT GetTransform(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransform(&this, transform);

	public HRESULT GetTransformLocal(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransformLocal(&this, transform);

	public HRESULT SetTransformLocal(IXpsOMMatrixTransform* transform) mut => VT.[Friend]SetTransformLocal(&this, transform);

	public HRESULT GetTransformLookup(PWSTR* lookup) mut => VT.[Friend]GetTransformLookup(&this, lookup);

	public HRESULT SetTransformLookup(PWSTR lookup) mut => VT.[Friend]SetTransformLookup(&this, lookup);

	public HRESULT Clone(IXpsOMGeometry** geometry) mut => VT.[Friend]Clone(&this, geometry);
}

[CRepr]struct IXpsOMGeometryFigure : IUnknown
{
	public new const Guid IID = .(0xd410dc83, 0x908c, 0x443e, 0x89, 0x47, 0xb1, 0x79, 0x5d, 0x3c, 0x16, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dataCount, float* segmentData) GetSegmentData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* segmentCount, XPS_SEGMENT_TYPE* segmentTypes) GetSegmentTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* segmentCount, BOOL* segmentStrokes) GetSegmentStrokes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 segmentCount, uint32 segmentDataCount, XPS_SEGMENT_TYPE* segmentTypes, float* segmentData, BOOL* segmentStrokes) SetSegments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* startPoint) GetStartPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* startPoint) SetStartPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isClosed) GetIsClosed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isClosed) SetIsClosed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isFilled) GetIsFilled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isFilled) SetIsFilled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* segmentCount) GetSegmentCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* segmentDataCount) GetSegmentDataCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SEGMENT_STROKE_PATTERN* segmentStrokePattern) GetSegmentStrokePattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometryFigure** geometryFigure) Clone;
	}


	public HRESULT GetOwner(IXpsOMGeometry** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetSegmentData(uint32* dataCount, float* segmentData) mut => VT.[Friend]GetSegmentData(&this, dataCount, segmentData);

	public HRESULT GetSegmentTypes(uint32* segmentCount, XPS_SEGMENT_TYPE* segmentTypes) mut => VT.[Friend]GetSegmentTypes(&this, segmentCount, segmentTypes);

	public HRESULT GetSegmentStrokes(uint32* segmentCount, BOOL* segmentStrokes) mut => VT.[Friend]GetSegmentStrokes(&this, segmentCount, segmentStrokes);

	public HRESULT SetSegments(uint32 segmentCount, uint32 segmentDataCount, XPS_SEGMENT_TYPE* segmentTypes, float* segmentData, BOOL* segmentStrokes) mut => VT.[Friend]SetSegments(&this, segmentCount, segmentDataCount, segmentTypes, segmentData, segmentStrokes);

	public HRESULT GetStartPoint(XPS_POINT* startPoint) mut => VT.[Friend]GetStartPoint(&this, startPoint);

	public HRESULT SetStartPoint(XPS_POINT* startPoint) mut => VT.[Friend]SetStartPoint(&this, startPoint);

	public HRESULT GetIsClosed(BOOL* isClosed) mut => VT.[Friend]GetIsClosed(&this, isClosed);

	public HRESULT SetIsClosed(BOOL isClosed) mut => VT.[Friend]SetIsClosed(&this, isClosed);

	public HRESULT GetIsFilled(BOOL* isFilled) mut => VT.[Friend]GetIsFilled(&this, isFilled);

	public HRESULT SetIsFilled(BOOL isFilled) mut => VT.[Friend]SetIsFilled(&this, isFilled);

	public HRESULT GetSegmentCount(uint32* segmentCount) mut => VT.[Friend]GetSegmentCount(&this, segmentCount);

	public HRESULT GetSegmentDataCount(uint32* segmentDataCount) mut => VT.[Friend]GetSegmentDataCount(&this, segmentDataCount);

	public HRESULT GetSegmentStrokePattern(XPS_SEGMENT_STROKE_PATTERN* segmentStrokePattern) mut => VT.[Friend]GetSegmentStrokePattern(&this, segmentStrokePattern);

	public HRESULT Clone(IXpsOMGeometryFigure** geometryFigure) mut => VT.[Friend]Clone(&this, geometryFigure);
}

[CRepr]struct IXpsOMGeometryFigureCollection : IUnknown
{
	public new const Guid IID = .(0xfd48c3f3, 0xa58e, 0x4b5a, 0x88, 0x26, 0x1d, 0xe5, 0x4a, 0xbe, 0x72, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGeometryFigure** geometryFigure) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGeometryFigure* geometryFigure) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGeometryFigure* geometryFigure) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometryFigure* geometryFigure) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMGeometryFigure** geometryFigure) mut => VT.[Friend]GetAt(&this, index, geometryFigure);

	public HRESULT InsertAt(uint32 index, IXpsOMGeometryFigure* geometryFigure) mut => VT.[Friend]InsertAt(&this, index, geometryFigure);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMGeometryFigure* geometryFigure) mut => VT.[Friend]SetAt(&this, index, geometryFigure);

	public HRESULT Append(IXpsOMGeometryFigure* geometryFigure) mut => VT.[Friend]Append(&this, geometryFigure);
}

[CRepr]struct IXpsOMPath : IXpsOMVisual
{
	public new const Guid IID = .(0x37d38bb6, 0x3ee9, 0x4110, 0x93, 0x12, 0x14, 0xb1, 0x94, 0x16, 0x33, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMVisual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** geometry) GetGeometry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** geometry) GetGeometryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry* geometry) SetGeometryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lookup) GetGeometryLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lookup) SetGeometryLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* shortDescription) GetAccessibilityShortDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR shortDescription) SetAccessibilityShortDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* longDescription) GetAccessibilityLongDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR longDescription) SetAccessibilityLongDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* snapsToPixels) GetSnapsToPixels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL snapsToPixels) SetSnapsToPixels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** brush) GetStrokeBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** brush) GetStrokeBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush* brush) SetStrokeBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lookup) GetStrokeBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lookup) SetStrokeBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDashCollection** strokeDashes) GetStrokeDashes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DASH_CAP* strokeDashCap) GetStrokeDashCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DASH_CAP strokeDashCap) SetStrokeDashCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* strokeDashOffset) GetStrokeDashOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float strokeDashOffset) SetStrokeDashOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_CAP* strokeStartLineCap) GetStrokeStartLineCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_CAP strokeStartLineCap) SetStrokeStartLineCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_CAP* strokeEndLineCap) GetStrokeEndLineCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_CAP strokeEndLineCap) SetStrokeEndLineCap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_JOIN* strokeLineJoin) GetStrokeLineJoin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_LINE_JOIN strokeLineJoin) SetStrokeLineJoin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* strokeMiterLimit) GetStrokeMiterLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float strokeMiterLimit) SetStrokeMiterLimit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* strokeThickness) GetStrokeThickness;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float strokeThickness) SetStrokeThickness;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** brush) GetFillBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush** brush) GetFillBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMBrush* brush) SetFillBrushLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lookup) GetFillBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lookup) SetFillBrushLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPath** path) Clone;
	}


	public HRESULT GetGeometry(IXpsOMGeometry** geometry) mut => VT.[Friend]GetGeometry(&this, geometry);

	public HRESULT GetGeometryLocal(IXpsOMGeometry** geometry) mut => VT.[Friend]GetGeometryLocal(&this, geometry);

	public HRESULT SetGeometryLocal(IXpsOMGeometry* geometry) mut => VT.[Friend]SetGeometryLocal(&this, geometry);

	public HRESULT GetGeometryLookup(PWSTR* lookup) mut => VT.[Friend]GetGeometryLookup(&this, lookup);

	public HRESULT SetGeometryLookup(PWSTR lookup) mut => VT.[Friend]SetGeometryLookup(&this, lookup);

	public HRESULT GetAccessibilityShortDescription(PWSTR* shortDescription) mut => VT.[Friend]GetAccessibilityShortDescription(&this, shortDescription);

	public HRESULT SetAccessibilityShortDescription(PWSTR shortDescription) mut => VT.[Friend]SetAccessibilityShortDescription(&this, shortDescription);

	public HRESULT GetAccessibilityLongDescription(PWSTR* longDescription) mut => VT.[Friend]GetAccessibilityLongDescription(&this, longDescription);

	public HRESULT SetAccessibilityLongDescription(PWSTR longDescription) mut => VT.[Friend]SetAccessibilityLongDescription(&this, longDescription);

	public HRESULT GetSnapsToPixels(BOOL* snapsToPixels) mut => VT.[Friend]GetSnapsToPixels(&this, snapsToPixels);

	public HRESULT SetSnapsToPixels(BOOL snapsToPixels) mut => VT.[Friend]SetSnapsToPixels(&this, snapsToPixels);

	public HRESULT GetStrokeBrush(IXpsOMBrush** brush) mut => VT.[Friend]GetStrokeBrush(&this, brush);

	public HRESULT GetStrokeBrushLocal(IXpsOMBrush** brush) mut => VT.[Friend]GetStrokeBrushLocal(&this, brush);

	public HRESULT SetStrokeBrushLocal(IXpsOMBrush* brush) mut => VT.[Friend]SetStrokeBrushLocal(&this, brush);

	public HRESULT GetStrokeBrushLookup(PWSTR* lookup) mut => VT.[Friend]GetStrokeBrushLookup(&this, lookup);

	public HRESULT SetStrokeBrushLookup(PWSTR lookup) mut => VT.[Friend]SetStrokeBrushLookup(&this, lookup);

	public HRESULT GetStrokeDashes(IXpsOMDashCollection** strokeDashes) mut => VT.[Friend]GetStrokeDashes(&this, strokeDashes);

	public HRESULT GetStrokeDashCap(XPS_DASH_CAP* strokeDashCap) mut => VT.[Friend]GetStrokeDashCap(&this, strokeDashCap);

	public HRESULT SetStrokeDashCap(XPS_DASH_CAP strokeDashCap) mut => VT.[Friend]SetStrokeDashCap(&this, strokeDashCap);

	public HRESULT GetStrokeDashOffset(float* strokeDashOffset) mut => VT.[Friend]GetStrokeDashOffset(&this, strokeDashOffset);

	public HRESULT SetStrokeDashOffset(float strokeDashOffset) mut => VT.[Friend]SetStrokeDashOffset(&this, strokeDashOffset);

	public HRESULT GetStrokeStartLineCap(XPS_LINE_CAP* strokeStartLineCap) mut => VT.[Friend]GetStrokeStartLineCap(&this, strokeStartLineCap);

	public HRESULT SetStrokeStartLineCap(XPS_LINE_CAP strokeStartLineCap) mut => VT.[Friend]SetStrokeStartLineCap(&this, strokeStartLineCap);

	public HRESULT GetStrokeEndLineCap(XPS_LINE_CAP* strokeEndLineCap) mut => VT.[Friend]GetStrokeEndLineCap(&this, strokeEndLineCap);

	public HRESULT SetStrokeEndLineCap(XPS_LINE_CAP strokeEndLineCap) mut => VT.[Friend]SetStrokeEndLineCap(&this, strokeEndLineCap);

	public HRESULT GetStrokeLineJoin(XPS_LINE_JOIN* strokeLineJoin) mut => VT.[Friend]GetStrokeLineJoin(&this, strokeLineJoin);

	public HRESULT SetStrokeLineJoin(XPS_LINE_JOIN strokeLineJoin) mut => VT.[Friend]SetStrokeLineJoin(&this, strokeLineJoin);

	public HRESULT GetStrokeMiterLimit(float* strokeMiterLimit) mut => VT.[Friend]GetStrokeMiterLimit(&this, strokeMiterLimit);

	public HRESULT SetStrokeMiterLimit(float strokeMiterLimit) mut => VT.[Friend]SetStrokeMiterLimit(&this, strokeMiterLimit);

	public HRESULT GetStrokeThickness(float* strokeThickness) mut => VT.[Friend]GetStrokeThickness(&this, strokeThickness);

	public HRESULT SetStrokeThickness(float strokeThickness) mut => VT.[Friend]SetStrokeThickness(&this, strokeThickness);

	public HRESULT GetFillBrush(IXpsOMBrush** brush) mut => VT.[Friend]GetFillBrush(&this, brush);

	public HRESULT GetFillBrushLocal(IXpsOMBrush** brush) mut => VT.[Friend]GetFillBrushLocal(&this, brush);

	public HRESULT SetFillBrushLocal(IXpsOMBrush* brush) mut => VT.[Friend]SetFillBrushLocal(&this, brush);

	public HRESULT GetFillBrushLookup(PWSTR* lookup) mut => VT.[Friend]GetFillBrushLookup(&this, lookup);

	public HRESULT SetFillBrushLookup(PWSTR lookup) mut => VT.[Friend]SetFillBrushLookup(&this, lookup);

	public HRESULT Clone(IXpsOMPath** path) mut => VT.[Friend]Clone(&this, path);
}

[CRepr]struct IXpsOMBrush : IXpsOMShareable
{
	public new const Guid IID = .(0x56a3f80c, 0xea4c, 0x4187, 0xa5, 0x7b, 0xa2, 0xa4, 0x73, 0xb2, 0xb4, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMShareable.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* opacity) GetOpacity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float opacity) SetOpacity;
	}


	public HRESULT GetOpacity(float* opacity) mut => VT.[Friend]GetOpacity(&this, opacity);

	public HRESULT SetOpacity(float opacity) mut => VT.[Friend]SetOpacity(&this, opacity);
}

[CRepr]struct IXpsOMGradientStopCollection : IUnknown
{
	public new const Guid IID = .(0xc9174c3a, 0x3cd3, 0x4319, 0xbd, 0xa4, 0x11, 0xa3, 0x93, 0x92, 0xce, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGradientStop** stop) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGradientStop* stop) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMGradientStop* stop) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientStop* stop) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMGradientStop** stop) mut => VT.[Friend]GetAt(&this, index, stop);

	public HRESULT InsertAt(uint32 index, IXpsOMGradientStop* stop) mut => VT.[Friend]InsertAt(&this, index, stop);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMGradientStop* stop) mut => VT.[Friend]SetAt(&this, index, stop);

	public HRESULT Append(IXpsOMGradientStop* stop) mut => VT.[Friend]Append(&this, stop);
}

[CRepr]struct IXpsOMSolidColorBrush : IXpsOMBrush
{
	public new const Guid IID = .(0xa06f9f05, 0x3be9, 0x4763, 0x98, 0xa8, 0x09, 0x4f, 0xc6, 0x72, 0xe4, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource** colorProfile) GetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile) SetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMSolidColorBrush** solidColorBrush) Clone;
	}


	public HRESULT GetColor(XPS_COLOR* color, IXpsOMColorProfileResource** colorProfile) mut => VT.[Friend]GetColor(&this, color, colorProfile);

	public HRESULT SetColor(XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile) mut => VT.[Friend]SetColor(&this, color, colorProfile);

	public HRESULT Clone(IXpsOMSolidColorBrush** solidColorBrush) mut => VT.[Friend]Clone(&this, solidColorBrush);
}

[CRepr]struct IXpsOMTileBrush : IXpsOMBrush
{
	public new const Guid IID = .(0x0fc2328d, 0xd722, 0x4a54, 0xb2, 0xec, 0xbe, 0x90, 0x21, 0x8a, 0x78, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform* transform) SetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* viewbox) GetViewbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* viewbox) SetViewbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* viewport) GetViewport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* viewport) SetViewport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_TILE_MODE* tileMode) GetTileMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_TILE_MODE tileMode) SetTileMode;
	}


	public HRESULT GetTransform(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransform(&this, transform);

	public HRESULT GetTransformLocal(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransformLocal(&this, transform);

	public HRESULT SetTransformLocal(IXpsOMMatrixTransform* transform) mut => VT.[Friend]SetTransformLocal(&this, transform);

	public HRESULT GetTransformLookup(PWSTR* key) mut => VT.[Friend]GetTransformLookup(&this, key);

	public HRESULT SetTransformLookup(PWSTR key) mut => VT.[Friend]SetTransformLookup(&this, key);

	public HRESULT GetViewbox(XPS_RECT* viewbox) mut => VT.[Friend]GetViewbox(&this, viewbox);

	public HRESULT SetViewbox(XPS_RECT* viewbox) mut => VT.[Friend]SetViewbox(&this, viewbox);

	public HRESULT GetViewport(XPS_RECT* viewport) mut => VT.[Friend]GetViewport(&this, viewport);

	public HRESULT SetViewport(XPS_RECT* viewport) mut => VT.[Friend]SetViewport(&this, viewport);

	public HRESULT GetTileMode(XPS_TILE_MODE* tileMode) mut => VT.[Friend]GetTileMode(&this, tileMode);

	public HRESULT SetTileMode(XPS_TILE_MODE tileMode) mut => VT.[Friend]SetTileMode(&this, tileMode);
}

[CRepr]struct IXpsOMVisualBrush : IXpsOMTileBrush
{
	public new const Guid IID = .(0x97e294af, 0x5b37, 0x46b4, 0x80, 0x57, 0x87, 0x4d, 0x2f, 0x64, 0x11, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMTileBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisual** visual) GetVisual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisual** visual) GetVisualLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisual* visual) SetVisualLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lookup) GetVisualLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lookup) SetVisualLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisualBrush** visualBrush) Clone;
	}


	public HRESULT GetVisual(IXpsOMVisual** visual) mut => VT.[Friend]GetVisual(&this, visual);

	public HRESULT GetVisualLocal(IXpsOMVisual** visual) mut => VT.[Friend]GetVisualLocal(&this, visual);

	public HRESULT SetVisualLocal(IXpsOMVisual* visual) mut => VT.[Friend]SetVisualLocal(&this, visual);

	public HRESULT GetVisualLookup(PWSTR* lookup) mut => VT.[Friend]GetVisualLookup(&this, lookup);

	public HRESULT SetVisualLookup(PWSTR lookup) mut => VT.[Friend]SetVisualLookup(&this, lookup);

	public HRESULT Clone(IXpsOMVisualBrush** visualBrush) mut => VT.[Friend]Clone(&this, visualBrush);
}

[CRepr]struct IXpsOMImageBrush : IXpsOMTileBrush
{
	public new const Guid IID = .(0x3df0b466, 0xd382, 0x49ef, 0x85, 0x50, 0xdd, 0x94, 0xc8, 0x02, 0x42, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMTileBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource** imageResource) GetImageResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* imageResource) SetImageResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMColorProfileResource** colorProfileResource) GetColorProfileResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMColorProfileResource* colorProfileResource) SetColorProfileResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageBrush** imageBrush) Clone;
	}


	public HRESULT GetImageResource(IXpsOMImageResource** imageResource) mut => VT.[Friend]GetImageResource(&this, imageResource);

	public HRESULT SetImageResource(IXpsOMImageResource* imageResource) mut => VT.[Friend]SetImageResource(&this, imageResource);

	public HRESULT GetColorProfileResource(IXpsOMColorProfileResource** colorProfileResource) mut => VT.[Friend]GetColorProfileResource(&this, colorProfileResource);

	public HRESULT SetColorProfileResource(IXpsOMColorProfileResource* colorProfileResource) mut => VT.[Friend]SetColorProfileResource(&this, colorProfileResource);

	public HRESULT Clone(IXpsOMImageBrush** imageBrush) mut => VT.[Friend]Clone(&this, imageBrush);
}

[CRepr]struct IXpsOMGradientStop : IUnknown
{
	public new const Guid IID = .(0x5cf4f5cc, 0x3969, 0x49b5, 0xa7, 0x0a, 0x55, 0x50, 0xb6, 0x18, 0xfe, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientBrush** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* offset) GetOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float offset) SetOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource** colorProfile) GetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile) SetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientStop** gradientStop) Clone;
	}


	public HRESULT GetOwner(IXpsOMGradientBrush** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetOffset(float* offset) mut => VT.[Friend]GetOffset(&this, offset);

	public HRESULT SetOffset(float offset) mut => VT.[Friend]SetOffset(&this, offset);

	public HRESULT GetColor(XPS_COLOR* color, IXpsOMColorProfileResource** colorProfile) mut => VT.[Friend]GetColor(&this, color, colorProfile);

	public HRESULT SetColor(XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile) mut => VT.[Friend]SetColor(&this, color, colorProfile);

	public HRESULT Clone(IXpsOMGradientStop** gradientStop) mut => VT.[Friend]Clone(&this, gradientStop);
}

[CRepr]struct IXpsOMGradientBrush : IXpsOMBrush
{
	public new const Guid IID = .(0xedb59622, 0x61a2, 0x42c3, 0xba, 0xce, 0xac, 0xf2, 0x28, 0x6c, 0x06, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientStopCollection** gradientStops) GetGradientStops;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform** transform) GetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMMatrixTransform* transform) SetTransformLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* key) GetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key) SetTransformLookup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SPREAD_METHOD* spreadMethod) GetSpreadMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SPREAD_METHOD spreadMethod) SetSpreadMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR_INTERPOLATION* colorInterpolationMode) GetColorInterpolationMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR_INTERPOLATION colorInterpolationMode) SetColorInterpolationMode;
	}


	public HRESULT GetGradientStops(IXpsOMGradientStopCollection** gradientStops) mut => VT.[Friend]GetGradientStops(&this, gradientStops);

	public HRESULT GetTransform(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransform(&this, transform);

	public HRESULT GetTransformLocal(IXpsOMMatrixTransform** transform) mut => VT.[Friend]GetTransformLocal(&this, transform);

	public HRESULT SetTransformLocal(IXpsOMMatrixTransform* transform) mut => VT.[Friend]SetTransformLocal(&this, transform);

	public HRESULT GetTransformLookup(PWSTR* key) mut => VT.[Friend]GetTransformLookup(&this, key);

	public HRESULT SetTransformLookup(PWSTR key) mut => VT.[Friend]SetTransformLookup(&this, key);

	public HRESULT GetSpreadMethod(XPS_SPREAD_METHOD* spreadMethod) mut => VT.[Friend]GetSpreadMethod(&this, spreadMethod);

	public HRESULT SetSpreadMethod(XPS_SPREAD_METHOD spreadMethod) mut => VT.[Friend]SetSpreadMethod(&this, spreadMethod);

	public HRESULT GetColorInterpolationMode(XPS_COLOR_INTERPOLATION* colorInterpolationMode) mut => VT.[Friend]GetColorInterpolationMode(&this, colorInterpolationMode);

	public HRESULT SetColorInterpolationMode(XPS_COLOR_INTERPOLATION colorInterpolationMode) mut => VT.[Friend]SetColorInterpolationMode(&this, colorInterpolationMode);
}

[CRepr]struct IXpsOMLinearGradientBrush : IXpsOMGradientBrush
{
	public new const Guid IID = .(0x005e279f, 0xc30d, 0x40ff, 0x93, 0xec, 0x19, 0x50, 0xd3, 0xc5, 0x28, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMGradientBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* startPoint) GetStartPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* startPoint) SetStartPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* endPoint) GetEndPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* endPoint) SetEndPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMLinearGradientBrush** linearGradientBrush) Clone;
	}


	public HRESULT GetStartPoint(XPS_POINT* startPoint) mut => VT.[Friend]GetStartPoint(&this, startPoint);

	public HRESULT SetStartPoint(XPS_POINT* startPoint) mut => VT.[Friend]SetStartPoint(&this, startPoint);

	public HRESULT GetEndPoint(XPS_POINT* endPoint) mut => VT.[Friend]GetEndPoint(&this, endPoint);

	public HRESULT SetEndPoint(XPS_POINT* endPoint) mut => VT.[Friend]SetEndPoint(&this, endPoint);

	public HRESULT Clone(IXpsOMLinearGradientBrush** linearGradientBrush) mut => VT.[Friend]Clone(&this, linearGradientBrush);
}

[CRepr]struct IXpsOMRadialGradientBrush : IXpsOMGradientBrush
{
	public new const Guid IID = .(0x75f207e5, 0x08bf, 0x413c, 0x96, 0xb1, 0xb8, 0x2b, 0x40, 0x64, 0x17, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMGradientBrush.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* center) GetCenter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* center) SetCenter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* radiiSizes) GetRadiiSizes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* radiiSizes) SetRadiiSizes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* origin) GetGradientOrigin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* origin) SetGradientOrigin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRadialGradientBrush** radialGradientBrush) Clone;
	}


	public HRESULT GetCenter(XPS_POINT* center) mut => VT.[Friend]GetCenter(&this, center);

	public HRESULT SetCenter(XPS_POINT* center) mut => VT.[Friend]SetCenter(&this, center);

	public HRESULT GetRadiiSizes(XPS_SIZE* radiiSizes) mut => VT.[Friend]GetRadiiSizes(&this, radiiSizes);

	public HRESULT SetRadiiSizes(XPS_SIZE* radiiSizes) mut => VT.[Friend]SetRadiiSizes(&this, radiiSizes);

	public HRESULT GetGradientOrigin(XPS_POINT* origin) mut => VT.[Friend]GetGradientOrigin(&this, origin);

	public HRESULT SetGradientOrigin(XPS_POINT* origin) mut => VT.[Friend]SetGradientOrigin(&this, origin);

	public HRESULT Clone(IXpsOMRadialGradientBrush** radialGradientBrush) mut => VT.[Friend]Clone(&this, radialGradientBrush);
}

[CRepr]struct IXpsOMResource : IXpsOMPart
{
	public new const Guid IID = .(0xda2ac0a2, 0x73a2, 0x4975, 0xad, 0x14, 0x74, 0x09, 0x7c, 0x3f, 0xf3, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPart.VTable
	{
	}

}

[CRepr]struct IXpsOMPartResources : IUnknown
{
	public new const Guid IID = .(0xf4cf7729, 0x4864, 0x4275, 0x99, 0xb3, 0xa8, 0x71, 0x71, 0x63, 0xec, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMFontResourceCollection** fontResources) GetFontResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResourceCollection** imageResources) GetImageResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMColorProfileResourceCollection** colorProfileResources) GetColorProfileResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResourceCollection** dictionaryResources) GetRemoteDictionaryResources;
	}


	public HRESULT GetFontResources(IXpsOMFontResourceCollection** fontResources) mut => VT.[Friend]GetFontResources(&this, fontResources);

	public HRESULT GetImageResources(IXpsOMImageResourceCollection** imageResources) mut => VT.[Friend]GetImageResources(&this, imageResources);

	public HRESULT GetColorProfileResources(IXpsOMColorProfileResourceCollection** colorProfileResources) mut => VT.[Friend]GetColorProfileResources(&this, colorProfileResources);

	public HRESULT GetRemoteDictionaryResources(IXpsOMRemoteDictionaryResourceCollection** dictionaryResources) mut => VT.[Friend]GetRemoteDictionaryResources(&this, dictionaryResources);
}

[CRepr]struct IXpsOMDictionary : IUnknown
{
	public new const Guid IID = .(0x897c86b8, 0x8eaf, 0x4ae3, 0xbd, 0xde, 0x56, 0x41, 0x9f, 0xcf, 0x42, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR* key, IXpsOMShareable** entry) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key, IXpsOMShareable* beforeEntry, IXpsOMShareable** entry) GetByKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMShareable* entry, uint32* index) GetIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR key, IXpsOMShareable* entry) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR key, IXpsOMShareable* entry) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR key, IXpsOMShareable* entry) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** dictionary) Clone;
	}


	public HRESULT GetOwner(IUnknown** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, PWSTR* key, IXpsOMShareable** entry) mut => VT.[Friend]GetAt(&this, index, key, entry);

	public HRESULT GetByKey(PWSTR key, IXpsOMShareable* beforeEntry, IXpsOMShareable** entry) mut => VT.[Friend]GetByKey(&this, key, beforeEntry, entry);

	public HRESULT GetIndex(IXpsOMShareable* entry, uint32* index) mut => VT.[Friend]GetIndex(&this, entry, index);

	public HRESULT Append(PWSTR key, IXpsOMShareable* entry) mut => VT.[Friend]Append(&this, key, entry);

	public HRESULT InsertAt(uint32 index, PWSTR key, IXpsOMShareable* entry) mut => VT.[Friend]InsertAt(&this, index, key, entry);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, PWSTR key, IXpsOMShareable* entry) mut => VT.[Friend]SetAt(&this, index, key, entry);

	public HRESULT Clone(IXpsOMDictionary** dictionary) mut => VT.[Friend]Clone(&this, dictionary);
}

[CRepr]struct IXpsOMFontResource : IXpsOMResource
{
	public new const Guid IID = .(0xa8c45708, 0x47d9, 0x4af4, 0x8d, 0x20, 0x33, 0xb4, 0x8c, 0x9b, 0x84, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** readerStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, XPS_FONT_EMBEDDING embeddingOption, IOpcPartUri* partName) SetContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_FONT_EMBEDDING* embeddingOption) GetEmbeddingOption;
	}


	public HRESULT GetStream(IStream** readerStream) mut => VT.[Friend]GetStream(&this, readerStream);

	public HRESULT SetContent(IStream* sourceStream, XPS_FONT_EMBEDDING embeddingOption, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, embeddingOption, partName);

	public HRESULT GetEmbeddingOption(XPS_FONT_EMBEDDING* embeddingOption) mut => VT.[Friend]GetEmbeddingOption(&this, embeddingOption);
}

[CRepr]struct IXpsOMFontResourceCollection : IUnknown
{
	public new const Guid IID = .(0x70b4a6bb, 0x88d4, 0x4fa8, 0xaa, 0xf9, 0x6d, 0x9c, 0x59, 0x6f, 0xdb, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMFontResource** value) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMFontResource* value) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMFontResource* value) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMFontResource* value) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, IXpsOMFontResource** part) GetByPartName;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMFontResource** value) mut => VT.[Friend]GetAt(&this, index, value);

	public HRESULT SetAt(uint32 index, IXpsOMFontResource* value) mut => VT.[Friend]SetAt(&this, index, value);

	public HRESULT InsertAt(uint32 index, IXpsOMFontResource* value) mut => VT.[Friend]InsertAt(&this, index, value);

	public HRESULT Append(IXpsOMFontResource* value) mut => VT.[Friend]Append(&this, value);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT GetByPartName(IOpcPartUri* partName, IXpsOMFontResource** part) mut => VT.[Friend]GetByPartName(&this, partName, part);
}

[CRepr]struct IXpsOMImageResource : IXpsOMResource
{
	public new const Guid IID = .(0x3db8417d, 0xae50, 0x485e, 0x9a, 0x44, 0xd7, 0x75, 0x8f, 0x78, 0xa2, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** readerStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, XPS_IMAGE_TYPE imageType, IOpcPartUri* partName) SetContent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_IMAGE_TYPE* imageType) GetImageType;
	}


	public HRESULT GetStream(IStream** readerStream) mut => VT.[Friend]GetStream(&this, readerStream);

	public HRESULT SetContent(IStream* sourceStream, XPS_IMAGE_TYPE imageType, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, imageType, partName);

	public HRESULT GetImageType(XPS_IMAGE_TYPE* imageType) mut => VT.[Friend]GetImageType(&this, imageType);
}

[CRepr]struct IXpsOMImageResourceCollection : IUnknown
{
	public new const Guid IID = .(0x7a4a1a71, 0x9cde, 0x4b71, 0xb3, 0x3f, 0x62, 0xde, 0x84, 0x3e, 0xab, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMImageResource** object) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMImageResource* object) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMImageResource* object) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* object) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, IXpsOMImageResource** part) GetByPartName;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMImageResource** object) mut => VT.[Friend]GetAt(&this, index, object);

	public HRESULT InsertAt(uint32 index, IXpsOMImageResource* object) mut => VT.[Friend]InsertAt(&this, index, object);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMImageResource* object) mut => VT.[Friend]SetAt(&this, index, object);

	public HRESULT Append(IXpsOMImageResource* object) mut => VT.[Friend]Append(&this, object);

	public HRESULT GetByPartName(IOpcPartUri* partName, IXpsOMImageResource** part) mut => VT.[Friend]GetByPartName(&this, partName, part);
}

[CRepr]struct IXpsOMColorProfileResource : IXpsOMResource
{
	public new const Guid IID = .(0x67bd7d69, 0x1eef, 0x4bb1, 0xb5, 0xe7, 0x6f, 0x4f, 0x87, 0xbe, 0x8a, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, IOpcPartUri* partName) SetContent;
	}


	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);

	public HRESULT SetContent(IStream* sourceStream, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, partName);
}

[CRepr]struct IXpsOMColorProfileResourceCollection : IUnknown
{
	public new const Guid IID = .(0x12759630, 0x5fba, 0x4283, 0x8f, 0x7d, 0xcc, 0xa8, 0x49, 0x80, 0x9e, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMColorProfileResource** object) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMColorProfileResource* object) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMColorProfileResource* object) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMColorProfileResource* object) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, IXpsOMColorProfileResource** part) GetByPartName;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMColorProfileResource** object) mut => VT.[Friend]GetAt(&this, index, object);

	public HRESULT InsertAt(uint32 index, IXpsOMColorProfileResource* object) mut => VT.[Friend]InsertAt(&this, index, object);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMColorProfileResource* object) mut => VT.[Friend]SetAt(&this, index, object);

	public HRESULT Append(IXpsOMColorProfileResource* object) mut => VT.[Friend]Append(&this, object);

	public HRESULT GetByPartName(IOpcPartUri* partName, IXpsOMColorProfileResource** part) mut => VT.[Friend]GetByPartName(&this, partName, part);
}

[CRepr]struct IXpsOMPrintTicketResource : IXpsOMResource
{
	public new const Guid IID = .(0xe7ff32d2, 0x34aa, 0x499b, 0xbb, 0xe9, 0x9c, 0xd4, 0xee, 0x6c, 0x59, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, IOpcPartUri* partName) SetContent;
	}


	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);

	public HRESULT SetContent(IStream* sourceStream, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, partName);
}

[CRepr]struct IXpsOMRemoteDictionaryResource : IXpsOMResource
{
	public new const Guid IID = .(0xc9bd7cd4, 0xe16a, 0x4bf8, 0x8c, 0x84, 0xc9, 0x50, 0xaf, 0x7a, 0x30, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** dictionary) GetDictionary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary* dictionary) SetDictionary;
	}


	public HRESULT GetDictionary(IXpsOMDictionary** dictionary) mut => VT.[Friend]GetDictionary(&this, dictionary);

	public HRESULT SetDictionary(IXpsOMDictionary* dictionary) mut => VT.[Friend]SetDictionary(&this, dictionary);
}

[CRepr]struct IXpsOMRemoteDictionaryResourceCollection : IUnknown
{
	public new const Guid IID = .(0x5c38db61, 0x7fec, 0x464a, 0x87, 0xbd, 0x41, 0xe3, 0xbe, 0xf0, 0x18, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMRemoteDictionaryResource** object) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMRemoteDictionaryResource* object) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMRemoteDictionaryResource* object) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResource* object) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) GetByPartName;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMRemoteDictionaryResource** object) mut => VT.[Friend]GetAt(&this, index, object);

	public HRESULT InsertAt(uint32 index, IXpsOMRemoteDictionaryResource* object) mut => VT.[Friend]InsertAt(&this, index, object);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMRemoteDictionaryResource* object) mut => VT.[Friend]SetAt(&this, index, object);

	public HRESULT Append(IXpsOMRemoteDictionaryResource* object) mut => VT.[Friend]Append(&this, object);

	public HRESULT GetByPartName(IOpcPartUri* partName, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) mut => VT.[Friend]GetByPartName(&this, partName, remoteDictionaryResource);
}

[CRepr]struct IXpsOMSignatureBlockResourceCollection : IUnknown
{
	public new const Guid IID = .(0xab8f5d8e, 0x351b, 0x4d33, 0xaa, 0xed, 0xfa, 0x56, 0xf0, 0x02, 0x29, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMSignatureBlockResource** signatureBlockResource) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMSignatureBlockResource* signatureBlockResource) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMSignatureBlockResource* signatureBlockResource) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMSignatureBlockResource* signatureBlockResource) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, IXpsOMSignatureBlockResource** signatureBlockResource) GetByPartName;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMSignatureBlockResource** signatureBlockResource) mut => VT.[Friend]GetAt(&this, index, signatureBlockResource);

	public HRESULT InsertAt(uint32 index, IXpsOMSignatureBlockResource* signatureBlockResource) mut => VT.[Friend]InsertAt(&this, index, signatureBlockResource);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMSignatureBlockResource* signatureBlockResource) mut => VT.[Friend]SetAt(&this, index, signatureBlockResource);

	public HRESULT Append(IXpsOMSignatureBlockResource* signatureBlockResource) mut => VT.[Friend]Append(&this, signatureBlockResource);

	public HRESULT GetByPartName(IOpcPartUri* partName, IXpsOMSignatureBlockResource** signatureBlockResource) mut => VT.[Friend]GetByPartName(&this, partName, signatureBlockResource);
}

[CRepr]struct IXpsOMDocumentStructureResource : IXpsOMResource
{
	public new const Guid IID = .(0x85febc8a, 0x6b63, 0x48a9, 0xaf, 0x07, 0x70, 0x64, 0xe4, 0xec, 0xff, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocument** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, IOpcPartUri* partName) SetContent;
	}


	public HRESULT GetOwner(IXpsOMDocument** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);

	public HRESULT SetContent(IStream* sourceStream, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, partName);
}

[CRepr]struct IXpsOMStoryFragmentsResource : IXpsOMResource
{
	public new const Guid IID = .(0xc2b3ca09, 0x0473, 0x4282, 0x87, 0xae, 0x17, 0x80, 0x86, 0x32, 0x23, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPageReference** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, IOpcPartUri* partName) SetContent;
	}


	public HRESULT GetOwner(IXpsOMPageReference** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);

	public HRESULT SetContent(IStream* sourceStream, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, partName);
}

[CRepr]struct IXpsOMSignatureBlockResource : IXpsOMResource
{
	public new const Guid IID = .(0x4776ad35, 0x2e04, 0x4357, 0x87, 0x43, 0xeb, 0xf6, 0xc1, 0x71, 0xa9, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocument** owner) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* sourceStream, IOpcPartUri* partName) SetContent;
	}


	public HRESULT GetOwner(IXpsOMDocument** owner) mut => VT.[Friend]GetOwner(&this, owner);

	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);

	public HRESULT SetContent(IStream* sourceStream, IOpcPartUri* partName) mut => VT.[Friend]SetContent(&this, sourceStream, partName);
}

[CRepr]struct IXpsOMVisualCollection : IUnknown
{
	public new const Guid IID = .(0x94d8abde, 0xab91, 0x46a8, 0x82, 0xb7, 0xf5, 0xb0, 0x5e, 0xf0, 0x1a, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMVisual** object) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMVisual* object) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMVisual* object) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisual* object) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMVisual** object) mut => VT.[Friend]GetAt(&this, index, object);

	public HRESULT InsertAt(uint32 index, IXpsOMVisual* object) mut => VT.[Friend]InsertAt(&this, index, object);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMVisual* object) mut => VT.[Friend]SetAt(&this, index, object);

	public HRESULT Append(IXpsOMVisual* object) mut => VT.[Friend]Append(&this, object);
}

[CRepr]struct IXpsOMCanvas : IXpsOMVisual
{
	public new const Guid IID = .(0x221d1452, 0x331e, 0x47c6, 0x87, 0xe9, 0x6c, 0xce, 0xfb, 0x9b, 0x5b, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMVisual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisualCollection** visuals) GetVisuals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* useAliasedEdgeMode) GetUseAliasedEdgeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL useAliasedEdgeMode) SetUseAliasedEdgeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* shortDescription) GetAccessibilityShortDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR shortDescription) SetAccessibilityShortDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* longDescription) GetAccessibilityLongDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR longDescription) SetAccessibilityLongDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** resourceDictionary) GetDictionary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** resourceDictionary) GetDictionaryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary* resourceDictionary) SetDictionaryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) GetDictionaryResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResource* remoteDictionaryResource) SetDictionaryResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMCanvas** canvas) Clone;
	}


	public HRESULT GetVisuals(IXpsOMVisualCollection** visuals) mut => VT.[Friend]GetVisuals(&this, visuals);

	public HRESULT GetUseAliasedEdgeMode(BOOL* useAliasedEdgeMode) mut => VT.[Friend]GetUseAliasedEdgeMode(&this, useAliasedEdgeMode);

	public HRESULT SetUseAliasedEdgeMode(BOOL useAliasedEdgeMode) mut => VT.[Friend]SetUseAliasedEdgeMode(&this, useAliasedEdgeMode);

	public HRESULT GetAccessibilityShortDescription(PWSTR* shortDescription) mut => VT.[Friend]GetAccessibilityShortDescription(&this, shortDescription);

	public HRESULT SetAccessibilityShortDescription(PWSTR shortDescription) mut => VT.[Friend]SetAccessibilityShortDescription(&this, shortDescription);

	public HRESULT GetAccessibilityLongDescription(PWSTR* longDescription) mut => VT.[Friend]GetAccessibilityLongDescription(&this, longDescription);

	public HRESULT SetAccessibilityLongDescription(PWSTR longDescription) mut => VT.[Friend]SetAccessibilityLongDescription(&this, longDescription);

	public HRESULT GetDictionary(IXpsOMDictionary** resourceDictionary) mut => VT.[Friend]GetDictionary(&this, resourceDictionary);

	public HRESULT GetDictionaryLocal(IXpsOMDictionary** resourceDictionary) mut => VT.[Friend]GetDictionaryLocal(&this, resourceDictionary);

	public HRESULT SetDictionaryLocal(IXpsOMDictionary* resourceDictionary) mut => VT.[Friend]SetDictionaryLocal(&this, resourceDictionary);

	public HRESULT GetDictionaryResource(IXpsOMRemoteDictionaryResource** remoteDictionaryResource) mut => VT.[Friend]GetDictionaryResource(&this, remoteDictionaryResource);

	public HRESULT SetDictionaryResource(IXpsOMRemoteDictionaryResource* remoteDictionaryResource) mut => VT.[Friend]SetDictionaryResource(&this, remoteDictionaryResource);

	public HRESULT Clone(IXpsOMCanvas** canvas) mut => VT.[Friend]Clone(&this, canvas);
}

[CRepr]struct IXpsOMPage : IXpsOMPart
{
	public new const Guid IID = .(0xd3e18888, 0xf120, 0x4fee, 0x8c, 0x68, 0x35, 0x29, 0x6e, 0xae, 0x91, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPart.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPageReference** pageReference) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMVisualCollection** visuals) GetVisuals;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions) GetPageDimensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions) SetPageDimensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* contentBox) GetContentBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* contentBox) SetContentBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* bleedBox) GetBleedBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* bleedBox) SetBleedBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* language) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR language) SetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name) SetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isHyperlinkTarget) GetIsHyperlinkTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isHyperlinkTarget) SetIsHyperlinkTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** resourceDictionary) GetDictionary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** resourceDictionary) GetDictionaryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary* resourceDictionary) SetDictionaryLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) GetDictionaryResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMRemoteDictionaryResource* remoteDictionaryResource) SetDictionaryResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* stream, BOOL optimizeMarkupSize) Write;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_OBJECT_TYPE type, PWSTR* key) GenerateUnusedLookupKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage** page) Clone;
	}


	public HRESULT GetOwner(IXpsOMPageReference** pageReference) mut => VT.[Friend]GetOwner(&this, pageReference);

	public HRESULT GetVisuals(IXpsOMVisualCollection** visuals) mut => VT.[Friend]GetVisuals(&this, visuals);

	public HRESULT GetPageDimensions(XPS_SIZE* pageDimensions) mut => VT.[Friend]GetPageDimensions(&this, pageDimensions);

	public HRESULT SetPageDimensions(XPS_SIZE* pageDimensions) mut => VT.[Friend]SetPageDimensions(&this, pageDimensions);

	public HRESULT GetContentBox(XPS_RECT* contentBox) mut => VT.[Friend]GetContentBox(&this, contentBox);

	public HRESULT SetContentBox(XPS_RECT* contentBox) mut => VT.[Friend]SetContentBox(&this, contentBox);

	public HRESULT GetBleedBox(XPS_RECT* bleedBox) mut => VT.[Friend]GetBleedBox(&this, bleedBox);

	public HRESULT SetBleedBox(XPS_RECT* bleedBox) mut => VT.[Friend]SetBleedBox(&this, bleedBox);

	public HRESULT GetLanguage(PWSTR* language) mut => VT.[Friend]GetLanguage(&this, language);

	public HRESULT SetLanguage(PWSTR language) mut => VT.[Friend]SetLanguage(&this, language);

	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT SetName(PWSTR name) mut => VT.[Friend]SetName(&this, name);

	public HRESULT GetIsHyperlinkTarget(BOOL* isHyperlinkTarget) mut => VT.[Friend]GetIsHyperlinkTarget(&this, isHyperlinkTarget);

	public HRESULT SetIsHyperlinkTarget(BOOL isHyperlinkTarget) mut => VT.[Friend]SetIsHyperlinkTarget(&this, isHyperlinkTarget);

	public HRESULT GetDictionary(IXpsOMDictionary** resourceDictionary) mut => VT.[Friend]GetDictionary(&this, resourceDictionary);

	public HRESULT GetDictionaryLocal(IXpsOMDictionary** resourceDictionary) mut => VT.[Friend]GetDictionaryLocal(&this, resourceDictionary);

	public HRESULT SetDictionaryLocal(IXpsOMDictionary* resourceDictionary) mut => VT.[Friend]SetDictionaryLocal(&this, resourceDictionary);

	public HRESULT GetDictionaryResource(IXpsOMRemoteDictionaryResource** remoteDictionaryResource) mut => VT.[Friend]GetDictionaryResource(&this, remoteDictionaryResource);

	public HRESULT SetDictionaryResource(IXpsOMRemoteDictionaryResource* remoteDictionaryResource) mut => VT.[Friend]SetDictionaryResource(&this, remoteDictionaryResource);

	public HRESULT Write(ISequentialStream* stream, BOOL optimizeMarkupSize) mut => VT.[Friend]Write(&this, stream, optimizeMarkupSize);

	public HRESULT GenerateUnusedLookupKey(XPS_OBJECT_TYPE type, PWSTR* key) mut => VT.[Friend]GenerateUnusedLookupKey(&this, type, key);

	public HRESULT Clone(IXpsOMPage** page) mut => VT.[Friend]Clone(&this, page);
}

[CRepr]struct IXpsOMPageReference : IUnknown
{
	public new const Guid IID = .(0xed360180, 0x6f92, 0x4998, 0x89, 0x0d, 0x2f, 0x20, 0x85, 0x31, 0xa0, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocument** document) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage** page) GetPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* page) SetPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DiscardPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isPageLoaded) IsPageLoaded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions) GetAdvisoryPageDimensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions) SetAdvisoryPageDimensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMStoryFragmentsResource** storyFragmentsResource) GetStoryFragmentsResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMStoryFragmentsResource* storyFragmentsResource) SetStoryFragmentsResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource** printTicketResource) GetPrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource* printTicketResource) SetPrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource** imageResource) GetThumbnailResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* imageResource) SetThumbnailResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMNameCollection** linkTargets) CollectLinkTargets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPartResources** partResources) CollectPartResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* restrictedFonts) HasRestrictedFonts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPageReference** pageReference) Clone;
	}


	public HRESULT GetOwner(IXpsOMDocument** document) mut => VT.[Friend]GetOwner(&this, document);

	public HRESULT GetPage(IXpsOMPage** page) mut => VT.[Friend]GetPage(&this, page);

	public HRESULT SetPage(IXpsOMPage* page) mut => VT.[Friend]SetPage(&this, page);

	public HRESULT DiscardPage() mut => VT.[Friend]DiscardPage(&this);

	public HRESULT IsPageLoaded(BOOL* isPageLoaded) mut => VT.[Friend]IsPageLoaded(&this, isPageLoaded);

	public HRESULT GetAdvisoryPageDimensions(XPS_SIZE* pageDimensions) mut => VT.[Friend]GetAdvisoryPageDimensions(&this, pageDimensions);

	public HRESULT SetAdvisoryPageDimensions(XPS_SIZE* pageDimensions) mut => VT.[Friend]SetAdvisoryPageDimensions(&this, pageDimensions);

	public HRESULT GetStoryFragmentsResource(IXpsOMStoryFragmentsResource** storyFragmentsResource) mut => VT.[Friend]GetStoryFragmentsResource(&this, storyFragmentsResource);

	public HRESULT SetStoryFragmentsResource(IXpsOMStoryFragmentsResource* storyFragmentsResource) mut => VT.[Friend]SetStoryFragmentsResource(&this, storyFragmentsResource);

	public HRESULT GetPrintTicketResource(IXpsOMPrintTicketResource** printTicketResource) mut => VT.[Friend]GetPrintTicketResource(&this, printTicketResource);

	public HRESULT SetPrintTicketResource(IXpsOMPrintTicketResource* printTicketResource) mut => VT.[Friend]SetPrintTicketResource(&this, printTicketResource);

	public HRESULT GetThumbnailResource(IXpsOMImageResource** imageResource) mut => VT.[Friend]GetThumbnailResource(&this, imageResource);

	public HRESULT SetThumbnailResource(IXpsOMImageResource* imageResource) mut => VT.[Friend]SetThumbnailResource(&this, imageResource);

	public HRESULT CollectLinkTargets(IXpsOMNameCollection** linkTargets) mut => VT.[Friend]CollectLinkTargets(&this, linkTargets);

	public HRESULT CollectPartResources(IXpsOMPartResources** partResources) mut => VT.[Friend]CollectPartResources(&this, partResources);

	public HRESULT HasRestrictedFonts(BOOL* restrictedFonts) mut => VT.[Friend]HasRestrictedFonts(&this, restrictedFonts);

	public HRESULT Clone(IXpsOMPageReference** pageReference) mut => VT.[Friend]Clone(&this, pageReference);
}

[CRepr]struct IXpsOMPageReferenceCollection : IUnknown
{
	public new const Guid IID = .(0xca16ba4d, 0xe7b9, 0x45c5, 0x95, 0x8b, 0xf9, 0x80, 0x22, 0x47, 0x37, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMPageReference** pageReference) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMPageReference* pageReference) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMPageReference* pageReference) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPageReference* pageReference) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMPageReference** pageReference) mut => VT.[Friend]GetAt(&this, index, pageReference);

	public HRESULT InsertAt(uint32 index, IXpsOMPageReference* pageReference) mut => VT.[Friend]InsertAt(&this, index, pageReference);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMPageReference* pageReference) mut => VT.[Friend]SetAt(&this, index, pageReference);

	public HRESULT Append(IXpsOMPageReference* pageReference) mut => VT.[Friend]Append(&this, pageReference);
}

[CRepr]struct IXpsOMDocument : IXpsOMPart
{
	public new const Guid IID = .(0x2c2c94cb, 0xac5f, 0x4254, 0x8e, 0xe9, 0x23, 0x94, 0x83, 0x09, 0xd9, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPart.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentSequence** documentSequence) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPageReferenceCollection** pageReferences) GetPageReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource** printTicketResource) GetPrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource* printTicketResource) SetPrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentStructureResource** documentStructureResource) GetDocumentStructureResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentStructureResource* documentStructureResource) SetDocumentStructureResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMSignatureBlockResourceCollection** signatureBlockResources) GetSignatureBlockResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocument** document) Clone;
	}


	public HRESULT GetOwner(IXpsOMDocumentSequence** documentSequence) mut => VT.[Friend]GetOwner(&this, documentSequence);

	public HRESULT GetPageReferences(IXpsOMPageReferenceCollection** pageReferences) mut => VT.[Friend]GetPageReferences(&this, pageReferences);

	public HRESULT GetPrintTicketResource(IXpsOMPrintTicketResource** printTicketResource) mut => VT.[Friend]GetPrintTicketResource(&this, printTicketResource);

	public HRESULT SetPrintTicketResource(IXpsOMPrintTicketResource* printTicketResource) mut => VT.[Friend]SetPrintTicketResource(&this, printTicketResource);

	public HRESULT GetDocumentStructureResource(IXpsOMDocumentStructureResource** documentStructureResource) mut => VT.[Friend]GetDocumentStructureResource(&this, documentStructureResource);

	public HRESULT SetDocumentStructureResource(IXpsOMDocumentStructureResource* documentStructureResource) mut => VT.[Friend]SetDocumentStructureResource(&this, documentStructureResource);

	public HRESULT GetSignatureBlockResources(IXpsOMSignatureBlockResourceCollection** signatureBlockResources) mut => VT.[Friend]GetSignatureBlockResources(&this, signatureBlockResources);

	public HRESULT Clone(IXpsOMDocument** document) mut => VT.[Friend]Clone(&this, document);
}

[CRepr]struct IXpsOMDocumentCollection : IUnknown
{
	public new const Guid IID = .(0xd1c87f0d, 0xe947, 0x4754, 0x8a, 0x25, 0x97, 0x14, 0x78, 0xf7, 0xe8, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMDocument** document) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMDocument* document) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsOMDocument* document) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocument* document) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsOMDocument** document) mut => VT.[Friend]GetAt(&this, index, document);

	public HRESULT InsertAt(uint32 index, IXpsOMDocument* document) mut => VT.[Friend]InsertAt(&this, index, document);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IXpsOMDocument* document) mut => VT.[Friend]SetAt(&this, index, document);

	public HRESULT Append(IXpsOMDocument* document) mut => VT.[Friend]Append(&this, document);
}

[CRepr]struct IXpsOMDocumentSequence : IXpsOMPart
{
	public new const Guid IID = .(0x56492eb4, 0xd8d5, 0x425e, 0x82, 0x56, 0x4c, 0x2b, 0x64, 0xad, 0x02, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPart.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPackage** package) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentCollection** documents) GetDocuments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource** printTicketResource) GetPrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPrintTicketResource* printTicketResource) SetPrintTicketResource;
	}


	public HRESULT GetOwner(IXpsOMPackage** package) mut => VT.[Friend]GetOwner(&this, package);

	public HRESULT GetDocuments(IXpsOMDocumentCollection** documents) mut => VT.[Friend]GetDocuments(&this, documents);

	public HRESULT GetPrintTicketResource(IXpsOMPrintTicketResource** printTicketResource) mut => VT.[Friend]GetPrintTicketResource(&this, printTicketResource);

	public HRESULT SetPrintTicketResource(IXpsOMPrintTicketResource* printTicketResource) mut => VT.[Friend]SetPrintTicketResource(&this, printTicketResource);
}

[CRepr]struct IXpsOMCoreProperties : IXpsOMPart
{
	public new const Guid IID = .(0x3340fe8f, 0x4027, 0x4aa1, 0x8f, 0x5f, 0xd3, 0x5a, 0xe4, 0x5f, 0xe5, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPart.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPackage** package) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* category) GetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR category) SetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentStatus) GetContentStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR contentStatus) SetContentStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentType) GetContentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR contentType) SetContentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* created) GetCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* created) SetCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* creator) GetCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR creator) SetCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* description) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR description) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* identifier) GetIdentifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR identifier) SetIdentifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* keywords) GetKeywords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR keywords) SetKeywords;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* language) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR language) SetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lastModifiedBy) GetLastModifiedBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lastModifiedBy) SetLastModifiedBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* lastPrinted) GetLastPrinted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* lastPrinted) SetLastPrinted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* modified) GetModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* modified) SetModified;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* revision) GetRevision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR revision) SetRevision;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* subject) GetSubject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR subject) SetSubject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* title) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR title) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* version) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR version) SetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMCoreProperties** coreProperties) Clone;
	}


	public HRESULT GetOwner(IXpsOMPackage** package) mut => VT.[Friend]GetOwner(&this, package);

	public HRESULT GetCategory(PWSTR* category) mut => VT.[Friend]GetCategory(&this, category);

	public HRESULT SetCategory(PWSTR category) mut => VT.[Friend]SetCategory(&this, category);

	public HRESULT GetContentStatus(PWSTR* contentStatus) mut => VT.[Friend]GetContentStatus(&this, contentStatus);

	public HRESULT SetContentStatus(PWSTR contentStatus) mut => VT.[Friend]SetContentStatus(&this, contentStatus);

	public HRESULT GetContentType(PWSTR* contentType) mut => VT.[Friend]GetContentType(&this, contentType);

	public HRESULT SetContentType(PWSTR contentType) mut => VT.[Friend]SetContentType(&this, contentType);

	public HRESULT GetCreated(SYSTEMTIME* created) mut => VT.[Friend]GetCreated(&this, created);

	public HRESULT SetCreated(SYSTEMTIME* created) mut => VT.[Friend]SetCreated(&this, created);

	public HRESULT GetCreator(PWSTR* creator) mut => VT.[Friend]GetCreator(&this, creator);

	public HRESULT SetCreator(PWSTR creator) mut => VT.[Friend]SetCreator(&this, creator);

	public HRESULT GetDescription(PWSTR* description) mut => VT.[Friend]GetDescription(&this, description);

	public HRESULT SetDescription(PWSTR description) mut => VT.[Friend]SetDescription(&this, description);

	public HRESULT GetIdentifier(PWSTR* identifier) mut => VT.[Friend]GetIdentifier(&this, identifier);

	public HRESULT SetIdentifier(PWSTR identifier) mut => VT.[Friend]SetIdentifier(&this, identifier);

	public HRESULT GetKeywords(PWSTR* keywords) mut => VT.[Friend]GetKeywords(&this, keywords);

	public HRESULT SetKeywords(PWSTR keywords) mut => VT.[Friend]SetKeywords(&this, keywords);

	public HRESULT GetLanguage(PWSTR* language) mut => VT.[Friend]GetLanguage(&this, language);

	public HRESULT SetLanguage(PWSTR language) mut => VT.[Friend]SetLanguage(&this, language);

	public HRESULT GetLastModifiedBy(PWSTR* lastModifiedBy) mut => VT.[Friend]GetLastModifiedBy(&this, lastModifiedBy);

	public HRESULT SetLastModifiedBy(PWSTR lastModifiedBy) mut => VT.[Friend]SetLastModifiedBy(&this, lastModifiedBy);

	public HRESULT GetLastPrinted(SYSTEMTIME* lastPrinted) mut => VT.[Friend]GetLastPrinted(&this, lastPrinted);

	public HRESULT SetLastPrinted(SYSTEMTIME* lastPrinted) mut => VT.[Friend]SetLastPrinted(&this, lastPrinted);

	public HRESULT GetModified(SYSTEMTIME* modified) mut => VT.[Friend]GetModified(&this, modified);

	public HRESULT SetModified(SYSTEMTIME* modified) mut => VT.[Friend]SetModified(&this, modified);

	public HRESULT GetRevision(PWSTR* revision) mut => VT.[Friend]GetRevision(&this, revision);

	public HRESULT SetRevision(PWSTR revision) mut => VT.[Friend]SetRevision(&this, revision);

	public HRESULT GetSubject(PWSTR* subject) mut => VT.[Friend]GetSubject(&this, subject);

	public HRESULT SetSubject(PWSTR subject) mut => VT.[Friend]SetSubject(&this, subject);

	public HRESULT GetTitle(PWSTR* title) mut => VT.[Friend]GetTitle(&this, title);

	public HRESULT SetTitle(PWSTR title) mut => VT.[Friend]SetTitle(&this, title);

	public HRESULT GetVersion(PWSTR* version) mut => VT.[Friend]GetVersion(&this, version);

	public HRESULT SetVersion(PWSTR version) mut => VT.[Friend]SetVersion(&this, version);

	public HRESULT Clone(IXpsOMCoreProperties** coreProperties) mut => VT.[Friend]Clone(&this, coreProperties);
}

[CRepr]struct IXpsOMPackage : IUnknown
{
	public new const Guid IID = .(0x18c3df65, 0x81e1, 0x4674, 0x91, 0xdc, 0xfc, 0x45, 0x2f, 0x5a, 0x41, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentSequence** documentSequence) GetDocumentSequence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDocumentSequence* documentSequence) SetDocumentSequence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMCoreProperties** coreProperties) GetCoreProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMCoreProperties* coreProperties) SetCoreProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** discardControlPartUri) GetDiscardControlPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* discardControlPartUri) SetDiscardControlPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource** imageResource) GetThumbnailResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* imageResource) SetThumbnailResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize) WriteToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* stream, BOOL optimizeMarkupSize) WriteToStream;
	}


	public HRESULT GetDocumentSequence(IXpsOMDocumentSequence** documentSequence) mut => VT.[Friend]GetDocumentSequence(&this, documentSequence);

	public HRESULT SetDocumentSequence(IXpsOMDocumentSequence* documentSequence) mut => VT.[Friend]SetDocumentSequence(&this, documentSequence);

	public HRESULT GetCoreProperties(IXpsOMCoreProperties** coreProperties) mut => VT.[Friend]GetCoreProperties(&this, coreProperties);

	public HRESULT SetCoreProperties(IXpsOMCoreProperties* coreProperties) mut => VT.[Friend]SetCoreProperties(&this, coreProperties);

	public HRESULT GetDiscardControlPartName(IOpcPartUri** discardControlPartUri) mut => VT.[Friend]GetDiscardControlPartName(&this, discardControlPartUri);

	public HRESULT SetDiscardControlPartName(IOpcPartUri* discardControlPartUri) mut => VT.[Friend]SetDiscardControlPartName(&this, discardControlPartUri);

	public HRESULT GetThumbnailResource(IXpsOMImageResource** imageResource) mut => VT.[Friend]GetThumbnailResource(&this, imageResource);

	public HRESULT SetThumbnailResource(IXpsOMImageResource* imageResource) mut => VT.[Friend]SetThumbnailResource(&this, imageResource);

	public HRESULT WriteToFile(PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize) mut => VT.[Friend]WriteToFile(&this, fileName, securityAttributes, flagsAndAttributes, optimizeMarkupSize);

	public HRESULT WriteToStream(ISequentialStream* stream, BOOL optimizeMarkupSize) mut => VT.[Friend]WriteToStream(&this, stream, optimizeMarkupSize);
}

[CRepr]struct IXpsOMObjectFactory : IUnknown
{
	public new const Guid IID = .(0xf9b2a685, 0xa50d, 0x4fc2, 0xb7, 0x64, 0xb5, 0x6e, 0x09, 0x3e, 0xa0, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPackage** package) CreatePackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, BOOL reuseObjects, IXpsOMPackage** package) CreatePackageFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream, BOOL reuseObjects, IXpsOMPackage** package) CreatePackageFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMStoryFragmentsResource** storyFragmentsResource) CreateStoryFragmentsResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMDocumentStructureResource** documentStructureResource) CreateDocumentStructureResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMSignatureBlockResource** signatureBlockResource) CreateSignatureBlockResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary* dictionary, IOpcPartUri* partUri, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) CreateRemoteDictionaryResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* dictionaryMarkupStream, IOpcPartUri* dictionaryPartUri, IXpsOMPartResources* resources, IXpsOMRemoteDictionaryResource** dictionaryResource) CreateRemoteDictionaryResourceFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPartResources** partResources) CreatePartResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri, IXpsOMDocumentSequence** documentSequence) CreateDocumentSequence;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri, IXpsOMDocument** document) CreateDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* advisoryPageDimensions, IXpsOMPageReference** pageReference) CreatePageReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions, PWSTR language, IOpcPartUri* partUri, IXpsOMPage** page) CreatePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pageMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, BOOL reuseObjects, IXpsOMPage** page) CreatePageFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMCanvas** canvas) CreateCanvas;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMFontResource* fontResource, IXpsOMGlyphs** glyphs) CreateGlyphs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPath** path) CreatePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGeometry** geometry) CreateGeometry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_POINT* startPoint, IXpsOMGeometryFigure** figure) CreateGeometryFigure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_MATRIX* matrix, IXpsOMMatrixTransform** transform) CreateMatrixTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile, IXpsOMSolidColorBrush** solidColorBrush) CreateSolidColorBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMColorProfileResource** colorProfileResource) CreateColorProfileResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* image, XPS_RECT* viewBox, XPS_RECT* viewPort, IXpsOMImageBrush** imageBrush) CreateImageBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_RECT* viewBox, XPS_RECT* viewPort, IXpsOMVisualBrush** visualBrush) CreateVisualBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, XPS_IMAGE_TYPE contentType, IOpcPartUri* partUri, IXpsOMImageResource** imageResource) CreateImageResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMPrintTicketResource** printTicketResource) CreatePrintTicketResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* acquiredStream, XPS_FONT_EMBEDDING fontEmbedding, IOpcPartUri* partUri, BOOL isObfSourceStream, IXpsOMFontResource** fontResource) CreateFontResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile, float offset, IXpsOMGradientStop** gradientStop) CreateGradientStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientStop* gradStop1, IXpsOMGradientStop* gradStop2, XPS_POINT* startPoint, XPS_POINT* endPoint, IXpsOMLinearGradientBrush** linearGradientBrush) CreateLinearGradientBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMGradientStop* gradStop1, IXpsOMGradientStop* gradStop2, XPS_POINT* centerPoint, XPS_POINT* gradientOrigin, XPS_SIZE* radiiSizes, IXpsOMRadialGradientBrush** radialGradientBrush) CreateRadialGradientBrush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri, IXpsOMCoreProperties** coreProperties) CreateCoreProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMDictionary** dictionary) CreateDictionary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPartUriCollection** partUriCollection) CreatePartUriCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) CreatePackageWriterOnFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) CreatePackageWriterOnStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR uri, IOpcPartUri** partUri) CreatePartUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, IStream** stream) CreateReadOnlyStreamOnFile;
	}


	public HRESULT CreatePackage(IXpsOMPackage** package) mut => VT.[Friend]CreatePackage(&this, package);

	public HRESULT CreatePackageFromFile(PWSTR filename, BOOL reuseObjects, IXpsOMPackage** package) mut => VT.[Friend]CreatePackageFromFile(&this, filename, reuseObjects, package);

	public HRESULT CreatePackageFromStream(IStream* stream, BOOL reuseObjects, IXpsOMPackage** package) mut => VT.[Friend]CreatePackageFromStream(&this, stream, reuseObjects, package);

	public HRESULT CreateStoryFragmentsResource(IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMStoryFragmentsResource** storyFragmentsResource) mut => VT.[Friend]CreateStoryFragmentsResource(&this, acquiredStream, partUri, storyFragmentsResource);

	public HRESULT CreateDocumentStructureResource(IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMDocumentStructureResource** documentStructureResource) mut => VT.[Friend]CreateDocumentStructureResource(&this, acquiredStream, partUri, documentStructureResource);

	public HRESULT CreateSignatureBlockResource(IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMSignatureBlockResource** signatureBlockResource) mut => VT.[Friend]CreateSignatureBlockResource(&this, acquiredStream, partUri, signatureBlockResource);

	public HRESULT CreateRemoteDictionaryResource(IXpsOMDictionary* dictionary, IOpcPartUri* partUri, IXpsOMRemoteDictionaryResource** remoteDictionaryResource) mut => VT.[Friend]CreateRemoteDictionaryResource(&this, dictionary, partUri, remoteDictionaryResource);

	public HRESULT CreateRemoteDictionaryResourceFromStream(IStream* dictionaryMarkupStream, IOpcPartUri* dictionaryPartUri, IXpsOMPartResources* resources, IXpsOMRemoteDictionaryResource** dictionaryResource) mut => VT.[Friend]CreateRemoteDictionaryResourceFromStream(&this, dictionaryMarkupStream, dictionaryPartUri, resources, dictionaryResource);

	public HRESULT CreatePartResources(IXpsOMPartResources** partResources) mut => VT.[Friend]CreatePartResources(&this, partResources);

	public HRESULT CreateDocumentSequence(IOpcPartUri* partUri, IXpsOMDocumentSequence** documentSequence) mut => VT.[Friend]CreateDocumentSequence(&this, partUri, documentSequence);

	public HRESULT CreateDocument(IOpcPartUri* partUri, IXpsOMDocument** document) mut => VT.[Friend]CreateDocument(&this, partUri, document);

	public HRESULT CreatePageReference(XPS_SIZE* advisoryPageDimensions, IXpsOMPageReference** pageReference) mut => VT.[Friend]CreatePageReference(&this, advisoryPageDimensions, pageReference);

	public HRESULT CreatePage(XPS_SIZE* pageDimensions, PWSTR language, IOpcPartUri* partUri, IXpsOMPage** page) mut => VT.[Friend]CreatePage(&this, pageDimensions, language, partUri, page);

	public HRESULT CreatePageFromStream(IStream* pageMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, BOOL reuseObjects, IXpsOMPage** page) mut => VT.[Friend]CreatePageFromStream(&this, pageMarkupStream, partUri, resources, reuseObjects, page);

	public HRESULT CreateCanvas(IXpsOMCanvas** canvas) mut => VT.[Friend]CreateCanvas(&this, canvas);

	public HRESULT CreateGlyphs(IXpsOMFontResource* fontResource, IXpsOMGlyphs** glyphs) mut => VT.[Friend]CreateGlyphs(&this, fontResource, glyphs);

	public HRESULT CreatePath(IXpsOMPath** path) mut => VT.[Friend]CreatePath(&this, path);

	public HRESULT CreateGeometry(IXpsOMGeometry** geometry) mut => VT.[Friend]CreateGeometry(&this, geometry);

	public HRESULT CreateGeometryFigure(XPS_POINT* startPoint, IXpsOMGeometryFigure** figure) mut => VT.[Friend]CreateGeometryFigure(&this, startPoint, figure);

	public HRESULT CreateMatrixTransform(XPS_MATRIX* matrix, IXpsOMMatrixTransform** transform) mut => VT.[Friend]CreateMatrixTransform(&this, matrix, transform);

	public HRESULT CreateSolidColorBrush(XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile, IXpsOMSolidColorBrush** solidColorBrush) mut => VT.[Friend]CreateSolidColorBrush(&this, color, colorProfile, solidColorBrush);

	public HRESULT CreateColorProfileResource(IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMColorProfileResource** colorProfileResource) mut => VT.[Friend]CreateColorProfileResource(&this, acquiredStream, partUri, colorProfileResource);

	public HRESULT CreateImageBrush(IXpsOMImageResource* image, XPS_RECT* viewBox, XPS_RECT* viewPort, IXpsOMImageBrush** imageBrush) mut => VT.[Friend]CreateImageBrush(&this, image, viewBox, viewPort, imageBrush);

	public HRESULT CreateVisualBrush(XPS_RECT* viewBox, XPS_RECT* viewPort, IXpsOMVisualBrush** visualBrush) mut => VT.[Friend]CreateVisualBrush(&this, viewBox, viewPort, visualBrush);

	public HRESULT CreateImageResource(IStream* acquiredStream, XPS_IMAGE_TYPE contentType, IOpcPartUri* partUri, IXpsOMImageResource** imageResource) mut => VT.[Friend]CreateImageResource(&this, acquiredStream, contentType, partUri, imageResource);

	public HRESULT CreatePrintTicketResource(IStream* acquiredStream, IOpcPartUri* partUri, IXpsOMPrintTicketResource** printTicketResource) mut => VT.[Friend]CreatePrintTicketResource(&this, acquiredStream, partUri, printTicketResource);

	public HRESULT CreateFontResource(IStream* acquiredStream, XPS_FONT_EMBEDDING fontEmbedding, IOpcPartUri* partUri, BOOL isObfSourceStream, IXpsOMFontResource** fontResource) mut => VT.[Friend]CreateFontResource(&this, acquiredStream, fontEmbedding, partUri, isObfSourceStream, fontResource);

	public HRESULT CreateGradientStop(XPS_COLOR* color, IXpsOMColorProfileResource* colorProfile, float offset, IXpsOMGradientStop** gradientStop) mut => VT.[Friend]CreateGradientStop(&this, color, colorProfile, offset, gradientStop);

	public HRESULT CreateLinearGradientBrush(IXpsOMGradientStop* gradStop1, IXpsOMGradientStop* gradStop2, XPS_POINT* startPoint, XPS_POINT* endPoint, IXpsOMLinearGradientBrush** linearGradientBrush) mut => VT.[Friend]CreateLinearGradientBrush(&this, gradStop1, gradStop2, startPoint, endPoint, linearGradientBrush);

	public HRESULT CreateRadialGradientBrush(IXpsOMGradientStop* gradStop1, IXpsOMGradientStop* gradStop2, XPS_POINT* centerPoint, XPS_POINT* gradientOrigin, XPS_SIZE* radiiSizes, IXpsOMRadialGradientBrush** radialGradientBrush) mut => VT.[Friend]CreateRadialGradientBrush(&this, gradStop1, gradStop2, centerPoint, gradientOrigin, radiiSizes, radialGradientBrush);

	public HRESULT CreateCoreProperties(IOpcPartUri* partUri, IXpsOMCoreProperties** coreProperties) mut => VT.[Friend]CreateCoreProperties(&this, partUri, coreProperties);

	public HRESULT CreateDictionary(IXpsOMDictionary** dictionary) mut => VT.[Friend]CreateDictionary(&this, dictionary);

	public HRESULT CreatePartUriCollection(IXpsOMPartUriCollection** partUriCollection) mut => VT.[Friend]CreatePartUriCollection(&this, partUriCollection);

	public HRESULT CreatePackageWriterOnFile(PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]CreatePackageWriterOnFile(&this, fileName, securityAttributes, flagsAndAttributes, optimizeMarkupSize, interleaving, documentSequencePartName, coreProperties, packageThumbnail, documentSequencePrintTicket, discardControlPartName, packageWriter);

	public HRESULT CreatePackageWriterOnStream(ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]CreatePackageWriterOnStream(&this, outputStream, optimizeMarkupSize, interleaving, documentSequencePartName, coreProperties, packageThumbnail, documentSequencePrintTicket, discardControlPartName, packageWriter);

	public HRESULT CreatePartUri(PWSTR uri, IOpcPartUri** partUri) mut => VT.[Friend]CreatePartUri(&this, uri, partUri);

	public HRESULT CreateReadOnlyStreamOnFile(PWSTR filename, IStream** stream) mut => VT.[Friend]CreateReadOnlyStreamOnFile(&this, filename, stream);
}

[CRepr]struct IXpsOMNameCollection : IUnknown
{
	public new const Guid IID = .(0x4bddf8ec, 0xc915, 0x421b, 0xa1, 0x66, 0xd1, 0x73, 0xd2, 0x56, 0x53, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PWSTR* name) GetAt;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, PWSTR* name) mut => VT.[Friend]GetAt(&this, index, name);
}

[CRepr]struct IXpsOMPartUriCollection : IUnknown
{
	public new const Guid IID = .(0x57c650d4, 0x067c, 0x4893, 0x8c, 0x33, 0xf6, 0x2a, 0x06, 0x33, 0x73, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IOpcPartUri** partUri) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IOpcPartUri* partUri) InsertAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IOpcPartUri* partUri) SetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri) Append;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IOpcPartUri** partUri) mut => VT.[Friend]GetAt(&this, index, partUri);

	public HRESULT InsertAt(uint32 index, IOpcPartUri* partUri) mut => VT.[Friend]InsertAt(&this, index, partUri);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT SetAt(uint32 index, IOpcPartUri* partUri) mut => VT.[Friend]SetAt(&this, index, partUri);

	public HRESULT Append(IOpcPartUri* partUri) mut => VT.[Friend]Append(&this, partUri);
}

[CRepr]struct IXpsOMPackageWriter : IUnknown
{
	public new const Guid IID = .(0x4e2aa182, 0xa443, 0x42c6, 0xb4, 0x1b, 0x4f, 0x8e, 0x9d, 0xe7, 0x3f, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* documentPartName, IXpsOMPrintTicketResource* documentPrintTicket, IXpsOMDocumentStructureResource* documentStructure, IXpsOMSignatureBlockResourceCollection* signatureBlockResources, IXpsOMPartUriCollection* restrictedFonts) StartNewDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* page, XPS_SIZE* advisoryPageDimensions, IXpsOMPartUriCollection* discardableResourceParts, IXpsOMStoryFragmentsResource* storyFragments, IXpsOMPrintTicketResource* pagePrintTicket, IXpsOMImageResource* pageThumbnail) AddPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMResource* resource) AddResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isClosed) IsClosed;
	}


	public HRESULT StartNewDocument(IOpcPartUri* documentPartName, IXpsOMPrintTicketResource* documentPrintTicket, IXpsOMDocumentStructureResource* documentStructure, IXpsOMSignatureBlockResourceCollection* signatureBlockResources, IXpsOMPartUriCollection* restrictedFonts) mut => VT.[Friend]StartNewDocument(&this, documentPartName, documentPrintTicket, documentStructure, signatureBlockResources, restrictedFonts);

	public HRESULT AddPage(IXpsOMPage* page, XPS_SIZE* advisoryPageDimensions, IXpsOMPartUriCollection* discardableResourceParts, IXpsOMStoryFragmentsResource* storyFragments, IXpsOMPrintTicketResource* pagePrintTicket, IXpsOMImageResource* pageThumbnail) mut => VT.[Friend]AddPage(&this, page, advisoryPageDimensions, discardableResourceParts, storyFragments, pagePrintTicket, pageThumbnail);

	public HRESULT AddResource(IXpsOMResource* resource) mut => VT.[Friend]AddResource(&this, resource);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT IsClosed(BOOL* isClosed) mut => VT.[Friend]IsClosed(&this, isClosed);
}

[CRepr]struct IXpsOMPackageTarget : IUnknown
{
	public new const Guid IID = .(0x219a9db0, 0x4959, 0x47d0, 0x80, 0x34, 0xb1, 0xce, 0x84, 0xf4, 0x1a, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* documentSequencePartName, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) CreateXpsOMPackageWriter;
	}


	public HRESULT CreateXpsOMPackageWriter(IOpcPartUri* documentSequencePartName, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]CreateXpsOMPackageWriter(&this, documentSequencePartName, documentSequencePrintTicket, discardControlPartName, packageWriter);
}

[CRepr]struct IXpsOMThumbnailGenerator : IUnknown
{
	public new const Guid IID = .(0x15b873d5, 0x1971, 0x41e8, 0x83, 0xa3, 0x65, 0x78, 0x40, 0x30, 0x64, 0xc7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPage* page, XPS_IMAGE_TYPE thumbnailType, XPS_THUMBNAIL_SIZE thumbnailSize, IOpcPartUri* imageResourcePartName, IXpsOMImageResource** imageResource) GenerateThumbnail;
	}


	public HRESULT GenerateThumbnail(IXpsOMPage* page, XPS_IMAGE_TYPE thumbnailType, XPS_THUMBNAIL_SIZE thumbnailSize, IOpcPartUri* imageResourcePartName, IXpsOMImageResource** imageResource) mut => VT.[Friend]GenerateThumbnail(&this, page, thumbnailType, thumbnailSize, imageResourcePartName, imageResource);
}

[CRepr]struct IXpsOMObjectFactory1 : IXpsOMObjectFactory
{
	public new const Guid IID = .(0x0a91b617, 0xd612, 0x4181, 0xbf, 0x7c, 0xbe, 0x58, 0x24, 0xe9, 0xcc, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMObjectFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, XPS_DOCUMENT_TYPE* documentType) GetDocumentTypeFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* xpsDocumentStream, XPS_DOCUMENT_TYPE* documentType) GetDocumentTypeFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* imageResource) ConvertHDPhotoToJpegXR;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMImageResource* imageResource) ConvertJpegXRToHDPhoto;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, XPS_DOCUMENT_TYPE documentType, IXpsOMPackageWriter** packageWriter) CreatePackageWriterOnFile1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, XPS_DOCUMENT_TYPE documentType, IXpsOMPackageWriter** packageWriter) CreatePackageWriterOnStream1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMPackage1** package) CreatePackage1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream, BOOL reuseObjects, IXpsOMPackage1** package) CreatePackageFromStream1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, BOOL reuseObjects, IXpsOMPackage1** package) CreatePackageFromFile1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIZE* pageDimensions, PWSTR language, IOpcPartUri* partUri, IXpsOMPage1** page) CreatePage1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pageMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, BOOL reuseObjects, IXpsOMPage1** page) CreatePageFromStream1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* dictionaryMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, IXpsOMRemoteDictionaryResource** dictionaryResource) CreateRemoteDictionaryResourceFromStream1;
	}


	public HRESULT GetDocumentTypeFromFile(PWSTR filename, XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetDocumentTypeFromFile(&this, filename, documentType);

	public HRESULT GetDocumentTypeFromStream(IStream* xpsDocumentStream, XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetDocumentTypeFromStream(&this, xpsDocumentStream, documentType);

	public HRESULT ConvertHDPhotoToJpegXR(IXpsOMImageResource* imageResource) mut => VT.[Friend]ConvertHDPhotoToJpegXR(&this, imageResource);

	public HRESULT ConvertJpegXRToHDPhoto(IXpsOMImageResource* imageResource) mut => VT.[Friend]ConvertJpegXRToHDPhoto(&this, imageResource);

	public HRESULT CreatePackageWriterOnFile1(PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, XPS_DOCUMENT_TYPE documentType, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]CreatePackageWriterOnFile1(&this, fileName, securityAttributes, flagsAndAttributes, optimizeMarkupSize, interleaving, documentSequencePartName, coreProperties, packageThumbnail, documentSequencePrintTicket, discardControlPartName, documentType, packageWriter);

	public HRESULT CreatePackageWriterOnStream1(ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_INTERLEAVING interleaving, IOpcPartUri* documentSequencePartName, IXpsOMCoreProperties* coreProperties, IXpsOMImageResource* packageThumbnail, IXpsOMPrintTicketResource* documentSequencePrintTicket, IOpcPartUri* discardControlPartName, XPS_DOCUMENT_TYPE documentType, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]CreatePackageWriterOnStream1(&this, outputStream, optimizeMarkupSize, interleaving, documentSequencePartName, coreProperties, packageThumbnail, documentSequencePrintTicket, discardControlPartName, documentType, packageWriter);

	public HRESULT CreatePackage1(IXpsOMPackage1** package) mut => VT.[Friend]CreatePackage1(&this, package);

	public HRESULT CreatePackageFromStream1(IStream* stream, BOOL reuseObjects, IXpsOMPackage1** package) mut => VT.[Friend]CreatePackageFromStream1(&this, stream, reuseObjects, package);

	public HRESULT CreatePackageFromFile1(PWSTR filename, BOOL reuseObjects, IXpsOMPackage1** package) mut => VT.[Friend]CreatePackageFromFile1(&this, filename, reuseObjects, package);

	public HRESULT CreatePage1(XPS_SIZE* pageDimensions, PWSTR language, IOpcPartUri* partUri, IXpsOMPage1** page) mut => VT.[Friend]CreatePage1(&this, pageDimensions, language, partUri, page);

	public HRESULT CreatePageFromStream1(IStream* pageMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, BOOL reuseObjects, IXpsOMPage1** page) mut => VT.[Friend]CreatePageFromStream1(&this, pageMarkupStream, partUri, resources, reuseObjects, page);

	public HRESULT CreateRemoteDictionaryResourceFromStream1(IStream* dictionaryMarkupStream, IOpcPartUri* partUri, IXpsOMPartResources* resources, IXpsOMRemoteDictionaryResource** dictionaryResource) mut => VT.[Friend]CreateRemoteDictionaryResourceFromStream1(&this, dictionaryMarkupStream, partUri, resources, dictionaryResource);
}

[CRepr]struct IXpsOMPackage1 : IXpsOMPackage
{
	public new const Guid IID = .(0x95a9435e, 0x12bb, 0x461b, 0x8e, 0x7f, 0xc6, 0xad, 0xb0, 0x4c, 0xd9, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPackage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DOCUMENT_TYPE* documentType) GetDocumentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) WriteToFile1;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) WriteToStream1;
	}


	public HRESULT GetDocumentType(XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetDocumentType(&this, documentType);

	public HRESULT WriteToFile1(PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) mut => VT.[Friend]WriteToFile1(&this, fileName, securityAttributes, flagsAndAttributes, optimizeMarkupSize, documentType);

	public HRESULT WriteToStream1(ISequentialStream* outputStream, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) mut => VT.[Friend]WriteToStream1(&this, outputStream, optimizeMarkupSize, documentType);
}

[CRepr]struct IXpsOMPage1 : IXpsOMPage
{
	public new const Guid IID = .(0x305b60ef, 0x6892, 0x4dda, 0x9c, 0xbb, 0x3a, 0xa6, 0x59, 0x74, 0x50, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DOCUMENT_TYPE* documentType) GetDocumentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* stream, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) Write1;
	}


	public HRESULT GetDocumentType(XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetDocumentType(&this, documentType);

	public HRESULT Write1(ISequentialStream* stream, BOOL optimizeMarkupSize, XPS_DOCUMENT_TYPE documentType) mut => VT.[Friend]Write1(&this, stream, optimizeMarkupSize, documentType);
}

[CRepr]struct IXpsDocumentPackageTarget : IUnknown
{
	public new const Guid IID = .(0x3b0b6d38, 0x53ad, 0x41da, 0xb2, 0x12, 0xd3, 0x76, 0x37, 0xa6, 0x71, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* documentSequencePartName, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) GetXpsOMPackageWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMObjectFactory** xpsFactory) GetXpsOMFactory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DOCUMENT_TYPE* documentType) GetXpsType;
	}


	public HRESULT GetXpsOMPackageWriter(IOpcPartUri* documentSequencePartName, IOpcPartUri* discardControlPartName, IXpsOMPackageWriter** packageWriter) mut => VT.[Friend]GetXpsOMPackageWriter(&this, documentSequencePartName, discardControlPartName, packageWriter);

	public HRESULT GetXpsOMFactory(IXpsOMObjectFactory** xpsFactory) mut => VT.[Friend]GetXpsOMFactory(&this, xpsFactory);

	public HRESULT GetXpsType(XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetXpsType(&this, documentType);
}

[CRepr]struct IXpsOMRemoteDictionaryResource1 : IXpsOMRemoteDictionaryResource
{
	public new const Guid IID = .(0xbf8fc1d4, 0x9d46, 0x4141, 0xba, 0x5f, 0x94, 0xbb, 0x92, 0x50, 0xd0, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMRemoteDictionaryResource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_DOCUMENT_TYPE* documentType) GetDocumentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISequentialStream* stream, XPS_DOCUMENT_TYPE documentType) Write1;
	}


	public HRESULT GetDocumentType(XPS_DOCUMENT_TYPE* documentType) mut => VT.[Friend]GetDocumentType(&this, documentType);

	public HRESULT Write1(ISequentialStream* stream, XPS_DOCUMENT_TYPE documentType) mut => VT.[Friend]Write1(&this, stream, documentType);
}

[CRepr]struct IXpsOMPackageWriter3D : IXpsOMPackageWriter
{
	public new const Guid IID = .(0xe8a45033, 0x640e, 0x43fa, 0x9b, 0xdf, 0xfd, 0xde, 0xaa, 0x31, 0xc6, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXpsOMPackageWriter.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* texturePartName, IStream* textureData) AddModelTexture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* printTicketPartName, IStream* printTicketData) SetModelPrintTicket;
	}


	public HRESULT AddModelTexture(IOpcPartUri* texturePartName, IStream* textureData) mut => VT.[Friend]AddModelTexture(&this, texturePartName, textureData);

	public HRESULT SetModelPrintTicket(IOpcPartUri* printTicketPartName, IStream* printTicketData) mut => VT.[Friend]SetModelPrintTicket(&this, printTicketPartName, printTicketData);
}

[CRepr]struct IXpsDocumentPackageTarget3D : IUnknown
{
	public new const Guid IID = .(0x60ba71b8, 0x3101, 0x4984, 0x91, 0x99, 0xf4, 0xea, 0x77, 0x5f, 0xf0, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* documentSequencePartName, IOpcPartUri* discardControlPartName, IOpcPartUri* modelPartName, IStream* modelData, IXpsOMPackageWriter3D** packageWriter) GetXpsOMPackageWriter3D;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsOMObjectFactory** xpsFactory) GetXpsOMFactory;
	}


	public HRESULT GetXpsOMPackageWriter3D(IOpcPartUri* documentSequencePartName, IOpcPartUri* discardControlPartName, IOpcPartUri* modelPartName, IStream* modelData, IXpsOMPackageWriter3D** packageWriter) mut => VT.[Friend]GetXpsOMPackageWriter3D(&this, documentSequencePartName, discardControlPartName, modelPartName, modelData, packageWriter);

	public HRESULT GetXpsOMFactory(IXpsOMObjectFactory** xpsFactory) mut => VT.[Friend]GetXpsOMFactory(&this, xpsFactory);
}

[CRepr]struct IXpsSigningOptions : IUnknown
{
	public new const Guid IID = .(0x7718eae4, 0x3215, 0x49be, 0xaf, 0x5b, 0x59, 0x4f, 0xef, 0x7f, 0xcf, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureId) GetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR signatureId) SetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureMethod) GetSignatureMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR signatureMethod) SetSignatureMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* digestMethod) GetDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR digestMethod) SetDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signaturePartName) GetSignaturePartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signaturePartName) SetSignaturePartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIGN_POLICY* policy) GetPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIGN_POLICY policy) SetPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT* timeFormat) GetSigningTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT timeFormat) SetSigningTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectSet** customObjectSet) GetCustomObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceSet** customReferenceSet) GetCustomReferences;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateSet** certificateSet) GetCertificateSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIGN_FLAGS* flags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIGN_FLAGS flags) SetFlags;
	}


	public HRESULT GetSignatureId(PWSTR* signatureId) mut => VT.[Friend]GetSignatureId(&this, signatureId);

	public HRESULT SetSignatureId(PWSTR signatureId) mut => VT.[Friend]SetSignatureId(&this, signatureId);

	public HRESULT GetSignatureMethod(PWSTR* signatureMethod) mut => VT.[Friend]GetSignatureMethod(&this, signatureMethod);

	public HRESULT SetSignatureMethod(PWSTR signatureMethod) mut => VT.[Friend]SetSignatureMethod(&this, signatureMethod);

	public HRESULT GetDigestMethod(PWSTR* digestMethod) mut => VT.[Friend]GetDigestMethod(&this, digestMethod);

	public HRESULT SetDigestMethod(PWSTR digestMethod) mut => VT.[Friend]SetDigestMethod(&this, digestMethod);

	public HRESULT GetSignaturePartName(IOpcPartUri** signaturePartName) mut => VT.[Friend]GetSignaturePartName(&this, signaturePartName);

	public HRESULT SetSignaturePartName(IOpcPartUri* signaturePartName) mut => VT.[Friend]SetSignaturePartName(&this, signaturePartName);

	public HRESULT GetPolicy(XPS_SIGN_POLICY* policy) mut => VT.[Friend]GetPolicy(&this, policy);

	public HRESULT SetPolicy(XPS_SIGN_POLICY policy) mut => VT.[Friend]SetPolicy(&this, policy);

	public HRESULT GetSigningTimeFormat(OPC_SIGNATURE_TIME_FORMAT* timeFormat) mut => VT.[Friend]GetSigningTimeFormat(&this, timeFormat);

	public HRESULT SetSigningTimeFormat(OPC_SIGNATURE_TIME_FORMAT timeFormat) mut => VT.[Friend]SetSigningTimeFormat(&this, timeFormat);

	public HRESULT GetCustomObjects(IOpcSignatureCustomObjectSet** customObjectSet) mut => VT.[Friend]GetCustomObjects(&this, customObjectSet);

	public HRESULT GetCustomReferences(IOpcSignatureReferenceSet** customReferenceSet) mut => VT.[Friend]GetCustomReferences(&this, customReferenceSet);

	public HRESULT GetCertificateSet(IOpcCertificateSet** certificateSet) mut => VT.[Friend]GetCertificateSet(&this, certificateSet);

	public HRESULT GetFlags(XPS_SIGN_FLAGS* flags) mut => VT.[Friend]COM_GetFlags(&this, flags);

	public HRESULT SetFlags(XPS_SIGN_FLAGS flags) mut => VT.[Friend]SetFlags(&this, flags);
}

[CRepr]struct IXpsSignatureCollection : IUnknown
{
	public new const Guid IID = .(0xa2d1d95d, 0xadd2, 0x4dff, 0xab, 0x27, 0x6b, 0x9c, 0x64, 0x5f, 0xf3, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsSignature** signature) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsSignature** signature) mut => VT.[Friend]GetAt(&this, index, signature);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);
}

[CRepr]struct IXpsSignature : IUnknown
{
	public new const Guid IID = .(0x6ae4c93e, 0x1ade, 0x42fb, 0x89, 0x8b, 0x3a, 0x56, 0x58, 0x28, 0x48, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sigId) GetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** signatureHashValue, uint32* count) GetSignatureValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateEnumerator** certificateEnumerator) GetCertificateEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sigDateTimeString) GetSigningTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT* timeFormat) GetSigningTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signaturePartName) GetSignaturePartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* x509Certificate, XPS_SIGNATURE_STATUS* sigStatus) Verify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XPS_SIGN_POLICY* policy) GetPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) GetCustomObjectEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceEnumerator** customReferenceEnumerator) GetCustomReferenceEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** signatureXml, uint32* count) GetSignatureXml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* signatureXml, uint32 count) SetSignatureXml;
	}


	public HRESULT GetSignatureId(PWSTR* sigId) mut => VT.[Friend]GetSignatureId(&this, sigId);

	public HRESULT GetSignatureValue(uint8** signatureHashValue, uint32* count) mut => VT.[Friend]GetSignatureValue(&this, signatureHashValue, count);

	public HRESULT GetCertificateEnumerator(IOpcCertificateEnumerator** certificateEnumerator) mut => VT.[Friend]GetCertificateEnumerator(&this, certificateEnumerator);

	public HRESULT GetSigningTime(PWSTR* sigDateTimeString) mut => VT.[Friend]GetSigningTime(&this, sigDateTimeString);

	public HRESULT GetSigningTimeFormat(OPC_SIGNATURE_TIME_FORMAT* timeFormat) mut => VT.[Friend]GetSigningTimeFormat(&this, timeFormat);

	public HRESULT GetSignaturePartName(IOpcPartUri** signaturePartName) mut => VT.[Friend]GetSignaturePartName(&this, signaturePartName);

	public HRESULT Verify(CERT_CONTEXT* x509Certificate, XPS_SIGNATURE_STATUS* sigStatus) mut => VT.[Friend]Verify(&this, x509Certificate, sigStatus);

	public HRESULT GetPolicy(XPS_SIGN_POLICY* policy) mut => VT.[Friend]GetPolicy(&this, policy);

	public HRESULT GetCustomObjectEnumerator(IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) mut => VT.[Friend]GetCustomObjectEnumerator(&this, customObjectEnumerator);

	public HRESULT GetCustomReferenceEnumerator(IOpcSignatureReferenceEnumerator** customReferenceEnumerator) mut => VT.[Friend]GetCustomReferenceEnumerator(&this, customReferenceEnumerator);

	public HRESULT GetSignatureXml(uint8** signatureXml, uint32* count) mut => VT.[Friend]GetSignatureXml(&this, signatureXml, count);

	public HRESULT SetSignatureXml(uint8* signatureXml, uint32 count) mut => VT.[Friend]SetSignatureXml(&this, signatureXml, count);
}

[CRepr]struct IXpsSignatureBlockCollection : IUnknown
{
	public new const Guid IID = .(0x23397050, 0xfe99, 0x467a, 0x8d, 0xce, 0x92, 0x37, 0xf0, 0x74, 0xff, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsSignatureBlock** signatureBlock) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsSignatureBlock** signatureBlock) mut => VT.[Friend]GetAt(&this, index, signatureBlock);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);
}

[CRepr]struct IXpsSignatureBlock : IUnknown
{
	public new const Guid IID = .(0x151fac09, 0x0b97, 0x4ac6, 0xa3, 0x23, 0x5e, 0x42, 0x97, 0xd4, 0x32, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSignatureRequestCollection** requests) GetRequests;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** partName) GetPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* fixedDocumentIndex) GetDocumentIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** fixedDocumentName) GetDocumentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR requestId, IXpsSignatureRequest** signatureRequest) CreateRequest;
	}


	public HRESULT GetRequests(IXpsSignatureRequestCollection** requests) mut => VT.[Friend]GetRequests(&this, requests);

	public HRESULT GetPartName(IOpcPartUri** partName) mut => VT.[Friend]GetPartName(&this, partName);

	public HRESULT GetDocumentIndex(uint32* fixedDocumentIndex) mut => VT.[Friend]GetDocumentIndex(&this, fixedDocumentIndex);

	public HRESULT GetDocumentName(IOpcPartUri** fixedDocumentName) mut => VT.[Friend]GetDocumentName(&this, fixedDocumentName);

	public HRESULT CreateRequest(PWSTR requestId, IXpsSignatureRequest** signatureRequest) mut => VT.[Friend]CreateRequest(&this, requestId, signatureRequest);
}

[CRepr]struct IXpsSignatureRequestCollection : IUnknown
{
	public new const Guid IID = .(0xf0253e68, 0x9f19, 0x412e, 0x9b, 0x4f, 0x54, 0xd3, 0xb0, 0xac, 0x6c, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IXpsSignatureRequest** signatureRequest) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetAt(uint32 index, IXpsSignatureRequest** signatureRequest) mut => VT.[Friend]GetAt(&this, index, signatureRequest);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);
}

[CRepr]struct IXpsSignatureRequest : IUnknown
{
	public new const Guid IID = .(0xac58950b, 0x7208, 0x4b2d, 0xb2, 0xc4, 0x95, 0x10, 0x83, 0xd3, 0xb8, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* intent) GetIntent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR intent) SetIntent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signerName) GetRequestedSigner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR signerName) SetRequestedSigner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* dateString) GetRequestSignByDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR dateString) SetRequestSignByDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* place) GetSigningLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR place) SetSigningLocale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pageIndex, IOpcPartUri** pagePartName, float* x, float* y) GetSpotLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 pageIndex, float x, float y) SetSpotLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* requestId) GetRequestId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSignature** signature) GetSignature;
	}


	public HRESULT GetIntent(PWSTR* intent) mut => VT.[Friend]GetIntent(&this, intent);

	public HRESULT SetIntent(PWSTR intent) mut => VT.[Friend]SetIntent(&this, intent);

	public HRESULT GetRequestedSigner(PWSTR* signerName) mut => VT.[Friend]GetRequestedSigner(&this, signerName);

	public HRESULT SetRequestedSigner(PWSTR signerName) mut => VT.[Friend]SetRequestedSigner(&this, signerName);

	public HRESULT GetRequestSignByDate(PWSTR* dateString) mut => VT.[Friend]GetRequestSignByDate(&this, dateString);

	public HRESULT SetRequestSignByDate(PWSTR dateString) mut => VT.[Friend]SetRequestSignByDate(&this, dateString);

	public HRESULT GetSigningLocale(PWSTR* place) mut => VT.[Friend]GetSigningLocale(&this, place);

	public HRESULT SetSigningLocale(PWSTR place) mut => VT.[Friend]SetSigningLocale(&this, place);

	public HRESULT GetSpotLocation(int32* pageIndex, IOpcPartUri** pagePartName, float* x, float* y) mut => VT.[Friend]GetSpotLocation(&this, pageIndex, pagePartName, x, y);

	public HRESULT SetSpotLocation(int32 pageIndex, float x, float y) mut => VT.[Friend]SetSpotLocation(&this, pageIndex, x, y);

	public HRESULT GetRequestId(PWSTR* requestId) mut => VT.[Friend]GetRequestId(&this, requestId);

	public HRESULT GetSignature(IXpsSignature** signature) mut => VT.[Friend]GetSignature(&this, signature);
}

[CRepr]struct IXpsSignatureManager : IUnknown
{
	public new const Guid IID = .(0xd3e8d338, 0xfdc4, 0x4afc, 0x80, 0xb5, 0xd5, 0x32, 0xa1, 0x78, 0x2e, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName) LoadPackageFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream) LoadPackageStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSigningOptions* signOptions, CERT_CONTEXT* x509Certificate, IXpsSignature** signature) Sign;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signatureOriginPartName) GetSignatureOriginPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signatureOriginPartName) SetSignatureOriginPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSignatureCollection** signatures) GetSignatures;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partName, uint32 fixedDocumentIndex, IXpsSignatureBlock** signatureBlock) AddSignatureBlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSignatureBlockCollection** signatureBlocks) GetSignatureBlocks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXpsSigningOptions** signingOptions) CreateSigningOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes) SavePackageToFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream) SavePackageToStream;
	}


	public HRESULT LoadPackageFile(PWSTR fileName) mut => VT.[Friend]LoadPackageFile(&this, fileName);

	public HRESULT LoadPackageStream(IStream* stream) mut => VT.[Friend]LoadPackageStream(&this, stream);

	public HRESULT Sign(IXpsSigningOptions* signOptions, CERT_CONTEXT* x509Certificate, IXpsSignature** signature) mut => VT.[Friend]Sign(&this, signOptions, x509Certificate, signature);

	public HRESULT GetSignatureOriginPartName(IOpcPartUri** signatureOriginPartName) mut => VT.[Friend]GetSignatureOriginPartName(&this, signatureOriginPartName);

	public HRESULT SetSignatureOriginPartName(IOpcPartUri* signatureOriginPartName) mut => VT.[Friend]SetSignatureOriginPartName(&this, signatureOriginPartName);

	public HRESULT GetSignatures(IXpsSignatureCollection** signatures) mut => VT.[Friend]GetSignatures(&this, signatures);

	public HRESULT AddSignatureBlock(IOpcPartUri* partName, uint32 fixedDocumentIndex, IXpsSignatureBlock** signatureBlock) mut => VT.[Friend]AddSignatureBlock(&this, partName, fixedDocumentIndex, signatureBlock);

	public HRESULT GetSignatureBlocks(IXpsSignatureBlockCollection** signatureBlocks) mut => VT.[Friend]GetSignatureBlocks(&this, signatureBlocks);

	public HRESULT CreateSigningOptions(IXpsSigningOptions** signingOptions) mut => VT.[Friend]CreateSigningOptions(&this, signingOptions);

	public HRESULT SavePackageToFile(PWSTR fileName, SECURITY_ATTRIBUTES* securityAttributes, uint32 flagsAndAttributes) mut => VT.[Friend]SavePackageToFile(&this, fileName, securityAttributes, flagsAndAttributes);

	public HRESULT SavePackageToStream(IStream* stream) mut => VT.[Friend]SavePackageToStream(&this, stream);
}

#endregion

#region Functions
public static
{
	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DeviceCapabilitiesA(PSTR pDevice, PSTR pPort, DEVICE_CAPABILITIES fwCapability, PSTR pOutput, DEVMODEA* pDevMode);
	public static int32 DeviceCapabilities(PSTR pDevice, PSTR pPort, DEVICE_CAPABILITIES fwCapability, PSTR pOutput, DEVMODEA* pDevMode) => DeviceCapabilitiesA(pDevice, pPort, fwCapability, pOutput, pDevMode);

	[Import("winspool.drv"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DeviceCapabilitiesW(PWSTR pDevice, PWSTR pPort, DEVICE_CAPABILITIES fwCapability, PWSTR pOutput, DEVMODEW* pDevMode);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 Escape(HDC hdc, int32 iEscape, int32 cjIn, PSTR pvIn, void* pvOut);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ExtEscape(HDC hdc, int32 iEscape, int32 cjInput, PSTR lpInData, int32 cjOutput, PSTR lpOutData);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StartDocA(HDC hdc, DOCINFOA* lpdi);
	public static int32 StartDoc(HDC hdc, DOCINFOA* lpdi) => StartDocA(hdc, lpdi);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StartDocW(HDC hdc, DOCINFOW* lpdi);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EndDoc(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StartPage(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 EndPage(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 AbortDoc(HDC hdc);

	[Import("GDI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetAbortProc(HDC hdc, ABORTPROC proc);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PrintWindow(HWND hwnd, HDC hdcBlt, PRINT_WINDOW_FLAGS nFlags);

}
#endregion
