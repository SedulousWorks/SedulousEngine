using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.Storage.Packaging.Appx;

#region Constants
public static
{
	public const uint32 PACKAGE_PROPERTY_FRAMEWORK = 1;
	public const uint32 PACKAGE_PROPERTY_RESOURCE = 2;
	public const uint32 PACKAGE_PROPERTY_BUNDLE = 4;
	public const uint32 PACKAGE_PROPERTY_OPTIONAL = 8;
	public const uint32 PACKAGE_FILTER_HEAD = 16;
	public const uint32 PACKAGE_FILTER_DIRECT = 32;
	public const uint32 PACKAGE_FILTER_RESOURCE = 64;
	public const uint32 PACKAGE_FILTER_BUNDLE = 128;
	public const uint32 PACKAGE_INFORMATION_BASIC = 0;
	public const uint32 PACKAGE_INFORMATION_FULL = 256;
	public const uint32 PACKAGE_PROPERTY_DEVELOPMENT_MODE = 65536;
	public const uint32 PACKAGE_FILTER_OPTIONAL = 131072;
	public const uint32 PACKAGE_PROPERTY_IS_IN_RELATED_SET = 262144;
	public const uint32 PACKAGE_FILTER_IS_IN_RELATED_SET = 262144;
	public const uint32 PACKAGE_PROPERTY_STATIC = 524288;
	public const uint32 PACKAGE_FILTER_STATIC = 524288;
	public const uint32 PACKAGE_PROPERTY_DYNAMIC = 1048576;
	public const uint32 PACKAGE_FILTER_DYNAMIC = 1048576;
	public const uint32 PACKAGE_PROPERTY_HOSTRUNTIME = 2097152;
	public const uint32 PACKAGE_FILTER_HOSTRUNTIME = 2097152;
	public const uint32 PACKAGE_FILTER_ALL_LOADED = 0;
	public const uint32 PACKAGE_DEPENDENCY_RANK_DEFAULT = 0;
}
#endregion

#region Enums

[AllowDuplicates]
public enum APPX_COMPRESSION_OPTION : int32
{
	APPX_COMPRESSION_OPTION_NONE = 0,
	APPX_COMPRESSION_OPTION_NORMAL = 1,
	APPX_COMPRESSION_OPTION_MAXIMUM = 2,
	APPX_COMPRESSION_OPTION_FAST = 3,
	APPX_COMPRESSION_OPTION_SUPERFAST = 4,
}


[AllowDuplicates]
public enum APPX_FOOTPRINT_FILE_TYPE : int32
{
	APPX_FOOTPRINT_FILE_TYPE_MANIFEST = 0,
	APPX_FOOTPRINT_FILE_TYPE_BLOCKMAP = 1,
	APPX_FOOTPRINT_FILE_TYPE_SIGNATURE = 2,
	APPX_FOOTPRINT_FILE_TYPE_CODEINTEGRITY = 3,
	APPX_FOOTPRINT_FILE_TYPE_CONTENTGROUPMAP = 4,
}


[AllowDuplicates]
public enum APPX_BUNDLE_FOOTPRINT_FILE_TYPE : int32
{
	APPX_BUNDLE_FOOTPRINT_FILE_TYPE_FIRST = 0,
	APPX_BUNDLE_FOOTPRINT_FILE_TYPE_MANIFEST = 0,
	APPX_BUNDLE_FOOTPRINT_FILE_TYPE_BLOCKMAP = 1,
	APPX_BUNDLE_FOOTPRINT_FILE_TYPE_SIGNATURE = 2,
	APPX_BUNDLE_FOOTPRINT_FILE_TYPE_LAST = 2,
}


[AllowDuplicates]
public enum APPX_CAPABILITIES : uint32
{
	APPX_CAPABILITY_INTERNET_CLIENT = 1,
	APPX_CAPABILITY_INTERNET_CLIENT_SERVER = 2,
	APPX_CAPABILITY_PRIVATE_NETWORK_CLIENT_SERVER = 4,
	APPX_CAPABILITY_DOCUMENTS_LIBRARY = 8,
	APPX_CAPABILITY_PICTURES_LIBRARY = 16,
	APPX_CAPABILITY_VIDEOS_LIBRARY = 32,
	APPX_CAPABILITY_MUSIC_LIBRARY = 64,
	APPX_CAPABILITY_ENTERPRISE_AUTHENTICATION = 128,
	APPX_CAPABILITY_SHARED_USER_CERTIFICATES = 256,
	APPX_CAPABILITY_REMOVABLE_STORAGE = 512,
	APPX_CAPABILITY_APPOINTMENTS = 1024,
	APPX_CAPABILITY_CONTACTS = 2048,
}


[AllowDuplicates]
public enum APPX_PACKAGE_ARCHITECTURE : int32
{
	APPX_PACKAGE_ARCHITECTURE_X86 = 0,
	APPX_PACKAGE_ARCHITECTURE_ARM = 5,
	APPX_PACKAGE_ARCHITECTURE_X64 = 9,
	APPX_PACKAGE_ARCHITECTURE_NEUTRAL = 11,
	APPX_PACKAGE_ARCHITECTURE_ARM64 = 12,
}


[AllowDuplicates]
public enum APPX_PACKAGE_ARCHITECTURE2 : int32
{
	APPX_PACKAGE_ARCHITECTURE2_X86 = 0,
	APPX_PACKAGE_ARCHITECTURE2_ARM = 5,
	APPX_PACKAGE_ARCHITECTURE2_X64 = 9,
	APPX_PACKAGE_ARCHITECTURE2_NEUTRAL = 11,
	APPX_PACKAGE_ARCHITECTURE2_ARM64 = 12,
	APPX_PACKAGE_ARCHITECTURE2_X86_ON_ARM64 = 14,
	APPX_PACKAGE_ARCHITECTURE2_UNKNOWN = 65535,
}


[AllowDuplicates]
public enum APPX_BUNDLE_PAYLOAD_PACKAGE_TYPE : int32
{
	APPX_BUNDLE_PAYLOAD_PACKAGE_TYPE_APPLICATION = 0,
	APPX_BUNDLE_PAYLOAD_PACKAGE_TYPE_RESOURCE = 1,
}


[AllowDuplicates]
public enum DX_FEATURE_LEVEL : int32
{
	DX_FEATURE_LEVEL_UNSPECIFIED = 0,
	DX_FEATURE_LEVEL_9 = 1,
	DX_FEATURE_LEVEL_10 = 2,
	DX_FEATURE_LEVEL_11 = 3,
}


[AllowDuplicates]
public enum APPX_CAPABILITY_CLASS_TYPE : int32
{
	APPX_CAPABILITY_CLASS_DEFAULT = 0,
	APPX_CAPABILITY_CLASS_GENERAL = 1,
	APPX_CAPABILITY_CLASS_RESTRICTED = 2,
	APPX_CAPABILITY_CLASS_WINDOWS = 4,
	APPX_CAPABILITY_CLASS_ALL = 7,
	APPX_CAPABILITY_CLASS_CUSTOM = 8,
}


[AllowDuplicates]
public enum APPX_PACKAGING_CONTEXT_CHANGE_TYPE : int32
{
	APPX_PACKAGING_CONTEXT_CHANGE_TYPE_START = 0,
	APPX_PACKAGING_CONTEXT_CHANGE_TYPE_CHANGE = 1,
	APPX_PACKAGING_CONTEXT_CHANGE_TYPE_DETAILS = 2,
	APPX_PACKAGING_CONTEXT_CHANGE_TYPE_END = 3,
}


[AllowDuplicates]
public enum APPX_ENCRYPTED_PACKAGE_OPTIONS : uint32
{
	APPX_ENCRYPTED_PACKAGE_OPTION_NONE = 0,
	APPX_ENCRYPTED_PACKAGE_OPTION_DIFFUSION = 1,
	APPX_ENCRYPTED_PACKAGE_OPTION_PAGE_HASHING = 2,
}


[AllowDuplicates]
public enum APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION : int32
{
	APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION_APPEND_DELTA = 0,
}


[AllowDuplicates]
public enum APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTIONS : uint32
{
	APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTION_NONE = 0,
	APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTION_SKIP_VALIDATION = 1,
	APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTION_LOCALIZED = 2,
}


[AllowDuplicates]
public enum PackagePathType : int32
{
	PackagePathType_Install = 0,
	PackagePathType_Mutable = 1,
	PackagePathType_Effective = 2,
	PackagePathType_MachineExternal = 3,
	PackagePathType_UserExternal = 4,
	PackagePathType_EffectiveExternal = 5,
}


[AllowDuplicates]
public enum PackageOrigin : int32
{
	PackageOrigin_Unknown = 0,
	PackageOrigin_Unsigned = 1,
	PackageOrigin_Inbox = 2,
	PackageOrigin_Store = 3,
	PackageOrigin_DeveloperUnsigned = 4,
	PackageOrigin_DeveloperSigned = 5,
	PackageOrigin_LineOfBusiness = 6,
}


[AllowDuplicates]
public enum CreatePackageDependencyOptions : int32
{
	CreatePackageDependencyOptions_None = 0,
	CreatePackageDependencyOptions_DoNotVerifyDependencyResolution = 1,
	CreatePackageDependencyOptions_ScopeIsSystem = 2,
}


[AllowDuplicates]
public enum PackageDependencyLifetimeKind : int32
{
	PackageDependencyLifetimeKind_Process = 0,
	PackageDependencyLifetimeKind_FilePath = 1,
	PackageDependencyLifetimeKind_RegistryKey = 2,
}


[AllowDuplicates]
public enum AddPackageDependencyOptions : int32
{
	AddPackageDependencyOptions_None = 0,
	AddPackageDependencyOptions_PrependIfRankCollision = 1,
}


[AllowDuplicates]
public enum PackageDependencyProcessorArchitectures : int32
{
	PackageDependencyProcessorArchitectures_None = 0,
	PackageDependencyProcessorArchitectures_Neutral = 1,
	PackageDependencyProcessorArchitectures_X86 = 2,
	PackageDependencyProcessorArchitectures_X64 = 4,
	PackageDependencyProcessorArchitectures_Arm = 8,
	PackageDependencyProcessorArchitectures_Arm64 = 16,
	PackageDependencyProcessorArchitectures_X86A64 = 32,
}


[AllowDuplicates]
public enum AppPolicyLifecycleManagement : int32
{
	AppPolicyLifecycleManagement_Unmanaged = 0,
	AppPolicyLifecycleManagement_Managed = 1,
}


