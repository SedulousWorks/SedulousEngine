using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// The clip as the toolkit's dopesheet and curve view see it: a channel per scalar curve of each track
/// (a Float3's x, y, z, a Color's r, g, b, a) and a rotation track one channel of its keys; the curve
/// view the chosen tracks' scalar curves. Each move, deletion, insertion and curve edit is one step of
/// the document's, a first key on an empty channel taking the application's value of its target.
class ClipSource : ICurveSource, ITimelineSource
{
	/// A channel: its track and, for a scalar track, which of its curves (-1: a rotation's keys).
	public struct Channel
	{
		public int Track = 0;
		public int Curve = -1;

		public this(int track, int curve)
		{
			Track = track;
			Curve = curve;
		}
	}

	/// Keys this close are at one time.
	private const float cSameTime = 1e-4f;

	/// Borrowed: its owner's, which outlives it.
	private ClipDocument mDocument;
	/// The dopesheet's.
	private List<Channel> mChannels = new .() ~ delete _;
	/// The curve view's: the shown tracks' scalar channels.
	private List<Channel> mCurves = new .() ~ delete _;
	private List<int> mShown = new .() ~ delete _;
	/// A move's clip as it began.
	private PropertyAnimationClip mMoveFrom = new .() ~ delete _;
	private List<ITimelineSourceClient> mTimelineClients = new .() ~ delete _;

	/// The application's value of a track's target now (the bound entity's), for a first key; null
	/// or empty: the type's zero.
	public delegate Sedulous.PropertyAnimation.PropertyValue(PropertyTrack track) CurrentValue ~ delete _;

	public this(ClipDocument document)
	{
		mDocument = document;
		Rebuild();
	}

	public Span<Channel> Channels => mChannels;
	public Span<int> ShownTracks => mShown;

	/// The tracks whose curves the curve view shows (the chosen ones); empty: none.
	public void ShowTracks(Span<int> tracks)
	{
		mShown.Clear();
		mShown.AddRange(tracks);
		Refresh();
	}

	/// The document changed (its owner calls this from the document's OnChanged): the channels and
	/// curves read again, the views told.
	public void Refresh()
	{
		Rebuild();
		for (int i = 0; i < mTimelineClients.Count; ++i)
			mTimelineClients[i].OnTimelineChanged();
		NotifyCurvesChanged();
	}

	/// A track's channels' path ("Light.Tint"), into `outPath`.
	public static void TrackPath(PropertyTrack track, String outPath)
	{
		outPath.AppendF("{}.{}", track.ComponentType, track.PropertyPath);
	}

	// === ITimelineSource ===

	public int ChannelCount => mChannels.Count;

	public void GetChannelPath(int channel, String outPath)
	{
		if ((channel < 0) || (channel >= mChannels.Count) || !Valid(mChannels[channel]))
			return;
		ChannelName(mChannels[channel], outPath);
	}

