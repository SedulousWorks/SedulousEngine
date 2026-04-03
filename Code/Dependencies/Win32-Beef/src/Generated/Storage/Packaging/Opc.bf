using Win32.Foundation;
using Win32.System.Com;
using Win32.Security.Cryptography;
using Win32.Security;
using System;

namespace Win32.Storage.Packaging.Opc;

#region Constants
public static
{
	public const HRESULT OPC_E_NONCONFORMING_URI = -2142175231;
	public const HRESULT OPC_E_RELATIVE_URI_REQUIRED = -2142175230;
	public const HRESULT OPC_E_RELATIONSHIP_URI_REQUIRED = -2142175229;
	public const HRESULT OPC_E_PART_CANNOT_BE_DIRECTORY = -2142175228;
	public const HRESULT OPC_E_UNEXPECTED_CONTENT_TYPE = -2142175227;
	public const HRESULT OPC_E_INVALID_CONTENT_TYPE_XML = -2142175226;
	public const HRESULT OPC_E_MISSING_CONTENT_TYPES = -2142175225;
	public const HRESULT OPC_E_NONCONFORMING_CONTENT_TYPES_XML = -2142175224;
	public const HRESULT OPC_E_NONCONFORMING_RELS_XML = -2142175223;
	public const HRESULT OPC_E_INVALID_RELS_XML = -2142175222;
	public const HRESULT OPC_E_DUPLICATE_PART = -2142175221;
	public const HRESULT OPC_E_INVALID_OVERRIDE_PART_NAME = -2142175220;
	public const HRESULT OPC_E_DUPLICATE_OVERRIDE_PART = -2142175219;
	public const HRESULT OPC_E_INVALID_DEFAULT_EXTENSION = -2142175218;
	public const HRESULT OPC_E_DUPLICATE_DEFAULT_EXTENSION = -2142175217;
	public const HRESULT OPC_E_INVALID_RELATIONSHIP_ID = -2142175216;
	public const HRESULT OPC_E_INVALID_RELATIONSHIP_TYPE = -2142175215;
	public const HRESULT OPC_E_INVALID_RELATIONSHIP_TARGET = -2142175214;
	public const HRESULT OPC_E_DUPLICATE_RELATIONSHIP = -2142175213;
	public const HRESULT OPC_E_CONFLICTING_SETTINGS = -2142175212;
	public const HRESULT OPC_E_DUPLICATE_PIECE = -2142175211;
	public const HRESULT OPC_E_INVALID_PIECE = -2142175210;
	public const HRESULT OPC_E_MISSING_PIECE = -2142175209;
	public const HRESULT OPC_E_NO_SUCH_PART = -2142175208;
	public const HRESULT OPC_E_DS_SIGNATURE_CORRUPT = -2142175207;
	public const HRESULT OPC_E_DS_DIGEST_VALUE_ERROR = -2142175206;
	public const HRESULT OPC_E_DS_DUPLICATE_SIGNATURE_ORIGIN_RELATIONSHIP = -2142175205;
	public const HRESULT OPC_E_DS_INVALID_SIGNATURE_ORIGIN_RELATIONSHIP = -2142175204;
	public const HRESULT OPC_E_DS_INVALID_CERTIFICATE_RELATIONSHIP = -2142175203;
	public const HRESULT OPC_E_DS_EXTERNAL_SIGNATURE = -2142175202;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_ORIGIN_PART = -2142175201;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_PART = -2142175200;
	public const HRESULT OPC_E_DS_INVALID_RELATIONSHIP_TRANSFORM_XML = -2142175199;
	public const HRESULT OPC_E_DS_INVALID_CANONICALIZATION_METHOD = -2142175198;
	public const HRESULT OPC_E_DS_INVALID_RELATIONSHIPS_SIGNING_OPTION = -2142175197;
	public const HRESULT OPC_E_DS_INVALID_OPC_SIGNATURE_TIME_FORMAT = -2142175196;
	public const HRESULT OPC_E_DS_PACKAGE_REFERENCE_URI_RESERVED = -2142175195;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_PROPERTIES_ELEMENT = -2142175194;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_PROPERTY_ELEMENT = -2142175193;
	public const HRESULT OPC_E_DS_DUPLICATE_SIGNATURE_PROPERTY_ELEMENT = -2142175192;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_TIME_PROPERTY = -2142175191;
	public const HRESULT OPC_E_DS_INVALID_SIGNATURE_XML = -2142175190;
	public const HRESULT OPC_E_DS_INVALID_SIGNATURE_COUNT = -2142175189;
	public const HRESULT OPC_E_DS_MISSING_SIGNATURE_ALGORITHM = -2142175188;
	public const HRESULT OPC_E_DS_DUPLICATE_PACKAGE_OBJECT_REFERENCES = -2142175187;
	public const HRESULT OPC_E_DS_MISSING_PACKAGE_OBJECT_REFERENCE = -2142175186;
	public const HRESULT OPC_E_DS_EXTERNAL_SIGNATURE_REFERENCE = -2142175185;
	public const HRESULT OPC_E_DS_REFERENCE_MISSING_CONTENT_TYPE = -2142175184;
	public const HRESULT OPC_E_DS_MULTIPLE_RELATIONSHIP_TRANSFORMS = -2142175183;
	public const HRESULT OPC_E_DS_MISSING_CANONICALIZATION_TRANSFORM = -2142175182;
	public const HRESULT OPC_E_MC_UNEXPECTED_ELEMENT = -2142175181;
	public const HRESULT OPC_E_MC_UNEXPECTED_REQUIRES_ATTR = -2142175180;
	public const HRESULT OPC_E_MC_MISSING_REQUIRES_ATTR = -2142175179;
	public const HRESULT OPC_E_MC_UNEXPECTED_ATTR = -2142175178;
	public const HRESULT OPC_E_MC_INVALID_PREFIX_LIST = -2142175177;
	public const HRESULT OPC_E_MC_INVALID_QNAME_LIST = -2142175176;
	public const HRESULT OPC_E_MC_NESTED_ALTERNATE_CONTENT = -2142175175;
	public const HRESULT OPC_E_MC_UNEXPECTED_CHOICE = -2142175174;
	public const HRESULT OPC_E_MC_MISSING_CHOICE = -2142175173;
	public const HRESULT OPC_E_MC_INVALID_ENUM_TYPE = -2142175172;
	public const HRESULT OPC_E_MC_UNKNOWN_NAMESPACE = -2142175170;
	public const HRESULT OPC_E_MC_UNKNOWN_PREFIX = -2142175169;
	public const HRESULT OPC_E_MC_INVALID_ATTRIBUTES_ON_IGNORABLE_ELEMENT = -2142175168;
	public const HRESULT OPC_E_MC_INVALID_XMLNS_ATTRIBUTE = -2142175167;
	public const HRESULT OPC_E_INVALID_XML_ENCODING = -2142175166;
	public const HRESULT OPC_E_DS_SIGNATURE_REFERENCE_MISSING_URI = -2142175165;
	public const HRESULT OPC_E_INVALID_CONTENT_TYPE = -2142175164;
	public const HRESULT OPC_E_DS_SIGNATURE_PROPERTY_MISSING_TARGET = -2142175163;
	public const HRESULT OPC_E_DS_SIGNATURE_METHOD_NOT_SET = -2142175162;
	public const HRESULT OPC_E_DS_DEFAULT_DIGEST_METHOD_NOT_SET = -2142175161;
	public const HRESULT OPC_E_NO_SUCH_RELATIONSHIP = -2142175160;
	public const HRESULT OPC_E_MC_MULTIPLE_FALLBACK_ELEMENTS = -2142175159;
	public const HRESULT OPC_E_MC_INCONSISTENT_PROCESS_CONTENT = -2142175158;
	public const HRESULT OPC_E_MC_INCONSISTENT_PRESERVE_ATTRIBUTES = -2142175157;
	public const HRESULT OPC_E_MC_INCONSISTENT_PRESERVE_ELEMENTS = -2142175156;
	public const HRESULT OPC_E_INVALID_RELATIONSHIP_TARGET_MODE = -2142175155;
	public const HRESULT OPC_E_COULD_NOT_RECOVER = -2142175154;
	public const HRESULT OPC_E_UNSUPPORTED_PACKAGE = -2142175153;
	public const HRESULT OPC_E_ENUM_COLLECTION_CHANGED = -2142175152;
	public const HRESULT OPC_E_ENUM_CANNOT_MOVE_NEXT = -2142175151;
	public const HRESULT OPC_E_ENUM_CANNOT_MOVE_PREVIOUS = -2142175150;
	public const HRESULT OPC_E_ENUM_INVALID_POSITION = -2142175149;
	public const HRESULT OPC_E_DS_SIGNATURE_ORIGIN_EXISTS = -2142175148;
	public const HRESULT OPC_E_DS_UNSIGNED_PACKAGE = -2142175147;
	public const HRESULT OPC_E_DS_MISSING_CERTIFICATE_PART = -2142175146;
	public const HRESULT OPC_E_NO_SUCH_SETTINGS = -2142175145;
	public const HRESULT OPC_E_ZIP_INCORRECT_DATA_SIZE = -2142171135;
	public const HRESULT OPC_E_ZIP_CORRUPTED_ARCHIVE = -2142171134;
	public const HRESULT OPC_E_ZIP_COMPRESSION_FAILED = -2142171133;
	public const HRESULT OPC_E_ZIP_DECOMPRESSION_FAILED = -2142171132;
	public const HRESULT OPC_E_ZIP_INCONSISTENT_FILEITEM = -2142171131;
	public const HRESULT OPC_E_ZIP_INCONSISTENT_DIRECTORY = -2142171130;
	public const HRESULT OPC_E_ZIP_MISSING_DATA_DESCRIPTOR = -2142171129;
	public const HRESULT OPC_E_ZIP_UNSUPPORTEDARCHIVE = -2142171128;
	public const HRESULT OPC_E_ZIP_CENTRAL_DIRECTORY_TOO_LARGE = -2142171127;
	public const HRESULT OPC_E_ZIP_NAME_TOO_LARGE = -2142171126;
	public const HRESULT OPC_E_ZIP_DUPLICATE_NAME = -2142171125;
	public const HRESULT OPC_E_ZIP_COMMENT_TOO_LARGE = -2142171124;
	public const HRESULT OPC_E_ZIP_EXTRA_FIELDS_TOO_LARGE = -2142171123;
	public const HRESULT OPC_E_ZIP_FILE_HEADER_TOO_LARGE = -2142171122;
	public const HRESULT OPC_E_ZIP_MISSING_END_OF_CENTRAL_DIRECTORY = -2142171121;
	public const HRESULT OPC_E_ZIP_REQUIRES_64_BIT = -2142171120;
}
#endregion

