using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com;
using Win32.Foundation;
using Win32.Media.Audio;
using Win32.Media.KernelStreaming;
using Win32.Media.Audio.Apo;
using System;

namespace Win32.Media.Audio.Endpoints;

#region Constants
public static
{
	public const PROPERTYKEY DEVPKEY_AudioEndpointPlugin_FactoryCLSID = .(.(0x12d83bd7, 0xcf12, 0x46be, 0x85, 0x40, 0x81, 0x27, 0x10, 0xd3, 0x02, 0x1c), 1);
	public const PROPERTYKEY DEVPKEY_AudioEndpointPlugin_DataFlow = .(.(0x12d83bd7, 0xcf12, 0x46be, 0x85, 0x40, 0x81, 0x27, 0x10, 0xd3, 0x02, 0x1c), 2);
	public const PROPERTYKEY DEVPKEY_AudioEndpointPlugin_PnPInterface = .(.(0x12d83bd7, 0xcf12, 0x46be, 0x85, 0x40, 0x81, 0x27, 0x10, 0xd3, 0x02, 0x1c), 3);
	public const PROPERTYKEY DEVPKEY_AudioEndpointPlugin2_FactoryCLSID = .(.(0x12d83bd7, 0xcf12, 0x46be, 0x85, 0x40, 0x81, 0x27, 0x10, 0xd3, 0x02, 0x1c), 4);
}
#endregion

#region Enums

[AllowDuplicates]
public enum EndpointConnectorType : int32
{
	eHostProcessConnector = 0,
	eOffloadConnector = 1,
	eLoopbackConnector = 2,
	eKeywordDetectorConnector = 3,
	eConnectorCount = 4,
}

#endregion


#region Structs
[CRepr]
public struct AUDIO_ENDPOINT_SHARED_CREATE_PARAMS
{
	public uint32 u32Size;
	public uint32 u32TSSessionId;
	public EndpointConnectorType targetEndpointConnectorType;
	public WAVEFORMATEX wfxDeviceFormat;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_DEVINTERFACE_AUDIOENDPOINTPLUGIN = .(0x9f2f7b66, 0x65ac, 0x4fa6, 0x8a, 0xe4, 0x12, 0x3c, 0x78, 0xb8, 0x93, 0x13);


}
#endregion

#region COM Types
[CRepr]struct IAudioEndpointFormatControl : IUnknown
{
	public new const Guid IID = .(0x784cfd40, 0x9f89, 0x456e, 0xa1, 0xa6, 0x87, 0x3b, 0x00, 0x6a, 0x66, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ResetFlags) ResetToDefault;
	}


	public HRESULT ResetToDefault(uint32 ResetFlags) mut => VT.[Friend]ResetToDefault(&this, ResetFlags);
}

[CRepr]struct IAudioEndpointOffloadStreamVolume : IUnknown
{
	public new const Guid IID = .(0x64f1dd49, 0x71ca, 0x4281, 0x86, 0x72, 0x3a, 0x9e, 0xdd, 0xd1, 0xd0, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pu32ChannelCount) GetVolumeChannelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 u32ChannelCount, float* pf32Volumes, AUDIO_CURVE_TYPE u32CurveType, int64* pCurveDuration) SetChannelVolumes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 u32ChannelCount, float* pf32Volumes) GetChannelVolumes;
	}


	public HRESULT GetVolumeChannelCount(uint32* pu32ChannelCount) mut => VT.[Friend]GetVolumeChannelCount(&this, pu32ChannelCount);

	public HRESULT SetChannelVolumes(uint32 u32ChannelCount, float* pf32Volumes, AUDIO_CURVE_TYPE u32CurveType, int64* pCurveDuration) mut => VT.[Friend]SetChannelVolumes(&this, u32ChannelCount, pf32Volumes, u32CurveType, pCurveDuration);

	public HRESULT GetChannelVolumes(uint32 u32ChannelCount, float* pf32Volumes) mut => VT.[Friend]GetChannelVolumes(&this, u32ChannelCount, pf32Volumes);
}

