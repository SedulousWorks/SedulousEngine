using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Texture.Compression;

/// The BC6H unsigned half float encoder.
///
/// IN HOUSE rather than vendored, because there is nothing to vendor: bc7enc is BC1 to BC7 and
/// has no BC6H in either direction, Basis carries one only inside its HDR transcoder, and
/// DirectXTex's is three thousand lines with a DirectXMath dependency behind it. What a
/// radiance map needs is the mode real time encoders use: MODE 11, one region, two 10 bit
/// endpoints per channel, 4 bit interpolation weights, no delta coding. The two region
/// partitioned modes buy quality on hard edges, which skies and image based lighting sources
/// rarely have; they are the deferred step.
///
/// Every choice here follows the decoder's arithmetic, from the D3D11.3 specification's
/// section 19.5:
///
///   unquantize(q, 10 bits, unsigned): nought stays nought, 1023 saturates, else (q << 6) + 32
///   interpolate(a, b, w)            : (a * (64 - w) + b * w + 32) >> 6, w from the 4 bit table
///   finish(v)                       : (v * 31) >> 6, which IS the half float's bit pattern
///
/// so the encoder works in the decoder's own 16 bit internal domain, measures error there,
/// where half bits are near logarithmic and therefore suit radiance, and only converts to the
/// half representation at the boundary.
static class Bc6hEncoder
{
	private const int32 cInternalMax = 0xFFFF;
	private static readonly int32[16] cWeights4 = .(0, 4, 9, 13, 17, 21, 26, 30, 34, 38, 43, 47,
		51, 55, 60, 64);

	/// Encodes one level of tightly packed RGBA32F into BC6H unsigned, sixteen bytes per 4x4
	/// block, appending to `outBytes`. Edge blocks clamp replicate from the border texels.
	///
	/// Alpha is DROPPED, BC6H being an RGB format. Negatives, NaN and anything past the largest
	/// finite half clamp: a radiance map is non negative by construction, which is why the
	/// signed variant of the format stays unplumbed. `quality` runs 0 to 255 and buys endpoint
	/// refinement passes.
	public static void Encode(float* rgba, uint32 width, uint32 height, uint8 quality,
		List<uint8> outBytes)
	{
		if ((rgba == null) || (width == 0) || (height == 0))
			return;

		let blocksX = (width + 3) / 4;
		let blocksY = (height + 3) / 4;
		let start = outBytes.Count;
		outBytes.Count = start
			+ (int)TextureCompression.BlockCompressedSize(.BC6HRGBUfloat, width, height);

		var offset = start;
		float[16 * 4] block = .();
		for (uint32 by < blocksY)
		{
			for (uint32 bx < blocksX)
			{
				for (uint32 y < 4)
				{
					let sy = Math.Min(by * 4 + y, height - 1);
					for (uint32 x < 4)
					{
						let sx = Math.Min(bx * 4 + x, width - 1);
						let src = rgba + ((int)sy * (int)width + (int)sx) * 4;
						let dst = &block[((int)y * 4 + (int)x) * 4];
						dst[0] = src[0];
						dst[1] = src[1];
						dst[2] = src[2];
						dst[3] = src[3];
					}
				}
				EncodeBlockMode11(&block, quality, &outBytes[offset]);
				offset += 16;
			}
		}
	}

	// ==================== the half float boundary ====================

	/// A float to an IEEE half's bit pattern, rounding to nearest even. UNSIGNED BC6H, so a
	/// negative, a NaN and negative infinity all clamp to nought, and anything past the largest
	/// finite half clamps to it.
	private static uint16 FloatToHalfBits(float value)
	{
		if (!(value == value) || (value <= 0.0f))
			return 0;
		if (value >= 65504.0f)
			return 0x7BFF;

		var source = value;
		uint32 bits = *(uint32*)&source;
		let exponent = (int32)((bits >> 23) & 0xFF);
		var mantissa = bits & 0x7FFFFF;
		int32 e = exponent - 127 + 15;

		if (e <= 0)
		{
			// Subnormal in half, or too small to represent at all.
			if (e < -10)
				return 0;
			mantissa |= 0x800000;
			int32 shiftBits = 14 - e;
			let shift = (uint32)shiftBits;
			var half = mantissa >> shift;
			let remainder = mantissa & ((1U << shift) - 1);
			let halfway = 1U << (shift - 1);
			if ((remainder > halfway) || ((remainder == halfway) && ((half & 1) != 0)))
				half++;
			return (uint16)half;
		}

		var half = ((uint32)e << 10) | (mantissa >> 13);
		let remainder = mantissa & 0x1FFF;
		if ((remainder > 0x1000) || ((remainder == 0x1000) && ((half & 1) != 0)))
			half++;
		return (uint16)((half > 0x7BFF) ? 0x7BFF : half);
	}