#region Enums

[AllowDuplicates]
public enum OPC_URI_TARGET_MODE : int32
{
	OPC_URI_TARGET_MODE_INTERNAL = 0,
	OPC_URI_TARGET_MODE_EXTERNAL = 1,
}


[AllowDuplicates]
public enum OPC_COMPRESSION_OPTIONS : int32
{
	OPC_COMPRESSION_NONE = -1,
	OPC_COMPRESSION_NORMAL = 0,
	OPC_COMPRESSION_MAXIMUM = 1,
	OPC_COMPRESSION_FAST = 2,
	OPC_COMPRESSION_SUPERFAST = 3,
}


[AllowDuplicates]
public enum OPC_STREAM_IO_MODE : int32
{
	OPC_STREAM_IO_READ = 1,
	OPC_STREAM_IO_WRITE = 2,
}


[AllowDuplicates]
public enum OPC_READ_FLAGS : uint32
{
	OPC_READ_DEFAULT = 0,
	OPC_VALIDATE_ON_LOAD = 1,
	OPC_CACHE_ON_ACCESS = 2,
}


[AllowDuplicates]
public enum OPC_WRITE_FLAGS : uint32
{
	OPC_WRITE_DEFAULT = 0,
	OPC_WRITE_FORCE_ZIP32 = 1,
}


[AllowDuplicates]
public enum OPC_SIGNATURE_VALIDATION_RESULT : int32
{
	OPC_SIGNATURE_VALID = 0,
	OPC_SIGNATURE_INVALID = -1,
}


[AllowDuplicates]
public enum OPC_CANONICALIZATION_METHOD : int32
{
	OPC_CANONICALIZATION_NONE = 0,
	OPC_CANONICALIZATION_C14N = 1,
	OPC_CANONICALIZATION_C14N_WITH_COMMENTS = 2,
}


[AllowDuplicates]
public enum OPC_RELATIONSHIP_SELECTOR : int32
{
	OPC_RELATIONSHIP_SELECT_BY_ID = 0,
	OPC_RELATIONSHIP_SELECT_BY_TYPE = 1,
}


