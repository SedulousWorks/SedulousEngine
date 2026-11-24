using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// What a dopesheet reads: channels named by paths ("Lamp.color.r"), the dopesheet folding them into
// rows by their segments (component, property, channel), and each channel's key times. A key is
// (channel, index); an edit through the source returns the keys' new addresses, so a selection
// survives the source sorting its keys again. Edits are gestures as the other sources' are (a move
// begun, previewed from where the keys were, committed once or cancelled) or one change each (a
// deletion, an insertion); the undo is the source's.
//
// A channel may hold sections instead of keys: spans of time (a clip, a sound, a shot), which the
// dopesheet draws as bars on the channel's row and moves or trims. A source of keys alone leaves the
// section calls as they are.

/// A key of a timeline: its channel and its place among that channel's keys (sorted by time).
struct TimelineKeyRef : IEquatable<TimelineKeyRef>
{
	public int Channel = 0;
	public int Index = 0;

	public this() { }

	public this(int channel, int index)
	{
		Channel = channel;
		Index = index;
	}

	public bool Equals(TimelineKeyRef other) => this == other;

	[Commutable]
	public static bool operator==(TimelineKeyRef a, TimelineKeyRef b) => (a.Channel == b.Channel) && (a.Index == b.Index);
}

/// A span on a section channel: where it starts, how long it is, and what its bar says. A class: it
/// owns its label.
class TimelineSection
{
	public float Start = 0.0f;
	public float Length = 0.0f;
	public String Label = new .() ~ delete _;

	public this() { }

	public this(float start, float length, StringView label)
	{
		Start = start;
		Length = length;
		Label.Set(label);
	}
}

/// A section of a timeline: its channel and its place among that channel's sections.
struct TimelineSectionRef : IEquatable<TimelineSectionRef>
{
	public int Channel = 0;
	public int Index = 0;

	public this() { }

	public this(int channel, int index)
	{
		Channel = channel;
		Index = index;
	}

	public bool Equals(TimelineSectionRef other) => this == other;

	[Commutable]
	public static bool operator==(TimelineSectionRef a, TimelineSectionRef b) => (a.Channel == b.Channel) && (a.Index == b.Index);
}

/// What a timeline source tells its views.
interface ITimelineSourceClient
{
	/// The channels or their keys changed: read them again.
	void OnTimelineChanged();
}

/// A timeline's channels and keys. An interface (a source may be a curve source too): the source
/// keeps its views, each leaving as it goes, and tells them of each change.
interface ITimelineSource
{
	int ChannelCount { get; }
	/// Its path, its segments split by '.': the rows it folds into; appended to `outPath`.
	void GetChannelPath(int channel, String outPath);
	/// Its key times, sorted, into `outTimes` (emptied first).
	void GetKeyTimes(int channel, List<float> outTimes);

	/// A move begins: where the keys are now is what a preview moves from and a cancel puts back.
	void BeginKeysMove();
	/// `keys` (as they were at the beginning) moved by `delta` seconds, live; `moved` their places
	/// now (emptied first).
	void PreviewKeysMove(Span<TimelineKeyRef> keys, float delta, List<TimelineKeyRef> moved);
	/// The move ends as last previewed: one change.
	void CommitKeysMove();
	/// The move is given up: the keys as they were.
	void CancelKeysMove();
	/// Deletes `keys`, one change; false when none went.
	bool DeleteKeys(Span<TimelineKeyRef> keys);
	/// Adds a key to `channel` at `time` (its value the source's: the channel's there, as a rule),
	/// one change; false when it cannot (full, locked). `made` is where it went.
	bool InsertKey(int channel, float time, out TimelineKeyRef made);

	// === Sections (a source of keys alone keeps these) ===

	/// Whether the channel holds sections rather than keys.
	bool IsSectionChannel(int channel) => false;
	/// The channel's sections, in the order the source keeps them, into `outSections` (emptied
	/// first; the caller deletes what it holds).
	void GetSections(int channel, List<TimelineSection> outSections)
	{
		ClearAndDeleteItems!(outSections);
	}
	/// A move or a trim begins, as a key move does: each preview starts from where the section
	/// was, and a cancel puts it back.
	void BeginSectionEdit() {}
	/// The section's start and length, live. A trim of its start moves its start and keeps its
	/// end; the source decides what moves inside (a clip's offset, so what plays stays put).
	void PreviewSectionEdit(TimelineSectionRef section, float start, float length) {}
	void CommitSectionEdit() {}
	void CancelSectionEdit() {}
	/// Deletes the section, one change; false when it cannot.
	bool DeleteSection(TimelineSectionRef section) => false;

	/// A view to tell of each change (not owned: it leaves as it goes).
	void AddTimelineClient(ITimelineSourceClient client);
	void RemoveTimelineClient(ITimelineSourceClient client);
}
