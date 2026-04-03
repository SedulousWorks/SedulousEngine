using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.Data.Xml.XmlLite;

#region Constants
public static
{
	public const Guid _IID_IXmlReader = .(0x7279fc81, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);
	public const Guid _IID_IXmlWriter = .(0x7279fc88, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);
	public const Guid _IID_IXmlResolver = .(0x7279fc82, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);
}
#endregion

#region Enums

[AllowDuplicates]
public enum XmlNodeType : int32
{
	XmlNodeType_None = 0,
	XmlNodeType_Element = 1,
	XmlNodeType_Attribute = 2,
	XmlNodeType_Text = 3,
	XmlNodeType_CDATA = 4,
	XmlNodeType_ProcessingInstruction = 7,
	XmlNodeType_Comment = 8,
	XmlNodeType_DocumentType = 10,
	XmlNodeType_Whitespace = 13,
	XmlNodeType_EndElement = 15,
	XmlNodeType_XmlDeclaration = 17,
	_XmlNodeType_Last = 17,
}


[AllowDuplicates]
public enum XmlConformanceLevel : int32
{
	XmlConformanceLevel_Auto = 0,
	XmlConformanceLevel_Fragment = 1,
	XmlConformanceLevel_Document = 2,
	_XmlConformanceLevel_Last = 2,
}


[AllowDuplicates]
public enum DtdProcessing : int32
{
	DtdProcessing_Prohibit = 0,
	DtdProcessing_Parse = 1,
	_DtdProcessing_Last = 1,
}


[AllowDuplicates]
public enum XmlReadState : int32
{
	XmlReadState_Initial = 0,
	XmlReadState_Interactive = 1,
	XmlReadState_Error = 2,
	XmlReadState_EndOfFile = 3,
	XmlReadState_Closed = 4,
}


[AllowDuplicates]
public enum XmlReaderProperty : int32
{
	XmlReaderProperty_MultiLanguage = 0,
	XmlReaderProperty_ConformanceLevel = 1,
	XmlReaderProperty_RandomAccess = 2,
	XmlReaderProperty_XmlResolver = 3,
	XmlReaderProperty_DtdProcessing = 4,
	XmlReaderProperty_ReadState = 5,
	XmlReaderProperty_MaxElementDepth = 6,
	XmlReaderProperty_MaxEntityExpansion = 7,
	_XmlReaderProperty_Last = 7,
}


