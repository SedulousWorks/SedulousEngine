using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A multi channel keyframe editor: N curves on one set of axes, edited by direct manipulation.
///
/// MODEL AGNOSTIC by design. A caller describes its channels, pushes keys in, and listens for
/// the edits, then projects them back onto whatever it actually holds. So the same widget serves
/// particle curves, animation easing, audio envelopes, tone mapping and gameplay tuning, and
/// none of those need to know about each other.
///
/// The TIME axis can work two ways. Left alone, it fits zero to TimeSpan across the width, which
/// is what a standalone curve wants. Handed a shared transform, it maps time exactly as the
/// [[Timeline]] does, so a curve drawn under a dopesheet zooms and scrolls with it and the two
/// stay aligned rather than each keeping a private idea of where a second is.
///
/// The VALUE axis is a viewport, not a limit. It auto fits until the user zooms or pans, at
/// which point it stays where they put it, and dragging a key past the edge extrapolates rather
/// than clamping, because a frame that could not be left would make values outside it
/// unreachable.
class CurveCanvas : View
{
	private const float KeyHitRadius = 8.0f;
	private const float KeyDrawRadius = 4.0f;
	private const float HandleScreenLength = 32.0f;
	private const float HandleHitRadius = 7.0f;
	private const float HandleDrawRadius = 4.0f;
	private const float ValueZoomStep = 1.2f;
	private const int32 GridDivisions = 4;
	private const int32 CurveSamples = 128;

	/// One keypoint. Time is in seconds along the axis; the tangents are slopes, in value per
	/// second, at the key.
	public struct Key
	{
		public float Time = 0.0f;
		public float Value = 0.0f;
		public float TangentIn = 0.0f;
		public float TangentOut = 0.0f;
		public TangentMode Mode = .Mirrored;

		public this() {}

		public this(float time, float value, float tangentIn = 0.0f, float tangentOut = 0.0f,
			TangentMode mode = .Mirrored)
		{
			Time = time;
			Value = value;
			TangentIn = tangentIn;
			TangentOut = tangentOut;
			Mode = mode;
		}
	}

	private enum DraggingHandle
	{
		None,
		In,
		Out
	}

	/// The canvas's own copy of a channel. The strings are OWNED here, so a descriptor handed
	/// back stays valid for as long as the canvas does rather than for as long as the caller's
	/// buffer.
	private class Channel
	{
		public String Name = new .() ~ delete _;
		public String Description = new .() ~ delete _;
		public Color StrokeColor = .(0, 0, 0, 0);
		public float DefaultValue = 0.0f;
		public bool Hidden = false;
		public bool Locked = false;
		public float MinValue = 0.0f;
		public float MaxValue = 0.0f;
		public float DisplayMin = 0.0f;
		public float DisplayMax = 0.0f;
		public CurveInterpolation Interpolation = .Hermite;
		public List<Key> Keys = new .() ~ delete _;

		public void Adopt(ChannelDescriptor descriptor)
		{
			Name.Set(descriptor.Name);
			Description.Set(descriptor.Description);
			StrokeColor = descriptor.StrokeColor;
			DefaultValue = descriptor.DefaultValue;
			Hidden = descriptor.Hidden;
			Locked = descriptor.Locked;
			MinValue = descriptor.MinValue;
			MaxValue = descriptor.MaxValue;
			DisplayMin = descriptor.DisplayMin;
			DisplayMax = descriptor.DisplayMax;
			Interpolation = descriptor.Interpolation;
		}

		public ChannelDescriptor Describe()
		{
			ChannelDescriptor descriptor = .();
			descriptor.Name = Name;
			descriptor.Description = Description;
			descriptor.StrokeColor = StrokeColor;
			descriptor.DefaultValue = DefaultValue;
			descriptor.Hidden = Hidden;
			descriptor.Locked = Locked;
			descriptor.MinValue = MinValue;
			descriptor.MaxValue = MaxValue;
			descriptor.DisplayMin = DisplayMin;
			descriptor.DisplayMax = DisplayMax;
			descriptor.Interpolation = Interpolation;
			return descriptor;
		}
	}

	/// The ceiling on keys per channel. Defaults to what the particle system allows.
	public int32 MaxKeys = 8;

	/// When set, every channel shares one time axis: they all hold the same number of keys and
	/// the i-th key is at the same time on each. Adding, moving or deleting one key does the
	/// same to its counterparts.
	public bool LinkedTime = false;

	/// Recompute the value range from the visible keys. Turned off the moment the user zooms or
	/// pans, because they have then framed the view themselves.
	public bool AutoFitValueRange = true;

	public float ValueMin = 0.0f;
	public float ValueMax = 1.0f;

	/// The seconds the width covers, in the standalone mapping. One keeps the old normalised
	/// behaviour for callers that never set it.
	public float TimeSpan = 1.0f;

