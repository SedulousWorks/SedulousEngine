using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Terrain.Resource;

/// The splat painting brushes: pure raster maths, which the editor's paint tool wraps.
///
/// Every brush works over an elliptical disc in the terrain's zero to one footprint, edits
/// the top four model under it, bumps the version if anything changed, and reports the texel
/// rectangle it touched. Nothing here needs a device.
static class SplatBrush
{
	/// Paints a PALETTE layer over the brush disc.
	///
	/// Per touched texel:
	///
	///   1. the layer takes the slot already holding it, else a free one, else it EVICTS the
	///      smallest slot outright. The evicted weight falls to the base, so the error is
	///      bounded by the smallest weight there was, which is the least visible one.
	///   2. every OTHER slot fades toward zero, the base with them, since the base is what
	///      the slots left over.
	///   3. the painted layer rises toward one.
	///
	/// The result stays convex, and repeated full strength painting drives a texel to the one
	/// layer. A weight that quantises to zero frees its slot, so the top four keeps meaning
	/// the four largest.
	public static SplatRegion Paint(SplatWeights weights, float uvX, float uvY, float uvRadiusX,
		float uvRadiusY, uint32 paletteIndex, float amount, float coreFraction = 0.5f)
	{
		var region = SplatRegion();
		if (weights.IsEmpty || (uvRadiusX <= 0.0f) || (uvRadiusY <= 0.0f) || (amount <= 0.0f)
			|| (paletteIndex > 255))
			return region;

		let indices = weights.Indices;
		let raster = weights.Weights;
		let layer = (uint8)paletteIndex;
		var changed = false;

		VisitBrush(weights, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&] (x, y, t) =>
			{
				let at = weights.TexelOffset(x, y);

				// 1. The layer's slot: the one it already has, a free one, or the smallest.
				var slot = (int)SplatWeights.SlotCount;
				for (int k < (int)SplatWeights.SlotCount)
				{
					if ((raster[at + k] > 0) && (indices[at + k] == layer))
					{
						slot = k;
						break;
					}
				}
				if (slot == (int)SplatWeights.SlotCount)
				{
					for (int k < (int)SplatWeights.SlotCount)
					{
						if (raster[at + k] == 0)
						{
							slot = k;
							break;
						}
					}
				}
				if (slot == (int)SplatWeights.SlotCount)
				{
					var smallest = 0;
					for (int k = 1; k < (int)SplatWeights.SlotCount; k++)
					{
						if (raster[at + k] < raster[at + smallest])
							smallest = k;
					}
					slot = smallest;
					// The evicted weight falls to the base.
					raster[at + slot] = 0;
				}

				// 2 and 3. Fade the others, raise this one. Computed in float and quantised
				// ONCE, the raised slot LAST and capped by what the others quantised to:
				// rounding each to nearest independently can push the byte sum one over 255,
				// and convexity has to hold exactly in the stored bytes rather than nearly.
				var texelChanged = false;
				var othersSum = 0;
				for (int k < (int)SplatWeights.SlotCount)
				{
					if (k == slot)
						continue;

					let current = (float)raster[at + k] * (1.0f / 255.0f);
					let quantised = (uint8)Clamp(current * (1.0f - t) * 255.0f + 0.5f, 0.0f, 255.0f);
					if (quantised != raster[at + k])
					{
						raster[at + k] = quantised;
						texelChanged = true;
					}
					othersSum += (int)quantised;
				}

				let current = (float)raster[at + slot] * (1.0f / 255.0f);
				let raised = current + t * (1.0f - current);
				let cap = (float)(255 - Min(othersSum, 255));
				let quantised = (uint8)Clamp(raised * 255.0f + 0.5f, 0.0f, cap);
				if (quantised != raster[at + slot])
				{
					raster[at + slot] = quantised;
					texelChanged = true;
				}
				if (indices[at + slot] != layer)
				{
					indices[at + slot] = layer;
					texelChanged = true;
				}

				// A slot that quantised to nothing clears its index, so the top four stays
				// meaningful rather than holding a layer at no weight.
				if (ClearFreedSlots(indices, raster, at))
					texelChanged = true;

				if (texelChanged)
				{
					region.Add(x, y);
					changed = true;
				}
			});

