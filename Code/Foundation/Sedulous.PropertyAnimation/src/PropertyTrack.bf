using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation;

/// One animated property.
///
/// The component type is the reflected type's name, which the engine resolves to a live
/// component on the owning entity, and the path is dot joined for a nested property, such as
/// "light.tint". A float drives the first channel, a vector the first three, a colour all
/// four, and a rotation its own keys instead.
class PropertyTrack
{
	/// The widest a scalar kind needs, which is a colour's four.
	public const int cMaxChannels = 4;

	public String ComponentType = new .() ~ delete _;
	public String PropertyPath = new .() ~ delete _;
	public TrackValueKind Kind = .Float;

	public Curve[cMaxChannels] Channels = .(new .(), new .(), new .(), new .())
		~ { for (var curve in _) delete curve; };

	public List<QuatKey> QuatKeys = new .() ~ delete _;

	/// The track's own span: the longest of the channels it uses, and its rotation keys.
	public float Duration
	{
		get
		{
			var duration = 0.0f;
			let channelCount = (int)Kind.ChannelCount;
			for (int i < channelCount)
				duration = Max(duration, Channels[i].Duration);

			if (!QuatKeys.IsEmpty)
				duration = Max(duration, QuatKeys[QuatKeys.Count - 1].Time);

			return duration;
		}
	}

	/// Samples the track. The caller wraps or clamps the time: looping is the clip's business,
	/// not a track's.
	public PropertyValue Sample(float time)
	{
		switch (Kind)
		{
		case .Float:
			return .FromFloat(Channels[0].Evaluate(time));
		case .Float3:
			return .FromFloat3(.(Channels[0].Evaluate(time), Channels[1].Evaluate(time),
				Channels[2].Evaluate(time)));
		case .Color:
			return .FromColor(.(Channels[0].Evaluate(time), Channels[1].Evaluate(time),
				Channels[2].Evaluate(time), Channels[3].Evaluate(time)));
		case .Quat:
			return .FromQuaternion(SampleQuat(time));
		}
	}

	/// Samples, but KEEPS the current value for any channel that has no keys.
	///
	/// An empty channel does not drive its component. Without this an entity animated only in
	/// one axis would be teleported to nought in the other two, the empty curves sampling
	/// zero. A current value that could not be read falls back to nought, and a track whose
	/// channels are all empty answers the current value unchanged, which writes nothing.
	public PropertyValue SampleMerged(float time, PropertyValue current)
	{
		switch (Kind)
		{
		case .Float:
			return (Channels[0].KeyCount > 0) ? PropertyValue.FromFloat(Channels[0].Evaluate(time))
				: current;

		case .Float3:
			let vector = current.HasValue ? current.Vector : Float3(0, 0, 0);
			return .FromFloat3(.(
				(Channels[0].KeyCount > 0) ? Channels[0].Evaluate(time) : vector.X,
				(Channels[1].KeyCount > 0) ? Channels[1].Evaluate(time) : vector.Y,
				(Channels[2].KeyCount > 0) ? Channels[2].Evaluate(time) : vector.Z));

		case .Color:
			let color = current.HasValue ? current.Color : Color(0, 0, 0, 0);
			return .FromColor(.(
				(Channels[0].KeyCount > 0) ? Channels[0].Evaluate(time) : color.R,
				(Channels[1].KeyCount > 0) ? Channels[1].Evaluate(time) : color.G,
				(Channels[2].KeyCount > 0) ? Channels[2].Evaluate(time) : color.B,
				(Channels[3].KeyCount > 0) ? Channels[3].Evaluate(time) : color.A));

		case .Quat:
			return QuatKeys.IsEmpty ? current : PropertyValue.FromQuaternion(SampleQuat(time));
		}
	}

	/// Interpolates the rotation keys, clamped to the ends and along the shorter arc.
	public Quaternion SampleQuat(float time)
	{
		let count = QuatKeys.Count;
		if (count == 0)
			return .Identity;
		if ((count == 1) || (time <= QuatKeys[0].Time))
			return QuatKeys[0].Value;
		if (time >= QuatKeys[count - 1].Time)
			return QuatKeys[count - 1].Value;

		var i = 0;
		while (((i + 1) < count) && (QuatKeys[i + 1].Time <= time))
			i++;

		let a = QuatKeys[i];
		let b = QuatKeys[i + 1];
		let segment = b.Time - a.Time;
		if (segment <= 1e-6f)
			return b.Value;

		return Slerp(a.Value, b.Value, (time - a.Time) / segment);
	}
}