[AllowDuplicates]
public enum OPC_RELATIONSHIPS_SIGNING_OPTION : int32
{
	OPC_RELATIONSHIP_SIGN_USING_SELECTORS = 0,
	OPC_RELATIONSHIP_SIGN_PART = 1,
}


[AllowDuplicates]
public enum OPC_CERTIFICATE_EMBEDDING_OPTION : int32
{
	OPC_CERTIFICATE_IN_CERTIFICATE_PART = 0,
	OPC_CERTIFICATE_IN_SIGNATURE_PART = 1,
	OPC_CERTIFICATE_NOT_EMBEDDED = 2,
}


[AllowDuplicates]
public enum OPC_SIGNATURE_TIME_FORMAT : int32
{
	OPC_SIGNATURE_TIME_FORMAT_MILLISECONDS = 0,
	OPC_SIGNATURE_TIME_FORMAT_SECONDS = 1,
	OPC_SIGNATURE_TIME_FORMAT_MINUTES = 2,
	OPC_SIGNATURE_TIME_FORMAT_DAYS = 3,
	OPC_SIGNATURE_TIME_FORMAT_MONTHS = 4,
	OPC_SIGNATURE_TIME_FORMAT_YEARS = 5,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_OpcFactory = .(0x6b2d6ba0, 0x9f3e, 0x4f27, 0x92, 0x0b, 0x31, 0x3c, 0xc4, 0x26, 0xa3, 0x9e);


}
#endregion

#region COM Types
[CRepr]struct IOpcUri : IUri
{
	public new const Guid IID = .(0xbc9c1b9b, 0xd62c, 0x49eb, 0xae, 0xf0, 0x3b, 0x4e, 0x0b, 0x28, 0xeb, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUri.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** relationshipPartUri) GetRelationshipsPartUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* targetPartUri, IUri** relativeUri) GetRelativeUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri* relativeUri, IOpcPartUri** combinedUri) CombinePartUri;
	}


	public HRESULT GetRelationshipsPartUri(IOpcPartUri** relationshipPartUri) mut => VT.[Friend]GetRelationshipsPartUri(&this, relationshipPartUri);

	public HRESULT GetRelativeUri(IOpcPartUri* targetPartUri, IUri** relativeUri) mut => VT.[Friend]GetRelativeUri(&this, targetPartUri, relativeUri);

	public HRESULT CombinePartUri(IUri* relativeUri, IOpcPartUri** combinedUri) mut => VT.[Friend]CombinePartUri(&this, relativeUri, combinedUri);
}

[CRepr]struct IOpcPartUri : IOpcUri
{
	public new const Guid IID = .(0x7d3babe7, 0x88b2, 0x46ba, 0x85, 0xcb, 0x42, 0x03, 0xcb, 0x01, 0x6c, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOpcUri.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri, int32* comparisonResult) ComparePartUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcUri** sourceUri) GetSourceUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isRelationshipUri) IsRelationshipsPartUri;
	}


	public HRESULT ComparePartUri(IOpcPartUri* partUri, int32* comparisonResult) mut => VT.[Friend]ComparePartUri(&this, partUri, comparisonResult);

	public HRESULT GetSourceUri(IOpcUri** sourceUri) mut => VT.[Friend]GetSourceUri(&this, sourceUri);

	public HRESULT IsRelationshipsPartUri(BOOL* isRelationshipUri) mut => VT.[Friend]IsRelationshipsPartUri(&this, isRelationshipUri);
}

[CRepr]struct IOpcPackage : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartSet** partSet) GetPartSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSet** relationshipSet) GetRelationshipSet;
	}


	public HRESULT GetPartSet(IOpcPartSet** partSet) mut => VT.[Friend]GetPartSet(&this, partSet);

	public HRESULT GetRelationshipSet(IOpcRelationshipSet** relationshipSet) mut => VT.[Friend]GetRelationshipSet(&this, relationshipSet);
}

[CRepr]struct IOpcPart : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSet** relationshipSet) GetRelationshipSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetContentStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentType) GetContentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_COMPRESSION_OPTIONS* compressionOptions) GetCompressionOptions;
	}


	public HRESULT GetRelationshipSet(IOpcRelationshipSet** relationshipSet) mut => VT.[Friend]GetRelationshipSet(&this, relationshipSet);

	public HRESULT GetContentStream(IStream** stream) mut => VT.[Friend]GetContentStream(&this, stream);

	public HRESULT GetName(IOpcPartUri** name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetContentType(PWSTR* contentType) mut => VT.[Friend]GetContentType(&this, contentType);

	public HRESULT GetCompressionOptions(OPC_COMPRESSION_OPTIONS* compressionOptions) mut => VT.[Friend]GetCompressionOptions(&this, compressionOptions);
}

[CRepr]struct IOpcRelationship : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* relationshipIdentifier) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* relationshipType) GetRelationshipType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcUri** sourceUri) GetSourceUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri** targetUri) GetTargetUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_URI_TARGET_MODE* targetMode) GetTargetMode;
	}


	public HRESULT GetId(PWSTR* relationshipIdentifier) mut => VT.[Friend]GetId(&this, relationshipIdentifier);

	public HRESULT GetRelationshipType(PWSTR* relationshipType) mut => VT.[Friend]GetRelationshipType(&this, relationshipType);

	public HRESULT GetSourceUri(IOpcUri** sourceUri) mut => VT.[Friend]GetSourceUri(&this, sourceUri);

	public HRESULT GetTargetUri(IUri** targetUri) mut => VT.[Friend]GetTargetUri(&this, targetUri);

	public HRESULT GetTargetMode(OPC_URI_TARGET_MODE* targetMode) mut => VT.[Friend]GetTargetMode(&this, targetMode);
}

[CRepr]struct IOpcPartSet : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* name, IOpcPart** part) GetPart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* name, PWSTR contentType, OPC_COMPRESSION_OPTIONS compressionOptions, IOpcPart** part) CreatePart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* name) DeletePart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* name, BOOL* partExists) PartExists;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartEnumerator** partEnumerator) GetEnumerator;
	}


	public HRESULT GetPart(IOpcPartUri* name, IOpcPart** part) mut => VT.[Friend]GetPart(&this, name, part);

	public HRESULT CreatePart(IOpcPartUri* name, PWSTR contentType, OPC_COMPRESSION_OPTIONS compressionOptions, IOpcPart** part) mut => VT.[Friend]CreatePart(&this, name, contentType, compressionOptions, part);

	public HRESULT DeletePart(IOpcPartUri* name) mut => VT.[Friend]DeletePart(&this, name);

	public HRESULT PartExists(IOpcPartUri* name, BOOL* partExists) mut => VT.[Friend]PartExists(&this, name, partExists);

	public HRESULT GetEnumerator(IOpcPartEnumerator** partEnumerator) mut => VT.[Friend]GetEnumerator(&this, partEnumerator);
}

