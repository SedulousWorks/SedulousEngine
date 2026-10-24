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

	/// A view to tell of each change (not owned: it leaves as it goes).
	void AddTimelineClient(ITimelineSourceClient client);
	void RemoveTimelineClient(ITimelineSourceClient client);
}