[AllowDuplicates]
public enum AppPolicyWindowingModel : int32
{
	AppPolicyWindowingModel_None = 0,
	AppPolicyWindowingModel_Universal = 1,
	AppPolicyWindowingModel_ClassicDesktop = 2,
	AppPolicyWindowingModel_ClassicPhone = 3,
}


[AllowDuplicates]
public enum AppPolicyMediaFoundationCodecLoading : int32
{
	AppPolicyMediaFoundationCodecLoading_All = 0,
	AppPolicyMediaFoundationCodecLoading_InboxOnly = 1,
}


[AllowDuplicates]
public enum AppPolicyClrCompat : int32
{
	AppPolicyClrCompat_Other = 0,
	AppPolicyClrCompat_ClassicDesktop = 1,
	AppPolicyClrCompat_Universal = 2,
	AppPolicyClrCompat_PackagedDesktop = 3,
}


[AllowDuplicates]
public enum AppPolicyThreadInitializationType : int32
{
	AppPolicyThreadInitializationType_None = 0,
	AppPolicyThreadInitializationType_InitializeWinRT = 1,
}


[AllowDuplicates]
public enum AppPolicyShowDeveloperDiagnostic : int32
{
	AppPolicyShowDeveloperDiagnostic_None = 0,
	AppPolicyShowDeveloperDiagnostic_ShowUI = 1,
}


[AllowDuplicates]
public enum AppPolicyProcessTerminationMethod : int32
{
	AppPolicyProcessTerminationMethod_ExitProcess = 0,
	AppPolicyProcessTerminationMethod_TerminateProcess = 1,
}


[AllowDuplicates]
public enum AppPolicyCreateFileAccess : int32
{
	AppPolicyCreateFileAccess_Full = 0,
	AppPolicyCreateFileAccess_Limited = 1,
}

#endregion


#region Structs
[CRepr]
public struct APPX_PACKAGE_SETTINGS
{
	public BOOL forceZip32;
	public IUri* hashMethod;
}

[CRepr]
public struct APPX_PACKAGE_WRITER_PAYLOAD_STREAM
{
	public IStream* inputStream;
	public PWSTR fileName;
	public PWSTR contentType;
	public APPX_COMPRESSION_OPTION compressionOption;
}

[CRepr]
public struct APPX_ENCRYPTED_PACKAGE_SETTINGS
{
	public uint32 keyLength;
	public PWSTR encryptionAlgorithm;
	public BOOL useDiffusion;
	public IUri* blockMapHashAlgorithm;
}

[CRepr]
public struct APPX_ENCRYPTED_PACKAGE_SETTINGS2
{
	public uint32 keyLength;
	public PWSTR encryptionAlgorithm;
	public IUri* blockMapHashAlgorithm;
	public uint32 options;
}

[CRepr]
public struct APPX_KEY_INFO
{
	public uint32 keyLength;
	public uint32 keyIdLength;
	public uint8* key;
	public uint8* keyId;
}

[CRepr]
public struct APPX_ENCRYPTED_EXEMPTIONS
{
	public uint32 count;
	public PWSTR* plainTextFiles;
}

[CRepr]
public struct PACKAGE_VERSION
{
	[CRepr, Union, Packed(4)]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint16 Revision;
			public uint16 Build;
			public uint16 Minor;
			public uint16 Major;
		}
		public uint64 Version;
		public using _Anonymous_e__Struct Anonymous;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(4)]
public struct PACKAGE_ID
{
	public uint32 reserved;
	public uint32 processorArchitecture;
	public PACKAGE_VERSION version;
	public PWSTR name;
	public PWSTR publisher;
	public PWSTR resourceId;
	public PWSTR publisherId;
}

[CRepr]
public struct _PACKAGE_INFO_REFERENCE
{
	public void* reserved;
}

[CRepr, Packed(4)]
public struct PACKAGE_INFO
{
	public uint32 reserved;
	public uint32 flags;
	public PWSTR path;
	public PWSTR packageFullName;
	public PWSTR packageFamilyName;
	public PACKAGE_ID packageId;
}

[CRepr]
public struct PACKAGEDEPENDENCY_CONTEXT__
{
	public int32 unused;
}

[CRepr]
public struct PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__
{
	public int32 unused;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_AppxFactory = .(0x5842a140, 0xff9f, 0x4166, 0x8f, 0x5c, 0x62, 0xf5, 0xb7, 0xb0, 0xc7, 0x81);


	public const Guid CLSID_AppxBundleFactory = .(0x378e0446, 0x5384, 0x43b7, 0x88, 0x77, 0xe7, 0xdb, 0xdd, 0x88, 0x34, 0x46);


	public const Guid CLSID_AppxPackagingDiagnosticEventSinkManager = .(0x50ca0a46, 0x1588, 0x4161, 0x8e, 0xd2, 0xef, 0x9e, 0x46, 0x9c, 0xed, 0x5d);


	public const Guid CLSID_AppxEncryptionFactory = .(0xdc664fdd, 0xd868, 0x46ee, 0x87, 0x80, 0x8d, 0x19, 0x6c, 0xb7, 0x39, 0xf7);


	public const Guid CLSID_AppxPackageEditor = .(0xf004f2ca, 0xaebc, 0x4b0d, 0xbf, 0x58, 0xe5, 0x16, 0xd5, 0xbc, 0xc0, 0xab);


}
#endregion

#region COM Types
[CRepr]struct IAppxFactory : IUnknown
{
	public new const Guid IID = .(0xbeb94909, 0xe451, 0x438b, 0xb5, 0xa7, 0xd7, 0x9e, 0x76, 0x7b, 0x75, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, APPX_PACKAGE_SETTINGS* settings, IAppxPackageWriter** packageWriter) CreatePackageWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxPackageReader** packageReader) CreatePackageReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxManifestReader** manifestReader) CreateManifestReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxBlockMapReader** blockMapReader) CreateBlockMapReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* blockMapStream, PWSTR signatureFileName, IAppxBlockMapReader** blockMapReader) CreateValidatedBlockMapReader;
	}


	public HRESULT CreatePackageWriter(IStream* outputStream, APPX_PACKAGE_SETTINGS* settings, IAppxPackageWriter** packageWriter) mut => VT.[Friend]CreatePackageWriter(&this, outputStream, settings, packageWriter);

	public HRESULT CreatePackageReader(IStream* inputStream, IAppxPackageReader** packageReader) mut => VT.[Friend]CreatePackageReader(&this, inputStream, packageReader);

	public HRESULT CreateManifestReader(IStream* inputStream, IAppxManifestReader** manifestReader) mut => VT.[Friend]CreateManifestReader(&this, inputStream, manifestReader);

	public HRESULT CreateBlockMapReader(IStream* inputStream, IAppxBlockMapReader** blockMapReader) mut => VT.[Friend]CreateBlockMapReader(&this, inputStream, blockMapReader);

	public HRESULT CreateValidatedBlockMapReader(IStream* blockMapStream, PWSTR signatureFileName, IAppxBlockMapReader** blockMapReader) mut => VT.[Friend]CreateValidatedBlockMapReader(&this, blockMapStream, signatureFileName, blockMapReader);
}

[CRepr]struct IAppxFactory2 : IUnknown
{
	public new const Guid IID = .(0xf1346df2, 0xc282, 0x4e22, 0xb9, 0x18, 0x74, 0x3a, 0x92, 0x9a, 0x8d, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxContentGroupMapReader** contentGroupMapReader) CreateContentGroupMapReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxSourceContentGroupMapReader** reader) CreateSourceContentGroupMapReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* stream, IAppxContentGroupMapWriter** contentGroupMapWriter) CreateContentGroupMapWriter;
	}


	public HRESULT CreateContentGroupMapReader(IStream* inputStream, IAppxContentGroupMapReader** contentGroupMapReader) mut => VT.[Friend]CreateContentGroupMapReader(&this, inputStream, contentGroupMapReader);

	public HRESULT CreateSourceContentGroupMapReader(IStream* inputStream, IAppxSourceContentGroupMapReader** reader) mut => VT.[Friend]CreateSourceContentGroupMapReader(&this, inputStream, reader);

	public HRESULT CreateContentGroupMapWriter(IStream* stream, IAppxContentGroupMapWriter** contentGroupMapWriter) mut => VT.[Friend]CreateContentGroupMapWriter(&this, stream, contentGroupMapWriter);
}

[CRepr]struct IAppxPackageReader : IUnknown
{
	public new const Guid IID = .(0xb5c49650, 0x99bc, 0x481c, 0x9a, 0x34, 0x3d, 0x53, 0xa4, 0x10, 0x67, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapReader** blockMapReader) GetBlockMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_FOOTPRINT_FILE_TYPE type, IAppxFile** file) GetFootprintFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IAppxFile** file) GetPayloadFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxFilesEnumerator** filesEnumerator) GetPayloadFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestReader** manifestReader) GetManifest;
	}


	public HRESULT GetBlockMap(IAppxBlockMapReader** blockMapReader) mut => VT.[Friend]GetBlockMap(&this, blockMapReader);

	public HRESULT GetFootprintFile(APPX_FOOTPRINT_FILE_TYPE type, IAppxFile** file) mut => VT.[Friend]GetFootprintFile(&this, type, file);

	public HRESULT GetPayloadFile(PWSTR fileName, IAppxFile** file) mut => VT.[Friend]GetPayloadFile(&this, fileName, file);

	public HRESULT GetPayloadFiles(IAppxFilesEnumerator** filesEnumerator) mut => VT.[Friend]GetPayloadFiles(&this, filesEnumerator);

	public HRESULT GetManifest(IAppxManifestReader** manifestReader) mut => VT.[Friend]GetManifest(&this, manifestReader);
}

[CRepr]struct IAppxPackageWriter : IUnknown
{
	public new const Guid IID = .(0x9099e33b, 0x246f, 0x41e4, 0x88, 0x1a, 0x00, 0x8e, 0xb6, 0x13, 0xf8, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, PWSTR contentType, APPX_COMPRESSION_OPTION compressionOption, IStream* inputStream) AddPayloadFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* manifest) Close;
	}


	public HRESULT AddPayloadFile(PWSTR fileName, PWSTR contentType, APPX_COMPRESSION_OPTION compressionOption, IStream* inputStream) mut => VT.[Friend]AddPayloadFile(&this, fileName, contentType, compressionOption, inputStream);

	public HRESULT Close(IStream* manifest) mut => VT.[Friend]Close(&this, manifest);
}

[CRepr]struct IAppxPackageWriter2 : IUnknown
{
	public new const Guid IID = .(0x2cf5c4fd, 0xe54c, 0x4ea5, 0xba, 0x4e, 0xf8, 0xc4, 0xb1, 0x05, 0xa8, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* manifest, IStream* contentGroupMap) Close;
	}


	public HRESULT Close(IStream* manifest, IStream* contentGroupMap) mut => VT.[Friend]Close(&this, manifest, contentGroupMap);
}

