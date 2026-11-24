using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Sequence;

namespace Sedulous.Editor.Sequence;

/// A sequence document as the toolkit's dopesheet and curve view see it, whatever its track kinds:
/// each kind says what it holds as key channels or sections (SequenceTrack's editing calls), so a
/// kind a domain or a plugin adds edits here with no change. The rows fold by path: a binding's
/// name, then the track (its name, or its property for a property track, or its kind's name), then
/// the channel when the track has more than one ("Hero.Transform.Position.x", "Hero.Clip",
/// "Sequence.Event"); tracks bound to no one sit under "Sequence". A track with no key channels is
/// one row of sections. The curve view shows the curves of the tracks the panel shows (a property's
/// parts, a fade's amount). Every edit goes through the document: a drag is a gesture that previews
/// from where it began and becomes one undo step when it ends; a deletion or an insertion is one
/// step. Its markers are the ruler's (Markers): a hold says so on its label, and a drag moves one as
/// a gesture.
class SequenceSource : ICurveSource, ITimelineSource
{
	/// A row's channel: its track and, for keys, which of the track's key channels (-1: the track's
	/// sections).
	public struct Channel
	{
		public int Track = 0;
		public int Keys = -1;

		public this(int track, int keys)
		{
			Track = track;
			Keys = keys;
		}
	}

	/// The group of tracks bound to no one.
	private const String cUnbound = "Sequence";

	/// BORROWED: its owner's, which outlives it.
	private SequenceDocument mDocument;
	/// The dopesheet's rows that hold keys or sections.
	private List<Channel> mChannels = new .() ~ delete _;
	/// The curve view's: the shown tracks' curve channels.
	private List<Channel> mCurves = new .() ~ delete _;
	private List<int> mShown = new .() ~ delete _;
	private List<ITimelineSourceClient> mTimelineClients = new .() ~ delete _;
	private SequenceMarkerSource mMarkers ~ delete _;

	public this(SequenceDocument document)
	{
		mDocument = document;
		mMarkers = new .(document);
		Rebuild();
	}

	/// The sequence's markers, as the ruler sees them (a source of its own: a curve source and a
	/// marker source are each a class).
	public ITimeMarkerSource Markers => mMarkers;

	public Span<Channel> Channels => mChannels;
	public Span<int> ShownTracks => mShown;

	/// The tracks whose curves the curve view shows; empty: none.
	public void ShowTracks(Span<int> tracks)
	{
		mShown.Clear();
		mShown.AddRange(tracks);
		Refresh();
	}

	/// The document changed (its owner calls this from the document's OnChanged): the channels read
	/// again, the views told.
	public void Refresh()
	{
		Rebuild();
		for (int i = 0; i < mTimelineClients.Count; ++i)
			mTimelineClients[i].OnTimelineChanged();
		NotifyCurvesChanged();
		mMarkers.Changed();
	}

	/// The row a track's name gives it ("Transform.Position", "Clip", "Event"), into `outLabel`.
	public static void TrackLabel(SequenceTrack track, String outLabel)
	{
		if (!track.Name.IsEmpty)
		{
			outLabel.Append(track.Name);
			return;
		}
		if (let property = track as PropertySequenceTrack)
		{
			if (!property.Property.ComponentType.IsEmpty)
			{
				outLabel.AppendF("{}.{}", property.Property.ComponentType, property.Property.PropertyPath);
				return;
			}
		}
		// The kind's name, as it shows it.
		if (track.GetType().GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			outLabel.Append(shown.Name);
		else
			outLabel.Append(track.GetType().GetName(.. scope .()));
	}

	// === ITimelineSource ===

	public int ChannelCount => mChannels.Count;

	public void GetChannelPath(int channel, String outPath)
	{
		let track = TrackAt(channel);
		if (track == null)
			return;
		let sequence = mDocument.Sequence;
		let at = mChannels[channel];
		let bound = (track.Binding >= 0) && (track.Binding < sequence.Bindings.Count);
		outPath.Append(bound ? sequence.Bindings[track.Binding].Name : cUnbound);
		outPath.Append('.');
		TrackLabel(track, outPath);
		if ((at.Keys >= 0) && (track.KeyChannelCount > 1))
		{
			outPath.Append('.');
			track.GetKeyChannelName(at.Keys, outPath);
		}
	}

	public void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		let track = TrackAt(channel);
		if ((track != null) && (mChannels[channel].Keys >= 0))
			track.GetKeyTimes(mChannels[channel].Keys, outTimes);
	}

	public void BeginKeysMove() => mDocument.BeginGesture();