	/// Take the time mapping from PixelsPerSecond and ScrollSeconds instead of fitting TimeSpan
	/// to the width, which is how the curve follows a dopesheet's zoom and scroll. TimeSpan is
	/// then ignored.
	public bool UseSharedTimeTransform = false;
	public float PixelsPerSecond = 100.0f;
	public float ScrollSeconds = 0.0f;

	public Event<delegate void()> OnEditBegin ~ _.Dispose();
	public Event<delegate void()> OnEditEnd ~ _.Dispose();
	/// A key moved. Carries the channel and key indices.
	public Event<delegate void(int32, int32)> OnKeyChanged ~ _.Dispose();
	public Event<delegate void(int32, int32)> OnKeyAdded ~ _.Dispose();
	/// A key was deleted. Carries the index it HAD, before the removal.
	public Event<delegate void(int32, int32)> OnKeyRemoved ~ _.Dispose();
	/// The USER changed the selection, by clicking, adding, or deleting the selected key, which
	/// reports minus one. Programmatic resets stay quiet so a host can rebuild without looping.
	public Event<delegate void(int32, int32)> OnSelectionChanged ~ _.Dispose();

	private List<Channel> mChannels = new .() ~ DeleteContainerAndItems!(_);
	private int32 mSelectedChannel = -1;
	private int32 mSelectedKey = -1;
	private int32 mDraggingChannel = -1;
	private int32 mDraggingKey = -1;
	private DraggingHandle mDraggingHandle = .None;
	private bool mInGesture = false;
	private bool mValuePanning = false;
	private float mValuePanStartY = 0.0f;
	private float mValuePanStartMin = 0.0f;
	private float mValuePanStartMax = 1.0f;

	public int32 ChannelCount => (int32)mChannels.Count;

	public int32 SelectedChannel => mSelectedChannel;

	public int32 SelectedKeyIndex => mSelectedKey;

	/// The strings in the result are views into the canvas's own copies.
	public ChannelDescriptor GetChannelDescriptor(int32 index) => mChannels[index].Describe();

	public int32 GetKeyCount(int32 channelIndex) => (int32)mChannels[channelIndex].Keys.Count;

	public Key GetKey(int32 channelIndex, int32 keyIndex) =>
		mChannels[channelIndex].Keys[keyIndex];

	/// Sets the channel set, CLEARING every key. Selection falls to the first channel when
	/// there is one.
	public void SetChannels(Span<ChannelDescriptor> channels)
	{
		ClearAndDeleteItems!(mChannels);

		for (let descriptor in channels)
		{
			let channel = new Channel();
			channel.Adopt(descriptor);
			mChannels.Add(channel);
		}

		mSelectedChannel = mChannels.IsEmpty ? -1 : 0;
		mSelectedKey = -1;
		mDraggingChannel = -1;
		mDraggingKey = -1;
		Invalidate();
	}

	/// Replaces one channel's keys. Does NOT enforce the linked time alignment, because a host
	/// pushing channels in one at a time is briefly inconsistent by construction.
	public void SetKeys(int32 channelIndex, Span<Key> keys)
	{
		if ((channelIndex < 0) || (channelIndex >= mChannels.Count))
			return;

		let channel = mChannels[channelIndex];
		channel.Keys.Clear();
		for (let key in keys)
			channel.Keys.Add(key);

		// Whatever was being dragged or selected in this channel no longer exists.
		if (mDraggingChannel == channelIndex)
		{
			mDraggingChannel = -1;
			mDraggingKey = -1;
		}
		if (mSelectedChannel == channelIndex)
			mSelectedKey = -1;

		Invalidate();
	}

	/// The curve's value at a time, by this channel's own interpolation. Flat outside the ends.
	public float Evaluate(int32 channelIndex, float t)
	{
		let keys = mChannels[channelIndex].Keys;
		if (keys.IsEmpty)
			return 0.0f;

		let last = keys.Count - 1;
		if ((keys.Count == 1) || (t <= keys[0].Time))
			return keys[0].Value;
		if (t >= keys[last].Time)
			return keys[last].Value;

		for (int i = 0; i < last; i++)
		{
			let a = keys[i];
			let b = keys[i + 1];
			if ((t < a.Time) || (t > b.Time))
				continue;

			// Two keys at the same time have no span to interpolate across.
			let span = b.Time - a.Time;
			if (span < 0.0001f)
				return a.Value;

			let k = (t - a.Time) / span;
			switch (mChannels[channelIndex].Interpolation)
			{
			case .Linear:
				return a.Value + ((b.Value - a.Value) * k);

			case .Step:
				return a.Value;

			case .Hermite:
				// The tangents are scaled by the SEGMENT, because a slope in value per second
				// has to become a slope in value per unit of k to enter the basis.
				let k2 = k * k;
				let k3 = k2 * k;
				return (((2 * k3) - (3 * k2) + 1) * a.Value)
					+ ((k3 - (2 * k2) + k) * (a.TangentOut * span))
					+ (((-2 * k3) + (3 * k2)) * b.Value)
					+ ((k3 - k2) * (b.TangentIn * span));
			}
		}

		return keys[last].Value;
	}
}