[CRepr]struct IAppxPackageWriter3 : IUnknown
{
	public new const Guid IID = .(0xa83aacd3, 0x41c0, 0x4501, 0xb8, 0xa3, 0x74, 0x16, 0x4f, 0x50, 0xb2, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fileCount, APPX_PACKAGE_WRITER_PAYLOAD_STREAM* payloadFiles, uint64 memoryLimit) AddPayloadFiles;
	}


	public HRESULT AddPayloadFiles(uint32 fileCount, APPX_PACKAGE_WRITER_PAYLOAD_STREAM* payloadFiles, uint64 memoryLimit) mut => VT.[Friend]AddPayloadFiles(&this, fileCount, payloadFiles, memoryLimit);
}

[CRepr]struct IAppxFile : IUnknown
{
	public new const Guid IID = .(0x91df827b, 0x94fd, 0x468f, 0x82, 0x7b, 0x57, 0xf4, 0x1b, 0x2f, 0x6f, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_COMPRESSION_OPTION* compressionOption) GetCompressionOption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* contentType) GetContentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* fileName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* size) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** stream) GetStream;
	}


	public HRESULT GetCompressionOption(APPX_COMPRESSION_OPTION* compressionOption) mut => VT.[Friend]GetCompressionOption(&this, compressionOption);

	public HRESULT GetContentType(PWSTR* contentType) mut => VT.[Friend]GetContentType(&this, contentType);

	public HRESULT GetName(PWSTR* fileName) mut => VT.[Friend]GetName(&this, fileName);

	public HRESULT GetSize(uint64* size) mut => VT.[Friend]GetSize(&this, size);

	public HRESULT GetStream(IStream** stream) mut => VT.[Friend]GetStream(&this, stream);
}

[CRepr]struct IAppxFilesEnumerator : IUnknown
{
	public new const Guid IID = .(0xf007eeaf, 0x9831, 0x411c, 0x98, 0x47, 0x91, 0x7c, 0xdc, 0x62, 0xd1, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxFile** file) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxFile** file) mut => VT.[Friend]GetCurrent(&this, file);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxBlockMapReader : IUnknown
{
	public new const Guid IID = .(0x5efec991, 0xbca3, 0x42d1, 0x9e, 0xc2, 0xe9, 0x2d, 0x60, 0x9e, 0xc2, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR filename, IAppxBlockMapFile** file) GetFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapFilesEnumerator** enumerator) GetFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUri** hashMethod) GetHashMethod;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** blockMapStream) GetStream;
	}


	public HRESULT GetFile(PWSTR filename, IAppxBlockMapFile** file) mut => VT.[Friend]GetFile(&this, filename, file);

	public HRESULT GetFiles(IAppxBlockMapFilesEnumerator** enumerator) mut => VT.[Friend]GetFiles(&this, enumerator);

	public HRESULT GetHashMethod(IUri** hashMethod) mut => VT.[Friend]GetHashMethod(&this, hashMethod);

	public HRESULT GetStream(IStream** blockMapStream) mut => VT.[Friend]GetStream(&this, blockMapStream);
}

[CRepr]struct IAppxBlockMapFile : IUnknown
{
	public new const Guid IID = .(0x277672ac, 0x4f63, 0x42c1, 0x8a, 0xbc, 0xbe, 0xae, 0x36, 0x00, 0xeb, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapBlocksEnumerator** blocks) GetBlocks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lfhSize) GetLocalFileHeaderSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* size) GetUncompressedSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* fileStream, BOOL* isValid) ValidateFileHash;
	}


	public HRESULT GetBlocks(IAppxBlockMapBlocksEnumerator** blocks) mut => VT.[Friend]GetBlocks(&this, blocks);

	public HRESULT GetLocalFileHeaderSize(uint32* lfhSize) mut => VT.[Friend]GetLocalFileHeaderSize(&this, lfhSize);

	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetUncompressedSize(uint64* size) mut => VT.[Friend]GetUncompressedSize(&this, size);

	public HRESULT ValidateFileHash(IStream* fileStream, BOOL* isValid) mut => VT.[Friend]ValidateFileHash(&this, fileStream, isValid);
}

[CRepr]struct IAppxBlockMapFilesEnumerator : IUnknown
{
	public new const Guid IID = .(0x02b856a2, 0x4262, 0x4070, 0xba, 0xcb, 0x1a, 0x8c, 0xbb, 0xc4, 0x23, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapFile** file) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) MoveNext;
	}


	public HRESULT GetCurrent(IAppxBlockMapFile** file) mut => VT.[Friend]GetCurrent(&this, file);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasCurrent) mut => VT.[Friend]MoveNext(&this, hasCurrent);
}

[CRepr]struct IAppxBlockMapBlock : IUnknown
{
	public new const Guid IID = .(0x75cf3930, 0x3244, 0x4fe0, 0xa8, 0xc8, 0xe0, 0xbc, 0xb2, 0x70, 0xb8, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* bufferSize, uint8** buffer) GetHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* size) GetCompressedSize;
	}


	public HRESULT GetHash(uint32* bufferSize, uint8** buffer) mut => VT.[Friend]GetHash(&this, bufferSize, buffer);

	public HRESULT GetCompressedSize(uint32* size) mut => VT.[Friend]GetCompressedSize(&this, size);
}

[CRepr]struct IAppxBlockMapBlocksEnumerator : IUnknown
{
	public new const Guid IID = .(0x6b429b5b, 0x36ef, 0x479e, 0xb9, 0xeb, 0x0c, 0x14, 0x82, 0xb4, 0x9e, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapBlock** block) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxBlockMapBlock** block) mut => VT.[Friend]GetCurrent(&this, block);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestReader : IUnknown
{
	public new const Guid IID = .(0x4e1bd148, 0x55a0, 0x4480, 0xa3, 0xd1, 0x15, 0x54, 0x47, 0x10, 0x63, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageId** packageId) GetPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestProperties** packageProperties) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageDependenciesEnumerator** dependencies) GetPackageDependencies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_CAPABILITIES* capabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestResourcesEnumerator** resources) GetResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestDeviceCapabilitiesEnumerator** deviceCapabilities) GetDeviceCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, uint64* value) GetPrerequisite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestApplicationsEnumerator** applications) GetApplications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** manifestStream) GetStream;
	}


	public HRESULT GetPackageId(IAppxManifestPackageId** packageId) mut => VT.[Friend]GetPackageId(&this, packageId);

	public HRESULT GetProperties(IAppxManifestProperties** packageProperties) mut => VT.[Friend]GetProperties(&this, packageProperties);

	public HRESULT GetPackageDependencies(IAppxManifestPackageDependenciesEnumerator** dependencies) mut => VT.[Friend]GetPackageDependencies(&this, dependencies);

	public HRESULT GetCapabilities(APPX_CAPABILITIES* capabilities) mut => VT.[Friend]GetCapabilities(&this, capabilities);

	public HRESULT GetResources(IAppxManifestResourcesEnumerator** resources) mut => VT.[Friend]GetResources(&this, resources);

	public HRESULT GetDeviceCapabilities(IAppxManifestDeviceCapabilitiesEnumerator** deviceCapabilities) mut => VT.[Friend]GetDeviceCapabilities(&this, deviceCapabilities);

	public HRESULT GetPrerequisite(PWSTR name, uint64* value) mut => VT.[Friend]GetPrerequisite(&this, name, value);

	public HRESULT GetApplications(IAppxManifestApplicationsEnumerator** applications) mut => VT.[Friend]GetApplications(&this, applications);

	public HRESULT GetStream(IStream** manifestStream) mut => VT.[Friend]GetStream(&this, manifestStream);
}

[CRepr]struct IAppxManifestReader2 : IAppxManifestReader
{
	public new const Guid IID = .(0xd06f67bc, 0xb31d, 0x4eba, 0xa8, 0xaf, 0x63, 0x8e, 0x73, 0xe7, 0x7b, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAppxManifestReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestQualifiedResourcesEnumerator** resources) GetQualifiedResources;
	}


	public HRESULT GetQualifiedResources(IAppxManifestQualifiedResourcesEnumerator** resources) mut => VT.[Friend]GetQualifiedResources(&this, resources);
}

[CRepr]struct IAppxManifestReader3 : IAppxManifestReader2
{
	public new const Guid IID = .(0xc43825ab, 0x69b7, 0x400a, 0x97, 0x09, 0xcc, 0x37, 0xf5, 0xa7, 0x2d, 0x24);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAppxManifestReader2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_CAPABILITY_CLASS_TYPE capabilityClass, IAppxManifestCapabilitiesEnumerator** capabilities) GetCapabilitiesByCapabilityClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestTargetDeviceFamiliesEnumerator** targetDeviceFamilies) GetTargetDeviceFamilies;
	}


	public HRESULT GetCapabilitiesByCapabilityClass(APPX_CAPABILITY_CLASS_TYPE capabilityClass, IAppxManifestCapabilitiesEnumerator** capabilities) mut => VT.[Friend]GetCapabilitiesByCapabilityClass(&this, capabilityClass, capabilities);

	public HRESULT GetTargetDeviceFamilies(IAppxManifestTargetDeviceFamiliesEnumerator** targetDeviceFamilies) mut => VT.[Friend]GetTargetDeviceFamilies(&this, targetDeviceFamilies);
}

[CRepr]struct IAppxManifestReader4 : IAppxManifestReader3
{
	public new const Guid IID = .(0x4579bb7c, 0x741d, 0x4161, 0xb5, 0xa1, 0x47, 0xbd, 0x3b, 0x78, 0xad, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAppxManifestReader3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestOptionalPackageInfo** optionalPackageInfo) GetOptionalPackageInfo;
	}


	public HRESULT GetOptionalPackageInfo(IAppxManifestOptionalPackageInfo** optionalPackageInfo) mut => VT.[Friend]GetOptionalPackageInfo(&this, optionalPackageInfo);
}

[CRepr]struct IAppxManifestReader5 : IUnknown
{
	public new const Guid IID = .(0x8d7ae132, 0xa690, 0x4c00, 0xb7, 0x5a, 0x6a, 0xae, 0x1f, 0xea, 0xac, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestMainPackageDependenciesEnumerator** mainPackageDependencies) GetMainPackageDependencies;
	}


	public HRESULT GetMainPackageDependencies(IAppxManifestMainPackageDependenciesEnumerator** mainPackageDependencies) mut => VT.[Friend]GetMainPackageDependencies(&this, mainPackageDependencies);
}

