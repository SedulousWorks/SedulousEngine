using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// The key edits the view and the panel share: finding, retiming and upserting keys on a track
/// by time, keeping every channel and the quaternion list time-sorted.
static class TrackKeys
{
	public const float cTimeEps = 1e-4f;

	public static int32 FindChannelKeyAt(PropertyTrack track, uint32 channel, float time)
	{
		let keys = track.Channels[channel].Keys;
		for (int i < keys.Count)
		{
			if (Math.Abs(keys[i].Time - time) < cTimeEps)
				return (int32)i;
		}
		return -1;
	}

	public static int32 FindQuatKeyAt(PropertyTrack track, float time)
	{
		for (int i < track.QuatKeys.Count)
		{
			if (Math.Abs(track.QuatKeys[i].Time - time) < cTimeEps)
				return (int32)i;
		}
		return -1;
	}

	/// Retimes every channel and quaternion key sitting at t0 to t1, keeping the arrays sorted.
	public static void RetimeTrackKeysAt(PropertyTrack track, float t0, float t1)
	{
		for (uint32 ch < track.Kind.ChannelCount)
		{
			let cur = track.Channels[ch];
			let keys = scope List<CurveKey>();
			for (var k in cur.Keys)
			{
				if (Math.Abs(k.Time - t0) < cTimeEps)
					k.Time = t1;
				keys.Add(k);
			}
			cur.Clear();
			for (let k in keys)
				cur.AddKey(k); // AddKey keeps time order
		}
		for (int i < track.QuatKeys.Count)
		{
			if (Math.Abs(track.QuatKeys[i].Time - t0) < cTimeEps)
				track.QuatKeys[i].Time = t1;
		}
		SortQuatKeys(track);
	}

	/// Sets or inserts a channel key at the time; a new key inherits the channel's
	/// interpolation, Linear on an empty channel.
	public static void UpsertChannelKeyAt(PropertyTrack track, uint32 channel, float time, float value)
	{
		let cur = track.Channels[channel];
		let at = FindChannelKeyAt(track, channel, time);
		if (at >= 0)
		{
			cur.Keys[at].Value = value;
			return;
		}
		var k = CurveKey();
		k.Time = time;
		k.Value = value;
		k.Interpolation = (cur.KeyCount > 0) ? cur.Keys[0].Interpolation : .Linear;
		cur.AddKey(k);
	}

	public static void UpsertQuatKeyAt(PropertyTrack track, float time, Quaternion value)
	{
		let at = FindQuatKeyAt(track, time);
		if (at >= 0)
		{
			track.QuatKeys[at].Value = value;
			return;
		}
		track.QuatKeys.Add(QuatKey(time, value));
		SortQuatKeys(track);
	}

	/// Decomposes a captured value into per-channel key writes at the time. False when the
	/// value's kind does not match the track's; the caller warns and skips.
	public static bool UpsertTrackValueAt(PropertyTrack track, float time, PropertyValue v)
	{
		if (!v.HasValue || (v.Kind != track.Kind))
			return false;
		switch (track.Kind)
		{
		case .Float:
			UpsertChannelKeyAt(track, 0, time, v.Scalar);
		case .Float3:
			let f = v.Vector;
			UpsertChannelKeyAt(track, 0, time, f.X);
			UpsertChannelKeyAt(track, 1, time, f.Y);
			UpsertChannelKeyAt(track, 2, time, f.Z);
		case .Color:
			let c = v.Color;
			UpsertChannelKeyAt(track, 0, time, c.R);
			UpsertChannelKeyAt(track, 1, time, c.G);
			UpsertChannelKeyAt(track, 2, time, c.B);
			UpsertChannelKeyAt(track, 3, time, c.A);
		case .Quat:
			UpsertQuatKeyAt(track, time, v.Rotation);
		}
		return true;
	}

	/// Removes every channel and quaternion key at the time.
	public static void RemoveKeysAt(PropertyTrack track, float time)
	{
		for (uint32 ch < track.Kind.ChannelCount)
		{
			let at = FindChannelKeyAt(track, ch, time);
			if (at < 0)
				continue;
			let cur = track.Channels[ch];
			let keep = scope List<CurveKey>();
			for (int i < cur.Keys.Count)
			{
				if (i != at)
					keep.Add(cur.Keys[i]);
			}
			cur.Clear();
			for (let k in keep)
				cur.AddKey(k);
		}
		let qat = FindQuatKeyAt(track, time);
		if (qat >= 0)
			track.QuatKeys.RemoveAt(qat);
	}

	/// The sorted, de-duplicated key times on a track: a dopesheet marker wherever any channel
	/// or a quaternion key lands.
	public static void CollectKeyTimes(PropertyTrack track, List<float> outTimes)
	{
		outTimes.Clear();
		mixin AddTime(float t)
		{
			bool seen = false;
			for (let e in outTimes)
			{
				if (Math.Abs(e - t) < cTimeEps)
				{
					seen = true;
					break;
				}
			}
			if (!seen)
				outTimes.Add(t);
		}
		for (uint32 c < track.Kind.ChannelCount)
		{
			for (let k in track.Channels[c].Keys)
				AddTime!(k.Time);
		}
		for (let q in track.QuatKeys)
			AddTime!(q.Time);
		outTimes.Sort(scope (a, b) => a <=> b);
	}

	private static void SortQuatKeys(PropertyTrack track)
	{
		track.QuatKeys.Sort(scope (a, b) => a.Time <=> b.Time);
	}
}