[CRepr]struct IOpcRelationshipSet : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR relationshipIdentifier, IOpcRelationship** relationship) GetRelationship;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR relationshipIdentifier, PWSTR relationshipType, IUri* targetUri, OPC_URI_TARGET_MODE targetMode, IOpcRelationship** relationship) CreateRelationship;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR relationshipIdentifier) DeleteRelationship;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR relationshipIdentifier, BOOL* relationshipExists) RelationshipExists;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipEnumerator** relationshipEnumerator) GetEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR relationshipType, IOpcRelationshipEnumerator** relationshipEnumerator) GetEnumeratorForType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** contents) GetRelationshipsContentStream;
	}


	public HRESULT GetRelationship(PWSTR relationshipIdentifier, IOpcRelationship** relationship) mut => VT.[Friend]GetRelationship(&this, relationshipIdentifier, relationship);

	public HRESULT CreateRelationship(PWSTR relationshipIdentifier, PWSTR relationshipType, IUri* targetUri, OPC_URI_TARGET_MODE targetMode, IOpcRelationship** relationship) mut => VT.[Friend]CreateRelationship(&this, relationshipIdentifier, relationshipType, targetUri, targetMode, relationship);

	public HRESULT DeleteRelationship(PWSTR relationshipIdentifier) mut => VT.[Friend]DeleteRelationship(&this, relationshipIdentifier);

	public HRESULT RelationshipExists(PWSTR relationshipIdentifier, BOOL* relationshipExists) mut => VT.[Friend]RelationshipExists(&this, relationshipIdentifier, relationshipExists);

	public HRESULT GetEnumerator(IOpcRelationshipEnumerator** relationshipEnumerator) mut => VT.[Friend]GetEnumerator(&this, relationshipEnumerator);

	public HRESULT GetEnumeratorForType(PWSTR relationshipType, IOpcRelationshipEnumerator** relationshipEnumerator) mut => VT.[Friend]GetEnumeratorForType(&this, relationshipType, relationshipEnumerator);

	public HRESULT GetRelationshipsContentStream(IStream** contents) mut => VT.[Friend]GetRelationshipsContentStream(&this, contents);
}

[CRepr]struct IOpcPartEnumerator : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPart** part) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcPart** part) mut => VT.[Friend]GetCurrent(&this, part);

	public HRESULT Clone(IOpcPartEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcRelationshipEnumerator : IUnknown
{
	public new const Guid IID = .(0x42195949, 0x3b79, 0x4fc8, 0x89, 0xc6, 0xfc, 0x7f, 0xb9, 0x79, 0xee, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationship** relationship) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcRelationship** relationship) mut => VT.[Friend]GetCurrent(&this, relationship);

	public HRESULT Clone(IOpcRelationshipEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcSignaturePartReference : IUnknown
{
	public new const Guid IID = .(0xe24231ca, 0x59f4, 0x484e, 0xb6, 0x4b, 0x36, 0xee, 0xda, 0x36, 0x07, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** partName) GetPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentType) GetContentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* digestMethod) GetDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** digestValue, uint32* count) GetDigestValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CANONICALIZATION_METHOD* transformMethod) GetTransformMethod;
	}


	public HRESULT GetPartName(IOpcPartUri** partName) mut => VT.[Friend]GetPartName(&this, partName);

	public HRESULT GetContentType(PWSTR* contentType) mut => VT.[Friend]GetContentType(&this, contentType);

	public HRESULT GetDigestMethod(PWSTR* digestMethod) mut => VT.[Friend]GetDigestMethod(&this, digestMethod);

	public HRESULT GetDigestValue(uint8** digestValue, uint32* count) mut => VT.[Friend]GetDigestValue(&this, digestValue, count);

	public HRESULT GetTransformMethod(OPC_CANONICALIZATION_METHOD* transformMethod) mut => VT.[Friend]GetTransformMethod(&this, transformMethod);
}

[CRepr]struct IOpcSignatureRelationshipReference : IUnknown
{
	public new const Guid IID = .(0x57babac6, 0x9d4a, 0x4e50, 0x8b, 0x86, 0xe5, 0xd4, 0x05, 0x1e, 0xae, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcUri** sourceUri) GetSourceUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* digestMethod) GetDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** digestValue, uint32* count) GetDigestValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CANONICALIZATION_METHOD* transformMethod) GetTransformMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_RELATIONSHIPS_SIGNING_OPTION* relationshipSigningOption) GetRelationshipSigningOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelectorEnumerator** selectorEnumerator) GetRelationshipSelectorEnumerator;
	}


	public HRESULT GetSourceUri(IOpcUri** sourceUri) mut => VT.[Friend]GetSourceUri(&this, sourceUri);

	public HRESULT GetDigestMethod(PWSTR* digestMethod) mut => VT.[Friend]GetDigestMethod(&this, digestMethod);

	public HRESULT GetDigestValue(uint8** digestValue, uint32* count) mut => VT.[Friend]GetDigestValue(&this, digestValue, count);

	public HRESULT GetTransformMethod(OPC_CANONICALIZATION_METHOD* transformMethod) mut => VT.[Friend]GetTransformMethod(&this, transformMethod);

	public HRESULT GetRelationshipSigningOption(OPC_RELATIONSHIPS_SIGNING_OPTION* relationshipSigningOption) mut => VT.[Friend]GetRelationshipSigningOption(&this, relationshipSigningOption);

	public HRESULT GetRelationshipSelectorEnumerator(IOpcRelationshipSelectorEnumerator** selectorEnumerator) mut => VT.[Friend]GetRelationshipSelectorEnumerator(&this, selectorEnumerator);
}

