using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// What a curve view reads: curves of Core's `CurveKey`s, the one model, so what is edited is what
// plays; the toolkit has no curve type of its own. A source says which curves there are and each
// one's keys, and the view edits through it as gestures, as a property grid does through a property
// source: begun, previewed live (each changed curve's keys whole), then committed (one change, one
// undo entry) or cancelled (the keys as they were). The undo is the source's, an application's.
//
// CurveSet is a source of its own curves in memory: what tests and a page without curves of its own
// edit, its commits told to whoever keeps the undo, which hands them back to undo and redo. It is a
// timeline source too, each curve a channel named by its path (its name), so a dopesheet and a curve
// view stack over one clip.

/// What a source says of one curve. A class: it owns its name; Set copies another into it.
class CurveInfo
{
	public String Name = new .() ~ delete _;
	public Color StrokeColor = .(0.9f, 0.9f, 0.9f, 1.0f);
	/// Values kept between Min and Max, and a framing shows at least them.
	public bool HasRange = false;
	public float Min = 0.0f;
	public float Max = 0.0f;
	/// The most keys it holds (a particle curve's eight); 0: no limit.
	public uint32 MaxKeys = 0;
	/// Drawn, not edited.
	public bool Locked = false;

	public this() { }

	public this(StringView name)
	{
		Name.Set(name);
	}

	public void Set(CurveInfo other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		StrokeColor = other.StrokeColor;
		HasRange = other.HasRange;
		Min = other.Min;
		Max = other.Max;
		MaxKeys = other.MaxKeys;
		Locked = other.Locked;
	}
}

/// A key: its curve and its place among that curve's keys (sorted by time).
struct CurveKeyRef : IEquatable<CurveKeyRef>
{
	public int Curve = 0;
	public int Index = 0;

	public this() { }

	public this(int curve, int index)
	{
		Curve = curve;
		Index = index;
	}

	public bool Equals(CurveKeyRef other) => this == other;

	[Commutable]
	public static bool operator==(CurveKeyRef a, CurveKeyRef b) => (a.Curve == b.Curve) && (a.Index == b.Index);
}

/// What a source tells its views.
interface ICurveSourceClient
{
	/// The curves, what they say of themselves, or their keys changed: read them again.
	void OnCurvesChanged();
}

abstract class ICurveSource
{
	// Not owned: each view leaves as it goes.
	private List<ICurveSourceClient> mClients = new .() ~ delete _;

	public abstract int CurveCount { get; }
	/// What curve `curve` says of itself, into `outInfo` (a default one when there is none).
	public abstract void GetCurveInfo(int curve, CurveInfo outInfo);
	/// Its keys, sorted by time: a view, valid until the source changes.
	public abstract Span<CurveKey> GetKeys(int curve);

	/// An edit begins: the keys now are what a cancel puts back.
	public abstract void BeginKeysEdit();
	/// A curve's keys as the edit goes (sorted, their tangents set by their modes), live.
	public abstract void PreviewKeys(int curve, Span<CurveKey> keys);
	/// The edit ends: what it previewed is one change.
	public abstract void CommitKeysEdit();
	/// The edit is given up: the keys as they were.
	public abstract void CancelKeysEdit();

	public void AddClient(ICurveSourceClient client)
	{
		mClients.Add(client);
	}

	public void RemoveClient(ICurveSourceClient client)
	{
		for (int i = 0; i < mClients.Count; ++i)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	protected void NotifyCurvesChanged()
	{
		for (int i = 0; i < mClients.Count; ++i)
			mClients[i].OnCurvesChanged();
	}
}

/// One curve's keys before and after a change. A class: it owns its keys.
class CurveEdit
{
	public int Curve = 0;
	public List<CurveKey> Before = new .() ~ delete _;
	public List<CurveKey> After = new .() ~ delete _;
}

/// A committed change: the curves it touched (owned).
class CurveChange
{
	public List<CurveEdit> Curves = new .() ~ DeleteContainerAndItems!(_);
}

/// Curves of its own, in memory; its curves the channels of a timeline, by their names.
class CurveSet : ICurveSource, ITimelineSource
{
	private class Curve
	{
		public CurveInfo Info = new .() ~ delete _;
		public List<CurveKey> Keys = new .() ~ delete _;
	}

	private List<Curve> mCurves = new .() ~ DeleteContainerAndItems!(_);
	private List<List<CurveKey>> mBefore = new .() ~ DeleteContainerAndItems!(_);
	private bool mEditing = false;
	private delegate void(CurveChange change) mOnCommit ~ delete _;
	// Not owned: each view leaves as it goes.
	private List<ITimelineSourceClient> mTimelineClients = new .() ~ delete _;

