using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// A clip for audition, straight from the source file under the project: probed for its
/// metadata and carrying the encoded bytes, which is what the engine decodes on play.
static class AudioClipLoader
{
	/// Null without a project, a readable file, or a decodable one. The caller owns the clip.
	public static AudioClip Load(EditorContext context, AudioClipAsset asset)
	{
		if ((asset == null) || (context.Project == null))
			return null;
		let path = PathJoin(context.Project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
		let bytes = scope List<uint8>();
		if (!(ReadFile(path, bytes) case .Ok))
		{
			GlobalLog(.Warning, "Editor: audio source missing: {}", path);
			return null;
		}
		AudioClipMetadata metadata = ?;
		if (!AudioCodec.Probe(bytes, out metadata))
			return null;
		let clip = new AudioClip();
		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		clip.Gain = asset.Gain;
		clip.Loop = asset.Loop;
		clip.LoopStartFrame = asset.LoopStartFrame;
		clip.LoopEndFrame = asset.LoopEndFrame;
		clip.EncodedData.AddRange(bytes);
		return clip;
	}
}
