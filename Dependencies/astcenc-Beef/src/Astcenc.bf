using System;

namespace astcenc_Beef;

/*
 * astcenc - the ARM ASTC texture encoder and decoder.
 *
 * Source: https://github.com/ARM-software/astc-encoder
 * License: Apache 2.0 (astcenc/LICENSE.txt)
 *
 * NO WRAPPER, unlike the other bindings here: astcenc.h is already an extern "C" surface with
 * plain structs, so this binds it directly. The struct layouts below mirror that header field
 * for field and in order; a version bump that changes one has to be mirrored here too.
 *
 * SCOPE: the astcenc_*.cpp core. No command line front end, no test or benchmark harness. The
 * build is forced onto the scalar ISA path so one archive serves every architecture, which a
 * cook time encoder can afford.
 */

enum AstcError : int32
{
	Success = 0,
	OutOfMem,
	BadCpuFloat,
	BadParam,
	BadBlockSize,
	BadProfile,
	BadQuality,
	BadSwizzle,
	BadFlags,
	BadContext,
	NotImplemented,
	DtraceFailure,
}

/// Which colour space the encoder weights its error in, and whether it is encoding an LDR or
/// an HDR image.
enum AstcProfile : int32
{
	LdrSrgb = 0,
	Ldr,
	HdrRgbLdrA,
	Hdr,
}

/// Where each output channel reads from.
enum AstcSwz : int32
{
	R = 0,
	G = 1,
	B = 2,
	A = 3,
	/// A constant zero.
	Zero = 4,
	/// A constant one.
	One = 5,
	/// The reconstructed third component of a unit vector, for two channel normal maps.
	Z = 6,
}

/// What the input or output pixels are, which is NOT the same as the encoded profile: an LDR
/// profile still accepts float input.
enum AstcType : int32
{
	U8 = 0,
	F16 = 1,
	F32 = 2,
}

[CRepr]
struct AstcSwizzle
{
	public AstcSwz R;
	public AstcSwz G;
	public AstcSwz B;
	public AstcSwz A;

	/// Straight through, which is what an RGBA8 source wants.
	public static AstcSwizzle Identity => .() { R = .R, G = .G, B = .B, A = .A };
}

/// One image handed to the codec. `Data` is an ARRAY OF SLICE POINTERS, one per Z layer, so a
/// two dimensional image passes the address of a single pointer.
[CRepr]
struct AstcImage
{
	public uint32 DimX;
	public uint32 DimY;
	public uint32 DimZ;
	public AstcType DataType;
	public void** Data;
}

/// Every knob the encoder has. Never fill this in by hand: `astcenc_config_init` writes the
/// whole struct from a profile, a block size and an effort level, and a caller then adjusts
/// the one or two fields it actually cares about.
///
/// MIRRORS astcenc.h field for field. The diagnostics only `trace_file_path` tail is absent,
/// since the vendored build does not define ASTCENC_DIAGNOSTICS.
[CRepr]
struct AstcConfig
{
	public AstcProfile Profile;
	public uint32 Flags;
	public uint32 BlockX;
	public uint32 BlockY;
	public uint32 BlockZ;

	public float ChannelWeightR;
	public float ChannelWeightG;
	public float ChannelWeightB;
	public float ChannelWeightA;

	public uint32 AlphaScaleRadius;
	public float RgbmScale;

	public uint32 TunePartitionCountLimit;
	public uint32 Tune2PartitionIndexLimit;
	public uint32 Tune3PartitionIndexLimit;
	public uint32 Tune4PartitionIndexLimit;
	public uint32 TuneBlockModeLimit;
	public uint32 TuneRefinementLimit;
	public uint32 TuneCandidateLimit;
	public uint32 Tune2PartitioningCandidateLimit;
	public uint32 Tune3PartitioningCandidateLimit;
	public uint32 Tune4PartitioningCandidateLimit;
	public float TuneDbLimit;
	public float TuneMseOvershoot;
	public float Tune2PartitionEarlyOutLimitFactor;
	public float Tune3PartitionEarlyOutLimitFactor;
	public float Tune2PlaneEarlyOutLimitCorrelation;
	public float TuneSearchMode0Enable;

	public void* ProgressCallback;
}

static
{
	// ---- effort levels, the named points on the 0 to 100 quality scale ---------------------

	public const float ASTCENC_PRE_FASTEST = 0.0f;
	public const float ASTCENC_PRE_FAST = 10.0f;
	public const float ASTCENC_PRE_MEDIUM = 60.0f;
	public const float ASTCENC_PRE_THOROUGH = 98.0f;
	public const float ASTCENC_PRE_VERYTHOROUGH = 99.0f;
	public const float ASTCENC_PRE_EXHAUSTIVE = 100.0f;

	// ---- config flags ---------------------------------------------------------------------

	/// The source is a tangent space normal map, so the encoder weights and swizzles for one.
	public const uint32 ASTCENC_FLG_MAP_NORMAL = 1 << 0;
	public const uint32 ASTCENC_FLG_USE_DECODE_UNORM8 = 1 << 1;
	public const uint32 ASTCENC_FLG_USE_ALPHA_WEIGHT = 1 << 2;
	/// Weight error perceptually rather than by mean square error.
	public const uint32 ASTCENC_FLG_USE_PERCEPTUAL = 1 << 3;
	/// A context that can only decode, which costs far less memory to allocate.
	public const uint32 ASTCENC_FLG_DECOMPRESS_ONLY = 1 << 4;
	public const uint32 ASTCENC_FLG_SELF_DECOMPRESS_ONLY = 1 << 5;
	public const uint32 ASTCENC_FLG_MAP_RGBM = 1 << 6;

	// ---- the codec ------------------------------------------------------------------------

	/// Fills a config from a profile, a block size and an effort level between
	/// ASTCENC_PRE_FASTEST and ASTCENC_PRE_EXHAUSTIVE. Block Z is one for a flat image.
	[CLink] public static extern AstcError astcenc_config_init(AstcProfile profile, uint32 blockX,
		uint32 blockY, uint32 blockZ, float quality, uint32 flags, AstcConfig* config);

	/// Allocates a codec context from a config. The context is what holds the lookup tables,
	/// so it is worth keeping across images; `parentContext` is null unless sharing one
	/// across threads.
	[CLink] public static extern AstcError astcenc_context_alloc(AstcConfig* config,
		uint32 threadCount, void** context, void* parentContext);

	[CLink] public static extern void astcenc_context_free(void* context);

	/// Encodes a WHOLE image, not a block: ASTC's block layout is the codec's business.
	/// `dataOut` must already be the exact block count times sixteen bytes.
	[CLink] public static extern AstcError astcenc_compress_image(void* context, AstcImage* image,
		AstcSwizzle* swizzle, uint8* dataOut, uint dataLength, uint32 threadIndex);

	/// Required between compressing two images on the same context.
	[CLink] public static extern AstcError astcenc_compress_reset(void* context);

	[CLink] public static extern AstcError astcenc_decompress_image(void* context, uint8* data,
		uint dataLength, AstcImage* imageOut, AstcSwizzle* swizzle, uint32 threadIndex);

	[CLink] public static extern AstcError astcenc_decompress_reset(void* context);

	/// A human readable name for an error code, from the library rather than restated here.
	[CLink] public static extern char8* astcenc_get_error_string(AstcError status);
}