	/// Half bits to the decoder's internal domain, which is the inverse of finish: the v for
	/// which (v * 31) >> 6 comes back as this half.
	private static int32 HalfToInternal(uint16 half)
	{
		let v = ((int32)half * 64 + 30) / 31;
		return (v > cInternalMax) ? cInternalMax : v;
	}

	private static int32 Unquantize10(int32 q)
	{
		if (q <= 0)
			return 0;
		if (q >= 1023)
			return cInternalMax;
		return (q << 6) + 32;
	}

	/// The nearest 10 bit endpoint for an internal value. The representable values sit at
	/// 64q + 32, so the quantisation is a plain shift.
	private static int32 Quantize10(int32 v)
	{
		if (v <= 0)
			return 0;
		if (v >= cInternalMax)
			return 1023;
		let q = v >> 6;
		return (q > 1023) ? 1023 : q;
	}

	private static int32 Interpolate(int32 a, int32 b, int32 w) => (a * (64 - w) + b * w + 32) >> 6;

	// ==================== the block search ====================

	private struct Endpoints
	{
		public int32[3] E0;
		public int32[3] E1;
	}

	private struct Quantized
	{
		public int32[3] Q0;
		public int32[3] Q1;
	}

	private struct Candidate
	{
		public Quantized Q;
		public uint8[16] Index;
		public uint64 Error = uint64.MaxValue;

		public this() { Q = .(); Index = .(); }
	}

	private static Quantized Quantize(Endpoints ep)
	{
		Quantized q = .();
		for (int c < 3)
		{
			q.Q0[c] = Quantize10(ep.E0[c]);
			q.Q1[c] = Quantize10(ep.E1[c]);
		}
		return q;
	}

	private static Endpoints Unquantize(Quantized q)
	{
		Endpoints ep = .();
		for (int c < 3)
		{
			ep.E0[c] = Unquantize10(q.Q0[c]);
			ep.E1[c] = Unquantize10(q.Q1[c]);
		}
		return ep;
	}

	/// Each texel takes the 4 bit weight nearest its projection onto the segment from the first
	/// endpoint to the second.
	private static void AssignWeights(int32[16][3]* u, Endpoints ep, uint8* index)
	{
		float[3] d = .();
		var length2 = 0.0f;
		for (int c < 3)
		{
			d[c] = (float)(ep.E1[c] - ep.E0[c]);
			length2 += d[c] * d[c];
		}

		for (int i < 16)
		{
			if (length2 <= 0.0f)
			{
				index[i] = 0;
				continue;
			}
			var t = 0.0f;
			for (int c < 3)
				t += (float)((*u)[i][c] - ep.E0[c]) * d[c];
			t /= length2;
			t = Math.Clamp(t, 0.0f, 1.0f);
			index[i] = (uint8)(int32)(t * 15.0f + 0.5f);
		}
	}

	private static uint64 BlockError(int32[16][3]* u, Endpoints ep, uint8* index)
	{
		uint64 error = 0;
		for (int i < 16)
		{
			let w = cWeights4[index[i]];
			for (int c < 3)
			{
				let diff = (int64)(Interpolate(ep.E0[c], ep.E1[c], w) - (*u)[i][c]);
				error += (uint64)(diff * diff);
			}
		}
		return error;
	}

	/// Least squares endpoints for a fixed set of weights, being the classic two by two normal
	/// equations solved per channel. False when the weights carry no spread at all, which is
	/// every texel sitting on one endpoint.
	private static bool SolveEndpoints(int32[16][3]* u, uint8* index, ref Endpoints ep)
	{
		double alpha2 = 0.0, beta2 = 0.0, alphaBeta = 0.0;
		double[3] alphaX = .();
		double[3] betaX = .();

		for (int i < 16)
		{
			let b = (double)cWeights4[index[i]] / 64.0;
			let a = 1.0 - b;
			alpha2 += a * a;
			beta2 += b * b;
			alphaBeta += a * b;
			for (int c < 3)
			{
				alphaX[c] += a * (*u)[i][c];
				betaX[c] += b * (*u)[i][c];
			}
		}

		let det = alpha2 * beta2 - alphaBeta * alphaBeta;
		if ((det < 1.0e-6) && (det > -1.0e-6))
			return false;

		for (int c < 3)
		{
			let e0 = (alphaX[c] * beta2 - betaX[c] * alphaBeta) / det;
			let e1 = (betaX[c] * alpha2 - alphaX[c] * alphaBeta) / det;
			ep.E0[c] = (int32)((e0 < 0.0) ? 0.0 : ((e0 > cInternalMax) ? cInternalMax : e0 + 0.5));
			ep.E1[c] = (int32)((e1 < 0.0) ? 0.0 : ((e1 > cInternalMax) ? cInternalMax : e1 + 0.5));
		}
		return true;
	}