[CRepr]struct IAudioEndpointOffloadStreamMute : IUnknown
{
	public new const Guid IID = .(0xdfe21355, 0x5ec2, 0x40e0, 0x8d, 0x6b, 0x71, 0x0a, 0xc3, 0xc0, 0x02, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8 bMuted) SetMute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbMuted) GetMute;
	}


	public HRESULT SetMute(uint8 bMuted) mut => VT.[Friend]SetMute(&this, bMuted);

	public HRESULT GetMute(uint8* pbMuted) mut => VT.[Friend]GetMute(&this, pbMuted);
}

[CRepr]struct IAudioEndpointOffloadStreamMeter : IUnknown
{
	public new const Guid IID = .(0xe1546dce, 0x9dd1, 0x418b, 0x9a, 0xb2, 0x34, 0x8c, 0xed, 0x16, 0x1c, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pu32ChannelCount) GetMeterChannelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 u32ChannelCount, float* pf32PeakValues) GetMeteringData;
	}


	public HRESULT GetMeterChannelCount(uint32* pu32ChannelCount) mut => VT.[Friend]GetMeterChannelCount(&this, pu32ChannelCount);

	public HRESULT GetMeteringData(uint32 u32ChannelCount, float* pf32PeakValues) mut => VT.[Friend]GetMeteringData(&this, u32ChannelCount, pf32PeakValues);
}

[CRepr]struct IAudioEndpointLastBufferControl : IUnknown
{
	public new const Guid IID = .(0xf8520dd3, 0x8f9d, 0x4437, 0x98, 0x61, 0x62, 0xf5, 0x84, 0xc3, 0x3d, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsLastBufferControlSupported;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, APO_CONNECTION_PROPERTY* pConnectionProperty) ReleaseOutputDataPointerForLastBuffer;
	}


	public BOOL IsLastBufferControlSupported() mut => VT.[Friend]IsLastBufferControlSupported(&this);

	public void ReleaseOutputDataPointerForLastBuffer(APO_CONNECTION_PROPERTY* pConnectionProperty) mut => VT.[Friend]ReleaseOutputDataPointerForLastBuffer(&this, pConnectionProperty);
}

[CRepr]struct IAudioLfxControl : IUnknown
{
	public new const Guid IID = .(0x076a6922, 0xd802, 0x4f83, 0xba, 0xf6, 0x40, 0x9d, 0x9c, 0xa1, 0x1b, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bEnabled) SetLocalEffectsState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbEnabled) GetLocalEffectsState;
	}


	public HRESULT SetLocalEffectsState(BOOL bEnabled) mut => VT.[Friend]SetLocalEffectsState(&this, bEnabled);

	public HRESULT GetLocalEffectsState(BOOL* pbEnabled) mut => VT.[Friend]GetLocalEffectsState(&this, pbEnabled);
}

[CRepr]struct IHardwareAudioEngineBase : IUnknown
{
	public new const Guid IID = .(0xeddce3e4, 0xf3c1, 0x453a, 0xb4, 0x61, 0x22, 0x35, 0x63, 0xcb, 0xd8, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR _pwstrDeviceId, uint32 _uConnectorId, uint32* _pAvailableConnectorInstanceCount) GetAvailableOffloadConnectorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMMDevice* pDevice, BOOL _bRequestDeviceFormat, WAVEFORMATEX** _ppwfxFormat) GetEngineFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMMDevice* pDevice, WAVEFORMATEX* _pwfxFormat) SetEngineDeviceFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMMDevice* pDevice, BOOL _bEnable) SetGfxState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMMDevice* pDevice, BOOL* _pbEnable) GetGfxState;
	}


	public HRESULT GetAvailableOffloadConnectorCount(PWSTR _pwstrDeviceId, uint32 _uConnectorId, uint32* _pAvailableConnectorInstanceCount) mut => VT.[Friend]GetAvailableOffloadConnectorCount(&this, _pwstrDeviceId, _uConnectorId, _pAvailableConnectorInstanceCount);

	public HRESULT GetEngineFormat(IMMDevice* pDevice, BOOL _bRequestDeviceFormat, WAVEFORMATEX** _ppwfxFormat) mut => VT.[Friend]GetEngineFormat(&this, pDevice, _bRequestDeviceFormat, _ppwfxFormat);

	public HRESULT SetEngineDeviceFormat(IMMDevice* pDevice, WAVEFORMATEX* _pwfxFormat) mut => VT.[Friend]SetEngineDeviceFormat(&this, pDevice, _pwfxFormat);

	public HRESULT SetGfxState(IMMDevice* pDevice, BOOL _bEnable) mut => VT.[Friend]SetGfxState(&this, pDevice, _bEnable);

	public HRESULT GetGfxState(IMMDevice* pDevice, BOOL* _pbEnable) mut => VT.[Friend]GetGfxState(&this, pDevice, _pbEnable);
}

