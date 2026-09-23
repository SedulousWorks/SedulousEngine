using System;

namespace bcdec_Beef;

/*
 * bcdec - a single header BCn DECODER.
 *
 * Source: https://github.com/iOrange/bcdec
 * License: MIT or Unlicense, the caller's choice (bcdec/LICENSE)
 *
 * Header only, so bcdec-c/ is the one translation unit that defines BCDEC_IMPLEMENTATION and
 * this binds the header's own plain C declarations. There is nothing to wrap.
 *
 * WHY A SECOND DECODER when bc7enc-Beef already decodes BC1 through BC7: bc7enc has no BC6H
 * at all, in either direction. This is the independent reference the engine's own BC6H
 * encoder is measured against, which is worth more than a decoder written alongside it: a
 * shared misreading of the format would pass a self check and fail on a GPU.
 */

static
{
	/// `destinationPitch` is in BYTES per output row for the integer entry points and in
	/// FLOATS per row for the float ones, which is bcdec's own convention rather than a
	/// choice made here.
	///
	/// The BC4 and BC5 entry points take an `isSigned` flag because bcdec-c is built with
	/// BCDEC_BC4BC5_PRECISE; without that define the header declares three argument unsigned
	/// only versions of those two and no float ones at all, so the define and these
	/// declarations have to move together.
	[CLink] public static extern void bcdec_bc1(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch);
	[CLink] public static extern void bcdec_bc2(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch);
	[CLink] public static extern void bcdec_bc3(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch);
	[CLink] public static extern void bcdec_bc4(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch, int32 isSigned);
	[CLink] public static extern void bcdec_bc5(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch, int32 isSigned);

	/// The same two, read back as FLOATS rather than bytes, which is the only lossless way to
	/// see a signed block: the byte entry points fold minus one through one into nought
	/// through 255.
	[CLink] public static extern void bcdec_bc4_float(void* compressedBlock,
		void* decompressedBlock, int32 destinationPitch, int32 isSigned);
	[CLink] public static extern void bcdec_bc5_float(void* compressedBlock,
		void* decompressedBlock, int32 destinationPitch, int32 isSigned);

	/// 16 texels of three FLOATS each, RGB with no alpha, which is what BC6H stores.
	/// `isSigned` picks the signed variant of the format.
	[CLink] public static extern void bcdec_bc6h_float(void* compressedBlock,
		void* decompressedBlock, int32 destinationPitch, int32 isSigned);

	/// The same, as three half floats per texel.
	[CLink] public static extern void bcdec_bc6h_half(void* compressedBlock,
		void* decompressedBlock, int32 destinationPitch, int32 isSigned);

	[CLink] public static extern void bcdec_bc7(void* compressedBlock, void* decompressedBlock,
		int32 destinationPitch);
}