	public void PreviewKeysMove(Span<TimelineKeyRef> keys, float delta, List<TimelineKeyRef> moved)
	{
		moved.Clear();
		if (!mDocument.InGesture)
			return;
		// Each preview moves the keys from where they began.
		mDocument.RestoreGestureStart();
		let done = scope List<int>();
		let indices = scope List<int>();
		let landed = scope List<int>();
		for (let first in keys)
		{
			if (done.Contains(first.Channel))
				continue;
			done.Add(first.Channel);
			let track = TrackAt(first.Channel);
			if ((track == null) || (mChannels[first.Channel].Keys < 0))
				continue;
			indices.Clear();
			for (let key in keys)
			{
				if (key.Channel == first.Channel)
					indices.Add(key.Index);
			}
			track.MoveKeys(mChannels[first.Channel].Keys, indices, delta, landed);
			for (let index in landed)
				moved.Add(.(first.Channel, index));
		}
		mDocument.PreviewGesture();
	}

	public void CommitKeysMove() => mDocument.CommitGesture("sequence-move-keys");

	public void CancelKeysMove() => mDocument.CancelGesture();

	public bool DeleteKeys(Span<TimelineKeyRef> keys)
	{
		if (keys.IsEmpty)
			return false;
		// The rows as the selection saw them.
		let channels = scope List<Channel>();
		channels.AddRange(mChannels);
		let done = scope List<int>();
		let indices = scope List<int>();
		mDocument.Edit("sequence-delete-keys", scope [&] (sequence) =>
			{
				for (let first in keys)
				{
					if (done.Contains(first.Channel) || (first.Channel < 0) || (first.Channel >= channels.Count))
						continue;
					done.Add(first.Channel);
					let at = channels[first.Channel];
					if ((at.Keys < 0) || (at.Track >= sequence.Tracks.Count))
						continue;
					indices.Clear();
					for (let key in keys)
					{
						if (key.Channel == first.Channel)
							indices.Add(key.Index);
					}
					sequence.Tracks[at.Track].DeleteKeys(at.Keys, indices);
				}
			});
		return true;
	}

	public bool InsertKey(int channel, float time, out TimelineKeyRef made)
	{
		made = .();
		if ((TrackAt(channel) == null) || (mChannels[channel].Keys < 0))
			return false;
		let at = mChannels[channel];
		var index = -1;
		mDocument.Edit("sequence-insert-key", scope [&] (sequence) =>
			{
				if (at.Track < sequence.Tracks.Count)
					index = sequence.Tracks[at.Track].InsertKey(at.Keys, time);
			});
		if (index < 0)
			return false;
		made = .(channel, index);
		return true;
	}

	public bool IsSectionChannel(int channel) => (channel >= 0) && (channel < mChannels.Count) && (mChannels[channel].Keys < 0);

	public void GetSections(int channel, List<TimelineSection> outSections)
	{
		ClearAndDeleteItems!(outSections);
		if (!IsSectionChannel(channel))
			return;
		let track = TrackAt(channel);
		if (track == null)
			return;
		for (int i < track.SectionCount)
		{
			let section = new TimelineSection();
			track.GetSection(i, out section.Start, out section.Length, section.Label);
			outSections.Add(section);
		}
	}

	public void BeginSectionEdit() => mDocument.BeginGesture();

	public void PreviewSectionEdit(TimelineSectionRef section, float start, float length)
	{
		if (!IsSectionChannel(section.Channel) || !mDocument.InGesture)
			return;
		// Each preview sets the span from where it began.
		mDocument.RestoreGestureStart();
		if (let track = TrackAt(section.Channel))
			track.SetSection(section.Index, start, length);
		mDocument.PreviewGesture();
	}

	public void CommitSectionEdit() => mDocument.CommitGesture("sequence-edit-section");

	public void CancelSectionEdit() => mDocument.CancelGesture();

	public bool DeleteSection(TimelineSectionRef section)
	{
		if (!IsSectionChannel(section.Channel))
			return false;
		let track = mChannels[section.Channel].Track;
		mDocument.Edit("sequence-delete-section", scope [&] (sequence) =>
			{
				if (track < sequence.Tracks.Count)
					sequence.Tracks[track].RemoveSection(section.Index);
			});
		return true;
	}

