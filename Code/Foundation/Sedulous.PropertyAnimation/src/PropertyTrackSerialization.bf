using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.PropertyAnimation;

/// One property track, keyed: its target, its kind, each channel's keys and the quaternion keys.
/// For data that holds tracks one by one (a sequence's property tracks); a clip's cooked form is
/// its own flat wire.
static class PropertyTrackSerialization
{
	public static void Serialize(ISerializer ar, PropertyTrack track)
	{
		let reading = ar.Mode == .Read;
		Sedulous.Core.Serialization.Serialize(ar, "component", track.ComponentType);
		Sedulous.Core.Serialization.Serialize(ar, "path", track.PropertyPath);
		uint8 kind = (uint8)track.Kind;
		SerializeValue(ar, "kind", ref kind);

		// Every channel's keys in one pool, channel after channel, with each channel's count.
		let keyCount = scope List<uint32>();
		let keyTime = scope List<float>();
		let keyValue = scope List<float>();
		let keyTangentIn = scope List<float>();
		let keyTangentOut = scope List<float>();
		let keyInterpolation = scope List<uint8>();
		let keyTangentMode = scope List<uint8>();
		let quatTime = scope List<float>();
		let quatValue = scope List<Float4>();
		if (!reading)
		{
			for (int c < PropertyTrack.cMaxChannels)
			{
				let channel = track.Channels[c];
				keyCount.Add((uint32)channel.KeyCount);
				for (let key in channel.Keys)
				{
					keyTime.Add(key.Time);
					keyValue.Add(key.Value);
					keyTangentIn.Add(key.TangentIn);
					keyTangentOut.Add(key.TangentOut);
					keyInterpolation.Add((uint8)key.Interpolation);
					keyTangentMode.Add((uint8)key.TangentMode);
				}
			}
			for (let key in track.QuatKeys)
			{
				quatTime.Add(key.Time);
				quatValue.Add(.(key.Value.X, key.Value.Y, key.Value.Z, key.Value.W));
			}
		}
		ar.Key("keyCount");
		SerializeList(ar, keyCount);
		ar.Key("keyTime");
		SerializeList(ar, keyTime);
		ar.Key("keyValue");
		SerializeList(ar, keyValue);
		ar.Key("keyTangentIn");
		SerializeList(ar, keyTangentIn);
		ar.Key("keyTangentOut");
		SerializeList(ar, keyTangentOut);
		ar.Key("keyInterpolation");
		SerializeList(ar, keyInterpolation);
		ar.Key("keyTangentMode");
		SerializeList(ar, keyTangentMode);
		ar.Key("quatTime");
		SerializeList(ar, quatTime);
		ar.Key("quatValue");
		SerializeList(ar, quatValue);
		if (!reading)
			return;

		// Every count and index is checked against the pools before use: a short or damaged
		// payload leaves the track empty rather than reading past a list.
		track.Kind = (kind <= (uint8)TrackValueKind.Color) ? (TrackValueKind)kind : .Float;
		let pool = keyTime.Count;
		let pooled = (keyValue.Count == pool) && (keyTangentIn.Count == pool) && (keyTangentOut.Count == pool)
			&& (keyInterpolation.Count == pool) && (keyTangentMode.Count == pool);
		int cursor = 0;
		for (int c < PropertyTrack.cMaxChannels)
		{
			track.Channels[c].Clear();
			let count = (pooled && (c < keyCount.Count)) ? (int)keyCount[c] : 0;
			if (count > pool - cursor)
				break;
			for (int k < count)
			{
				var key = CurveKey();
				key.Time = keyTime[cursor];
				key.Value = keyValue[cursor];
				key.TangentIn = keyTangentIn[cursor];
				key.TangentOut = keyTangentOut[cursor];
				key.Interpolation = (keyInterpolation[cursor] <= (uint8)CurveKeyInterpolation.Cubic)
					? (CurveKeyInterpolation)keyInterpolation[cursor] : .Linear;
				key.TangentMode = (keyTangentMode[cursor] <= (uint8)CurveTangentMode.Flat)
					? (CurveTangentMode)keyTangentMode[cursor] : .Broken;
				track.Channels[c].AddKey(key);
				cursor++;
			}
		}
		track.QuatKeys.Clear();
		for (int i < Math.Min(quatTime.Count, quatValue.Count))
		{
			let v = quatValue[i];
			track.QuatKeys.Add(.(quatTime[i], .(v.X, v.Y, v.Z, v.W)));
		}
	}
}
