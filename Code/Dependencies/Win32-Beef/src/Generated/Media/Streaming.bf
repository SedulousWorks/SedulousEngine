using Win32.Foundation;
using System;

namespace Win32.Media.Streaming;

#region Enums

[AllowDuplicates]
public enum MF_TRANSFER_VIDEO_FRAME_FLAGS : int32
{
	MF_TRANSFER_VIDEO_FRAME_DEFAULT = 0,
	MF_TRANSFER_VIDEO_FRAME_STRETCH = 1,
	MF_TRANSFER_VIDEO_FRAME_IGNORE_PAR = 2,
}


[AllowDuplicates]
public enum MF_MEDIASOURCE_STATUS_INFO : int32
{
	MF_MEDIASOURCE_STATUS_INFO_FULLYSUPPORTED = 0,
	MF_MEDIASOURCE_STATUS_INFO_UNKNOWN = 1,
}

#endregion


#region Structs
[CRepr]
public struct FaceRectInfoBlobHeader
{
	public uint32 Size;
	public uint32 Count;
}

[CRepr]
public struct FaceRectInfo
{
	public RECT Region;
	public int32 confidenceLevel;
}

[CRepr]
public struct FaceCharacterizationBlobHeader
{
	public uint32 Size;
	public uint32 Count;
}

[CRepr]
public struct FaceCharacterization
{
	public uint32 BlinkScoreLeft;
	public uint32 BlinkScoreRight;
	public uint32 FacialExpression;
	public uint32 FacialExpressionScore;
}

[CRepr]
public struct CapturedMetadataExposureCompensation
{
	public uint64 Flags;
	public int32 Value;
}

[CRepr]
public struct CapturedMetadataISOGains
{
	public float AnalogGain;
	public float DigitalGain;
}

[CRepr]
public struct CapturedMetadataWhiteBalanceGains
{
	public float R;
	public float G;
	public float B;
}

[CRepr]
public struct MetadataTimeStamps
{
	public uint32 Flags;
	public int64 Device;
	public int64 Presentation;
}

[CRepr]
public struct HistogramGrid
{
	public uint32 Width;
	public uint32 Height;
	public RECT Region;
}

[CRepr]
public struct HistogramBlobHeader
{
	public uint32 Size;
	public uint32 Histograms;
}

[CRepr]
public struct HistogramHeader
{
	public uint32 Size;
	public uint32 Bins;
	public uint32 FourCC;
	public uint32 ChannelMasks;
	public HistogramGrid Grid;
}

[CRepr]
public struct HistogramDataHeader
{
	public uint32 Size;
	public uint32 ChannelMask;
	public uint32 Linear;
}

#endregion