[CRepr]struct IOpcRelationshipSelector : IUnknown
{
	public new const Guid IID = .(0xf8f26c7f, 0xb28f, 0x4899, 0x84, 0xc8, 0x5d, 0x56, 0x39, 0xed, 0xe7, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_RELATIONSHIP_SELECTOR* selector) GetSelectorType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* selectionCriterion) GetSelectionCriterion;
	}


	public HRESULT GetSelectorType(OPC_RELATIONSHIP_SELECTOR* selector) mut => VT.[Friend]GetSelectorType(&this, selector);

	public HRESULT GetSelectionCriterion(PWSTR* selectionCriterion) mut => VT.[Friend]GetSelectionCriterion(&this, selectionCriterion);
}

[CRepr]struct IOpcSignatureReference : IUnknown
{
	public new const Guid IID = .(0x1b47005e, 0x3011, 0x4edc, 0xbe, 0x6f, 0x0f, 0x65, 0xe5, 0xab, 0x03, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* referenceId) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri** referenceUri) GetUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* type) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CANONICALIZATION_METHOD* transformMethod) GetTransformMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* digestMethod) GetDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** digestValue, uint32* count) GetDigestValue;
	}


	public HRESULT GetId(PWSTR* referenceId) mut => VT.[Friend]GetId(&this, referenceId);

	public HRESULT GetUri(IUri** referenceUri) mut => VT.[Friend]GetUri(&this, referenceUri);

	public HRESULT GetType(PWSTR* type) mut => VT.[Friend]COM_GetType(&this, type);

	public HRESULT GetTransformMethod(OPC_CANONICALIZATION_METHOD* transformMethod) mut => VT.[Friend]GetTransformMethod(&this, transformMethod);

	public HRESULT GetDigestMethod(PWSTR* digestMethod) mut => VT.[Friend]GetDigestMethod(&this, digestMethod);

	public HRESULT GetDigestValue(uint8** digestValue, uint32* count) mut => VT.[Friend]GetDigestValue(&this, digestValue, count);
}

[CRepr]struct IOpcSignatureCustomObject : IUnknown
{
	public new const Guid IID = .(0x5d77a19e, 0x62c1, 0x44e7, 0xbe, 0xcd, 0x45, 0xda, 0x5a, 0xe5, 0x1a, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** xmlMarkup, uint32* count) GetXml;
	}


	public HRESULT GetXml(uint8** xmlMarkup, uint32* count) mut => VT.[Friend]GetXml(&this, xmlMarkup, count);
}

[CRepr]struct IOpcDigitalSignature : IUnknown
{
	public new const Guid IID = .(0x52ab21dd, 0x1cd0, 0x4949, 0xbc, 0x80, 0x0c, 0x12, 0x32, 0xd0, 0x0c, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR** prefixes, PWSTR** namespaces, uint32* count) GetNamespaces;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureId) GetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signaturePartName) GetSignaturePartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureMethod) GetSignatureMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CANONICALIZATION_METHOD* canonicalizationMethod) GetCanonicalizationMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** signatureValue, uint32* count) GetSignatureValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReferenceEnumerator** partReferenceEnumerator) GetSignaturePartReferenceEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReferenceEnumerator** relationshipReferenceEnumerator) GetSignatureRelationshipReferenceEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signingTime) GetSigningTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT* timeFormat) GetTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReference** packageObjectReference) GetPackageObjectReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateEnumerator** certificateEnumerator) GetCertificateEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceEnumerator** customReferenceEnumerator) GetCustomReferenceEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) GetCustomObjectEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** signatureXml, uint32* count) GetSignatureXml;
	}


	public HRESULT GetNamespaces(PWSTR** prefixes, PWSTR** namespaces, uint32* count) mut => VT.[Friend]GetNamespaces(&this, prefixes, namespaces, count);

	public HRESULT GetSignatureId(PWSTR* signatureId) mut => VT.[Friend]GetSignatureId(&this, signatureId);

	public HRESULT GetSignaturePartName(IOpcPartUri** signaturePartName) mut => VT.[Friend]GetSignaturePartName(&this, signaturePartName);

	public HRESULT GetSignatureMethod(PWSTR* signatureMethod) mut => VT.[Friend]GetSignatureMethod(&this, signatureMethod);

	public HRESULT GetCanonicalizationMethod(OPC_CANONICALIZATION_METHOD* canonicalizationMethod) mut => VT.[Friend]GetCanonicalizationMethod(&this, canonicalizationMethod);

	public HRESULT GetSignatureValue(uint8** signatureValue, uint32* count) mut => VT.[Friend]GetSignatureValue(&this, signatureValue, count);

	public HRESULT GetSignaturePartReferenceEnumerator(IOpcSignaturePartReferenceEnumerator** partReferenceEnumerator) mut => VT.[Friend]GetSignaturePartReferenceEnumerator(&this, partReferenceEnumerator);

	public HRESULT GetSignatureRelationshipReferenceEnumerator(IOpcSignatureRelationshipReferenceEnumerator** relationshipReferenceEnumerator) mut => VT.[Friend]GetSignatureRelationshipReferenceEnumerator(&this, relationshipReferenceEnumerator);

	public HRESULT GetSigningTime(PWSTR* signingTime) mut => VT.[Friend]GetSigningTime(&this, signingTime);

	public HRESULT GetTimeFormat(OPC_SIGNATURE_TIME_FORMAT* timeFormat) mut => VT.[Friend]GetTimeFormat(&this, timeFormat);

	public HRESULT GetPackageObjectReference(IOpcSignatureReference** packageObjectReference) mut => VT.[Friend]GetPackageObjectReference(&this, packageObjectReference);

	public HRESULT GetCertificateEnumerator(IOpcCertificateEnumerator** certificateEnumerator) mut => VT.[Friend]GetCertificateEnumerator(&this, certificateEnumerator);

	public HRESULT GetCustomReferenceEnumerator(IOpcSignatureReferenceEnumerator** customReferenceEnumerator) mut => VT.[Friend]GetCustomReferenceEnumerator(&this, customReferenceEnumerator);

	public HRESULT GetCustomObjectEnumerator(IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) mut => VT.[Friend]GetCustomObjectEnumerator(&this, customObjectEnumerator);

	public HRESULT GetSignatureXml(uint8** signatureXml, uint32* count) mut => VT.[Friend]GetSignatureXml(&this, signatureXml, count);
}