[AllowDuplicates]
public enum XmlError : int32
{
	MX_E_MX = -1072894464,
	MX_E_INPUTEND = -1072894463,
	MX_E_ENCODING = -1072894462,
	MX_E_ENCODINGSWITCH = -1072894461,
	MX_E_ENCODINGSIGNATURE = -1072894460,
	WC_E_WC = -1072894432,
	WC_E_WHITESPACE = -1072894431,
	WC_E_SEMICOLON = -1072894430,
	WC_E_GREATERTHAN = -1072894429,
	WC_E_QUOTE = -1072894428,
	WC_E_EQUAL = -1072894427,
	WC_E_LESSTHAN = -1072894426,
	WC_E_HEXDIGIT = -1072894425,
	WC_E_DIGIT = -1072894424,
	WC_E_LEFTBRACKET = -1072894423,
	WC_E_LEFTPAREN = -1072894422,
	WC_E_XMLCHARACTER = -1072894421,
	WC_E_NAMECHARACTER = -1072894420,
	WC_E_SYNTAX = -1072894419,
	WC_E_CDSECT = -1072894418,
	WC_E_COMMENT = -1072894417,
	WC_E_CONDSECT = -1072894416,
	WC_E_DECLATTLIST = -1072894415,
	WC_E_DECLDOCTYPE = -1072894414,
	WC_E_DECLELEMENT = -1072894413,
	WC_E_DECLENTITY = -1072894412,
	WC_E_DECLNOTATION = -1072894411,
	WC_E_NDATA = -1072894410,
	WC_E_PUBLIC = -1072894409,
	WC_E_SYSTEM = -1072894408,
	WC_E_NAME = -1072894407,
	WC_E_ROOTELEMENT = -1072894406,
	WC_E_ELEMENTMATCH = -1072894405,
	WC_E_UNIQUEATTRIBUTE = -1072894404,
	WC_E_TEXTXMLDECL = -1072894403,
	WC_E_LEADINGXML = -1072894402,
	WC_E_TEXTDECL = -1072894401,
	WC_E_XMLDECL = -1072894400,
	WC_E_ENCNAME = -1072894399,
	WC_E_PUBLICID = -1072894398,
	WC_E_PESINTERNALSUBSET = -1072894397,
	WC_E_PESBETWEENDECLS = -1072894396,
	WC_E_NORECURSION = -1072894395,
	WC_E_ENTITYCONTENT = -1072894394,
	WC_E_UNDECLAREDENTITY = -1072894393,
	WC_E_PARSEDENTITY = -1072894392,
	WC_E_NOEXTERNALENTITYREF = -1072894391,
	WC_E_PI = -1072894390,
	WC_E_SYSTEMID = -1072894389,
	WC_E_QUESTIONMARK = -1072894388,
	WC_E_CDSECTEND = -1072894387,
	WC_E_MOREDATA = -1072894386,
	WC_E_DTDPROHIBITED = -1072894385,
	WC_E_INVALIDXMLSPACE = -1072894384,
	NC_E_NC = -1072894368,
	NC_E_QNAMECHARACTER = -1072894367,
	NC_E_QNAMECOLON = -1072894366,
	NC_E_NAMECOLON = -1072894365,
	NC_E_DECLAREDPREFIX = -1072894364,
	NC_E_UNDECLAREDPREFIX = -1072894363,
	NC_E_EMPTYURI = -1072894362,
	NC_E_XMLPREFIXRESERVED = -1072894361,
	NC_E_XMLNSPREFIXRESERVED = -1072894360,
	NC_E_XMLURIRESERVED = -1072894359,
	NC_E_XMLNSURIRESERVED = -1072894358,
	SC_E_SC = -1072894336,
	SC_E_MAXELEMENTDEPTH = -1072894335,
	SC_E_MAXENTITYEXPANSION = -1072894334,
	WR_E_WR = -1072894208,
	WR_E_NONWHITESPACE = -1072894207,
	WR_E_NSPREFIXDECLARED = -1072894206,
	WR_E_NSPREFIXWITHEMPTYNSURI = -1072894205,
	WR_E_DUPLICATEATTRIBUTE = -1072894204,
	WR_E_XMLNSPREFIXDECLARATION = -1072894203,
	WR_E_XMLPREFIXDECLARATION = -1072894202,
	WR_E_XMLURIDECLARATION = -1072894201,
	WR_E_XMLNSURIDECLARATION = -1072894200,
	WR_E_NAMESPACEUNDECLARED = -1072894199,
	WR_E_INVALIDXMLSPACE = -1072894198,
	WR_E_INVALIDACTION = -1072894197,
	WR_E_INVALIDSURROGATEPAIR = -1072894196,
	XML_E_INVALID_DECIMAL = -1072898019,
	XML_E_INVALID_HEXIDECIMAL = -1072898018,
	XML_E_INVALID_UNICODE = -1072898017,
	XML_E_INVALIDENCODING = -1072897938,
}


[AllowDuplicates]
public enum XmlStandalone : int32
{
	XmlStandalone_Omit = 0,
	XmlStandalone_Yes = 1,
	XmlStandalone_No = 2,
	_XmlStandalone_Last = 2,
}


[AllowDuplicates]
public enum XmlWriterProperty : int32
{
	XmlWriterProperty_MultiLanguage = 0,
	XmlWriterProperty_Indent = 1,
	XmlWriterProperty_ByteOrderMark = 2,
	XmlWriterProperty_OmitXmlDeclaration = 3,
	XmlWriterProperty_ConformanceLevel = 4,
	XmlWriterProperty_CompactEmptyElement = 5,
	_XmlWriterProperty_Last = 5,
}

#endregion