	public void AddTimelineClient(ITimelineSourceClient client) => mTimelineClients.Add(client);

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
		let track = CurveTrack(curve);
		if (track == null)
			return;
		let channel = mCurves[curve].Keys;
		outInfo.Name.Clear();
		TrackLabel(track, outInfo.Name);
		outInfo.Name.Append('.');
		track.GetKeyChannelName(channel, outInfo.Name);
		// x and r red, y and g green, z and b blue, a grey; a lone curve amber.
		Color[4] colors = .(.(0.92f, 0.38f, 0.38f, 1.0f), .(0.42f, 0.82f, 0.45f, 1.0f), .(0.42f, 0.62f, 1.0f, 1.0f), .(0.8f, 0.8f, 0.8f, 1.0f));
		outInfo.StrokeColor = (track.KeyChannelCount == 1) ? .(0.95f, 0.75f, 0.3f, 1.0f) : colors[Math.Min(channel, 3)];
	}

	public override Span<CurveKey> GetKeys(int curve)
	{
		let track = CurveTrack(curve);
		let keys = (track != null) ? track.KeyCurve(mCurves[curve].Keys) : null;
		return (keys != null) ? keys.Keys : default;
	}

	public override void BeginKeysEdit() => mDocument.BeginGesture();

	public override void PreviewKeys(int curve, Span<CurveKey> keys)
	{
		if (!mDocument.InGesture)
			return;
		let track = CurveTrack(curve);
		let target = (track != null) ? track.KeyCurve(mCurves[curve].Keys) : null;
		if (target == null)
			return;
		target.Keys.Clear();
		target.Keys.AddRange(keys);
		mDocument.PreviewGesture();
	}

	public override void CommitKeysEdit() => mDocument.CommitGesture("sequence-edit-curve");

	public override void CancelKeysEdit() => mDocument.CancelGesture();

	// === Private ===

	private void Rebuild()
	{
		let sequence = mDocument.Sequence;
		mChannels.Clear();
		// By binding, in the cast's order, then the tracks bound to no one.
		for (int binding = 0; binding <= sequence.Bindings.Count; binding++)
		{
			let wanted = (binding < sequence.Bindings.Count) ? binding : -1;
			for (int t < sequence.Tracks.Count)
			{
				let track = sequence.Tracks[t];
				let bound = (track.Binding >= 0) && (track.Binding < sequence.Bindings.Count);
				if ((bound ? (int)track.Binding : -1) != wanted)
					continue;
				let keyChannels = track.KeyChannelCount;
				if (keyChannels == 0)
				{
					mChannels.Add(.(t, -1));
					continue;
				}
				for (int c < keyChannels)
					mChannels.Add(.(t, c));
			}
		}
		// The shown tracks that are still there; their curve channels the curves.
		for (int i = mShown.Count - 1; i >= 0; i--)
		{
			if (mShown[i] >= sequence.Tracks.Count)
				mShown.RemoveAt(i);
		}
		mCurves.Clear();
		for (let t in mShown)
		{
			let track = sequence.Tracks[t];
			for (int c < track.KeyChannelCount)
			{
				if (track.KeyCurve(c) != null)
					mCurves.Add(.(t, c));
			}
		}
	}

	/// The track of the dopesheet's channel, read from the sequence now (a gesture replaces it);
	/// null when there is none.
	private SequenceTrack TrackAt(int channel)
	{
		if ((channel < 0) || (channel >= mChannels.Count))
			return null;
		let sequence = mDocument.Sequence;
		let track = mChannels[channel].Track;
		return (track < sequence.Tracks.Count) ? sequence.Tracks[track] : null;
	}

	private SequenceTrack CurveTrack(int curve)
	{
		if ((curve < 0) || (curve >= mCurves.Count))
			return null;
		let sequence = mDocument.Sequence;
		let track = mCurves[curve].Track;
		return (track < sequence.Tracks.Count) ? sequence.Tracks[track] : null;
	}
}

/// A sequence's markers as a ruler sees them: a hold says so on its label; a drag moves one as a
/// gesture of the document's, the markers kept by time when it ends, as the play reads them.
class SequenceMarkerSource : ITimeMarkerSource
{
	/// BORROWED.
	private SequenceDocument mDocument;

	public this(SequenceDocument document)
	{
		mDocument = document;
	}

	/// The document changed: the rulers read the markers again.
	public void Changed() => NotifyTimeMarkersChanged();

	public override int MarkerCount => mDocument.Sequence.Markers.Count;

	public override void GetMarker(int marker, TimeMarker outMarker)
	{
		let markers = mDocument.Sequence.Markers;
		if ((marker < 0) || (marker >= markers.Count))
			return;
		outMarker.Time = markers[marker].Time;
		outMarker.Label.Clear();
		outMarker.Label.Append(markers[marker].Name);
		if (markers[marker].Hold)
			outMarker.Label.Append(" (hold)");
	}

	public override void BeginMarkerMove(int marker) => mDocument.BeginGesture();

	public override void PreviewMarkerMove(int marker, float time)
	{
		let markers = mDocument.GestureSequence.Markers;
		if ((marker < 0) || (marker >= markers.Count))
			return;
		markers[marker].Time = Math.Max(0.0f, time);
		mDocument.PreviewGesture();
	}

	public override void CommitMarkerMove()
	{
		// Kept by time, as the play reads them.
		let markers = mDocument.GestureSequence.Markers;
		for (int i = 1; i < markers.Count; i++)
		{
			for (int j = i; (j > 0) && (markers[j - 1].Time > markers[j].Time); j--)
				Swap!(markers[j - 1], markers[j]);
		}
		mDocument.CommitGesture("sequence-move-marker");
	}

	public override void CancelMarkerMove() => mDocument.CancelGesture();
}