[CRepr]struct IOpcSigningOptions : IUnknown
{
	public new const Guid IID = .(0x50d2d6a5, 0x7aeb, 0x46c0, 0xb2, 0x41, 0x43, 0xab, 0x0e, 0x9b, 0x40, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureId) GetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR signatureId) SetSignatureId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* signatureMethod) GetSignatureMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR signatureMethod) SetSignatureMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* digestMethod) GetDefaultDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR digestMethod) SetDefaultDigestMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CERTIFICATE_EMBEDDING_OPTION* embeddingOption) GetCertificateEmbeddingOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_CERTIFICATE_EMBEDDING_OPTION embeddingOption) SetCertificateEmbeddingOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT* timeFormat) GetTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_SIGNATURE_TIME_FORMAT timeFormat) SetTimeFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReferenceSet** partReferenceSet) GetSignaturePartReferenceSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReferenceSet** relationshipReferenceSet) GetSignatureRelationshipReferenceSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectSet** customObjectSet) GetCustomObjectSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceSet** customReferenceSet) GetCustomReferenceSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateSet** certificateSet) GetCertificateSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signaturePartName) GetSignaturePartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signaturePartName) SetSignaturePartName;
	}


	public HRESULT GetSignatureId(PWSTR* signatureId) mut => VT.[Friend]GetSignatureId(&this, signatureId);

	public HRESULT SetSignatureId(PWSTR signatureId) mut => VT.[Friend]SetSignatureId(&this, signatureId);

	public HRESULT GetSignatureMethod(PWSTR* signatureMethod) mut => VT.[Friend]GetSignatureMethod(&this, signatureMethod);

	public HRESULT SetSignatureMethod(PWSTR signatureMethod) mut => VT.[Friend]SetSignatureMethod(&this, signatureMethod);

	public HRESULT GetDefaultDigestMethod(PWSTR* digestMethod) mut => VT.[Friend]GetDefaultDigestMethod(&this, digestMethod);

	public HRESULT SetDefaultDigestMethod(PWSTR digestMethod) mut => VT.[Friend]SetDefaultDigestMethod(&this, digestMethod);

	public HRESULT GetCertificateEmbeddingOption(OPC_CERTIFICATE_EMBEDDING_OPTION* embeddingOption) mut => VT.[Friend]GetCertificateEmbeddingOption(&this, embeddingOption);

	public HRESULT SetCertificateEmbeddingOption(OPC_CERTIFICATE_EMBEDDING_OPTION embeddingOption) mut => VT.[Friend]SetCertificateEmbeddingOption(&this, embeddingOption);

	public HRESULT GetTimeFormat(OPC_SIGNATURE_TIME_FORMAT* timeFormat) mut => VT.[Friend]GetTimeFormat(&this, timeFormat);

	public HRESULT SetTimeFormat(OPC_SIGNATURE_TIME_FORMAT timeFormat) mut => VT.[Friend]SetTimeFormat(&this, timeFormat);

	public HRESULT GetSignaturePartReferenceSet(IOpcSignaturePartReferenceSet** partReferenceSet) mut => VT.[Friend]GetSignaturePartReferenceSet(&this, partReferenceSet);

	public HRESULT GetSignatureRelationshipReferenceSet(IOpcSignatureRelationshipReferenceSet** relationshipReferenceSet) mut => VT.[Friend]GetSignatureRelationshipReferenceSet(&this, relationshipReferenceSet);

	public HRESULT GetCustomObjectSet(IOpcSignatureCustomObjectSet** customObjectSet) mut => VT.[Friend]GetCustomObjectSet(&this, customObjectSet);

	public HRESULT GetCustomReferenceSet(IOpcSignatureReferenceSet** customReferenceSet) mut => VT.[Friend]GetCustomReferenceSet(&this, customReferenceSet);

	public HRESULT GetCertificateSet(IOpcCertificateSet** certificateSet) mut => VT.[Friend]GetCertificateSet(&this, certificateSet);

	public HRESULT GetSignaturePartName(IOpcPartUri** signaturePartName) mut => VT.[Friend]GetSignaturePartName(&this, signaturePartName);

	public HRESULT SetSignaturePartName(IOpcPartUri* signaturePartName) mut => VT.[Friend]SetSignaturePartName(&this, signaturePartName);
}

[CRepr]struct IOpcDigitalSignatureManager : IUnknown
{
	public new const Guid IID = .(0xd5e62a0b, 0x696d, 0x462f, 0x94, 0xdf, 0x72, 0xe3, 0x3c, 0xef, 0x26, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri** signatureOriginPartName) GetSignatureOriginPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signatureOriginPartName) SetSignatureOriginPartName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcDigitalSignatureEnumerator** signatureEnumerator) GetSignatureEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signaturePartName) RemoveSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSigningOptions** signingOptions) CreateSigningOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcDigitalSignature* signature, CERT_CONTEXT* certificate, OPC_SIGNATURE_VALIDATION_RESULT* validationResult) Validate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* certificate, IOpcSigningOptions* signingOptions, IOpcDigitalSignature** digitalSignature) Sign;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* signaturePartName, uint8* newSignatureXml, uint32 count, IOpcDigitalSignature** digitalSignature) ReplaceSignatureXml;
	}


	public HRESULT GetSignatureOriginPartName(IOpcPartUri** signatureOriginPartName) mut => VT.[Friend]GetSignatureOriginPartName(&this, signatureOriginPartName);

	public HRESULT SetSignatureOriginPartName(IOpcPartUri* signatureOriginPartName) mut => VT.[Friend]SetSignatureOriginPartName(&this, signatureOriginPartName);

	public HRESULT GetSignatureEnumerator(IOpcDigitalSignatureEnumerator** signatureEnumerator) mut => VT.[Friend]GetSignatureEnumerator(&this, signatureEnumerator);

	public HRESULT RemoveSignature(IOpcPartUri* signaturePartName) mut => VT.[Friend]RemoveSignature(&this, signaturePartName);

	public HRESULT CreateSigningOptions(IOpcSigningOptions** signingOptions) mut => VT.[Friend]CreateSigningOptions(&this, signingOptions);

	public HRESULT Validate(IOpcDigitalSignature* signature, CERT_CONTEXT* certificate, OPC_SIGNATURE_VALIDATION_RESULT* validationResult) mut => VT.[Friend]Validate(&this, signature, certificate, validationResult);

	public HRESULT Sign(CERT_CONTEXT* certificate, IOpcSigningOptions* signingOptions, IOpcDigitalSignature** digitalSignature) mut => VT.[Friend]Sign(&this, certificate, signingOptions, digitalSignature);

	public HRESULT ReplaceSignatureXml(IOpcPartUri* signaturePartName, uint8* newSignatureXml, uint32 count, IOpcDigitalSignature** digitalSignature) mut => VT.[Friend]ReplaceSignatureXml(&this, signaturePartName, newSignatureXml, count, digitalSignature);
}

