using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.ServerBackup;

#region Constants
public static
{
	public const uint32 WSB_MAX_OB_STATUS_VALUE_TYPE_PAIR = 5;
	public const uint32 WSB_MAX_OB_STATUS_ENTRY = 5;
	public const HRESULT WSBAPP_ASYNC_IN_PROGRESS = 7995396;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WSB_OB_STATUS_ENTRY_PAIR_TYPE : int32
{
	WSB_OB_ET_UNDEFINED = 0,
	WSB_OB_ET_STRING = 1,
	WSB_OB_ET_NUMBER = 2,
	WSB_OB_ET_DATETIME = 3,
	WSB_OB_ET_TIME = 4,
	WSB_OB_ET_SIZE = 5,
	WSB_OB_ET_MAX = 6,
}

#endregion


#region Structs
[CRepr]
public struct WSB_OB_STATUS_ENTRY_VALUE_TYPE_PAIR
{
	public PWSTR m_wszObStatusEntryPairValue;
	public WSB_OB_STATUS_ENTRY_PAIR_TYPE m_ObStatusEntryPairType;
}

[CRepr]
public struct WSB_OB_STATUS_ENTRY
{
	public uint32 m_dwIcon;
	public uint32 m_dwStatusEntryName;
	public uint32 m_dwStatusEntryValue;
	public uint32 m_cValueTypePair;
	public WSB_OB_STATUS_ENTRY_VALUE_TYPE_PAIR* m_rgValueTypePair;
}

[CRepr]
public struct WSB_OB_STATUS_INFO
{
	public Guid m_guidSnapinId;
	public uint32 m_cStatusEntry;
	public WSB_OB_STATUS_ENTRY* m_rgStatusEntry;
}

[CRepr]
public struct WSB_OB_REGISTRATION_INFO
{
	public PWSTR m_wszResourceDLL;
	public Guid m_guidSnapinId;
	public uint32 m_dwProviderName;
	public uint32 m_dwProviderIcon;
	public BOOLEAN m_bSupportsRemoting;
}

#endregion

#region COM Types
[CRepr]struct IWsbApplicationBackupSupport : IUnknown
{
	public new const Guid IID = .(0x1eff3510, 0x4a27, 0x46ad, 0xb9, 0xe0, 0x08, 0x33, 0x2f, 0x0f, 0x4f, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, uint32 cVolumes, PWSTR* rgwszSourceVolumePath, PWSTR* rgwszSnapshotVolumePath, IWsbApplicationAsync** ppAsync) CheckConsistency;
	}


	public HRESULT CheckConsistency(PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, uint32 cVolumes, PWSTR* rgwszSourceVolumePath, PWSTR* rgwszSnapshotVolumePath, IWsbApplicationAsync** ppAsync) mut => VT.[Friend]CheckConsistency(&this, wszWriterMetadata, wszComponentName, wszComponentLogicalPath, cVolumes, rgwszSourceVolumePath, rgwszSnapshotVolumePath, ppAsync);
}

[CRepr]struct IWsbApplicationRestoreSupport : IUnknown
{
	public new const Guid IID = .(0x8d3bdb38, 0x4ee8, 0x4718, 0x85, 0xf9, 0xc7, 0xdb, 0xc4, 0xab, 0x77, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, BOOLEAN bNoRollForward) PreRestore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, BOOLEAN bNoRollForward) PostRestore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cComponents, PWSTR* rgComponentName, PWSTR* rgComponentLogicalPaths, PWSTR** prgComponentName, PWSTR** prgComponentLogicalPath) OrderComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbRollForwardSupported) IsRollForwardSupported;
	}


	public HRESULT PreRestore(PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, BOOLEAN bNoRollForward) mut => VT.[Friend]PreRestore(&this, wszWriterMetadata, wszComponentName, wszComponentLogicalPath, bNoRollForward);

	public HRESULT PostRestore(PWSTR wszWriterMetadata, PWSTR wszComponentName, PWSTR wszComponentLogicalPath, BOOLEAN bNoRollForward) mut => VT.[Friend]PostRestore(&this, wszWriterMetadata, wszComponentName, wszComponentLogicalPath, bNoRollForward);

	public HRESULT OrderComponents(uint32 cComponents, PWSTR* rgComponentName, PWSTR* rgComponentLogicalPaths, PWSTR** prgComponentName, PWSTR** prgComponentLogicalPath) mut => VT.[Friend]OrderComponents(&this, cComponents, rgComponentName, rgComponentLogicalPaths, prgComponentName, prgComponentLogicalPath);

	public HRESULT IsRollForwardSupported(uint8* pbRollForwardSupported) mut => VT.[Friend]IsRollForwardSupported(&this, pbRollForwardSupported);
}

[CRepr]struct IWsbApplicationAsync : IUnknown
{
	public new const Guid IID = .(0x0843f6f7, 0x895c, 0x44a6, 0xb0, 0xc2, 0x05, 0xa5, 0x02, 0x2a, 0xa3, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrResult) QueryStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
	}


	public HRESULT QueryStatus(HRESULT* phrResult) mut => VT.[Friend]QueryStatus(&this, phrResult);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);
}

#endregion