#region COM Types
[CRepr]struct IXmlReader : IUnknown
{
	public new const Guid IID = .(0x7279fc81, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pInput) SetInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int* ppValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int pValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XmlNodeType* pNodeType) Read;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XmlNodeType* pNodeType) GetNodeType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveToFirstAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveToNextAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszLocalName, PWSTR pwszNamespaceUri) MoveToAttributeByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveToElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszQualifiedName, uint32* pcwchQualifiedName) GetQualifiedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszNamespaceUri, uint32* pcwchNamespaceUri) GetNamespaceUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszLocalName, uint32* pcwchLocalName) GetLocalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszPrefix, uint32* pcwchPrefix) GetPrefix;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszValue, uint32* pcwchValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwchBuffer, uint32 cwchChunkSize, uint32* pcwchRead) ReadValueChunk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszBaseUri, uint32* pcwchBaseUri) GetBaseUri;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsDefault;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsEmptyElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnLineNumber) GetLineNumber;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnLinePosition) GetLinePosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnAttributeCount) GetAttributeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnDepth) GetDepth;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsEOF;
	}


	public HRESULT SetInput(IUnknown* pInput) mut => VT.[Friend]SetInput(&this, pInput);

	public HRESULT GetProperty(uint32 nProperty, int* ppValue) mut => VT.[Friend]GetProperty(&this, nProperty, ppValue);

	public HRESULT SetProperty(uint32 nProperty, int pValue) mut => VT.[Friend]SetProperty(&this, nProperty, pValue);

	public HRESULT Read(XmlNodeType* pNodeType) mut => VT.[Friend]Read(&this, pNodeType);

	public HRESULT GetNodeType(XmlNodeType* pNodeType) mut => VT.[Friend]GetNodeType(&this, pNodeType);

	public HRESULT MoveToFirstAttribute() mut => VT.[Friend]MoveToFirstAttribute(&this);

	public HRESULT MoveToNextAttribute() mut => VT.[Friend]MoveToNextAttribute(&this);

	public HRESULT MoveToAttributeByName(PWSTR pwszLocalName, PWSTR pwszNamespaceUri) mut => VT.[Friend]MoveToAttributeByName(&this, pwszLocalName, pwszNamespaceUri);

	public HRESULT MoveToElement() mut => VT.[Friend]MoveToElement(&this);

	public HRESULT GetQualifiedName(PWSTR* ppwszQualifiedName, uint32* pcwchQualifiedName) mut => VT.[Friend]GetQualifiedName(&this, ppwszQualifiedName, pcwchQualifiedName);

	public HRESULT GetNamespaceUri(PWSTR* ppwszNamespaceUri, uint32* pcwchNamespaceUri) mut => VT.[Friend]GetNamespaceUri(&this, ppwszNamespaceUri, pcwchNamespaceUri);

	public HRESULT GetLocalName(PWSTR* ppwszLocalName, uint32* pcwchLocalName) mut => VT.[Friend]GetLocalName(&this, ppwszLocalName, pcwchLocalName);

	public HRESULT GetPrefix(PWSTR* ppwszPrefix, uint32* pcwchPrefix) mut => VT.[Friend]GetPrefix(&this, ppwszPrefix, pcwchPrefix);

	public HRESULT GetValue(PWSTR* ppwszValue, uint32* pcwchValue) mut => VT.[Friend]GetValue(&this, ppwszValue, pcwchValue);

	public HRESULT ReadValueChunk(char16* pwchBuffer, uint32 cwchChunkSize, uint32* pcwchRead) mut => VT.[Friend]ReadValueChunk(&this, pwchBuffer, cwchChunkSize, pcwchRead);

	public HRESULT GetBaseUri(PWSTR* ppwszBaseUri, uint32* pcwchBaseUri) mut => VT.[Friend]GetBaseUri(&this, ppwszBaseUri, pcwchBaseUri);

	public BOOL IsDefault() mut => VT.[Friend]IsDefault(&this);

	public BOOL IsEmptyElement() mut => VT.[Friend]IsEmptyElement(&this);

	public HRESULT GetLineNumber(uint32* pnLineNumber) mut => VT.[Friend]GetLineNumber(&this, pnLineNumber);

	public HRESULT GetLinePosition(uint32* pnLinePosition) mut => VT.[Friend]GetLinePosition(&this, pnLinePosition);

	public HRESULT GetAttributeCount(uint32* pnAttributeCount) mut => VT.[Friend]GetAttributeCount(&this, pnAttributeCount);

	public HRESULT GetDepth(uint32* pnDepth) mut => VT.[Friend]GetDepth(&this, pnDepth);

	public BOOL IsEOF() mut => VT.[Friend]IsEOF(&this);
}