[CRepr]struct IOpcSignaturePartReferenceEnumerator : IUnknown
{
	public new const Guid IID = .(0x80eb1561, 0x8c77, 0x49cf, 0x82, 0x66, 0x45, 0x9b, 0x35, 0x6e, 0xe9, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReference** partReference) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReferenceEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcSignaturePartReference** partReference) mut => VT.[Friend]GetCurrent(&this, partReference);

	public HRESULT Clone(IOpcSignaturePartReferenceEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcSignatureRelationshipReferenceEnumerator : IUnknown
{
	public new const Guid IID = .(0x773ba3e4, 0xf021, 0x48e4, 0xaa, 0x04, 0x98, 0x16, 0xdb, 0x5d, 0x34, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReference** relationshipReference) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReferenceEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcSignatureRelationshipReference** relationshipReference) mut => VT.[Friend]GetCurrent(&this, relationshipReference);

	public HRESULT Clone(IOpcSignatureRelationshipReferenceEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcRelationshipSelectorEnumerator : IUnknown
{
	public new const Guid IID = .(0x5e50a181, 0xa91b, 0x48ac, 0x88, 0xd2, 0xbc, 0xa3, 0xd8, 0xf8, 0xc0, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelector** relationshipSelector) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelectorEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcRelationshipSelector** relationshipSelector) mut => VT.[Friend]GetCurrent(&this, relationshipSelector);

	public HRESULT Clone(IOpcRelationshipSelectorEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcSignatureReferenceEnumerator : IUnknown
{
	public new const Guid IID = .(0xcfa59a45, 0x28b1, 0x4868, 0x96, 0x9e, 0xfa, 0x80, 0x97, 0xfd, 0xc1, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReference** reference) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcSignatureReference** reference) mut => VT.[Friend]GetCurrent(&this, reference);

	public HRESULT Clone(IOpcSignatureReferenceEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcSignatureCustomObjectEnumerator : IUnknown
{
	public new const Guid IID = .(0x5ee4fe1d, 0xe1b0, 0x4683, 0x80, 0x79, 0x7e, 0xa0, 0xfc, 0xf8, 0x0b, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObject** customObject) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcSignatureCustomObject** customObject) mut => VT.[Friend]GetCurrent(&this, customObject);

	public HRESULT Clone(IOpcSignatureCustomObjectEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcCertificateEnumerator : IUnknown
{
	public new const Guid IID = .(0x85131937, 0x8f24, 0x421f, 0xb4, 0x39, 0x59, 0xab, 0x24, 0xd1, 0x40, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT** certificate) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(CERT_CONTEXT** certificate) mut => VT.[Friend]GetCurrent(&this, certificate);

	public HRESULT Clone(IOpcCertificateEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcDigitalSignatureEnumerator : IUnknown
{
	public new const Guid IID = .(0x967b6882, 0x0ba3, 0x4358, 0xb9, 0xe7, 0xb6, 0x4c, 0x75, 0x06, 0x3c, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasPrevious) MovePrevious;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcDigitalSignature** digitalSignature) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcDigitalSignatureEnumerator** copy) Clone;
	}


	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);

	public HRESULT MovePrevious(BOOL* hasPrevious) mut => VT.[Friend]MovePrevious(&this, hasPrevious);

	public HRESULT GetCurrent(IOpcDigitalSignature** digitalSignature) mut => VT.[Friend]GetCurrent(&this, digitalSignature);

	public HRESULT Clone(IOpcDigitalSignatureEnumerator** copy) mut => VT.[Friend]Clone(&this, copy);
}

[CRepr]struct IOpcSignaturePartReferenceSet : IUnknown
{
	public new const Guid IID = .(0x6c9fe28c, 0xecd9, 0x4b22, 0x9d, 0x36, 0x7f, 0xdd, 0xe6, 0x70, 0xfe, 0xc0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPartUri* partUri, PWSTR digestMethod, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignaturePartReference** partReference) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReference* partReference) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignaturePartReferenceEnumerator** partReferenceEnumerator) GetEnumerator;
	}


	public HRESULT Create(IOpcPartUri* partUri, PWSTR digestMethod, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignaturePartReference** partReference) mut => VT.[Friend]Create(&this, partUri, digestMethod, transformMethod, partReference);

	public HRESULT Delete(IOpcSignaturePartReference* partReference) mut => VT.[Friend]Delete(&this, partReference);

	public HRESULT GetEnumerator(IOpcSignaturePartReferenceEnumerator** partReferenceEnumerator) mut => VT.[Friend]GetEnumerator(&this, partReferenceEnumerator);
}

[CRepr]struct IOpcSignatureRelationshipReferenceSet : IUnknown
{
	public new const Guid IID = .(0x9f863ca5, 0x3631, 0x404c, 0x82, 0x8d, 0x80, 0x7e, 0x07, 0x15, 0x06, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcUri* sourceUri, PWSTR digestMethod, OPC_RELATIONSHIPS_SIGNING_OPTION relationshipSigningOption, IOpcRelationshipSelectorSet* selectorSet, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignatureRelationshipReference** relationshipReference) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelectorSet** selectorSet) CreateRelationshipSelectorSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReference* relationshipReference) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureRelationshipReferenceEnumerator** relationshipReferenceEnumerator) GetEnumerator;
	}


	public HRESULT Create(IOpcUri* sourceUri, PWSTR digestMethod, OPC_RELATIONSHIPS_SIGNING_OPTION relationshipSigningOption, IOpcRelationshipSelectorSet* selectorSet, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignatureRelationshipReference** relationshipReference) mut => VT.[Friend]Create(&this, sourceUri, digestMethod, relationshipSigningOption, selectorSet, transformMethod, relationshipReference);

	public HRESULT CreateRelationshipSelectorSet(IOpcRelationshipSelectorSet** selectorSet) mut => VT.[Friend]CreateRelationshipSelectorSet(&this, selectorSet);

	public HRESULT Delete(IOpcSignatureRelationshipReference* relationshipReference) mut => VT.[Friend]Delete(&this, relationshipReference);

	public HRESULT GetEnumerator(IOpcSignatureRelationshipReferenceEnumerator** relationshipReferenceEnumerator) mut => VT.[Friend]GetEnumerator(&this, relationshipReferenceEnumerator);
}

