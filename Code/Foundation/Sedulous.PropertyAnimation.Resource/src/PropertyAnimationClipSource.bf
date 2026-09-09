using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.PropertyAnimation;

namespace Sedulous.PropertyAnimation.Resource;

/// The cooked WIRE for a clip: FLAT PARALLEL ARRAYS, so the serializer never nests.
///
/// The scalar key pool is shared by every channel and indexed per channel; the channels
/// appear in track then channel order; the rotation keys have a pool of their own, indexed
/// per track.
///
/// Reconstruction walks the SAME order the writer used, and every index is bounded against
/// the pool it reads from: a malformed record yields a partial but safe clip rather than a
/// read past the end of an array.
[Serializable]
class PropertyAnimationClipSource
{
	public float Duration = 0.0f;

	// Per track.
	public List<String> TrackComponent = new .() ~ DeleteContainerAndItems!(_);
	public List<String> TrackPath = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> TrackKind = new .() ~ delete _;

	// Per scalar CHANNEL, in track then channel order.
	public List<uint32> ChannelKeyStart = new .() ~ delete _;
	public List<uint32> ChannelKeyCount = new .() ~ delete _;

	// The scalar key pool.
	public List<float> KeyTime = new .() ~ delete _;
	public List<float> KeyValue = new .() ~ delete _;
	public List<float> KeyTangentIn = new .() ~ delete _;
	public List<float> KeyTangentOut = new .() ~ delete _;
	public List<uint8> KeyInterp = new .() ~ delete _;

	// Per track: its run of rotation keys, empty for a track that is not a rotation.
	public List<uint32> TrackQuatStart = new .() ~ delete _;
	public List<uint32> TrackQuatCount = new .() ~ delete _;
	public List<float> QuatTime = new .() ~ delete _;
	public List<Float4> QuatValue = new .() ~ delete _;

	/// Flattens a runtime clip into the wire, which is the cooking half. The channels are
	/// appended in track then channel order, so the walk back reconstructs them identically.
	public static void FromClip(PropertyAnimationClip clip, PropertyAnimationClipSource outSource)
	{
		outSource.Duration = clip.Duration;

		ClearAndDeleteItems!(outSource.TrackComponent);
		ClearAndDeleteItems!(outSource.TrackPath);
		outSource.TrackKind.Clear();
		outSource.ChannelKeyStart.Clear();
		outSource.ChannelKeyCount.Clear();
		outSource.KeyTime.Clear();
		outSource.KeyValue.Clear();
		outSource.KeyTangentIn.Clear();
		outSource.KeyTangentOut.Clear();
		outSource.KeyInterp.Clear();
		outSource.TrackQuatStart.Clear();
		outSource.TrackQuatCount.Clear();
		outSource.QuatTime.Clear();
		outSource.QuatValue.Clear();

		for (let track in clip.Tracks)
		{
			outSource.TrackComponent.Add(new String(track.ComponentType));
			outSource.TrackPath.Add(new String(track.PropertyPath));
			outSource.TrackKind.Add((uint8)track.Kind);

			let channelCount = (int)track.Kind.ChannelCount;
			for (int c < channelCount)
			{
				let keys = track.Channels[c].Keys;
				outSource.ChannelKeyStart.Add((uint32)outSource.KeyTime.Count);
				outSource.ChannelKeyCount.Add((uint32)keys.Count);

				for (let key in keys)
				{
					outSource.KeyTime.Add(key.Time);
					outSource.KeyValue.Add(key.Value);
					outSource.KeyTangentIn.Add(key.TangentIn);
					outSource.KeyTangentOut.Add(key.TangentOut);
					outSource.KeyInterp.Add((uint8)key.Interpolation);
				}
			}

			outSource.TrackQuatStart.Add((uint32)outSource.QuatTime.Count);
			outSource.TrackQuatCount.Add((uint32)track.QuatKeys.Count);
			for (let key in track.QuatKeys)
			{
				outSource.QuatTime.Add(key.Time);
				outSource.QuatValue.Add(.(key.Value.X, key.Value.Y, key.Value.Z, key.Value.W));
			}
		}
	}

	/// Rebuilds a runtime clip from the wire, which is the loading half.
	public void FillClip(PropertyAnimationClip outClip)
	{
		outClip.Duration = Duration;
		ClearAndDeleteItems!(outClip.Tracks);

		let trackCount = TrackKind.Count;
		var channelCursor = 0;

		for (int i < trackCount)
		{
			let track = new PropertyTrack();

			if (i < TrackComponent.Count)
				track.ComponentType.Set(TrackComponent[i]);
			if (i < TrackPath.Count)
				track.PropertyPath.Set(TrackPath[i]);

			// RANGE GUARD the kind: an out of range byte would make the channel count wrong and
			// desynchronise the cursor for every LATER track. Corrupt reads as a float, which
			// is a deterministic single channel walk.
			let rawKind = TrackKind[i];
			track.Kind = (rawKind <= (uint8)TrackValueKind.Color)
				? (TrackValueKind)rawKind
				: TrackValueKind.Float;

			let channelCount = (int)track.Kind.ChannelCount;
			for (int c = 0; (c < channelCount) && (channelCursor < ChannelKeyStart.Count); c++)
			{
				let start = ChannelKeyStart[channelCursor];
				let count = (channelCursor < ChannelKeyCount.Count)
					? ChannelKeyCount[channelCursor]
					: 0;

				for (uint32 j = 0; j < count; j++)
				{
					let index = (int)(start + j);
					if (index >= KeyTime.Count)
						break;

					var key = CurveKey();
					key.Time = KeyTime[index];
					key.Value = (index < KeyValue.Count) ? KeyValue[index] : 0.0f;
					key.TangentIn = (index < KeyTangentIn.Count) ? KeyTangentIn[index] : 0.0f;
					key.TangentOut = (index < KeyTangentOut.Count) ? KeyTangentOut[index] : 0.0f;

					// A truncated or out of range mode keeps the key's own default, which is
					// linear, rather than silently becoming a hold.
					if ((index < KeyInterp.Count)
						&& (KeyInterp[index] <= (uint8)CurveKeyInterpolation.Cubic))
						key.Interpolation = (CurveKeyInterpolation)KeyInterp[index];

					if (c < PropertyTrack.cMaxChannels)
						track.Channels[c].AddKey(key);
				}

				channelCursor++;
			}

			if ((track.Kind == .Quat) && (i < TrackQuatStart.Count))
			{
				let start = TrackQuatStart[i];
				let count = (i < TrackQuatCount.Count) ? TrackQuatCount[i] : 0;

				for (uint32 j = 0; j < count; j++)
				{
					let index = (int)(start + j);
					if ((index >= QuatTime.Count) || (index >= QuatValue.Count))
						break;

					let value = QuatValue[index];
					track.QuatKeys.Add(.(QuatTime[index], .(value.X, value.Y, value.Z, value.W)));
				}
			}

			outClip.Tracks.Add(track);
		}
	}
}