[CRepr]struct IAudioEndpointVolumeCallback : IUnknown
{
	public new const Guid IID = .(0x657804fa, 0xd6ad, 0x4496, 0x8a, 0x60, 0x35, 0x27, 0x52, 0xaf, 0x4f, 0x89);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AUDIO_VOLUME_NOTIFICATION_DATA* pNotify) OnNotify;
	}


	public HRESULT OnNotify(AUDIO_VOLUME_NOTIFICATION_DATA* pNotify) mut => VT.[Friend]OnNotify(&this, pNotify);
}

[CRepr]struct IAudioEndpointVolume : IUnknown
{
	public new const Guid IID = .(0x5cdf2c82, 0x841e, 0x4546, 0x97, 0x22, 0x0c, 0xf7, 0x40, 0x78, 0x22, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAudioEndpointVolumeCallback* pNotify) RegisterControlChangeNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAudioEndpointVolumeCallback* pNotify) UnregisterControlChangeNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnChannelCount) GetChannelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float fLevelDB, in Guid pguidEventContext) SetMasterVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float fLevel, in Guid pguidEventContext) SetMasterVolumeLevelScalar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pfLevelDB) GetMasterVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pfLevel) GetMasterVolumeLevelScalar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nChannel, float fLevelDB, in Guid pguidEventContext) SetChannelVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nChannel, float fLevel, in Guid pguidEventContext) SetChannelVolumeLevelScalar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nChannel, float* pfLevelDB) GetChannelVolumeLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nChannel, float* pfLevel) GetChannelVolumeLevelScalar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMute, in Guid pguidEventContext) SetMute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbMute) GetMute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnStep, uint32* pnStepCount) GetVolumeStepInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidEventContext) VolumeStepUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidEventContext) VolumeStepDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwHardwareSupportMask) QueryHardwareSupport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pflVolumeMindB, float* pflVolumeMaxdB, float* pflVolumeIncrementdB) GetVolumeRange;
	}


	public HRESULT RegisterControlChangeNotify(IAudioEndpointVolumeCallback* pNotify) mut => VT.[Friend]RegisterControlChangeNotify(&this, pNotify);

	public HRESULT UnregisterControlChangeNotify(IAudioEndpointVolumeCallback* pNotify) mut => VT.[Friend]UnregisterControlChangeNotify(&this, pNotify);

	public HRESULT GetChannelCount(uint32* pnChannelCount) mut => VT.[Friend]GetChannelCount(&this, pnChannelCount);

	public HRESULT SetMasterVolumeLevel(float fLevelDB, in Guid pguidEventContext) mut => VT.[Friend]SetMasterVolumeLevel(&this, fLevelDB, pguidEventContext);

	public HRESULT SetMasterVolumeLevelScalar(float fLevel, in Guid pguidEventContext) mut => VT.[Friend]SetMasterVolumeLevelScalar(&this, fLevel, pguidEventContext);

	public HRESULT GetMasterVolumeLevel(float* pfLevelDB) mut => VT.[Friend]GetMasterVolumeLevel(&this, pfLevelDB);

	public HRESULT GetMasterVolumeLevelScalar(float* pfLevel) mut => VT.[Friend]GetMasterVolumeLevelScalar(&this, pfLevel);

	public HRESULT SetChannelVolumeLevel(uint32 nChannel, float fLevelDB, in Guid pguidEventContext) mut => VT.[Friend]SetChannelVolumeLevel(&this, nChannel, fLevelDB, pguidEventContext);

	public HRESULT SetChannelVolumeLevelScalar(uint32 nChannel, float fLevel, in Guid pguidEventContext) mut => VT.[Friend]SetChannelVolumeLevelScalar(&this, nChannel, fLevel, pguidEventContext);

	public HRESULT GetChannelVolumeLevel(uint32 nChannel, float* pfLevelDB) mut => VT.[Friend]GetChannelVolumeLevel(&this, nChannel, pfLevelDB);

	public HRESULT GetChannelVolumeLevelScalar(uint32 nChannel, float* pfLevel) mut => VT.[Friend]GetChannelVolumeLevelScalar(&this, nChannel, pfLevel);

	public HRESULT SetMute(BOOL bMute, in Guid pguidEventContext) mut => VT.[Friend]SetMute(&this, bMute, pguidEventContext);

	public HRESULT GetMute(BOOL* pbMute) mut => VT.[Friend]GetMute(&this, pbMute);

	public HRESULT GetVolumeStepInfo(uint32* pnStep, uint32* pnStepCount) mut => VT.[Friend]GetVolumeStepInfo(&this, pnStep, pnStepCount);

	public HRESULT VolumeStepUp(in Guid pguidEventContext) mut => VT.[Friend]VolumeStepUp(&this, pguidEventContext);

	public HRESULT VolumeStepDown(in Guid pguidEventContext) mut => VT.[Friend]VolumeStepDown(&this, pguidEventContext);

	public HRESULT QueryHardwareSupport(uint32* pdwHardwareSupportMask) mut => VT.[Friend]QueryHardwareSupport(&this, pdwHardwareSupportMask);

	public HRESULT GetVolumeRange(float* pflVolumeMindB, float* pflVolumeMaxdB, float* pflVolumeIncrementdB) mut => VT.[Friend]GetVolumeRange(&this, pflVolumeMindB, pflVolumeMaxdB, pflVolumeIncrementdB);
}