		if (changed)
			weights.BumpVersion();
		return region;
	}

	/// Erases over the brush disc: every slot fades, so the base, being the remainder, rises
	/// toward one. Slots that quantise to nothing are freed.
	public static SplatRegion Erase(SplatWeights weights, float uvX, float uvY, float uvRadiusX,
		float uvRadiusY, float amount, float coreFraction = 0.5f)
	{
		var region = SplatRegion();
		if (weights.IsEmpty || (uvRadiusX <= 0.0f) || (uvRadiusY <= 0.0f) || (amount <= 0.0f))
			return region;

		let indices = weights.Indices;
		let raster = weights.Weights;
		var changed = false;

		VisitBrush(weights, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&] (x, y, t) =>
			{
				let at = weights.TexelOffset(x, y);
				var texelChanged = false;

				for (int k < (int)SplatWeights.SlotCount)
				{
					let current = (float)raster[at + k] * (1.0f / 255.0f);
					let quantised = (uint8)Clamp(current * (1.0f - t) * 255.0f + 0.5f, 0.0f, 255.0f);
					if (quantised != raster[at + k])
					{
						raster[at + k] = quantised;
						texelChanged = true;
					}
					if ((raster[at + k] == 0) && (indices[at + k] != 0))
					{
						indices[at + k] = 0;
						texelChanged = true;
					}
				}

				if (texelChanged)
				{
					region.Add(x, y);
					changed = true;
				}
			});

		if (changed)
			weights.BumpVersion();
		return region;
	}

	/// Smooths over the brush disc: every texel's weights move toward the AVERAGE of their
	/// three by three neighbourhood, which feathers an already painted seam without
	/// repainting either side of it.
	///
	/// The neighbourhoods are read from a SNAPSHOT of the touched rectangle and a one texel
	/// ring around it, so the pass is order independent: reading texels this same pass had
	/// already smoothed would smear the result in whichever direction the scan happened to
	/// run. Where the union of a neighbourhood's layers exceeds four, the four largest win
	/// and the tail falls to the base, which is the same least visible error rule the paint
	/// eviction follows.
	public static SplatRegion Smooth(SplatWeights weights, float uvX, float uvY, float uvRadiusX,
		float uvRadiusY, float amount, float coreFraction = 0.5f)
	{
		var region = SplatRegion();
		if (weights.IsEmpty || (uvRadiusX <= 0.0f) || (uvRadiusY <= 0.0f) || (amount <= 0.0f))
			return region;

		let width = weights.Width;
		let height = weights.Height;
		let cx = uvX * (float)width;
		let cy = uvY * (float)height;
		let rx = uvRadiusX * (float)width;
		let ry = uvRadiusY * (float)height;

		// The brush rectangle plus a one texel ring, which every neighbourhood read lands in.
		let sx0 = Max(0, (int32)Floor(cx - rx) - 1);
		let sx1 = Min(width - 1, (int32)Ceil(cx + rx) + 1);
		let sy0 = Max(0, (int32)Floor(cy - ry) - 1);
		let sy1 = Min(height - 1, (int32)Ceil(cy + ry) + 1);
		if ((sx1 < sx0) || (sy1 < sy0))
			return region;

		let snapWidth = sx1 - sx0 + 1;
		let snapHeight = sy1 - sy0 + 1;
		let snapBytes = (int)snapWidth * (int)snapHeight * (int)SplatWeights.SlotCount;

		let snapIndices = scope List<uint8>();
		let snapWeights = scope List<uint8>();
		snapIndices.Resize(snapBytes);
		snapWeights.Resize(snapBytes);

		let indices = weights.Indices;
		let raster = weights.Weights;
		let rowBytes = (int)snapWidth * (int)SplatWeights.SlotCount;
		for (int32 y = sy0; y <= sy1; y++)
		{
			let source = weights.TexelOffset(sx0, y);
			let destination = (int)(y - sy0) * rowBytes;
			Internal.MemCpy(&snapIndices[destination], &indices[source], rowBytes);
			Internal.MemCpy(&snapWeights[destination], &raster[source], rowBytes);
		}

		var changed = false;
		VisitBrush(weights, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&] (x, y, t) =>
			{
				// The union of the layers over nine texels: at most thirty six candidates.
				uint8[9 * (int)SplatWeights.SlotCount] candidateLayers = default;
				float[9 * (int)SplatWeights.SlotCount] candidateSums = default;
				var candidateCount = 0;

				for (int32 dy = -1; dy <= 1; dy++)
				{
					for (int32 dx = -1; dx <= 1; dx++)
					{
						// The edge texels clamp, which extends the border outward.
						let nx = Clamp(x + dx, sx0, sx1);
						let ny = Clamp(y + dy, sy0, sy1);
						let at = ((int)(ny - sy0) * (int)snapWidth + (int)(nx - sx0))
							* (int)SplatWeights.SlotCount;

						for (int k < (int)SplatWeights.SlotCount)
						{
							let weight = snapWeights[at + k];
							if (weight == 0)
								continue;

							let layer = snapIndices[at + k];
							var c = 0;
							for (; c < candidateCount; c++)
							{
								if (candidateLayers[c] == layer)
									break;
							}
							if (c == candidateCount)
							{
								candidateLayers[candidateCount] = layer;
								candidateSums[candidateCount] = 0.0f;
								candidateCount++;
							}
							candidateSums[c] += (float)weight * (1.0f / 255.0f);
						}
					}
				}

				// Each layer's target is its own weight moved toward the neighbourhood average.
				let own = ((int)(y - sy0) * (int)snapWidth + (int)(x - sx0))
					* (int)SplatWeights.SlotCount;
				float[9 * (int)SplatWeights.SlotCount] candidateTargets = default;
				for (int c < candidateCount)
				{
					var current = 0.0f;
					for (int k < (int)SplatWeights.SlotCount)
					{
						if ((snapWeights[own + k] > 0) && (snapIndices[own + k] == candidateLayers[c]))
						{
							current = (float)snapWeights[own + k] * (1.0f / 255.0f);
							break;
						}
					}
					let average = candidateSums[c] * (1.0f / 9.0f);
					candidateTargets[c] = current + t * (average - current);
				}

				// Keep the four largest, quantising in DESCENDING order with each capped by
				// what is left of the byte budget: convexity then holds exactly, and the
				// rounding error lands on the smallest weights.
				let at = weights.TexelOffset(x, y);
				uint8[(int)SplatWeights.SlotCount] newIndices = default;
				uint8[(int)SplatWeights.SlotCount] newWeights = default;
				var budget = 255;

				for (int k = 0; (k < (int)SplatWeights.SlotCount) && (k < candidateCount); k++)
				{
					var best = k;
					for (int c = k + 1; c < candidateCount; c++)
					{
						if (candidateTargets[c] > candidateTargets[best])
							best = c;
					}
					Swap!(candidateLayers[best], candidateLayers[k]);
					Swap!(candidateTargets[best], candidateTargets[k]);

					let quantised = (uint8)Clamp(candidateTargets[k] * 255.0f + 0.5f, 0.0f, (float)budget);
					if (quantised == 0)
						break;

					newIndices[k] = candidateLayers[k];
					newWeights[k] = quantised;
					budget -= (int)quantised;
				}

				var texelChanged = false;
				for (int k < (int)SplatWeights.SlotCount)
				{
					if ((indices[at + k] != newIndices[k]) || (raster[at + k] != newWeights[k]))
					{
						indices[at + k] = newIndices[k];
						raster[at + k] = newWeights[k];
						texelChanged = true;
					}
				}

				if (texelChanged)
				{
					region.Add(x, y);
					changed = true;
				}
			});

		if (changed)
			weights.BumpVersion();
		return region;
	}

	/// Rewrites the raster after a palette layer is REMOVED: slots naming it are freed, so
	/// their weight falls to the base, and every index above it decrements so the surviving
	/// slots still name the layers they meant. Answers whether anything changed.
	public static bool RemapOnPaletteRemove(SplatWeights weights, uint32 removedIndex)
	{
		if (weights.IsEmpty)
			return false;

		let indices = weights.Indices;
		let raster = weights.Weights;
		var changed = false;

		for (int i < indices.Length)
		{
			if (raster[i] == 0)
				continue;

			if (indices[i] == removedIndex)
			{
				// The freed weight falls to the base.
				raster[i] = 0;
				indices[i] = 0;
				changed = true;
			}
			else if (indices[i] > removedIndex)
			{
				indices[i]--;
				changed = true;
			}
		}

		if (changed)
			weights.BumpVersion();
		return changed;
	}

	/// Converts an IMPORTED flat raster, four fixed layers with red the base share and green,
	/// blue and alpha the first three palette layers, into the top four model.
	///
	/// The channels are RENORMALISED by the texel's own sum, so a raster whose sums drift
	/// from 255, which any painted or resized image does, still yields exact shares; the base
	/// is then the deficit. A texel that sums to nothing becomes pure base.
	///
	/// THE CALLER OWNS what comes back.
	public static SplatWeights FromFixedLayerRaster(Span<uint8> rgba, int32 width, int32 height)
	{
		if ((width <= 0) || (height <= 0) || (rgba.Length != (int)width * (int)height * 4))
			return new SplatWeights();

		let weights = new SplatWeights(width, height);
		let indices = weights.Indices;
		let raster = weights.Weights;
		let texels = (int)width * (int)height;

		for (int i < texels)
		{
			let at = i * 4;
			let base0 = (float)rgba[at + 0];
			let layer0 = (float)rgba[at + 1];
			let layer1 = (float)rgba[at + 2];
			let layer2 = (float)rgba[at + 3];
			let sum = base0 + layer0 + layer1 + layer2;
			// All zero slots, which is pure base.
			if (sum <= 0.0f)
				continue;

			let scale = 255.0f / sum;
			indices[at + 0] = 0;
			indices[at + 1] = 1;
			indices[at + 2] = 2;
			indices[at + 3] = 0;
			raster[at + 0] = (uint8)Clamp(layer0 * scale + 0.5f, 0.0f, 255.0f);
			raster[at + 1] = (uint8)Clamp(layer1 * scale + 0.5f, 0.0f, 255.0f);
			raster[at + 2] = (uint8)Clamp(layer2 * scale + 0.5f, 0.0f, 255.0f);
			raster[at + 3] = 0;

			ClearFreedSlots(indices, raster, at);
		}
		return weights;
	}

	/// A slot at no weight is unused, so it clears its index too. Answers whether it changed
	/// anything.
	private static bool ClearFreedSlots(Span<uint8> indices, Span<uint8> raster, int at)
	{
		var changed = false;
		for (int k < (int)SplatWeights.SlotCount)
		{
			if ((raster[at + k] == 0) && (indices[at + k] != 0))
			{
				indices[at + k] = 0;
				changed = true;
			}
		}
		return changed;
	}

	/// Visits every texel inside the brush's WORLD circle with its falloff scaled strength.
	///
	/// The radii are per axis, so a terrain whose footprint is not square still paints a
	/// circle. The profile is a flat inner core with a cosine skirt outside it: the core is
	/// what makes a full strength stamp DECISIVE, since a stamp needs an exact one somewhere
	/// and a pure cosine never delivers that at a texel centre, while the skirt keeps the
	/// edge soft. A caller scales the core with the stamp's strength.
	private static void VisitBrush(SplatWeights weights, float uvX, float uvY, float uvRadiusX,
		float uvRadiusY, float amount, float coreFraction,
		delegate void(int32 x, int32 y, float t) apply)
	{
		let width = weights.Width;
		let height = weights.Height;
		let cx = uvX * (float)width;
		let cy = uvY * (float)height;
		let rx = uvRadiusX * (float)width;
		let ry = uvRadiusY * (float)height;

		let x0 = Max(0, (int32)Floor(cx - rx));
		let x1 = Min(width - 1, (int32)Ceil(cx + rx));
		let y0 = Max(0, (int32)Floor(cy - ry));
		let y1 = Min(height - 1, (int32)Ceil(cy + ry));
		let inverseRadiusX = 1.0f / uvRadiusX;
		let inverseRadiusY = 1.0f / uvRadiusY;
		let core = Clamp(coreFraction, 0.0f, 0.95f);

		for (int32 y = y0; y <= y1; y++)
		{
			for (int32 x = x0; x <= x1; x++)
			{
				let du = (((float)x + 0.5f) / (float)width - uvX) * inverseRadiusX;
				let dv = (((float)y + 0.5f) / (float)height - uvY) * inverseRadiusY;
				// Zero at the centre, one at the rim of the world circle.
				let distance = Sqrt(du * du + dv * dv);
				if (distance >= 1.0f)
					continue;

				let falloff = (distance <= core)
					? 1.0f
					: (0.5f + 0.5f * Cos(Pi * (distance - core) / (1.0f - core)));
				let t = Clamp(amount * falloff, 0.0f, 1.0f);
				if (t > 0.0f)
					apply(x, y, t);
			}
		}
	}
}
