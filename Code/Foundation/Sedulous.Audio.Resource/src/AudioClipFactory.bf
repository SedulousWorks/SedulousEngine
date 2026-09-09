using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Resource;

namespace Sedulous.Audio.Resource;

/// Builds a cooked record into a playable clip.
///
/// PURELY CPU either way: an in memory clip reads its container bytes, and a streamed one
/// takes a lazy source that pages them on demand. Nothing is uploaded, so the whole build
/// runs on a worker and there is nothing left for the main thread to do.
class AudioClipFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<AudioClip>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as AudioClipSource;
		if (source == null)
		{
			// Something else was stored under this type name, so this is not a clip rather
			// than a clip that failed to read.
			delete stored;
			return null;
		}
		defer delete source;

		let clip = new AudioClip();
		clip.Channels = source.Channels;
		clip.SampleRate = source.SampleRate;
		clip.FrameCount = source.FrameCount;
		clip.DurationSeconds = source.DurationSeconds;
		clip.Gain = source.Gain;
		clip.Loop = source.Loop;
		clip.LoopStartFrame = source.LoopStartFrame;
		clip.LoopEndFrame = source.LoopEndFrame;
		clip.Stream = source.Stream;
		clip.KeepCompressed = source.KeepCompressed;

		if (source.Stream)
		{
			clip.StreamSource = new ContentInstanceStreamSource(instance);
			return clip;
		}

		let data = instance.ReadData("data");
		if (data == null)
		{
			// A clip with no payload is not playable, and answering one would put a silent
			// voice in the pool for every play of it.
			delete clip;
			return null;
		}
		defer delete data;

		let size = data.Size();
		if (size <= 0)
		{
			delete clip;
			return null;
		}

		clip.EncodedData.Count = (int)size;
		if (data.Read(.(clip.EncodedData.Ptr, (int)size)) != (int)size)
		{
			delete clip;
			return null;
		}
		return clip;
	}
}