	/// Adds a curve with no keys; its index.
	public int AddCurve(CurveInfo info) => AddCurve(info, default);

	/// Adds a curve (copies of `info` and `keys` kept); its index.
	public int AddCurve(CurveInfo info, Span<CurveKey> keys)
	{
		let curve = new Curve();
		curve.Info.Set(info);
		for (let key in keys)
			curve.Keys.Add(key);
		mCurves.Add(curve);
		Changed();
		return mCurves.Count - 1;
	}

	/// Sets a curve's keys from code: shown, no change told.
	public void SetKeys(int curve, Span<CurveKey> keys)
	{
		if ((curve < 0) || (curve >= mCurves.Count))
			return;
		Assign(mCurves[curve].Keys, keys);
		Changed();
	}

	/// Its info, to change; InfoChanged after.
	public CurveInfo Info(int curve) => mCurves[curve].Info;

	/// Something changed an info: tell the views.
	public void InfoChanged() => Changed();

	/// Each commit, for whoever keeps the undo. OWNERSHIP of `callback` transfers.
	public void SetOnCommit(delegate void(CurveChange change) callback)
	{
		delete mOnCommit;
		mOnCommit = callback;
	}

	/// Puts a change's keys back (`undo`: its befores; else its afters), no change told.
	public void Apply(CurveChange change, bool undo)
	{
		for (let edit in change.Curves)
		{
			if ((edit.Curve >= 0) && (edit.Curve < mCurves.Count))
				Assign(mCurves[edit.Curve].Keys, undo ? edit.Before : edit.After);
		}
		Changed();
	}

	public bool IsEditing => mEditing;

	// === ICurveSource ===

	public override int CurveCount => mCurves.Count;

	public override void GetCurveInfo(int curve, CurveInfo outInfo)
	{
		if ((curve >= 0) && (curve < mCurves.Count))
			outInfo.Set(mCurves[curve].Info);
		else
			outInfo.Set(scope CurveInfo());
	}

	public override Span<CurveKey> GetKeys(int curve) => ((curve >= 0) && (curve < mCurves.Count)) ? mCurves[curve].Keys : default;

	public override void BeginKeysEdit()
	{
		if (mEditing)
			CancelKeysEdit();
		mEditing = true;
		ClearAndDeleteItems!(mBefore);
		for (let curve in mCurves)
		{
			let copy = new List<CurveKey>();
			Assign(copy, curve.Keys);
			mBefore.Add(copy);
		}
	}

	public override void PreviewKeys(int curve, Span<CurveKey> keys)
	{
		if (!mEditing || (curve < 0) || (curve >= mCurves.Count))
			return;
		Assign(mCurves[curve].Keys, keys);
		Changed();
	}

	public override void CommitKeysEdit()
	{
		if (!mEditing)
			return;
		mEditing = false;
		let change = scope CurveChange();
		for (int c = 0; (c < mCurves.Count) && (c < mBefore.Count); ++c)
		{
			if (Same(mBefore[c], mCurves[c].Keys))
				continue;
			let edit = new CurveEdit();
			edit.Curve = c;
			Assign(edit.Before, mBefore[c]);
			Assign(edit.After, mCurves[c].Keys);
			change.Curves.Add(edit);
		}
		ClearAndDeleteItems!(mBefore);
		if (!change.Curves.IsEmpty && (mOnCommit != null))
			mOnCommit(change);
		Changed();
	}

	public override void CancelKeysEdit()
	{
		if (!mEditing)
			return;
		mEditing = false;
		for (int c = 0; (c < mCurves.Count) && (c < mBefore.Count); ++c)
			Assign(mCurves[c].Keys, mBefore[c]);
		ClearAndDeleteItems!(mBefore);
		Changed();
	}

	// === ITimelineSource ===

	public int ChannelCount => mCurves.Count;

	public void GetChannelPath(int channel, String outPath)
	{
		if ((channel >= 0) && (channel < mCurves.Count))
			outPath.Append(mCurves[channel].Info.Name);
	}

	public void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		if ((channel >= 0) && (channel < mCurves.Count))
		{
			for (let key in mCurves[channel].Keys)
				outTimes.Add(key.Time);
		}
	}

	public void BeginKeysMove() => BeginKeysEdit();