[CRepr]struct IXmlResolver : IUnknown
{
	public new const Guid IID = .(0x7279fc82, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszBaseUri, PWSTR pwszPublicIdentifier, PWSTR pwszSystemIdentifier, IUnknown** ppResolvedInput) ResolveUri;
	}


	public HRESULT ResolveUri(PWSTR pwszBaseUri, PWSTR pwszPublicIdentifier, PWSTR pwszSystemIdentifier, IUnknown** ppResolvedInput) mut => VT.[Friend]ResolveUri(&this, pwszBaseUri, pwszPublicIdentifier, pwszSystemIdentifier, ppResolvedInput);
}

[CRepr]struct IXmlWriter : IUnknown
{
	public new const Guid IID = .(0x7279fc88, 0x709d, 0x4095, 0xb6, 0x3d, 0x69, 0xfe, 0x4b, 0x0d, 0x90, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pOutput) SetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int* ppValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int pValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri, PWSTR pwszValue) WriteAttributeString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszText) WriteCData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16 wch) WriteCharEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwch, uint32 cwch) WriteChars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszComment) WriteComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, PWSTR pwszPublicId, PWSTR pwszSystemId, PWSTR pwszSubset) WriteDocType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri, PWSTR pwszValue) WriteElementString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WriteEndDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WriteEndElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) WriteEntityRef;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WriteFullEndElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) WriteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszNmToken) WriteNmToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteNodeShallow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, PWSTR pwszText) WriteProcessingInstruction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszLocalName, PWSTR pwszNamespaceUri) WriteQualifiedName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszData) WriteRaw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwch, uint32 cwch) WriteRawChars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XmlStandalone standalone) WriteStartDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri) WriteStartElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszText) WriteString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16 wchLow, char16 wchHigh) WriteSurrogateCharEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszWhitespace) WriteWhitespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
	}


	public HRESULT SetOutput(IUnknown* pOutput) mut => VT.[Friend]SetOutput(&this, pOutput);

	public HRESULT GetProperty(uint32 nProperty, int* ppValue) mut => VT.[Friend]GetProperty(&this, nProperty, ppValue);

	public HRESULT SetProperty(uint32 nProperty, int pValue) mut => VT.[Friend]SetProperty(&this, nProperty, pValue);

	public HRESULT WriteAttributes(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteAttributes(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteAttributeString(PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri, PWSTR pwszValue) mut => VT.[Friend]WriteAttributeString(&this, pwszPrefix, pwszLocalName, pwszNamespaceUri, pwszValue);

	public HRESULT WriteCData(PWSTR pwszText) mut => VT.[Friend]WriteCData(&this, pwszText);

	public HRESULT WriteCharEntity(char16 wch) mut => VT.[Friend]WriteCharEntity(&this, wch);

	public HRESULT WriteChars(char16* pwch, uint32 cwch) mut => VT.[Friend]WriteChars(&this, pwch, cwch);

	public HRESULT WriteComment(PWSTR pwszComment) mut => VT.[Friend]WriteComment(&this, pwszComment);

	public HRESULT WriteDocType(PWSTR pwszName, PWSTR pwszPublicId, PWSTR pwszSystemId, PWSTR pwszSubset) mut => VT.[Friend]WriteDocType(&this, pwszName, pwszPublicId, pwszSystemId, pwszSubset);

	public HRESULT WriteElementString(PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri, PWSTR pwszValue) mut => VT.[Friend]WriteElementString(&this, pwszPrefix, pwszLocalName, pwszNamespaceUri, pwszValue);

	public HRESULT WriteEndDocument() mut => VT.[Friend]WriteEndDocument(&this);

	public HRESULT WriteEndElement() mut => VT.[Friend]WriteEndElement(&this);

	public HRESULT WriteEntityRef(PWSTR pwszName) mut => VT.[Friend]WriteEntityRef(&this, pwszName);

	public HRESULT WriteFullEndElement() mut => VT.[Friend]WriteFullEndElement(&this);

	public HRESULT WriteName(PWSTR pwszName) mut => VT.[Friend]WriteName(&this, pwszName);

	public HRESULT WriteNmToken(PWSTR pwszNmToken) mut => VT.[Friend]WriteNmToken(&this, pwszNmToken);

	public HRESULT WriteNode(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteNode(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteNodeShallow(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteNodeShallow(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteProcessingInstruction(PWSTR pwszName, PWSTR pwszText) mut => VT.[Friend]WriteProcessingInstruction(&this, pwszName, pwszText);

	public HRESULT WriteQualifiedName(PWSTR pwszLocalName, PWSTR pwszNamespaceUri) mut => VT.[Friend]WriteQualifiedName(&this, pwszLocalName, pwszNamespaceUri);

	public HRESULT WriteRaw(PWSTR pwszData) mut => VT.[Friend]WriteRaw(&this, pwszData);

	public HRESULT WriteRawChars(char16* pwch, uint32 cwch) mut => VT.[Friend]WriteRawChars(&this, pwch, cwch);

	public HRESULT WriteStartDocument(XmlStandalone standalone) mut => VT.[Friend]WriteStartDocument(&this, standalone);

	public HRESULT WriteStartElement(PWSTR pwszPrefix, PWSTR pwszLocalName, PWSTR pwszNamespaceUri) mut => VT.[Friend]WriteStartElement(&this, pwszPrefix, pwszLocalName, pwszNamespaceUri);

	public HRESULT WriteString(PWSTR pwszText) mut => VT.[Friend]WriteString(&this, pwszText);

	public HRESULT WriteSurrogateCharEntity(char16 wchLow, char16 wchHigh) mut => VT.[Friend]WriteSurrogateCharEntity(&this, wchLow, wchHigh);

	public HRESULT WriteWhitespace(PWSTR pwszWhitespace) mut => VT.[Friend]WriteWhitespace(&this, pwszWhitespace);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);
}

[CRepr]struct IXmlWriterLite : IUnknown
{
	public new const Guid IID = .(0x862494c6, 0x1310, 0x4aad, 0xb3, 0xcd, 0x2d, 0xbe, 0xeb, 0xf6, 0x70, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pOutput) SetOutput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int* ppValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nProperty, int pValue) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszQName, uint32 cwszQName, char16* pwszValue, uint32 cwszValue) WriteAttributeString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszText) WriteCData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16 wch) WriteCharEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwch, uint32 cwch) WriteChars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszComment) WriteComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, PWSTR pwszPublicId, PWSTR pwszSystemId, PWSTR pwszSubset) WriteDocType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszQName, uint32 cwszQName, PWSTR pwszValue) WriteElementString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WriteEndDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszQName, uint32 cwszQName) WriteEndElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) WriteEntityRef;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszQName, uint32 cwszQName) WriteFullEndElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName) WriteName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszNmToken) WriteNmToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXmlReader* pReader, BOOL fWriteDefaultAttributes) WriteNodeShallow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, PWSTR pwszText) WriteProcessingInstruction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszData) WriteRaw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwch, uint32 cwch) WriteRawChars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, XmlStandalone standalone) WriteStartDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszQName, uint32 cwszQName) WriteStartElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszText) WriteString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16 wchLow, char16 wchHigh) WriteSurrogateCharEntity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszWhitespace) WriteWhitespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
	}


	public HRESULT SetOutput(IUnknown* pOutput) mut => VT.[Friend]SetOutput(&this, pOutput);

	public HRESULT GetProperty(uint32 nProperty, int* ppValue) mut => VT.[Friend]GetProperty(&this, nProperty, ppValue);

	public HRESULT SetProperty(uint32 nProperty, int pValue) mut => VT.[Friend]SetProperty(&this, nProperty, pValue);

	public HRESULT WriteAttributes(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteAttributes(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteAttributeString(char16* pwszQName, uint32 cwszQName, char16* pwszValue, uint32 cwszValue) mut => VT.[Friend]WriteAttributeString(&this, pwszQName, cwszQName, pwszValue, cwszValue);

	public HRESULT WriteCData(PWSTR pwszText) mut => VT.[Friend]WriteCData(&this, pwszText);

	public HRESULT WriteCharEntity(char16 wch) mut => VT.[Friend]WriteCharEntity(&this, wch);

	public HRESULT WriteChars(char16* pwch, uint32 cwch) mut => VT.[Friend]WriteChars(&this, pwch, cwch);

	public HRESULT WriteComment(PWSTR pwszComment) mut => VT.[Friend]WriteComment(&this, pwszComment);

	public HRESULT WriteDocType(PWSTR pwszName, PWSTR pwszPublicId, PWSTR pwszSystemId, PWSTR pwszSubset) mut => VT.[Friend]WriteDocType(&this, pwszName, pwszPublicId, pwszSystemId, pwszSubset);

	public HRESULT WriteElementString(char16* pwszQName, uint32 cwszQName, PWSTR pwszValue) mut => VT.[Friend]WriteElementString(&this, pwszQName, cwszQName, pwszValue);

	public HRESULT WriteEndDocument() mut => VT.[Friend]WriteEndDocument(&this);

	public HRESULT WriteEndElement(char16* pwszQName, uint32 cwszQName) mut => VT.[Friend]WriteEndElement(&this, pwszQName, cwszQName);

	public HRESULT WriteEntityRef(PWSTR pwszName) mut => VT.[Friend]WriteEntityRef(&this, pwszName);

	public HRESULT WriteFullEndElement(char16* pwszQName, uint32 cwszQName) mut => VT.[Friend]WriteFullEndElement(&this, pwszQName, cwszQName);

	public HRESULT WriteName(PWSTR pwszName) mut => VT.[Friend]WriteName(&this, pwszName);

	public HRESULT WriteNmToken(PWSTR pwszNmToken) mut => VT.[Friend]WriteNmToken(&this, pwszNmToken);

	public HRESULT WriteNode(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteNode(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteNodeShallow(IXmlReader* pReader, BOOL fWriteDefaultAttributes) mut => VT.[Friend]WriteNodeShallow(&this, pReader, fWriteDefaultAttributes);

	public HRESULT WriteProcessingInstruction(PWSTR pwszName, PWSTR pwszText) mut => VT.[Friend]WriteProcessingInstruction(&this, pwszName, pwszText);

	public HRESULT WriteRaw(PWSTR pwszData) mut => VT.[Friend]WriteRaw(&this, pwszData);

	public HRESULT WriteRawChars(char16* pwch, uint32 cwch) mut => VT.[Friend]WriteRawChars(&this, pwch, cwch);

	public HRESULT WriteStartDocument(XmlStandalone standalone) mut => VT.[Friend]WriteStartDocument(&this, standalone);

	public HRESULT WriteStartElement(char16* pwszQName, uint32 cwszQName) mut => VT.[Friend]WriteStartElement(&this, pwszQName, cwszQName);

	public HRESULT WriteString(PWSTR pwszText) mut => VT.[Friend]WriteString(&this, pwszText);

	public HRESULT WriteSurrogateCharEntity(char16 wchLow, char16 wchHigh) mut => VT.[Friend]WriteSurrogateCharEntity(&this, wchLow, wchHigh);

	public HRESULT WriteWhitespace(PWSTR pwszWhitespace) mut => VT.[Friend]WriteWhitespace(&this, pwszWhitespace);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);
}

#endregion

#region Functions
public static
{
	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlReader(in Guid riid, void** ppvObject, IMalloc* pMalloc);

	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlReaderInputWithEncodingCodePage(IUnknown* pInputStream, IMalloc* pMalloc, uint32 nEncodingCodePage, BOOL fEncodingHint, PWSTR pwszBaseUri, IUnknown** ppInput);

	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlReaderInputWithEncodingName(IUnknown* pInputStream, IMalloc* pMalloc, PWSTR pwszEncodingName, BOOL fEncodingHint, PWSTR pwszBaseUri, IUnknown** ppInput);

	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlWriter(in Guid riid, void** ppvObject, IMalloc* pMalloc);

	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlWriterOutputWithEncodingCodePage(IUnknown* pOutputStream, IMalloc* pMalloc, uint32 nEncodingCodePage, IUnknown** ppOutput);

	[Import("XmlLite.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateXmlWriterOutputWithEncodingName(IUnknown* pOutputStream, IMalloc* pMalloc, PWSTR pwszEncodingName, IUnknown** ppOutput);

}
#endregion
