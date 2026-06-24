namespace Sedulous.Editor;

using System;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Editor.Core;
using Sedulous.Images;
using Sedulous.Resources;

/// Renders a `.soundcue` thumbnail as a stacked set of waveforms - one
/// horizontal band per entry, up to MaxBands. Beyond that we show the
/// first MaxBands entries silently. CPU-only / fully synchronous; no
/// thumbnail-renderer involvement.
///
/// Loading: SoundCueResource arrives header-only-ish - it deserializes
/// its own entry list and ClipRefs, but the per-entry AudioClips aren't
/// fetched until ResolveClips is called. Since we only need samples
/// transiently, we walk ClipRefs ourselves with LoadByRef and release
/// each handle as we finish drawing it - the SoundCueResource's
/// internal handle list stays untouched.
class SoundCueThumbnailGenerator : IAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ILogger mLogger;

	private const int32 MaxBands = 4;

	// Color palette - matches AudioClip's cyan waveform foreground.
	private const uint8 BgR = 28, BgG = 30, BgB = 36, BgA = 255;
	private const uint8 FgR = 90, FgG = 200, FgB = 220, FgA = 255;
	private const uint8 CenterR = 60, CenterG = 70, CenterB = 90, CenterA = 255;
	private const uint8 DividerR = 14, DividerG = 16, DividerB = 22, DividerA = 255;

	public this(ResourceSystem resourceSystem, ILogger logger = null)
	{
		mResourceSystem = resourceSystem;
		mLogger = logger;
	}

	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		if (mResourceSystem == null || width <= 0 || height <= 0)
			return .Err;

		ResourceHandle<SoundCueResource> cueHandle;
		if (mResourceSystem.LoadResource<SoundCueResource>(assetPath) case .Ok(let h))
			cueHandle = h;
		else
		{
			mLogger?.LogWarning("[SoundCueThumbnail] LoadResource failed: {}", assetPath);
			return .Err;
		}
		defer cueHandle.Release();

		let cueRes = cueHandle.Resource;
		if (cueRes == null)
			return .Err;

		let pixels = new uint8[width * height * 4];
		FillBackground(pixels, width, height);

		// How many bands to actually render. Zero-entry cues still get
		// a center-line image so the cell isn't empty.
		let entryCount = (int32)cueRes.ClipRefs.Count;
		let bandCount = Math.Min(entryCount, MaxBands);

		if (bandCount == 0)
		{
			DrawCenterLine(pixels, width, height / 2);
			return .Ok(new OwnedImageData((uint32)width, (uint32)height, .RGBA8, pixels));
		}

		// Equal-height bands across the image. Last band absorbs any
		// integer-division remainder so we don't leave a 1-2px gutter.
		let bandHeight = height / bandCount;

		for (int32 b = 0; b < bandCount; b++)
		{
			let bandTop = b * bandHeight;
			let bandBottom = (b == bandCount - 1) ? height : (b + 1) * bandHeight;
			let bandH = bandBottom - bandTop;

			DrawCenterLine(pixels, width, bandTop + bandH / 2);
			DrawBandWaveform(pixels, width, bandTop, bandH, cueRes.ClipRefs[b]);

			// Thin divider line between bands so adjacent waveforms
			// don't merge visually.
			if (b > 0)
			{
				for (int32 x = 0; x < width; x++)
				{
					let i = (bandTop * width + x) * 4;
					pixels[i + 0] = DividerR;
					pixels[i + 1] = DividerG;
					pixels[i + 2] = DividerB;
					pixels[i + 3] = DividerA;
				}
			}
		}

		return .Ok(new OwnedImageData((uint32)width, (uint32)height, .RGBA8, pixels));
	}

	private void FillBackground(uint8[] pixels, int32 width, int32 height)
	{
		for (int i = 0; i < width * height; i++)
		{
			pixels[i * 4 + 0] = BgR;
			pixels[i * 4 + 1] = BgG;
			pixels[i * 4 + 2] = BgB;
			pixels[i * 4 + 3] = BgA;
		}
	}

	private void DrawCenterLine(uint8[] pixels, int32 width, int32 y)
	{
		for (int32 x = 0; x < width; x++)
		{
			let i = (y * width + x) * 4;
			pixels[i + 0] = CenterR;
			pixels[i + 1] = CenterG;
			pixels[i + 2] = CenterB;
			pixels[i + 3] = CenterA;
		}
	}

	/// Loads the referenced clip transiently and draws its peak waveform
	/// into rows [bandTop, bandTop + bandH). Silently skips on load
	/// failure - the band stays empty (background + center line).
	private void DrawBandWaveform(uint8[] pixels, int32 width, int32 bandTop, int32 bandH, ResourceRef clipRef)
	{
		if (!clipRef.IsValid) return;

		ResourceHandle<AudioClipResource> clipHandle;
		if (mResourceSystem.LoadByRef<AudioClipResource>(clipRef) case .Ok(let h))
			clipHandle = h;
		else
			return;
		defer clipHandle.Release();

		let clip = clipHandle.Resource?.Clip;
		if (clip == null || !clip.IsLoaded) return;

		let frameCount = clip.FrameCount;
		if (frameCount <= 0) return;

		let half = (float)(bandH - 1) * 0.5f;
		let centerY = (float)bandTop + half;

		for (int32 x = 0; x < width; x++)
		{
			let frameStart = (int)((int64)x * frameCount / (int64)width);
			let frameEndExclusive = (int)((int64)(x + 1) * frameCount / (int64)width);
			let frameEnd = (frameEndExclusive > frameStart) ? frameEndExclusive : frameStart + 1;

			float peakMin = 0.0f;
			float peakMax = 0.0f;
			GetPeaks(clip, frameStart, frameEnd, ref peakMin, ref peakMax);

			let yTop    = (int32)Math.Clamp(centerY - peakMax * half, (float)bandTop, (float)(bandTop + bandH - 1));
			let yBottom = (int32)Math.Clamp(centerY - peakMin * half, (float)bandTop, (float)(bandTop + bandH - 1));

			let yStart = Math.Min(yTop, yBottom);
			let yEnd = Math.Max(yTop, yBottom);
			for (int32 y = yStart; y <= yEnd; y++)
			{
				let i = (y * width + x) * 4;
				pixels[i + 0] = FgR;
				pixels[i + 1] = FgG;
				pixels[i + 2] = FgB;
				pixels[i + 3] = FgA;
			}
		}
	}

	/// Same per-channel peak walker as AudioClipThumbnailGenerator -
	/// mono-mixes any channel count, returns signed min/max in [-1, 1].
	/// Kept duplicated rather than factored out: two callers, both
	/// short, and the format-dispatch is what's bulky.
	private void GetPeaks(AudioClip clip, int frameStart, int frameEnd, ref float peakMin, ref float peakMax)
	{
		let channels = (int)clip.Channels;
		if (channels == 0) return;
		let data = clip.Data;
		if (data == null) return;

		switch (clip.Format)
		{
		case .Int16:
			{
				let samples = (int16*)data;
				const float invScale = 1.0f / 32768.0f;
				for (int f = frameStart; f < frameEnd; f++)
				{
					float mix = 0;
					for (int c = 0; c < channels; c++)
						mix += (float)samples[f * channels + c] * invScale;
					mix /= (float)channels;
					if (mix < peakMin) peakMin = mix;
					if (mix > peakMax) peakMax = mix;
				}
			}
		case .Int32:
			{
				let samples = (int32*)data;
				const float invScale = 1.0f / 2147483648.0f;
				for (int f = frameStart; f < frameEnd; f++)
				{
					float mix = 0;
					for (int c = 0; c < channels; c++)
						mix += (float)samples[f * channels + c] * invScale;
					mix /= (float)channels;
					if (mix < peakMin) peakMin = mix;
					if (mix > peakMax) peakMax = mix;
				}
			}
		case .Float32:
			{
				let samples = (float*)data;
				for (int f = frameStart; f < frameEnd; f++)
				{
					float mix = 0;
					for (int c = 0; c < channels; c++)
						mix += samples[f * channels + c];
					mix /= (float)channels;
					if (mix < peakMin) peakMin = mix;
					if (mix > peakMax) peakMax = mix;
				}
			}
		}
	}
}