[CRepr]struct IAppxManifestReader6 : IUnknown
{
	public new const Guid IID = .(0x34deaca4, 0xd3c0, 0x4e3e, 0xb3, 0x12, 0xe4, 0x26, 0x25, 0xe3, 0x80, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isNonQualifiedResourcePackage) GetIsNonQualifiedResourcePackage;
	}


	public HRESULT GetIsNonQualifiedResourcePackage(BOOL* isNonQualifiedResourcePackage) mut => VT.[Friend]GetIsNonQualifiedResourcePackage(&this, isNonQualifiedResourcePackage);
}

[CRepr]struct IAppxManifestReader7 : IUnknown
{
	public new const Guid IID = .(0x8efe6f27, 0x0ce0, 0x4988, 0xb3, 0x2d, 0x73, 0x8e, 0xb6, 0x3d, 0xb3, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestDriverDependenciesEnumerator** driverDependencies) GetDriverDependencies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestOSPackageDependenciesEnumerator** osPackageDependencies) GetOSPackageDependencies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestHostRuntimeDependenciesEnumerator** hostRuntimeDependencies) GetHostRuntimeDependencies;
	}


	public HRESULT GetDriverDependencies(IAppxManifestDriverDependenciesEnumerator** driverDependencies) mut => VT.[Friend]GetDriverDependencies(&this, driverDependencies);

	public HRESULT GetOSPackageDependencies(IAppxManifestOSPackageDependenciesEnumerator** osPackageDependencies) mut => VT.[Friend]GetOSPackageDependencies(&this, osPackageDependencies);

	public HRESULT GetHostRuntimeDependencies(IAppxManifestHostRuntimeDependenciesEnumerator** hostRuntimeDependencies) mut => VT.[Friend]GetHostRuntimeDependencies(&this, hostRuntimeDependencies);
}

[CRepr]struct IAppxManifestDriverDependenciesEnumerator : IUnknown
{
	public new const Guid IID = .(0xfe039db2, 0x467f, 0x4755, 0x84, 0x04, 0x8f, 0x5e, 0xb6, 0x86, 0x5b, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestDriverDependency** driverDependency) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestDriverDependency** driverDependency) mut => VT.[Friend]GetCurrent(&this, driverDependency);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestDriverDependency : IUnknown
{
	public new const Guid IID = .(0x1210cb94, 0x5a92, 0x4602, 0xbe, 0x24, 0x79, 0xf3, 0x18, 0xaf, 0x4a, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestDriverConstraintsEnumerator** driverConstraints) GetDriverConstraints;
	}


	public HRESULT GetDriverConstraints(IAppxManifestDriverConstraintsEnumerator** driverConstraints) mut => VT.[Friend]GetDriverConstraints(&this, driverConstraints);
}

[CRepr]struct IAppxManifestDriverConstraintsEnumerator : IUnknown
{
	public new const Guid IID = .(0xd402b2d1, 0xf600, 0x49e0, 0x95, 0xe6, 0x97, 0x5d, 0x8d, 0xa1, 0x3d, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestDriverConstraint** driverConstraint) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestDriverConstraint** driverConstraint) mut => VT.[Friend]GetCurrent(&this, driverConstraint);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestDriverConstraint : IUnknown
{
	public new const Guid IID = .(0xc031bee4, 0xbbcc, 0x48ea, 0xa2, 0x37, 0xc3, 0x40, 0x45, 0xc8, 0x0a, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* minVersion) GetMinVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* minDate) GetMinDate;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetMinVersion(uint64* minVersion) mut => VT.[Friend]GetMinVersion(&this, minVersion);

	public HRESULT GetMinDate(PWSTR* minDate) mut => VT.[Friend]GetMinDate(&this, minDate);
}

[CRepr]struct IAppxManifestOSPackageDependenciesEnumerator : IUnknown
{
	public new const Guid IID = .(0xb84e2fc3, 0xf8ec, 0x4bc1, 0x8a, 0xe2, 0x15, 0x63, 0x46, 0xf5, 0xff, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestOSPackageDependency** osPackageDependency) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestOSPackageDependency** osPackageDependency) mut => VT.[Friend]GetCurrent(&this, osPackageDependency);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestOSPackageDependency : IUnknown
{
	public new const Guid IID = .(0x154995ee, 0x54a6, 0x4f14, 0xac, 0x97, 0xd8, 0xcf, 0x05, 0x19, 0x64, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* version) GetVersion;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetVersion(uint64* version) mut => VT.[Friend]GetVersion(&this, version);
}

[CRepr]struct IAppxManifestHostRuntimeDependenciesEnumerator : IUnknown
{
	public new const Guid IID = .(0x6427a646, 0x7f49, 0x433e, 0xb1, 0xa6, 0x0d, 0xa3, 0x09, 0xf6, 0x88, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestHostRuntimeDependency** hostRuntimeDependency) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestHostRuntimeDependency** hostRuntimeDependency) mut => VT.[Friend]GetCurrent(&this, hostRuntimeDependency);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestHostRuntimeDependency : IUnknown
{
	public new const Guid IID = .(0x3455d234, 0x8414, 0x410d, 0x95, 0xc7, 0x7b, 0x35, 0x25, 0x5b, 0x83, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* publisher) GetPublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* minVersion) GetMinVersion;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetPublisher(PWSTR* publisher) mut => VT.[Friend]GetPublisher(&this, publisher);

	public HRESULT GetMinVersion(uint64* minVersion) mut => VT.[Friend]GetMinVersion(&this, minVersion);
}

[CRepr]struct IAppxManifestHostRuntimeDependency2 : IUnknown
{
	public new const Guid IID = .(0xc26f23a8, 0xee10, 0x4ad6, 0xb8, 0x98, 0x2b, 0x4d, 0x7a, 0xeb, 0xfe, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* packageFamilyName) GetPackageFamilyName;
	}


	public HRESULT GetPackageFamilyName(PWSTR* packageFamilyName) mut => VT.[Friend]GetPackageFamilyName(&this, packageFamilyName);
}

[CRepr]struct IAppxManifestOptionalPackageInfo : IUnknown
{
	public new const Guid IID = .(0x2634847d, 0x5b5d, 0x4fe5, 0xa2, 0x43, 0x00, 0x2f, 0xf9, 0x5e, 0xdc, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isOptionalPackage) GetIsOptionalPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* mainPackageName) GetMainPackageName;
	}


	public HRESULT GetIsOptionalPackage(BOOL* isOptionalPackage) mut => VT.[Friend]GetIsOptionalPackage(&this, isOptionalPackage);

	public HRESULT GetMainPackageName(PWSTR* mainPackageName) mut => VT.[Friend]GetMainPackageName(&this, mainPackageName);
}

[CRepr]struct IAppxManifestMainPackageDependenciesEnumerator : IUnknown
{
	public new const Guid IID = .(0xa99c4f00, 0x51d2, 0x4f0f, 0xba, 0x46, 0x7e, 0xd5, 0x25, 0x5e, 0xbd, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestMainPackageDependency** mainPackageDependency) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestMainPackageDependency** mainPackageDependency) mut => VT.[Friend]GetCurrent(&this, mainPackageDependency);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestMainPackageDependency : IUnknown
{
	public new const Guid IID = .(0x05d0611c, 0xbc29, 0x46d5, 0x97, 0xe2, 0x84, 0xb9, 0xc7, 0x9b, 0xd8, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* publisher) GetPublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* packageFamilyName) GetPackageFamilyName;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetPublisher(PWSTR* publisher) mut => VT.[Friend]GetPublisher(&this, publisher);

	public HRESULT GetPackageFamilyName(PWSTR* packageFamilyName) mut => VT.[Friend]GetPackageFamilyName(&this, packageFamilyName);
}

[CRepr]struct IAppxManifestPackageId : IUnknown
{
	public new const Guid IID = .(0x283ce2d7, 0x7153, 0x4a91, 0x96, 0x49, 0x7a, 0x0f, 0x72, 0x40, 0x94, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_PACKAGE_ARCHITECTURE* architecture) GetArchitecture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* publisher) GetPublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* packageVersion) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* resourceId) GetResourceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR other, BOOL* isSame) ComparePublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* packageFullName) GetPackageFullName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* packageFamilyName) GetPackageFamilyName;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetArchitecture(APPX_PACKAGE_ARCHITECTURE* architecture) mut => VT.[Friend]GetArchitecture(&this, architecture);

	public HRESULT GetPublisher(PWSTR* publisher) mut => VT.[Friend]GetPublisher(&this, publisher);

	public HRESULT GetVersion(uint64* packageVersion) mut => VT.[Friend]GetVersion(&this, packageVersion);

	public HRESULT GetResourceId(PWSTR* resourceId) mut => VT.[Friend]GetResourceId(&this, resourceId);

	public HRESULT ComparePublisher(PWSTR other, BOOL* isSame) mut => VT.[Friend]ComparePublisher(&this, other, isSame);

	public HRESULT GetPackageFullName(PWSTR* packageFullName) mut => VT.[Friend]GetPackageFullName(&this, packageFullName);

	public HRESULT GetPackageFamilyName(PWSTR* packageFamilyName) mut => VT.[Friend]GetPackageFamilyName(&this, packageFamilyName);
}

[CRepr]struct IAppxManifestPackageId2 : IAppxManifestPackageId
{
	public new const Guid IID = .(0x2256999d, 0xd617, 0x42f1, 0x88, 0x0e, 0x0b, 0xa4, 0x54, 0x23, 0x19, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAppxManifestPackageId.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_PACKAGE_ARCHITECTURE2* architecture) GetArchitecture2;
	}


	public HRESULT GetArchitecture2(APPX_PACKAGE_ARCHITECTURE2* architecture) mut => VT.[Friend]GetArchitecture2(&this, architecture);
}

[CRepr]struct IAppxManifestProperties : IUnknown
{
	public new const Guid IID = .(0x03faf64d, 0xf26f, 0x4b2c, 0xaa, 0xf7, 0x8f, 0xe7, 0x78, 0x9b, 0x8b, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, BOOL* value) GetBoolValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, PWSTR* value) GetStringValue;
	}


	public HRESULT GetBoolValue(PWSTR name, BOOL* value) mut => VT.[Friend]GetBoolValue(&this, name, value);

	public HRESULT GetStringValue(PWSTR name, PWSTR* value) mut => VT.[Friend]GetStringValue(&this, name, value);
}

