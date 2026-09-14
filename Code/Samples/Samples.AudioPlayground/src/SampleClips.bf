using System;
using System.Collections;
using System.IO;
using Sedulous.Audio;
using Sedulous.Core.IO;
using Samples.Common;

namespace Samples.AudioPlayground;

/// The sample's four wav files, read from the repository's data.
///
/// The bytes stay ENCODED in the clip: the engine decodes what it is handed, and pre-decoding
/// here would skip the half of the path most likely to be wrong.
static class SampleClips
{
	/// Null when this checkout has no data, or when the file is not something the codec reads.
	/// Null rather than an assertion, because the sample still demonstrates the buses and the
	/// panel with nothing to play.
	public static AudioClip Load(StringView fileName, bool loop = false)
	{
		let relative = scope String();
		PathJoin(SampleContent.cAudioDir, fileName, relative);

		let path = scope String();
		if (!SampleContent.FindFile(relative, path))
		{
			Console.Error.WriteLine(scope $"AudioPlayground: missing sample data: {relative}");
			return null;
		}

		let bytes = scope List<uint8>();
		if (File.ReadAll(path, bytes) case .Err)
		{
			Console.Error.WriteLine(scope $"AudioPlayground: unreadable: {path}");
			return null;
		}

		if (!AudioCodec.Probe(bytes, let metadata))
		{
			Console.Error.WriteLine(scope $"AudioPlayground: unrecognised audio: {path}");
			return null;
		}

		let clip = new AudioClip();
		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		clip.Loop = loop;
		clip.EncodedData.AddRange(bytes);
		return clip;
	}
}
