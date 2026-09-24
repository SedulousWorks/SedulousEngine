using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.VFS;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// A clip's thumbnail: its peak envelope as a teal bar strip on the tile ground, from the
/// encoded source bytes.
class AudioClipThumbnailGenerator : IThumbnailGenerator
{
	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("AudioClipAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources,
		ThumbnailPrepared outPrepared)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as AudioClipAsset;
		if ((asset == null) || asset.FileName.IsEmpty)
			return .Err(.InvalidArgument);
		let stream = sources.Open(asset.FileName.Value, .Read);
		if ((stream == null) || !stream.IsValid)
		{
			delete stream;
			return .Err(.NotFound);
		}
		if (stream.Size() <= 0)
		{
			delete stream;
			return .Err(.NotFound);
		}
		// Handed over UNREAD: the file is drained on the worker.
		outPrepared.TakeStream(stream);
		return .Ok;
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		let tile = ThumbnailService.cThumbnailSize;
		let peaks = scope List<float>();
		if (!AudioCodec.BuildWaveformPeaks(payload, tile, peaks) || (peaks.Count != (int)tile))
			return .Err(.InvalidArgument);
		uint8[3] ground = .(26, 28, 33);
		uint8[3] bar = .(64, 200, 190); // the clip page's waveform teal
		let dst = scope uint8[(int)tile * (int)tile * 4];
		for (int i = 0; i < dst.Count; i += 4)
		{
			dst[i] = ground[0];
			dst[i + 1] = ground[1];
			dst[i + 2] = ground[2];
			dst[i + 3] = 255;
		}
		let mid = (int32)tile / 2;
		for (int32 x < (int32)tile)
		{
			let half = Math.Max(1, (int32)(peaks[x] * (float)(mid - 2)));
			for (int32 y = mid - half; y < mid + half; y++)
			{
				let texel = ((int)y * (int)tile + (int)x) * 4;
				dst[texel] = bar[0];
				dst[texel + 1] = bar[1];
				dst[texel + 2] = bar[2];
			}
		}
		outImage.ReplaceData(tile, tile, .RGBA8, dst);
		return .Ok;
	}
}
