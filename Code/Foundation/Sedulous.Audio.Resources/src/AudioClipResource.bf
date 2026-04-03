using Sedulous.Audio;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Audio.Resources;

/// Resource wrapper for audio clips, enabling integration with the ResourceSystem.
class AudioClipResource : Resource
{
	public override ResourceType ResourceType => .("audioclip");
	private AudioClip mClip;

	/// Gets or sets the wrapped audio clip.
	public AudioClip Clip
	{
		get => mClip;
		set => mClip = value;
	}

	public ~this()
	{
		if (mClip != null)
			delete mClip;
	}

	public override int32 SerializationVersion => 1;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		// Audio clip data is loaded from raw bytes, not serialized
		return .Ok;
	}
}
