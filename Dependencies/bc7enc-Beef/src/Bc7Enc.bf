using System;

namespace bc7enc_Beef;

/*
 * bc7enc - fast BC1 to BC7 texture encoders, and the decoders that check them.
 *
 * Source: https://github.com/richgel999/bc7enc_rdo
 * License: see bc7enc/LICENSE. Attribution is requested but not required.
 *
 * bc7enc.h declares C functions but hands them a struct with member functions, and rgbcx
 * and bc7decomp are C++ namespaces with defaulted arguments. None of that crosses a C ABI,
 * so bc7enc-c/ re-declares the surface a cook needs with plain arguments and this binds
 * that. The same arrangement as msdfgen-Beef and recastnavigation-Beef.
 *
 * SCOPE: the encoder and decoder core only. No ISPC path, no rate distortion optimisation,
 * no command line tool, no lodepng, and none of the committed binaries. Encoding is a cook
 * time job, never a frame time one, so the scalar path is the whole story.
 */

static
{
	/// One time global table init for BOTH encoders, idempotent, and required before any
	/// encode below. BC1 uses the ideal approximation rather than a vendor specific one.
	[CLink] public static extern void bc7encc_init();

	/// The highest level the BC1 and BC3 encoders accept, for a caller mapping its own
	/// quality scale onto them. Read from the library rather than restated here.
	[CLink] public static extern uint32 bc7encc_rgbcx_max_level();

	// ---- encode: one 4x4 block of tightly packed RGBA8, being 64 bytes in ----------------

	/// 8 bytes out. Alpha is ignored.
	[CLink] public static extern void bc7encc_encode_bc1(uint32 level, void* dst, uint8* pixels,
		int32 allowThreeColor, int32 useTransparentTexelsForBlack);

	/// 16 bytes out: a BC1 colour block and a BC4 alpha block.
	[CLink] public static extern void bc7encc_encode_bc3(uint32 level, void* dst, uint8* pixels);

	/// 8 bytes out, one channel.
	[CLink] public static extern void bc7encc_encode_bc4(void* dst, uint8* pixels, uint32 stride);

	/// 16 bytes out, two channels.
	[CLink] public static extern void bc7encc_encode_bc5(void* dst, uint8* pixels, uint32 chan0,
		uint32 chan1, uint32 stride);

	/// 16 bytes out. The uber level is 0 to 4, higher being slower and better.
	[CLink] public static extern void bc7encc_encode_bc7(void* dst, uint8* pixels, uint32 uberLevel);

	// ---- decode: one block back to 64 bytes of RGBA8 -------------------------------------

	/// Zero when the block used the three colour mode, which is how a caller learns the
	/// block carried transparency.
	[CLink] public static extern int32 bc7encc_unpack_bc1(void* block, void* pixels, int32 setAlpha);

	[CLink] public static extern int32 bc7encc_unpack_bc3(void* block, void* pixels);

	[CLink] public static extern void bc7encc_unpack_bc4(void* block, uint8* pixels, uint32 stride);

	[CLink] public static extern void bc7encc_unpack_bc5(void* block, void* pixels, uint32 chan0,
		uint32 chan1, uint32 stride);

	/// Zero on a reserved or invalid mode.
	[CLink] public static extern int32 bc7encc_unpack_bc7(void* block, void* pixels);
}