[CRepr]struct IAudioEndpointVolumeEx : IAudioEndpointVolume
{
	public new const Guid IID = .(0x66e11784, 0xf695, 0x4f28, 0xa5, 0x05, 0xa7, 0x08, 0x00, 0x81, 0xa7, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAudioEndpointVolume.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iChannel, float* pflVolumeMindB, float* pflVolumeMaxdB, float* pflVolumeIncrementdB) GetVolumeRangeChannel;
	}


	public HRESULT GetVolumeRangeChannel(uint32 iChannel, float* pflVolumeMindB, float* pflVolumeMaxdB, float* pflVolumeIncrementdB) mut => VT.[Friend]GetVolumeRangeChannel(&this, iChannel, pflVolumeMindB, pflVolumeMaxdB, pflVolumeIncrementdB);
}

[CRepr]struct IAudioMeterInformation : IUnknown
{
	public new const Guid IID = .(0xc02216f6, 0x8c67, 0x4b5b, 0x9d, 0x00, 0xd0, 0x08, 0xe7, 0x3e, 0x00, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, float* pfPeak) GetPeakValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnChannelCount) GetMeteringChannelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 u32ChannelCount, float* afPeakValues) GetChannelsPeakValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwHardwareSupportMask) QueryHardwareSupport;
	}


	public HRESULT GetPeakValue(float* pfPeak) mut => VT.[Friend]GetPeakValue(&this, pfPeak);

	public HRESULT GetMeteringChannelCount(uint32* pnChannelCount) mut => VT.[Friend]GetMeteringChannelCount(&this, pnChannelCount);

	public HRESULT GetChannelsPeakValues(uint32 u32ChannelCount, float* afPeakValues) mut => VT.[Friend]GetChannelsPeakValues(&this, u32ChannelCount, afPeakValues);

	public HRESULT QueryHardwareSupport(uint32* pdwHardwareSupportMask) mut => VT.[Friend]QueryHardwareSupport(&this, pdwHardwareSupportMask);
}

#endregion
