namespace Sedulous.Editor;

using System;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Editor.Core;
using Sedulous.Images;
using Sedulous.Resources;

/// Renders an `.audioclip` thumbnail as a peak-rendered waveform.
/// CPU-only, fully synchronous - no GPU, no thumbnail-renderer use.
/// Mono mix of stereo (or higher) inputs, supports the three PCM
/// formats (Int16, Int32, Float32) AudioClip exposes today.
class AudioClipThumbnailGenerator : IAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ILogger mLogger;

	// Visual tuning. Background is a dark neutral; foreground is a
	// soft cyan that reads well against asset-browser cell colors at
	// 256x256 and small.
	private const uint8 BgR = 28, BgG = 30, BgB = 36, BgA = 255;
	private const uint8 FgR = 90, FgG = 200, FgB = 220, FgA = 255;
	private const uint8 CenterR = 60, CenterG = 70, CenterB = 90, CenterA = 255;

	public this(ResourceSystem resourceSystem, ILogger logger = null)
	{
		mResourceSystem = resourceSystem;
		mLogger = logger;
	}

	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		if (mResourceSystem == null || width <= 0 || height <= 0)
			return .Err;

		ResourceHandle<AudioClipResource> handle;
		if (mResourceSystem.LoadResource<AudioClipResource>(assetPath) case .Ok(let h))
			handle = h;
		else
		{
			mLogger?.LogWarning("[AudioClipThumbnail] LoadResource failed: {}", assetPath);
			return .Err;
		}
		defer handle.Release();

		let res = handle.Resource;
		let clip = res?.Clip;
		if (clip == null || !clip.IsLoaded)
			return .Err;

		let pixels = new uint8[width * height * 4];

		// Fill background + center-line. The center line gives "silent
		// stretches" a visual anchor instead of a blank cell.
		FillBackground(pixels, width, height);
		DrawCenterLine(pixels, width, height);

		// Each thumbnail column covers a slice of frames. We take the
		// min/max amplitude in that slice (peak rendering) so transient
		// content doesn't get washed out by averaging.
		let frameCount = clip.FrameCount;
		if (frameCount > 0)
			DrawWaveform(pixels, width, height, clip, frameCount);

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

	private void DrawCenterLine(uint8[] pixels, int32 width, int32 height)
	{
		let y = height / 2;
		for (int32 x = 0; x < width; x++)
		{
			let i = (y * width + x) * 4;
			pixels[i + 0] = CenterR;
			pixels[i + 1] = CenterG;
			pixels[i + 2] = CenterB;
			pixels[i + 3] = CenterA;
		}
	}

	/// Per-column peak rendering. For each thumbnail column we span a
	/// frame range and find min/max of the mono-mixed amplitude in
	/// [-1, 1]. Vertical line drawn between those two values.
	private void DrawWaveform(uint8[] pixels, int32 width, int32 height, AudioClip clip, int frameCount)
	{
		let half = (float)(height - 1) * 0.5f;
		let centerY = half;

		for (int32 x = 0; x < width; x++)
		{
			let frameStart = (int)((int64)x * frameCount / (int64)width);
			let frameEndExclusive = (int)((int64)(x + 1) * frameCount / (int64)width);
			let frameEnd = (frameEndExclusive > frameStart) ? frameEndExclusive : frameStart + 1;

			float peakMin = 0.0f;
			float peakMax = 0.0f;
			GetPeaks(clip, frameStart, frameEnd, ref peakMin, ref peakMax);

			// Map [-1, 1] -> column pixel range. peakMin <= peakMax always;
			// y axis grows downward so the larger amplitude paints higher up.
			let yTop    = (int32)Math.Clamp(centerY - peakMax * half, 0.0f, (float)(height - 1));
			let yBottom = (int32)Math.Clamp(centerY - peakMin * half, 0.0f, (float)(height - 1));

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

	/// Walks a frame range, mono-mixing channels, and returns the
	/// signed min/max amplitude in [-1, 1].
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