	private static void Consider(int32[16][3]* u, Endpoints ep, ref Candidate best)
	{
		let q = Quantize(ep);
		let unq = Unquantize(q);
		uint8[16] index = .();
		AssignWeights(u, unq, &index);
		let error = BlockError(u, unq, &index);
		if (error < best.Error)
		{
			best.Error = error;
			best.Q = q;
			best.Index = index;
		}
	}

	/// The block's 128 bits, written least significant bit first, which is BC6H's order.
	private struct BitWriter
	{
		public uint8* Out;
		public uint32 Position = 0;

		public void Write(uint32 value, uint32 bits) mut
		{
			for (uint32 i < bits)
			{
				if (((value >> i) & 1) != 0)
					Out[(Position + i) >> 3] |= (uint8)(1 << ((Position + i) & 7));
			}
			Position += bits;
		}
	}

	/// Sixteen texels of RGBA32F into one sixteen byte BC6H unsigned block, mode 11.
	private static void EncodeBlockMode11(float* rgba, uint8 quality, uint8* outBlock)
	{
		int32[16][3] u = .();
		int32[3] lo = .(cInternalMax, cInternalMax, cInternalMax);
		int32[3] hi = .(0, 0, 0);
		for (int i < 16)
		{
			for (int c < 3)
			{
				u[i][c] = HalfToInternal(FloatToHalfBits(rgba[i * 4 + c]));
				lo[c] = Math.Min(lo[c], u[i][c]);
				hi[c] = Math.Max(hi[c], u[i][c]);
			}
		}

		Candidate best = .();

		// 1. The bounding box diagonal, refined by least squares as many times as the quality
		//    asked for.
		Endpoints ep = .() { E0 = .(lo[0], lo[1], lo[2]), E1 = .(hi[0], hi[1], hi[2]) };
		let passes = 1 + (int32)quality / 64; // one to four
		for (int pass < passes)
		{
			Consider(&u, ep, ref best);
			uint8[16] index = .();
			AssignWeights(&u, ep, &index);
			if (!SolveEndpoints(&u, &index, ref ep))
				break;
		}

		// 2. Flat and near flat blocks, which is most of a sky. One shared weight per texel
		//    cannot satisfy three channels whose quantisation residues differ, so instead fix
		//    EVERY weight at the table's first step, w = 4, and give each channel its own
		//    second endpoint: interpolate(a, b, 4) is 60a/64 + 4b/64, so with a = 64q + 32 and
		//    b = a + 64d the reconstruction lands on 64q + 32 + 4d, a four unit grid the 10 bit
		//    endpoints alone, on their 64 unit grid, cannot reach. Tried whenever the block's
		//    range fits inside one quantisation step, and kept only when the error agrees.
		var narrow = true;
		for (int c < 3)
			narrow = narrow && ((hi[c] - lo[c]) <= 64);

		if (narrow)
		{
			Quantized flat = .();
			for (int c < 3)
			{
				let mid = (lo[c] + hi[c]) / 2;
				var q0 = Quantize10(mid);
				if (q0 == 0)
					q0 = 1; // keep the endpoint on the 64q + 32 grid, since q = 0 decodes to 0
				let residual = mid - Unquantize10(q0); // within plus or minus 32
				let d = (residual + ((residual >= 0) ? 2 : -2)) / 4; // the nearest four unit step
				var q1 = q0 + d;
				q1 = Math.Clamp(q1, 1, 1022);
				flat.Q0[c] = q0;
				flat.Q1[c] = q1;
			}

			let unq = Unquantize(flat);
			uint8[16] index = .();
			for (int i < 16)
				index[i] = 1;
			let error = BlockError(&u, unq, &index);
			if (error < best.Error)
			{
				best.Error = error;
				best.Q = flat;
				best.Index = index;
			}
		}

		// 3. The anchor index, texel nought, stores only THREE bits, so its top bit has to be
		//    nought. Swapping the endpoints mirrors every weight, which the interpolation table
		//    is symmetric enough to allow.
		var q = best.Q;
		var index = best.Index;
		if (index[0] >= 8)
		{
			for (int c < 3)
			{
				let t = q.Q0[c];
				q.Q0[c] = q.Q1[c];
				q.Q1[c] = t;
			}
			for (int i < 16)
				index[i] = (uint8)(15 - index[i]);
		}

		// 4. Pack: mode 11 in five bits, then the six 10 bit endpoint components, then the
		//    anchor's three bits and fifteen 4 bit indices, which is 128 bits exactly.
		Internal.MemSet(outBlock, 0, 16);
		BitWriter writer = .() { Out = outBlock };
		writer.Write(0x03, 5);
		for (int c < 3)
			writer.Write((uint32)q.Q0[c], 10);
		for (int c < 3)
			writer.Write((uint32)q.Q1[c], 10);
		writer.Write(index[0], 3);
		for (int i = 1; i < 16; ++i)
			writer.Write(index[i], 4);
		Runtime.Assert(writer.Position == 128, "a BC6H block must pack to 128 bits");
	}
}