	public void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		if ((channel < 0) || (channel >= mChannels.Count) || !Valid(mChannels[channel]))
			return;
		let at = mChannels[channel];
		let track = mDocument.Clip.Tracks[at.Track];
		if (at.Curve < 0)
		{
			for (let key in track.QuatKeys)
				outTimes.Add(key.Time);
		}
		else
		{
			for (let key in track.Channels[at.Curve].Keys)
				outTimes.Add(key.Time);
		}
	}

	public void BeginKeysMove()
	{
		mDocument.BeginGesture();
		mDocument.Clip.CopyTo(mMoveFrom);
	}

	public void PreviewKeysMove(Span<TimelineKeyRef> keys, float delta, List<TimelineKeyRef> moved)
	{
		moved.Clear();
		if (!mDocument.InGesture)
			return;
		let clip = mDocument.GestureClip;
		mMoveFrom.CopyTo(clip); // each preview from where the keys were
		// Channel by channel: its moved keys shifted, the channel sorted again.
		let done = scope List<int>();
		let indices = scope List<int>();
		let placed = scope List<int>();
		for (let first in keys)
		{
			if (done.Contains(first.Channel) || (first.Channel < 0) || (first.Channel >= mChannels.Count) || !Valid(mChannels[first.Channel]))
				continue;
			done.Add(first.Channel);
			indices.Clear();
			for (let key in keys)
			{
				if (key.Channel == first.Channel)
					indices.Add(key.Index);
			}
			let at = mChannels[first.Channel];
			let track = clip.Tracks[at.Track];
			if (at.Curve < 0)
				MoveQuatKeys(track.QuatKeys, indices, delta, placed);
			else
			{
				MoveCurveKeys(track.Channels[at.Curve].Keys, indices, delta, placed);
				track.Channels[at.Curve].ApplyTangentModes();
			}
			for (let index in placed)
				moved.Add(.(first.Channel, index));
		}
		mDocument.PreviewGesture();
	}

	public void CommitKeysMove() => mDocument.CommitGesture("propanim-move-keys");

	public void CancelKeysMove() => mDocument.CancelGesture();

	public bool DeleteKeys(Span<TimelineKeyRef> keys)
	{
		// Only keys that are there; none, nothing changes.
		let there = scope List<TimelineKeyRef>();
		let times = scope List<float>();
		for (let key in keys)
		{
			if ((key.Channel < 0) || (key.Channel >= mChannels.Count))
				continue;
			GetKeyTimes(key.Channel, times);
			if ((key.Index >= 0) && (key.Index < times.Count))
				there.Add(key);
		}
		if (there.IsEmpty)
			return false;
		// Last first, so each index still names its key.
		there.Sort(scope (a, b) => b.Index <=> a.Index);
		let channels = scope List<Channel>();
		channels.AddRange(mChannels);
		mDocument.Edit("propanim-delete-keys", scope [&] (clip) =>
			{
				for (let key in there)
				{
					let at = channels[key.Channel];
					let track = clip.Tracks[at.Track];
					if (at.Curve < 0)
						track.QuatKeys.RemoveAt(key.Index);
					else
					{
						track.Channels[at.Curve].Keys.RemoveAt(key.Index);
						track.Channels[at.Curve].ApplyTangentModes();
					}
				}
			});
		return true;
	}

	public bool InsertKey(int channel, float time, out TimelineKeyRef made)
	{
		made = .();
		if ((channel < 0) || (channel >= mChannels.Count) || !Valid(mChannels[channel]) || !mDocument.HasClip)
			return false;
		let at = mChannels[channel];
		let keyTime = Math.Max(0.0f, time);
		let track = mDocument.Clip.Tracks[at.Track];
		// A key already at that time is the one made.
		let times = scope List<float>();
		GetKeyTimes(channel, times);
		for (int i < times.Count)
		{
			if (Math.Abs(times[i] - keyTime) < cSameTime)
			{
				made = .(channel, i);
				return true;
			}
		}
		let current = (CurrentValue != null) ? CurrentValue(track) : Sedulous.PropertyAnimation.PropertyValue.Empty;
		var index = 0;
		if (at.Curve < 0)
		{
			let value = !track.QuatKeys.IsEmpty ? track.SampleQuat(keyTime)
				: ((current.HasValue && (current.Kind == .Quat)) ? current.Rotation : Quaternion.Identity);
			for (let key in track.QuatKeys)
				index += (key.Time < keyTime) ? 1 : 0;
			let place = index;
			mDocument.Edit("propanim-insert-key", scope [&] (clip) => { clip.Tracks[at.Track].QuatKeys.Insert(place, QuatKey(keyTime, value)); });
		}
		else
		{
			let curve = track.Channels[at.Curve];
			let value = (curve.KeyCount > 0) ? curve.Evaluate(keyTime) : PartOf(current, track.Kind, at.Curve);
			for (let key in curve.Keys)
				index += (key.Time < keyTime) ? 1 : 0;
			mDocument.Edit("propanim-insert-key", scope [&] (clip) =>
				{
					let edited = clip.Tracks[at.Track].Channels[at.Curve];
					var key = CurveKey(keyTime, value, .Cubic);
					key.TangentMode = .Auto;
					edited.AddKey(key);
					edited.ApplyTangentModes();
				});
		}
		made = .(channel, index);
		return true;
	}

	public void AddTimelineClient(ITimelineSourceClient client)
	{
		mTimelineClients.Add(client);
	}

	public void RemoveTimelineClient(ITimelineSourceClient client)
	{
		for (int i = 0; i < mTimelineClients.Count; ++i)
		{
			if (mTimelineClients[i] === client)
			{
				mTimelineClients.RemoveAt(i);
				return;
			}
		}
	}

	// === ICurveSource ===

	public override int CurveCount => mCurves.Count;

	public override void GetCurveInfo(int curve, CurveInfo outInfo)
	{
		if ((curve < 0) || (curve >= mCurves.Count) || !Valid(mCurves[curve]))
			return;
		let at = mCurves[curve];
		outInfo.Name.Clear();
		ChannelName(at, outInfo.Name);
		outInfo.StrokeColor = PartColor(mDocument.Clip.Tracks[at.Track].Kind, at.Curve);
	}

	public override Span<CurveKey> GetKeys(int curve)
	{
		if ((curve < 0) || (curve >= mCurves.Count) || !Valid(mCurves[curve]))
			return default;
		let at = mCurves[curve];
		return mDocument.Clip.Tracks[at.Track].Channels[at.Curve].Keys;
	}

	public override void BeginKeysEdit() => mDocument.BeginGesture();

	public override void PreviewKeys(int curve, Span<CurveKey> keys)
	{
		if (!mDocument.InGesture || (curve < 0) || (curve >= mCurves.Count) || !Valid(mCurves[curve]))
			return;
		let at = mCurves[curve];
		let edited = mDocument.GestureClip.Tracks[at.Track].Channels[at.Curve].Keys;
		edited.Clear();
		edited.AddRange(keys);
		mDocument.PreviewGesture();
	}

	public override void CommitKeysEdit() => mDocument.CommitGesture("propanim-edit-curve");

	public override void CancelKeysEdit() => mDocument.CancelGesture();

	// === Private ===

	private void Rebuild()
	{
		let clip = mDocument.Clip;
		mChannels.Clear();
		for (int t < clip.Tracks.Count)
		{
			let track = clip.Tracks[t];
			if (track.Kind == .Quat)
			{
				mChannels.Add(.(t, -1));
				continue;
			}
			for (int c < (int)track.Kind.ChannelCount)
				mChannels.Add(.(t, c));
		}
		// The shown tracks that are still there; their scalar channels the curves.
		for (int i = mShown.Count - 1; i >= 0; i--)
		{
			if (mShown[i] >= clip.Tracks.Count)
				mShown.RemoveAt(i);
		}
		mCurves.Clear();
		for (let t in mShown)
		{
			let track = clip.Tracks[t];
			if (track.Kind == .Quat)
				continue; // a rotation has no scalar curves
			for (int c < (int)track.Kind.ChannelCount)
				mCurves.Add(.(t, c));
		}
	}

	private bool Valid(Channel channel)
	{
		let clip = mDocument.Clip;
		if ((channel.Track < 0) || (channel.Track >= clip.Tracks.Count))
			return false;
		let track = clip.Tracks[channel.Track];
		return (channel.Curve < 0) ? (track.Kind == .Quat) : ((track.Kind != .Quat) && (channel.Curve < (int)track.Kind.ChannelCount));
	}

	// A channel's path: its track's, then a Float3's x, y, z or a Color's r, g, b, a.
	private void ChannelName(Channel channel, String outPath)
	{
		let track = mDocument.Clip.Tracks[channel.Track];
		TrackPath(track, outPath);
		let part = PartName(track.Kind, channel.Curve);
		if (!part.IsEmpty)
			outPath.AppendF(".{}", part);
	}

	private static StringView PartName(TrackValueKind kind, int curve)
	{
		StringView[3] xyz = .("x", "y", "z");
		StringView[4] rgba = .("r", "g", "b", "a");
		if ((kind == .Float3) && (curve >= 0) && (curve < 3))
			return xyz[curve];
		if ((kind == .Color) && (curve >= 0) && (curve < 4))
			return rgba[curve];
		return default;
	}

	// A curve's stroke: x and r red, y and g green, z and b blue, a grey, a lone float amber.
	private static Color PartColor(TrackValueKind kind, int curve)
	{
		if (kind == .Float)
			return .(0.95f, 0.75f, 0.3f, 1.0f);
		Color[4] colors = .(.(0.92f, 0.38f, 0.38f, 1.0f), .(0.42f, 0.82f, 0.45f, 1.0f), .(0.42f, 0.62f, 1.0f, 1.0f), .(0.8f, 0.8f, 0.8f, 1.0f));
		return ((curve >= 0) && (curve < 4)) ? colors[curve] : .(0.9f, 0.9f, 0.9f, 1.0f);
	}

	// A scalar channel's value in the application's value of its whole track.
	private static float PartOf(Sedulous.PropertyAnimation.PropertyValue value, TrackValueKind kind, int curve)
	{
		if (!value.HasValue)
			return 0.0f;
		switch (kind)
		{
		case .Float:
			return (value.Kind == .Float) ? value.Scalar : 0.0f;
		case .Float3:
			if ((value.Kind != .Float3) || (curve < 0) || (curve >= 3))
				return 0.0f;
			float[3] xyz = .(value.Vector.X, value.Vector.Y, value.Vector.Z);
			return xyz[curve];
		case .Color:
			if ((value.Kind != .Color) || (curve < 0) || (curve >= 4))
				return 0.0f;
			float[4] rgba = .(value.Color.R, value.Color.G, value.Color.B, value.Color.A);
			return rgba[curve];
		default:
			return 0.0f;
		}
	}

	// Keys sorted again by time after some were moved (stably: a key keeps its place among equals),
	// and where each moved one went into `outPlaced`.
	private static void MoveCurveKeys(List<CurveKey> keys, List<int> moved, float delta, List<int> outPlaced)
	{
		let from = scope List<int>();
		for (int i < keys.Count)
		{
			from.Add(i);
			if (moved.Contains(i))
				keys[i].Time = Math.Max(0.0f, keys[i].Time + delta);
		}
		for (int i = 1; i < keys.Count; i++)
		{
			let key = keys[i];
			let origin = from[i];
			var j = i;
			while ((j > 0) && (keys[j - 1].Time > key.Time))
			{
				keys[j] = keys[j - 1];
				from[j] = from[j - 1];
				j--;
			}
			keys[j] = key;
			from[j] = origin;
		}
		Placed(from, moved, outPlaced);
	}

	private static void MoveQuatKeys(List<QuatKey> keys, List<int> moved, float delta, List<int> outPlaced)
	{
		let from = scope List<int>();
		for (int i < keys.Count)
		{
			from.Add(i);
			if (moved.Contains(i))
				keys[i].Time = Math.Max(0.0f, keys[i].Time + delta);
		}
		for (int i = 1; i < keys.Count; i++)
		{
			let key = keys[i];
			let origin = from[i];
			var j = i;
			while ((j > 0) && (keys[j - 1].Time > key.Time))
			{
				keys[j] = keys[j - 1];
				from[j] = from[j - 1];
				j--;
			}
			keys[j] = key;
			from[j] = origin;
		}
		Placed(from, moved, outPlaced);
	}

	// Where each moved key went: its index in the order now.
	private static void Placed(List<int> from, List<int> moved, List<int> outPlaced)
	{
		outPlaced.Clear();
		for (let index in moved)
		{
			for (int i < from.Count)
			{
				if (from[i] == index)
					outPlaced.Add(i);
			}
		}
	}
}