[CRepr]struct IAppxManifestTargetDeviceFamiliesEnumerator : IUnknown
{
	public new const Guid IID = .(0x36537f36, 0x27a4, 0x4788, 0x88, 0xc0, 0x73, 0x38, 0x19, 0x57, 0x50, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestTargetDeviceFamily** targetDeviceFamily) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestTargetDeviceFamily** targetDeviceFamily) mut => VT.[Friend]GetCurrent(&this, targetDeviceFamily);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestTargetDeviceFamily : IUnknown
{
	public new const Guid IID = .(0x9091b09b, 0xc8d5, 0x4f31, 0x86, 0x87, 0xa3, 0x38, 0x25, 0x9f, 0xae, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* minVersion) GetMinVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* maxVersionTested) GetMaxVersionTested;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetMinVersion(uint64* minVersion) mut => VT.[Friend]GetMinVersion(&this, minVersion);

	public HRESULT GetMaxVersionTested(uint64* maxVersionTested) mut => VT.[Friend]GetMaxVersionTested(&this, maxVersionTested);
}

[CRepr]struct IAppxManifestPackageDependenciesEnumerator : IUnknown
{
	public new const Guid IID = .(0xb43bbcf9, 0x65a6, 0x42dd, 0xba, 0xc0, 0x8c, 0x67, 0x41, 0xe7, 0xf5, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageDependency** dependency) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestPackageDependency** dependency) mut => VT.[Friend]GetCurrent(&this, dependency);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestPackageDependency : IUnknown
{
	public new const Guid IID = .(0xe4946b59, 0x733e, 0x43f0, 0xa7, 0x24, 0x3b, 0xde, 0x4c, 0x12, 0x85, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* name) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* publisher) GetPublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* minVersion) GetMinVersion;
	}


	public HRESULT GetName(PWSTR* name) mut => VT.[Friend]GetName(&this, name);

	public HRESULT GetPublisher(PWSTR* publisher) mut => VT.[Friend]GetPublisher(&this, publisher);

	public HRESULT GetMinVersion(uint64* minVersion) mut => VT.[Friend]GetMinVersion(&this, minVersion);
}

[CRepr]struct IAppxManifestPackageDependency2 : IAppxManifestPackageDependency
{
	public new const Guid IID = .(0xdda0b713, 0xf3ff, 0x49d3, 0x89, 0x8a, 0x27, 0x86, 0x78, 0x0c, 0x5d, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAppxManifestPackageDependency.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* maxMajorVersionTested) GetMaxMajorVersionTested;
	}


	public HRESULT GetMaxMajorVersionTested(uint16* maxMajorVersionTested) mut => VT.[Friend]GetMaxMajorVersionTested(&this, maxMajorVersionTested);
}

[CRepr]struct IAppxManifestPackageDependency3 : IUnknown
{
	public new const Guid IID = .(0x1ac56374, 0x6198, 0x4d6b, 0x92, 0xe4, 0x74, 0x9d, 0x5a, 0xb8, 0xa8, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isOptional) GetIsOptional;
	}


	public HRESULT GetIsOptional(BOOL* isOptional) mut => VT.[Friend]GetIsOptional(&this, isOptional);
}

[CRepr]struct IAppxManifestResourcesEnumerator : IUnknown
{
	public new const Guid IID = .(0xde4dfbbd, 0x881a, 0x48bb, 0x85, 0x8c, 0xd6, 0xf2, 0xba, 0xea, 0xe6, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* resource) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(PWSTR* resource) mut => VT.[Friend]GetCurrent(&this, resource);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestDeviceCapabilitiesEnumerator : IUnknown
{
	public new const Guid IID = .(0x30204541, 0x427b, 0x4a1c, 0xba, 0xcf, 0x65, 0x5b, 0xf4, 0x63, 0xa5, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* deviceCapability) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(PWSTR* deviceCapability) mut => VT.[Friend]GetCurrent(&this, deviceCapability);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestCapabilitiesEnumerator : IUnknown
{
	public new const Guid IID = .(0x11d22258, 0xf470, 0x42c1, 0xb2, 0x91, 0x83, 0x61, 0xc5, 0x43, 0x7e, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* capability) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(PWSTR* capability) mut => VT.[Friend]GetCurrent(&this, capability);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestApplicationsEnumerator : IUnknown
{
	public new const Guid IID = .(0x9eb8a55a, 0xf04b, 0x4d0d, 0x80, 0x8d, 0x68, 0x61, 0x85, 0xd4, 0x84, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestApplication** application) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestApplication** application) mut => VT.[Friend]GetCurrent(&this, application);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestApplication : IUnknown
{
	public new const Guid IID = .(0x5da89bf4, 0x3773, 0x46be, 0xb6, 0x50, 0x7e, 0x74, 0x48, 0x63, 0xb7, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR name, PWSTR* value) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* appUserModelId) GetAppUserModelId;
	}


	public HRESULT GetStringValue(PWSTR name, PWSTR* value) mut => VT.[Friend]GetStringValue(&this, name, value);

	public HRESULT GetAppUserModelId(PWSTR* appUserModelId) mut => VT.[Friend]GetAppUserModelId(&this, appUserModelId);
}

[CRepr]struct IAppxManifestQualifiedResourcesEnumerator : IUnknown
{
	public new const Guid IID = .(0x8ef6adfe, 0x3762, 0x4a8f, 0x93, 0x73, 0x2f, 0xc5, 0xd4, 0x44, 0xc8, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestQualifiedResource** resource) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxManifestQualifiedResource** resource) mut => VT.[Friend]GetCurrent(&this, resource);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxManifestQualifiedResource : IUnknown
{
	public new const Guid IID = .(0x3b53a497, 0x3c5c, 0x48d1, 0x9e, 0xa3, 0xbb, 0x7e, 0xac, 0x8c, 0xd7, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* language) GetLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* scale) GetScale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DX_FEATURE_LEVEL* dxFeatureLevel) GetDXFeatureLevel;
	}


	public HRESULT GetLanguage(PWSTR* language) mut => VT.[Friend]GetLanguage(&this, language);

	public HRESULT GetScale(uint32* scale) mut => VT.[Friend]GetScale(&this, scale);

	public HRESULT GetDXFeatureLevel(DX_FEATURE_LEVEL* dxFeatureLevel) mut => VT.[Friend]GetDXFeatureLevel(&this, dxFeatureLevel);
}

[CRepr]struct IAppxBundleFactory : IUnknown
{
	public new const Guid IID = .(0xbba65864, 0x965f, 0x4a5f, 0x85, 0x5f, 0xf0, 0x74, 0xbd, 0xbf, 0x3a, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, uint64 bundleVersion, IAppxBundleWriter** bundleWriter) CreateBundleWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxBundleReader** bundleReader) CreateBundleReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IAppxBundleManifestReader** manifestReader) CreateBundleManifestReader;
	}


	public HRESULT CreateBundleWriter(IStream* outputStream, uint64 bundleVersion, IAppxBundleWriter** bundleWriter) mut => VT.[Friend]CreateBundleWriter(&this, outputStream, bundleVersion, bundleWriter);

	public HRESULT CreateBundleReader(IStream* inputStream, IAppxBundleReader** bundleReader) mut => VT.[Friend]CreateBundleReader(&this, inputStream, bundleReader);

	public HRESULT CreateBundleManifestReader(IStream* inputStream, IAppxBundleManifestReader** manifestReader) mut => VT.[Friend]CreateBundleManifestReader(&this, inputStream, manifestReader);
}

[CRepr]struct IAppxBundleWriter : IUnknown
{
	public new const Guid IID = .(0xec446fe8, 0xbfec, 0x4c64, 0xab, 0x4f, 0x49, 0xf0, 0x38, 0xf0, 0xc6, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* packageStream) AddPayloadPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT AddPayloadPackage(PWSTR fileName, IStream* packageStream) mut => VT.[Friend]AddPayloadPackage(&this, fileName, packageStream);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IAppxBundleWriter2 : IUnknown
{
	public new const Guid IID = .(0x6d8fe971, 0x01cc, 0x49a0, 0xb6, 0x85, 0x23, 0x38, 0x51, 0x27, 0x99, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream) AddExternalPackageReference;
	}


	public HRESULT AddExternalPackageReference(PWSTR fileName, IStream* inputStream) mut => VT.[Friend]AddExternalPackageReference(&this, fileName, inputStream);
}

[CRepr]struct IAppxBundleWriter3 : IUnknown
{
	public new const Guid IID = .(0xad711152, 0xf969, 0x4193, 0x82, 0xd5, 0x9d, 0xdf, 0x27, 0x86, 0xd2, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream) AddPackageReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR hashMethodString) Close;
	}


	public HRESULT AddPackageReference(PWSTR fileName, IStream* inputStream) mut => VT.[Friend]AddPackageReference(&this, fileName, inputStream);

	public HRESULT Close(PWSTR hashMethodString) mut => VT.[Friend]Close(&this, hashMethodString);
}

[CRepr]struct IAppxBundleWriter4 : IUnknown
{
	public new const Guid IID = .(0x9cd9d523, 0x5009, 0x4c01, 0x98, 0x82, 0xdc, 0x02, 0x9f, 0xbd, 0x47, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* packageStream, BOOL isDefaultApplicablePackage) AddPayloadPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) AddPackageReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) AddExternalPackageReference;
	}


	public HRESULT AddPayloadPackage(PWSTR fileName, IStream* packageStream, BOOL isDefaultApplicablePackage) mut => VT.[Friend]AddPayloadPackage(&this, fileName, packageStream, isDefaultApplicablePackage);

	public HRESULT AddPackageReference(PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) mut => VT.[Friend]AddPackageReference(&this, fileName, inputStream, isDefaultApplicablePackage);

	public HRESULT AddExternalPackageReference(PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) mut => VT.[Friend]AddExternalPackageReference(&this, fileName, inputStream, isDefaultApplicablePackage);
}

[CRepr]struct IAppxBundleReader : IUnknown
{
	public new const Guid IID = .(0xdd75b8c0, 0xba76, 0x43b0, 0xae, 0x0f, 0x68, 0x65, 0x6a, 0x1d, 0xc5, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_BUNDLE_FOOTPRINT_FILE_TYPE fileType, IAppxFile** footprintFile) GetFootprintFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBlockMapReader** blockMapReader) GetBlockMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestReader** manifestReader) GetManifest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxFilesEnumerator** payloadPackages) GetPayloadPackages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IAppxFile** payloadPackage) GetPayloadPackage;
	}


	public HRESULT GetFootprintFile(APPX_BUNDLE_FOOTPRINT_FILE_TYPE fileType, IAppxFile** footprintFile) mut => VT.[Friend]GetFootprintFile(&this, fileType, footprintFile);

	public HRESULT GetBlockMap(IAppxBlockMapReader** blockMapReader) mut => VT.[Friend]GetBlockMap(&this, blockMapReader);

	public HRESULT GetManifest(IAppxBundleManifestReader** manifestReader) mut => VT.[Friend]GetManifest(&this, manifestReader);

	public HRESULT GetPayloadPackages(IAppxFilesEnumerator** payloadPackages) mut => VT.[Friend]GetPayloadPackages(&this, payloadPackages);

	public HRESULT GetPayloadPackage(PWSTR fileName, IAppxFile** payloadPackage) mut => VT.[Friend]GetPayloadPackage(&this, fileName, payloadPackage);
}

