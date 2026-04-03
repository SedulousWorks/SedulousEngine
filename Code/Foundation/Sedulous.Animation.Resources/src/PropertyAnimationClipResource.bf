using System;
using System.IO;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Animation;

namespace Sedulous.Animation.Resources;

/// Resource wrapping a PropertyAnimationClip for the resource system.
class PropertyAnimationClipResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("propertyanimationclip");

	private PropertyAnimationClip mClip;
	private bool mOwnsClip;

	/// The underlying property animation clip data.
	public PropertyAnimationClip Clip => mClip;

	/// Duration of the animation in seconds.
	public float Duration => mClip?.Duration ?? 0;

	public this()
	{
		mClip = null;
		mOwnsClip = false;
	}

	public this(PropertyAnimationClip clip, bool ownsClip = false)
	{
		mClip = clip;
		mOwnsClip = ownsClip;
		if (clip != null && Name.IsEmpty)
			Name.Set(clip.Name);
	}

	public ~this()
	{
		if (mOwnsClip && mClip != null)
			delete mClip;
	}

	/// Sets the property animation clip. Takes ownership if ownsClip is true.
	public void SetClip(PropertyAnimationClip clip, bool ownsClip = false)
	{
		if (mOwnsClip && mClip != null)
			delete mClip;
		mClip = clip;
		mOwnsClip = ownsClip;
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mClip == null)
				return .InvalidData;

			mClip.Serialize(s);
		}
		else
		{
			let clip = new PropertyAnimationClip();
			clip.Serialize(s);
			SetClip(clip, true);
		}

		return .Ok;
	}

}