[CRepr]struct IOpcRelationshipSelectorSet : IUnknown
{
	public new const Guid IID = .(0x6e34c269, 0xa4d3, 0x47c0, 0xb5, 0xc4, 0x87, 0xff, 0x2b, 0x3b, 0x61, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OPC_RELATIONSHIP_SELECTOR selector, PWSTR selectionCriterion, IOpcRelationshipSelector** relationshipSelector) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelector* relationshipSelector) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcRelationshipSelectorEnumerator** relationshipSelectorEnumerator) GetEnumerator;
	}


	public HRESULT Create(OPC_RELATIONSHIP_SELECTOR selector, PWSTR selectionCriterion, IOpcRelationshipSelector** relationshipSelector) mut => VT.[Friend]Create(&this, selector, selectionCriterion, relationshipSelector);

	public HRESULT Delete(IOpcRelationshipSelector* relationshipSelector) mut => VT.[Friend]Delete(&this, relationshipSelector);

	public HRESULT GetEnumerator(IOpcRelationshipSelectorEnumerator** relationshipSelectorEnumerator) mut => VT.[Friend]GetEnumerator(&this, relationshipSelectorEnumerator);
}

[CRepr]struct IOpcSignatureReferenceSet : IUnknown
{
	public new const Guid IID = .(0xf3b02d31, 0xab12, 0x42dd, 0x9e, 0x2f, 0x2b, 0x16, 0x76, 0x1c, 0x3c, 0x1e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri* referenceUri, PWSTR referenceId, PWSTR type, PWSTR digestMethod, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignatureReference** reference) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReference* reference) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureReferenceEnumerator** referenceEnumerator) GetEnumerator;
	}


	public HRESULT Create(IUri* referenceUri, PWSTR referenceId, PWSTR type, PWSTR digestMethod, OPC_CANONICALIZATION_METHOD transformMethod, IOpcSignatureReference** reference) mut => VT.[Friend]Create(&this, referenceUri, referenceId, type, digestMethod, transformMethod, reference);

	public HRESULT Delete(IOpcSignatureReference* reference) mut => VT.[Friend]Delete(&this, reference);

	public HRESULT GetEnumerator(IOpcSignatureReferenceEnumerator** referenceEnumerator) mut => VT.[Friend]GetEnumerator(&this, referenceEnumerator);
}

[CRepr]struct IOpcSignatureCustomObjectSet : IUnknown
{
	public new const Guid IID = .(0x8f792ac5, 0x7947, 0x4e11, 0xbc, 0x3d, 0x26, 0x59, 0xff, 0x04, 0x6a, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* xmlMarkup, uint32 count, IOpcSignatureCustomObject** customObject) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObject* customObject) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) GetEnumerator;
	}


	public HRESULT Create(uint8* xmlMarkup, uint32 count, IOpcSignatureCustomObject** customObject) mut => VT.[Friend]Create(&this, xmlMarkup, count, customObject);

	public HRESULT Delete(IOpcSignatureCustomObject* customObject) mut => VT.[Friend]Delete(&this, customObject);

	public HRESULT GetEnumerator(IOpcSignatureCustomObjectEnumerator** customObjectEnumerator) mut => VT.[Friend]GetEnumerator(&this, customObjectEnumerator);
}

[CRepr]struct IOpcCertificateSet : IUnknown
{
	public new const Guid IID = .(0x56ea4325, 0x8e2d, 0x4167, 0xb1, 0xa4, 0xe4, 0x86, 0xd2, 0x4c, 0x8f, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* certificate) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CERT_CONTEXT* certificate) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcCertificateEnumerator** certificateEnumerator) GetEnumerator;
	}


	public HRESULT Add(CERT_CONTEXT* certificate) mut => VT.[Friend]Add(&this, certificate);

	public HRESULT Remove(CERT_CONTEXT* certificate) mut => VT.[Friend]Remove(&this, certificate);

	public HRESULT GetEnumerator(IOpcCertificateEnumerator** certificateEnumerator) mut => VT.[Friend]GetEnumerator(&this, certificateEnumerator);
}

[CRepr]struct IOpcFactory : IUnknown
{
	public new const Guid IID = .(0x6d0b4446, 0xcd73, 0x4ab3, 0x94, 0xf4, 0x8c, 0xcd, 0xf6, 0x11, 0x61, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcUri** rootUri) CreatePackageRootUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzUri, IOpcPartUri** partUri) CreatePartUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, OPC_STREAM_IO_MODE ioMode, SECURITY_ATTRIBUTES* securityAttributes, uint32 dwFlagsAndAttributes, IStream** stream) CreateStreamOnFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPackage** package) CreatePackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream, OPC_READ_FLAGS flags, IOpcPackage** package) ReadPackageFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPackage* package, OPC_WRITE_FLAGS flags, IStream* stream) WritePackageToStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOpcPackage* package, IOpcDigitalSignatureManager** signatureManager) CreateDigitalSignatureManager;
	}


	public HRESULT CreatePackageRootUri(IOpcUri** rootUri) mut => VT.[Friend]CreatePackageRootUri(&this, rootUri);

	public HRESULT CreatePartUri(PWSTR pwzUri, IOpcPartUri** partUri) mut => VT.[Friend]CreatePartUri(&this, pwzUri, partUri);

	public HRESULT CreateStreamOnFile(PWSTR filename, OPC_STREAM_IO_MODE ioMode, SECURITY_ATTRIBUTES* securityAttributes, uint32 dwFlagsAndAttributes, IStream** stream) mut => VT.[Friend]CreateStreamOnFile(&this, filename, ioMode, securityAttributes, dwFlagsAndAttributes, stream);

	public HRESULT CreatePackage(IOpcPackage** package) mut => VT.[Friend]CreatePackage(&this, package);

	public HRESULT ReadPackageFromStream(IStream* stream, OPC_READ_FLAGS flags, IOpcPackage** package) mut => VT.[Friend]ReadPackageFromStream(&this, stream, flags, package);

	public HRESULT WritePackageToStream(IOpcPackage* package, OPC_WRITE_FLAGS flags, IStream* stream) mut => VT.[Friend]WritePackageToStream(&this, package, flags, stream);

	public HRESULT CreateDigitalSignatureManager(IOpcPackage* package, IOpcDigitalSignatureManager** signatureManager) mut => VT.[Friend]CreateDigitalSignatureManager(&this, package, signatureManager);
}

#endregion