[CRepr]struct IAppxBundleManifestReader : IUnknown
{
	public new const Guid IID = .(0xcf0ebbc1, 0xcc99, 0x4106, 0x91, 0xeb, 0xe6, 0x74, 0x62, 0xe0, 0x4f, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageId** packageId) GetPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestPackageInfoEnumerator** packageInfoItems) GetPackageInfoItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** manifestStream) GetStream;
	}


	public HRESULT GetPackageId(IAppxManifestPackageId** packageId) mut => VT.[Friend]GetPackageId(&this, packageId);

	public HRESULT GetPackageInfoItems(IAppxBundleManifestPackageInfoEnumerator** packageInfoItems) mut => VT.[Friend]GetPackageInfoItems(&this, packageInfoItems);

	public HRESULT GetStream(IStream** manifestStream) mut => VT.[Friend]GetStream(&this, manifestStream);
}

[CRepr]struct IAppxBundleManifestReader2 : IUnknown
{
	public new const Guid IID = .(0x5517df70, 0x033f, 0x4af2, 0x82, 0x13, 0x87, 0xd7, 0x66, 0x80, 0x5c, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestOptionalBundleInfoEnumerator** optionalBundles) GetOptionalBundles;
	}


	public HRESULT GetOptionalBundles(IAppxBundleManifestOptionalBundleInfoEnumerator** optionalBundles) mut => VT.[Friend]GetOptionalBundles(&this, optionalBundles);
}

[CRepr]struct IAppxBundleManifestPackageInfoEnumerator : IUnknown
{
	public new const Guid IID = .(0xf9b856ee, 0x49a6, 0x4e19, 0xb2, 0xb0, 0x6a, 0x24, 0x06, 0xd6, 0x3a, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestPackageInfo** packageInfo) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxBundleManifestPackageInfo** packageInfo) mut => VT.[Friend]GetCurrent(&this, packageInfo);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxBundleManifestPackageInfo : IUnknown
{
	public new const Guid IID = .(0x54cd06c1, 0x268f, 0x40bb, 0x8e, 0xd2, 0x75, 0x7a, 0x9e, 0xba, 0xec, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_BUNDLE_PAYLOAD_PACKAGE_TYPE* packageType) GetPackageType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageId** packageId) GetPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* fileName) GetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* offset) GetOffset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* size) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestQualifiedResourcesEnumerator** resources) GetResources;
	}


	public HRESULT GetPackageType(APPX_BUNDLE_PAYLOAD_PACKAGE_TYPE* packageType) mut => VT.[Friend]GetPackageType(&this, packageType);

	public HRESULT GetPackageId(IAppxManifestPackageId** packageId) mut => VT.[Friend]GetPackageId(&this, packageId);

	public HRESULT GetFileName(PWSTR* fileName) mut => VT.[Friend]GetFileName(&this, fileName);

	public HRESULT GetOffset(uint64* offset) mut => VT.[Friend]GetOffset(&this, offset);

	public HRESULT GetSize(uint64* size) mut => VT.[Friend]GetSize(&this, size);

	public HRESULT GetResources(IAppxManifestQualifiedResourcesEnumerator** resources) mut => VT.[Friend]GetResources(&this, resources);
}

[CRepr]struct IAppxBundleManifestPackageInfo2 : IUnknown
{
	public new const Guid IID = .(0x44c2acbc, 0xb2cf, 0x4ccb, 0xbb, 0xdb, 0x9c, 0x6d, 0xa8, 0xc3, 0xbc, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isPackageReference) GetIsPackageReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isNonQualifiedResourcePackage) GetIsNonQualifiedResourcePackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isDefaultApplicablePackage) GetIsDefaultApplicablePackage;
	}


	public HRESULT GetIsPackageReference(BOOL* isPackageReference) mut => VT.[Friend]GetIsPackageReference(&this, isPackageReference);

	public HRESULT GetIsNonQualifiedResourcePackage(BOOL* isNonQualifiedResourcePackage) mut => VT.[Friend]GetIsNonQualifiedResourcePackage(&this, isNonQualifiedResourcePackage);

	public HRESULT GetIsDefaultApplicablePackage(BOOL* isDefaultApplicablePackage) mut => VT.[Friend]GetIsDefaultApplicablePackage(&this, isDefaultApplicablePackage);
}

[CRepr]struct IAppxBundleManifestPackageInfo3 : IUnknown
{
	public new const Guid IID = .(0x6ba74b98, 0xbb74, 0x4296, 0x80, 0xd0, 0x5f, 0x42, 0x56, 0xa9, 0x96, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestTargetDeviceFamiliesEnumerator** targetDeviceFamilies) GetTargetDeviceFamilies;
	}


	public HRESULT GetTargetDeviceFamilies(IAppxManifestTargetDeviceFamiliesEnumerator** targetDeviceFamilies) mut => VT.[Friend]GetTargetDeviceFamilies(&this, targetDeviceFamilies);
}

[CRepr]struct IAppxBundleManifestPackageInfo4 : IUnknown
{
	public new const Guid IID = .(0x5da6f13d, 0xa8a7, 0x4532, 0x85, 0x7c, 0x13, 0x93, 0xd6, 0x59, 0x37, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* isStub) GetIsStub;
	}


	public HRESULT GetIsStub(BOOL* isStub) mut => VT.[Friend]GetIsStub(&this, isStub);
}

[CRepr]struct IAppxBundleManifestOptionalBundleInfoEnumerator : IUnknown
{
	public new const Guid IID = .(0x9a178793, 0xf97e, 0x46ac, 0xaa, 0xca, 0xdd, 0x5b, 0xa4, 0xc1, 0x77, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestOptionalBundleInfo** optionalBundle) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxBundleManifestOptionalBundleInfo** optionalBundle) mut => VT.[Friend]GetCurrent(&this, optionalBundle);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxBundleManifestOptionalBundleInfo : IUnknown
{
	public new const Guid IID = .(0x515bf2e8, 0xbcb0, 0x4d69, 0x8c, 0x48, 0xe3, 0x83, 0x14, 0x7b, 0x6e, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxManifestPackageId** packageId) GetPackageId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* fileName) GetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxBundleManifestPackageInfoEnumerator** packageInfoItems) GetPackageInfoItems;
	}


	public HRESULT GetPackageId(IAppxManifestPackageId** packageId) mut => VT.[Friend]GetPackageId(&this, packageId);

	public HRESULT GetFileName(PWSTR* fileName) mut => VT.[Friend]GetFileName(&this, fileName);

	public HRESULT GetPackageInfoItems(IAppxBundleManifestPackageInfoEnumerator** packageInfoItems) mut => VT.[Friend]GetPackageInfoItems(&this, packageInfoItems);
}

[CRepr]struct IAppxContentGroupFilesEnumerator : IUnknown
{
	public new const Guid IID = .(0x1a09a2fd, 0x7440, 0x44eb, 0x8c, 0x84, 0x84, 0x82, 0x05, 0xa6, 0xa1, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* file) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(PWSTR* file) mut => VT.[Friend]GetCurrent(&this, file);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxContentGroup : IUnknown
{
	public new const Guid IID = .(0x328f6468, 0xc04f, 0x4e3c, 0xb6, 0xfa, 0x6b, 0x8d, 0x27, 0xf3, 0x00, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* groupName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroupFilesEnumerator** enumerator) GetFiles;
	}


	public HRESULT GetName(PWSTR* groupName) mut => VT.[Friend]GetName(&this, groupName);

	public HRESULT GetFiles(IAppxContentGroupFilesEnumerator** enumerator) mut => VT.[Friend]GetFiles(&this, enumerator);
}

[CRepr]struct IAppxContentGroupsEnumerator : IUnknown
{
	public new const Guid IID = .(0x3264e477, 0x16d1, 0x4d63, 0x82, 0x3e, 0x7d, 0x29, 0x84, 0x69, 0x66, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroup** stream) GetCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasCurrent) GetHasCurrent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* hasNext) MoveNext;
	}


	public HRESULT GetCurrent(IAppxContentGroup** stream) mut => VT.[Friend]GetCurrent(&this, stream);

	public HRESULT GetHasCurrent(BOOL* hasCurrent) mut => VT.[Friend]GetHasCurrent(&this, hasCurrent);

	public HRESULT MoveNext(BOOL* hasNext) mut => VT.[Friend]MoveNext(&this, hasNext);
}

[CRepr]struct IAppxContentGroupMapReader : IUnknown
{
	public new const Guid IID = .(0x418726d8, 0xdd99, 0x4f5d, 0x98, 0x86, 0x15, 0x7a, 0xdd, 0x20, 0xde, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroup** requiredGroup) GetRequiredGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroupsEnumerator** automaticGroupsEnumerator) GetAutomaticGroups;
	}


	public HRESULT GetRequiredGroup(IAppxContentGroup** requiredGroup) mut => VT.[Friend]GetRequiredGroup(&this, requiredGroup);

	public HRESULT GetAutomaticGroups(IAppxContentGroupsEnumerator** automaticGroupsEnumerator) mut => VT.[Friend]GetAutomaticGroups(&this, automaticGroupsEnumerator);
}

[CRepr]struct IAppxSourceContentGroupMapReader : IUnknown
{
	public new const Guid IID = .(0xf329791d, 0x540b, 0x4a9f, 0xbc, 0x75, 0x32, 0x82, 0xb7, 0xd7, 0x31, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroup** requiredGroup) GetRequiredGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxContentGroupsEnumerator** automaticGroupsEnumerator) GetAutomaticGroups;
	}


	public HRESULT GetRequiredGroup(IAppxContentGroup** requiredGroup) mut => VT.[Friend]GetRequiredGroup(&this, requiredGroup);

	public HRESULT GetAutomaticGroups(IAppxContentGroupsEnumerator** automaticGroupsEnumerator) mut => VT.[Friend]GetAutomaticGroups(&this, automaticGroupsEnumerator);
}