	public void PreviewKeysMove(Span<TimelineKeyRef> keys, float delta, List<TimelineKeyRef> moved)
	{
		moved.Clear();
		if (!mEditing)
			return;
		for (int c = 0; (c < mCurves.Count) && (c < mBefore.Count); ++c)
		{
			bool any = false;
			for (let @ref in keys)
				any = any || (@ref.Channel == c);
			if (!any || mCurves[c].Info.Locked)
				continue;
			let next = scope List<CurveKey>();
			let chosen = scope List<bool>();
			for (int i = 0; i < mBefore[c].Count; ++i)
			{
				var key = mBefore[c][i];
				bool selected = false;
				for (let @ref in keys)
					selected = selected || ((@ref.Channel == c) && (@ref.Index == i));
				if (selected)
					key.Time = Max(0.0f, key.Time + delta);
				next.Add(key);
				chosen.Add(selected);
			}
			// Sorted again, stably, the moved keys followed to their places.
			for (int i = 1; i < next.Count; ++i)
			{
				for (int j = i; (j > 0) && (next[j].Time < next[j - 1].Time); --j)
				{
					let swap = next[j];
					next[j] = next[j - 1];
					next[j - 1] = swap;
					let m = chosen[j];
					chosen[j] = chosen[j - 1];
					chosen[j - 1] = m;
				}
			}
			ApplyCurveTangentModes(next);
			Assign(mCurves[c].Keys, next);
			for (int n = 0; n < chosen.Count; ++n)
			{
				if (chosen[n])
					moved.Add(TimelineKeyRef(c, n));
			}
		}
		Changed();
	}

	public void CommitKeysMove() => CommitKeysEdit();
	public void CancelKeysMove() => CancelKeysEdit();

	public bool DeleteKeys(Span<TimelineKeyRef> keys)
	{
		if (keys.IsEmpty)
			return false;
		BeginKeysEdit();
		bool any = false;
		for (int c = 0; c < mCurves.Count; ++c)
		{
			if (mCurves[c].Info.Locked)
				continue;
			let kept = scope List<CurveKey>();
			for (int i = 0; i < mCurves[c].Keys.Count; ++i)
			{
				bool gone = false;
				for (let @ref in keys)
					gone = gone || ((@ref.Channel == c) && (@ref.Index == i));
				if (gone)
					any = true;
				else
					kept.Add(mCurves[c].Keys[i]);
			}
			ApplyCurveTangentModes(kept);
			Assign(mCurves[c].Keys, kept);
		}
		CommitKeysEdit();
		return any;
	}

	public bool InsertKey(int channel, float time, out TimelineKeyRef made)
	{
		made = .();
		if ((channel < 0) || (channel >= mCurves.Count))
			return false;
		let curve = mCurves[channel];
		if (curve.Info.Locked || ((curve.Info.MaxKeys != 0) && (curve.Keys.Count >= (int)curve.Info.MaxKeys)))
			return false;
		BeginKeysEdit();
		var key = CurveKey();
		key.Time = time;
		key.Value = EvaluateCurve(curve.Keys, time);
		key.Interpolation = .Cubic;
		key.TangentMode = .Auto;
		int at = 0;
		while ((at < curve.Keys.Count) && (curve.Keys[at].Time <= time))
			++at;
		if (at > 0)
			key.Interpolation = curve.Keys[at - 1].Interpolation; // the segment's it splits
		curve.Keys.Insert(at, key);
		ApplyCurveTangentModes(curve.Keys);
		CommitKeysEdit();
		made = TimelineKeyRef(channel, at);
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

	/// Whether two key lists are the same, key by key.
	public static bool Same(Span<CurveKey> a, Span<CurveKey> b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i = 0; i < a.Length; ++i)
		{
			if ((a[i].Time != b[i].Time) || (a[i].Value != b[i].Value) || (a[i].TangentIn != b[i].TangentIn) ||
				(a[i].TangentOut != b[i].TangentOut) || (a[i].Interpolation != b[i].Interpolation) || (a[i].TangentMode != b[i].TangentMode))
				return false;
		}
		return true;
	}

	// Its views told: the curve views and the dopesheets.
	private void Changed()
	{
		NotifyCurvesChanged();
		for (int i = 0; i < mTimelineClients.Count; ++i)
			mTimelineClients[i].OnTimelineChanged();
	}

	private static void Assign(List<CurveKey> to, Span<CurveKey> from)
	{
		if (to.Ptr == from.Ptr)
			return;
		to.Clear();
		for (let key in from)
			to.Add(key);
	}
}