[CRepr]struct IAppxContentGroupMapWriter : IUnknown
{
	public new const Guid IID = .(0xd07ab776, 0xa9de, 0x4798, 0x8c, 0x14, 0x3d, 0xb3, 0x1e, 0x68, 0x7c, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR groupName) AddAutomaticGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName) AddAutomaticFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT AddAutomaticGroup(PWSTR groupName) mut => VT.[Friend]AddAutomaticGroup(&this, groupName);

	public HRESULT AddAutomaticFile(PWSTR fileName) mut => VT.[Friend]AddAutomaticFile(&this, fileName);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IAppxPackagingDiagnosticEventSink : IUnknown
{
	public new const Guid IID = .(0x17239d47, 0x6adb, 0x45d2, 0x80, 0xf6, 0xf9, 0xcb, 0xc3, 0xbf, 0x05, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPX_PACKAGING_CONTEXT_CHANGE_TYPE changeType, int32 contextId, PSTR contextName, PWSTR contextMessage, PWSTR detailsMessage) ReportContextChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR errorMessage) ReportError;
	}


	public HRESULT ReportContextChange(APPX_PACKAGING_CONTEXT_CHANGE_TYPE changeType, int32 contextId, PSTR contextName, PWSTR contextMessage, PWSTR detailsMessage) mut => VT.[Friend]ReportContextChange(&this, changeType, contextId, contextName, contextMessage, detailsMessage);

	public HRESULT ReportError(PWSTR errorMessage) mut => VT.[Friend]ReportError(&this, errorMessage);
}

[CRepr]struct IAppxPackagingDiagnosticEventSinkManager : IUnknown
{
	public new const Guid IID = .(0x369648fa, 0xa7eb, 0x4909, 0xa1, 0x5d, 0x69, 0x54, 0xa0, 0x78, 0xf1, 0x8a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppxPackagingDiagnosticEventSink* sink) SetSinkForProcess;
	}


	public HRESULT SetSinkForProcess(IAppxPackagingDiagnosticEventSink* sink) mut => VT.[Friend]SetSinkForProcess(&this, sink);
}

[CRepr]struct IAppxEncryptionFactory : IUnknown
{
	public new const Guid IID = .(0x80e8e04d, 0x8c88, 0x44ae, 0xa0, 0x11, 0x7c, 0xad, 0xf6, 0xfb, 0x2e, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) EncryptPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_KEY_INFO* keyInfo) DecryptPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, IStream* manifestStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) CreateEncryptedPackageWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, APPX_KEY_INFO* keyInfo, IAppxPackageReader** packageReader) CreateEncryptedPackageReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) EncryptBundle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_KEY_INFO* keyInfo) DecryptBundle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, uint64 bundleVersion, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedBundleWriter** bundleWriter) CreateEncryptedBundleWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, APPX_KEY_INFO* keyInfo, IAppxBundleReader** bundleReader) CreateEncryptedBundleReader;
	}


	public HRESULT EncryptPackage(IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) mut => VT.[Friend]EncryptPackage(&this, inputStream, outputStream, settings, keyInfo, exemptedFiles);

	public HRESULT DecryptPackage(IStream* inputStream, IStream* outputStream, APPX_KEY_INFO* keyInfo) mut => VT.[Friend]DecryptPackage(&this, inputStream, outputStream, keyInfo);

	public HRESULT CreateEncryptedPackageWriter(IStream* outputStream, IStream* manifestStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) mut => VT.[Friend]CreateEncryptedPackageWriter(&this, outputStream, manifestStream, settings, keyInfo, exemptedFiles, packageWriter);

	public HRESULT CreateEncryptedPackageReader(IStream* inputStream, APPX_KEY_INFO* keyInfo, IAppxPackageReader** packageReader) mut => VT.[Friend]CreateEncryptedPackageReader(&this, inputStream, keyInfo, packageReader);

	public HRESULT EncryptBundle(IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) mut => VT.[Friend]EncryptBundle(&this, inputStream, outputStream, settings, keyInfo, exemptedFiles);

	public HRESULT DecryptBundle(IStream* inputStream, IStream* outputStream, APPX_KEY_INFO* keyInfo) mut => VT.[Friend]DecryptBundle(&this, inputStream, outputStream, keyInfo);

	public HRESULT CreateEncryptedBundleWriter(IStream* outputStream, uint64 bundleVersion, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedBundleWriter** bundleWriter) mut => VT.[Friend]CreateEncryptedBundleWriter(&this, outputStream, bundleVersion, settings, keyInfo, exemptedFiles, bundleWriter);

	public HRESULT CreateEncryptedBundleReader(IStream* inputStream, APPX_KEY_INFO* keyInfo, IAppxBundleReader** bundleReader) mut => VT.[Friend]CreateEncryptedBundleReader(&this, inputStream, keyInfo, bundleReader);
}

[CRepr]struct IAppxEncryptionFactory2 : IUnknown
{
	public new const Guid IID = .(0xc1b11eee, 0xc4ba, 0x4ab2, 0xa5, 0x5d, 0xd0, 0x15, 0xfe, 0x8f, 0xf6, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, IStream* manifestStream, IStream* contentGroupMapStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) CreateEncryptedPackageWriter;
	}


	public HRESULT CreateEncryptedPackageWriter(IStream* outputStream, IStream* manifestStream, IStream* contentGroupMapStream, APPX_ENCRYPTED_PACKAGE_SETTINGS* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) mut => VT.[Friend]CreateEncryptedPackageWriter(&this, outputStream, manifestStream, contentGroupMapStream, settings, keyInfo, exemptedFiles, packageWriter);
}

[CRepr]struct IAppxEncryptionFactory3 : IUnknown
{
	public new const Guid IID = .(0x09edca37, 0xcd64, 0x47d6, 0xb7, 0xe8, 0x1c, 0xb1, 0x1d, 0x4f, 0x7e, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) EncryptPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, IStream* manifestStream, IStream* contentGroupMapStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) CreateEncryptedPackageWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) EncryptBundle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* outputStream, uint64 bundleVersion, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedBundleWriter** bundleWriter) CreateEncryptedBundleWriter;
	}


	public HRESULT EncryptPackage(IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) mut => VT.[Friend]EncryptPackage(&this, inputStream, outputStream, settings, keyInfo, exemptedFiles);

	public HRESULT CreateEncryptedPackageWriter(IStream* outputStream, IStream* manifestStream, IStream* contentGroupMapStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedPackageWriter** packageWriter) mut => VT.[Friend]CreateEncryptedPackageWriter(&this, outputStream, manifestStream, contentGroupMapStream, settings, keyInfo, exemptedFiles, packageWriter);

	public HRESULT EncryptBundle(IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles) mut => VT.[Friend]EncryptBundle(&this, inputStream, outputStream, settings, keyInfo, exemptedFiles);

	public HRESULT CreateEncryptedBundleWriter(IStream* outputStream, uint64 bundleVersion, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, IAppxEncryptedBundleWriter** bundleWriter) mut => VT.[Friend]CreateEncryptedBundleWriter(&this, outputStream, bundleVersion, settings, keyInfo, exemptedFiles, bundleWriter);
}

[CRepr]struct IAppxEncryptionFactory4 : IUnknown
{
	public new const Guid IID = .(0xa879611f, 0x12fd, 0x41fe, 0x85, 0xd5, 0x06, 0xae, 0x77, 0x9b, 0xba, 0xf5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, uint64 memoryLimit) EncryptPackage;
	}


	public HRESULT EncryptPackage(IStream* inputStream, IStream* outputStream, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo, APPX_ENCRYPTED_EXEMPTIONS* exemptedFiles, uint64 memoryLimit) mut => VT.[Friend]EncryptPackage(&this, inputStream, outputStream, settings, keyInfo, exemptedFiles, memoryLimit);
}

[CRepr]struct IAppxEncryptedPackageWriter : IUnknown
{
	public new const Guid IID = .(0xf43d0b0b, 0x1379, 0x40e2, 0x9b, 0x29, 0x68, 0x2e, 0xa2, 0xbf, 0x42, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, APPX_COMPRESSION_OPTION compressionOption, IStream* inputStream) AddPayloadFileEncrypted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT AddPayloadFileEncrypted(PWSTR fileName, APPX_COMPRESSION_OPTION compressionOption, IStream* inputStream) mut => VT.[Friend]AddPayloadFileEncrypted(&this, fileName, compressionOption, inputStream);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IAppxEncryptedPackageWriter2 : IUnknown
{
	public new const Guid IID = .(0x3e475447, 0x3a25, 0x40b5, 0x8a, 0xd2, 0xf9, 0x53, 0xae, 0x50, 0xc9, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fileCount, APPX_PACKAGE_WRITER_PAYLOAD_STREAM* payloadFiles, uint64 memoryLimit) AddPayloadFilesEncrypted;
	}


	public HRESULT AddPayloadFilesEncrypted(uint32 fileCount, APPX_PACKAGE_WRITER_PAYLOAD_STREAM* payloadFiles, uint64 memoryLimit) mut => VT.[Friend]AddPayloadFilesEncrypted(&this, fileCount, payloadFiles, memoryLimit);
}

[CRepr]struct IAppxEncryptedBundleWriter : IUnknown
{
	public new const Guid IID = .(0x80b0902f, 0x7bf0, 0x4117, 0xb8, 0xc6, 0x42, 0x79, 0xef, 0x81, 0xee, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* packageStream) AddPayloadPackageEncrypted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
	}


	public HRESULT AddPayloadPackageEncrypted(PWSTR fileName, IStream* packageStream) mut => VT.[Friend]AddPayloadPackageEncrypted(&this, fileName, packageStream);

	public HRESULT Close() mut => VT.[Friend]Close(&this);
}

[CRepr]struct IAppxEncryptedBundleWriter2 : IUnknown
{
	public new const Guid IID = .(0xe644be82, 0xf0fa, 0x42b8, 0xa9, 0x56, 0x8d, 0x1c, 0xb4, 0x8e, 0xe3, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream) AddExternalPackageReference;
	}


	public HRESULT AddExternalPackageReference(PWSTR fileName, IStream* inputStream) mut => VT.[Friend]AddExternalPackageReference(&this, fileName, inputStream);
}

[CRepr]struct IAppxEncryptedBundleWriter3 : IUnknown
{
	public new const Guid IID = .(0x0d34deb3, 0x5cae, 0x4dd3, 0x97, 0x7c, 0x50, 0x49, 0x32, 0xa5, 0x1d, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* packageStream, BOOL isDefaultApplicablePackage) AddPayloadPackageEncrypted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) AddExternalPackageReference;
	}


	public HRESULT AddPayloadPackageEncrypted(PWSTR fileName, IStream* packageStream, BOOL isDefaultApplicablePackage) mut => VT.[Friend]AddPayloadPackageEncrypted(&this, fileName, packageStream, isDefaultApplicablePackage);

	public HRESULT AddExternalPackageReference(PWSTR fileName, IStream* inputStream, BOOL isDefaultApplicablePackage) mut => VT.[Friend]AddExternalPackageReference(&this, fileName, inputStream, isDefaultApplicablePackage);
}

[CRepr]struct IAppxPackageEditor : IUnknown
{
	public new const Guid IID = .(0xe2adb6dc, 0x5e71, 0x4416, 0x86, 0xb6, 0x86, 0xe5, 0xf5, 0x29, 0x1a, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR workingDirectory) SetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* updatedPackageStream, IStream* baselinePackageStream, IStream* deltaPackageStream) CreateDeltaPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* updatedPackageStream, IStream* baselineBlockMapStream, PWSTR baselinePackageFullName, IStream* deltaPackageStream) CreateDeltaPackageUsingBaselineBlockMap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* baselinePackageStream, IStream* deltaPackageStream, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION updateOption) UpdatePackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* baselineEncryptedPackageStream, IStream* deltaPackageStream, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION updateOption, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo) UpdateEncryptedPackage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* packageStream, IStream* updatedManifestStream, BOOL isPackageEncrypted, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTIONS options) UpdatePackageManifest;
	}


	public HRESULT SetWorkingDirectory(PWSTR workingDirectory) mut => VT.[Friend]SetWorkingDirectory(&this, workingDirectory);

	public HRESULT CreateDeltaPackage(IStream* updatedPackageStream, IStream* baselinePackageStream, IStream* deltaPackageStream) mut => VT.[Friend]CreateDeltaPackage(&this, updatedPackageStream, baselinePackageStream, deltaPackageStream);

	public HRESULT CreateDeltaPackageUsingBaselineBlockMap(IStream* updatedPackageStream, IStream* baselineBlockMapStream, PWSTR baselinePackageFullName, IStream* deltaPackageStream) mut => VT.[Friend]CreateDeltaPackageUsingBaselineBlockMap(&this, updatedPackageStream, baselineBlockMapStream, baselinePackageFullName, deltaPackageStream);

	public HRESULT UpdatePackage(IStream* baselinePackageStream, IStream* deltaPackageStream, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION updateOption) mut => VT.[Friend]UpdatePackage(&this, baselinePackageStream, deltaPackageStream, updateOption);

	public HRESULT UpdateEncryptedPackage(IStream* baselineEncryptedPackageStream, IStream* deltaPackageStream, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_OPTION updateOption, APPX_ENCRYPTED_PACKAGE_SETTINGS2* settings, APPX_KEY_INFO* keyInfo) mut => VT.[Friend]UpdateEncryptedPackage(&this, baselineEncryptedPackageStream, deltaPackageStream, updateOption, settings, keyInfo);

	public HRESULT UpdatePackageManifest(IStream* packageStream, IStream* updatedManifestStream, BOOL isPackageEncrypted, APPX_PACKAGE_EDITOR_UPDATE_PACKAGE_MANIFEST_OPTIONS options) mut => VT.[Friend]UpdatePackageManifest(&this, packageStream, updatedManifestStream, isPackageEncrypted, options);
}

#endregion

#region Functions
public static
{
	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackageId(uint32* bufferLength, uint8* buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackageFullName(uint32* packageFullNameLength, char16* packageFullName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackageFamilyName(uint32* packageFamilyNameLength, char16* packageFamilyName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackagePath(uint32* pathLength, char16* path);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageId(HANDLE hProcess, uint32* bufferLength, uint8* buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageFullName(HANDLE hProcess, uint32* packageFullNameLength, char16* packageFullName);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageFullNameFromToken(HANDLE token, uint32* packageFullNameLength, char16* packageFullName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageFamilyName(HANDLE hProcess, uint32* packageFamilyNameLength, char16* packageFamilyName);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageFamilyNameFromToken(HANDLE token, uint32* packageFamilyNameLength, char16* packageFamilyName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackagePath(PACKAGE_ID* packageId, uint32 reserved, uint32* pathLength, char16* path);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackagePathByFullName(PWSTR packageFullName, uint32* pathLength, char16* path);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetStagedPackagePathByFullName(PWSTR packageFullName, uint32* pathLength, char16* path);

	[Import("api-ms-win-appmodel-runtime-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackagePathByFullName2(PWSTR packageFullName, PackagePathType packagePathType, uint32* pathLength, char16* path);

	[Import("api-ms-win-appmodel-runtime-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetStagedPackagePathByFullName2(PWSTR packageFullName, PackagePathType packagePathType, uint32* pathLength, char16* path);

	[Import("api-ms-win-appmodel-runtime-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackageInfo2(uint32 flags, PackagePathType packagePathType, uint32* bufferLength, uint8* buffer, uint32* count);

	[Import("api-ms-win-appmodel-runtime-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackagePath2(PackagePathType packagePathType, uint32* pathLength, char16* path);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentApplicationUserModelId(uint32* applicationUserModelIdLength, char16* applicationUserModelId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetApplicationUserModelId(HANDLE hProcess, uint32* applicationUserModelIdLength, char16* applicationUserModelId);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetApplicationUserModelIdFromToken(HANDLE token, uint32* applicationUserModelIdLength, char16* applicationUserModelId);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR VerifyPackageFullName(PWSTR packageFullName);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR VerifyPackageFamilyName(PWSTR packageFamilyName);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR VerifyPackageId(PACKAGE_ID* packageId);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR VerifyApplicationUserModelId(PWSTR applicationUserModelId);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR VerifyPackageRelativeApplicationId(PWSTR packageRelativeApplicationId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR PackageIdFromFullName(PWSTR packageFullName, uint32 flags, uint32* bufferLength, uint8* buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR PackageFullNameFromId(PACKAGE_ID* packageId, uint32* packageFullNameLength, char16* packageFullName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR PackageFamilyNameFromId(PACKAGE_ID* packageId, uint32* packageFamilyNameLength, char16* packageFamilyName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR PackageFamilyNameFromFullName(PWSTR packageFullName, uint32* packageFamilyNameLength, char16* packageFamilyName);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR PackageNameAndPublisherIdFromFamilyName(PWSTR packageFamilyName, uint32* packageNameLength, char16* packageName, uint32* packagePublisherIdLength, char16* packagePublisherId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR FormatApplicationUserModelId(PWSTR packageFamilyName, PWSTR packageRelativeApplicationId, uint32* applicationUserModelIdLength, char16* applicationUserModelId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ParseApplicationUserModelId(PWSTR applicationUserModelId, uint32* packageFamilyNameLength, char16* packageFamilyName, uint32* packageRelativeApplicationIdLength, char16* packageRelativeApplicationId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackagesByPackageFamily(PWSTR packageFamilyName, uint32* count, PWSTR* packageFullNames, uint32* bufferLength, char16* buffer);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR FindPackagesByPackageFamily(PWSTR packageFamilyName, uint32 packageFilters, uint32* count, PWSTR* packageFullNames, uint32* bufferLength, char16* buffer, uint32* packageProperties);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetStagedPackageOrigin(PWSTR packageFullName, PackageOrigin* origin);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetCurrentPackageInfo(uint32 flags, uint32* bufferLength, uint8* buffer, uint32* count);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR OpenPackageInfoByFullName(PWSTR packageFullName, uint32 reserved, _PACKAGE_INFO_REFERENCE** packageInfoReference);

	[Import("api-ms-win-appmodel-runtime-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR OpenPackageInfoByFullNameForUser(PSID userSid, PWSTR packageFullName, uint32 reserved, _PACKAGE_INFO_REFERENCE** packageInfoReference);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR ClosePackageInfo(_PACKAGE_INFO_REFERENCE* packageInfoReference);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageInfo(_PACKAGE_INFO_REFERENCE* packageInfoReference, uint32 flags, uint32* bufferLength, uint8* buffer, uint32* count);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageApplicationIds(_PACKAGE_INFO_REFERENCE* packageInfoReference, uint32* bufferLength, uint8* buffer, uint32* count);

	[Import("api-ms-win-appmodel-runtime-l1-1-3.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR GetPackageInfo2(_PACKAGE_INFO_REFERENCE* packageInfoReference, uint32 flags, PackagePathType packagePathType, uint32* bufferLength, uint8* buffer, uint32* count);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CheckIsMSIXPackage(PWSTR packageFullName, BOOL* isMSIXPackage);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT TryCreatePackageDependency(PSID user, PWSTR packageFamilyName, PACKAGE_VERSION minVersion, PackageDependencyProcessorArchitectures packageDependencyProcessorArchitectures, PackageDependencyLifetimeKind lifetimeKind, PWSTR lifetimeArtifact, CreatePackageDependencyOptions options, PWSTR* packageDependencyId);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DeletePackageDependency(PWSTR packageDependencyId);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AddPackageDependency(PWSTR packageDependencyId, int32 rank, AddPackageDependencyOptions options, PACKAGEDEPENDENCY_CONTEXT__** packageDependencyContext, PWSTR* packageFullName);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RemovePackageDependency(PACKAGEDEPENDENCY_CONTEXT__* packageDependencyContext);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetResolvedPackageFullNameForPackageDependency(PWSTR packageDependencyId, PWSTR* packageFullName);

	[Import("KERNELBASE.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetIdForPackageDependencyContext(PACKAGEDEPENDENCY_CONTEXT__* packageDependencyContext, PWSTR* packageDependencyId);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetLifecycleManagement(HANDLE processToken, AppPolicyLifecycleManagement* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetWindowingModel(HANDLE processToken, AppPolicyWindowingModel* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetMediaFoundationCodecLoading(HANDLE processToken, AppPolicyMediaFoundationCodecLoading* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetClrCompat(HANDLE processToken, AppPolicyClrCompat* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetThreadInitializationType(HANDLE processToken, AppPolicyThreadInitializationType* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetShowDeveloperDiagnostic(HANDLE processToken, AppPolicyShowDeveloperDiagnostic* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetProcessTerminationMethod(HANDLE processToken, AppPolicyProcessTerminationMethod* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR AppPolicyGetCreateFileAccess(HANDLE processToken, AppPolicyCreateFileAccess* policy);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreatePackageVirtualizationContext(PWSTR packageFamilyName, PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__** context);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ActivatePackageVirtualizationContext(PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__* context, uint* cookie);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ReleasePackageVirtualizationContext(PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__* context);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DeactivatePackageVirtualizationContext(uint cookie);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DuplicatePackageVirtualizationContext(PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__* sourceContext, PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__** destContext);

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PACKAGE_VIRTUALIZATION_CONTEXT_HANDLE__* GetCurrentPackageVirtualizationContext();

	[Import("KERNEL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetProcessesInVirtualizationContext(PWSTR packageFamilyName, uint32* count, HANDLE** processes);

}
#endregion
