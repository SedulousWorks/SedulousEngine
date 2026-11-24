using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// Channels "Actor.walk" (keys at 0.4 and 1.2) and "Actor.clips" (sections 0.2 for 0.6, "wave", and
/// 1.0 for 0.4, "bow"); rows Actor, walk, clips.
class StagedSections : ITimelineSource
{
	public List<float> Walk = new .() ~ delete _;
	public List<TimelineSection> Clips = new .() ~ DeleteContainerAndItems!(_);
	private List<TimelineSection> mBefore = new .() ~ DeleteContainerAndItems!(_);
	private List<ITimelineSourceClient> mClients = new .() ~ delete _;
	public int Commits = 0;
	public int Cancels = 0;

	public this()
	{
		Walk.Add(0.4f);
		Walk.Add(1.2f);
		Clips.Add(new .(0.2f, 0.6f, "wave"));
		Clips.Add(new .(1.0f, 0.4f, "bow"));
	}

	public int ChannelCount => 2;
	public void GetChannelPath(int channel, String outPath) => outPath.Append((channel == 0) ? "Actor.walk" : "Actor.clips");
	public void GetKeyTimes(int channel, List<float> outTimes)
	{
		outTimes.Clear();
		if (channel == 0)
			outTimes.AddRange(Walk);
		else
		{
			// A source may list times for a section channel too (its sections' starts): the
			// dopesheet draws its bars, never keys.
			for (let section in Clips)
				outTimes.Add(section.Start);
		}
	}
	public void BeginKeysMove() {}
	public void PreviewKeysMove(Span<TimelineKeyRef> keys, float delta, List<TimelineKeyRef> moved) { moved.Clear(); }
	public void CommitKeysMove() {}
	public void CancelKeysMove() {}
	public bool DeleteKeys(Span<TimelineKeyRef> keys) => false;
	public bool InsertKey(int channel, float time, out TimelineKeyRef made)
	{
		made = .();
		return false;
	}

	public bool IsSectionChannel(int channel) => channel == 1;
	public void GetSections(int channel, List<TimelineSection> outSections)
	{
		ClearAndDeleteItems!(outSections);
		if (channel != 1)
			return;
		for (let section in Clips)
			outSections.Add(new .(section.Start, section.Length, section.Label));
	}
	public void BeginSectionEdit() => Copy(Clips, mBefore);
	public void PreviewSectionEdit(TimelineSectionRef section, float start, float length)
	{
		Copy(mBefore, Clips);
		Clips[section.Index].Start = start;
		Clips[section.Index].Length = length;
		Notify();
	}
	public void CommitSectionEdit() => Commits++;
	public void CancelSectionEdit()
	{
		Copy(mBefore, Clips);
		Cancels++;
		Notify();
	}
	public bool DeleteSection(TimelineSectionRef section)
	{
		delete Clips[section.Index];
		Clips.RemoveAt(section.Index);
		Notify();
		return true;
	}

	public bool InsertSection(int channel, float time, out TimelineSectionRef made)
	{
		Clips.Add(new .(time, 0.25f, "new"));
		made = .(channel, Clips.Count - 1);
		Notify();
		return true;
	}

	public void AddTimelineClient(ITimelineSourceClient client) => mClients.Add(client);
	public void RemoveTimelineClient(ITimelineSourceClient client) => mClients.Remove(client);

	private void Notify()
	{
		for (let client in mClients)
			client.OnTimelineChanged();
	}

	private static void Copy(List<TimelineSection> from, List<TimelineSection> to)
	{
		ClearAndDeleteItems!(to);
		for (let section in from)
			to.Add(new .(section.Start, section.Length, section.Label));
	}
}

/// A 660 by 200 dopesheet, names 160 wide, over 0 to 2 s at 250 px a second (time t on row r at
/// (160 + 250 t, 10 + 20 r)), showing the staged sections. The root goes with it.
class SectionBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public TimeAxis Axis = new .() ~ _.ReleaseRef();
	public Dopesheet Sheet = new .() ~ _.ReleaseRef();
	public StagedSections Source = new .() ~ delete _;

	public this()
	{
		Root = NewRoot(700.0f, 300.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Sheet.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(660.0f);
				s.Height = LayoutLength.Px(200.0f);
			});
		Root.AddChild(Sheet);
		Axis.Duration = 2.0f;
		Axis.PixelsPerSecond = 250.0f;
		Sheet.TimeAxis = Axis;
		Sheet.Source = Source;
		Root.UpdateLayout();
	}

	public ~this()
	{
		Sheet.Source = null;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static Float2 At(int row, float t) => .(160.0f + 250.0f * t, 10.0f + 20.0f * (float)row);

	public void Click(Float2 at)
	{
		D.InjectMouseMove(at);
		D.InjectMouseDown(at, .Left);
		D.InjectMouseUp(at, .Left);
	}

	public void Drag(Float2 from, Float2 to)
	{
		D.InjectMouseMove(from);
		D.InjectMouseDown(from, .Left);
		D.InjectMouseMove(.((from.X + to.X) * 0.5f, from.Y));
		D.InjectMouseMove(to);
		D.InjectMouseUp(to, .Left);
	}
}

/// The dopesheet's section rows: a channel that holds sections shows them as bars on its row, beside
/// rows of keys under the same parent. A click selects a bar (and lets go of the keys), a drag on its
/// body moves it and a drag on an end trims it, on frames and in the clip, previewed through the
/// source and committed once; Escape gives it up, Delete removes it.
class DopesheetSectionTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ASectionChannelIsARowOfBarsBesideRowsOfKeysAParentSummarizesKeysOnly()
	{
		let bed = scope SectionBed();
		let rows = bed.Sheet.Rows;
		Test.Assert(rows.Count == 3);
		Test.Assert(rows[2].Name == "clips");
		let times = scope List<float>();
		let keys = scope List<List<TimelineKeyRef>>();
		defer { ClearAndDeleteItems!(keys); }
		bed.Sheet.GetRowKeys(0, times, keys); // Actor: the walk's keys, not the clips' starts
		Test.Assert(times.Count == 2);
		bed.Sheet.GetRowKeys(2, times, keys);
		Test.Assert(times.IsEmpty);
		let bar = bed.Sheet.SectionBar(2, bed.Source.Clips[0].Start, bed.Source.Clips[0].Length);
		Test.Assert(Near(bar.X, SectionBed.At(2, 0.2f).X));
		Test.Assert(Near(bar.Width, 150.0f)); // 0.6 s
	}

	[Test]
	public static void AClickSelectsABarAndLetsGoOfKeysABodyDragMovesItOnFramesInTheClip()
	{
		let bed = scope SectionBed();
		TimelineKeyRef[1] walkKey = .(.(0, 0));
		bed.Sheet.SetSelection(walkKey);
		bed.Click(SectionBed.At(2, 0.5f)); // the wave's middle
		Test.Assert(bed.Sheet.HasSelectedSection);
		Test.Assert(bed.Sheet.SelectedSection.Index == 0);
		Test.Assert(bed.Sheet.Selection.IsEmpty, "the keys let go");
		Test.Assert(bed.Source.Commits == 0, "a click moves nothing");

		bed.Axis.FrameRate = 10.0f;
		bed.Drag(SectionBed.At(2, 0.5f), SectionBed.At(2, 0.83f));
		Test.Assert(bed.Source.Commits == 1);
		Test.Assert(Near(bed.Source.Clips[0].Start, 0.5f), "0.2 + 0.33 on a frame");
		Test.Assert(Near(bed.Source.Clips[0].Length, 0.6f), "a move keeps its length");

		bed.Drag(SectionBed.At(2, 0.8f), .(690.0f, SectionBed.At(2, 0.0f).Y)); // far right: it stops at the end
		Test.Assert(Near(bed.Source.Clips[0].Start + bed.Source.Clips[0].Length, 2.0f));
	}

	[Test]
	public static void ADragOnAnEndTrimsItTheOtherEndStayingEscapeCancelsDeleteRemoves()
	{
		let bed = scope SectionBed();
		bed.Axis.FrameRate = 10.0f;
		let startEdge = SectionBed.At(2, 0.2f);
		bed.Drag(.(startEdge.X + 1.0f, startEdge.Y), SectionBed.At(2, 0.4f)); // the wave's start
		Test.Assert(Near(bed.Source.Clips[0].Start, 0.4f));
		Test.Assert(Near(bed.Source.Clips[0].Length, 0.4f), "its end stays at 0.8");
		let endEdge = SectionBed.At(2, 0.8f);
		bed.Drag(.(endEdge.X - 1.0f, endEdge.Y), SectionBed.At(2, 0.9f)); // its end
		Test.Assert(Near(bed.Source.Clips[0].Start, 0.4f));
		Test.Assert(Near(bed.Source.Clips[0].Length, 0.5f));
		Test.Assert(bed.Source.Commits == 2);

		bed.D.InjectMouseMove(SectionBed.At(2, 1.2f));
		bed.D.InjectMouseDown(SectionBed.At(2, 1.2f), .Left); // the bow
		bed.D.InjectMouseMove(SectionBed.At(2, 1.5f));
		Test.Assert(Near(bed.Source.Clips[1].Start, 1.3f), "previewed");
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(Near(bed.Source.Clips[1].Start, 1.0f));
		Test.Assert(bed.Source.Cancels == 1);
		bed.D.InjectMouseUp(SectionBed.At(2, 1.5f), .Left);
		Test.Assert(bed.Source.Commits == 2);

		Test.Assert(bed.Sheet.HasSelectedSection);
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.Source.Clips.Count == 1);
		Test.Assert(bed.Source.Clips[0].Label == "wave");
		Test.Assert(!bed.Sheet.HasSelectedSection);
	}

	[Test]
	public static void ADoubleClickOnASectionRowsEmptySpaceAddsOneThereChosen()
	{
		let bed = scope SectionBed();
		bed.Axis.FrameRate = 10.0f;
		bed.Click(SectionBed.At(2, 1.63f));
		bed.Click(SectionBed.At(2, 1.63f));
		Test.Assert(bed.Source.Clips.Count == 3);
		Test.Assert(Near(bed.Source.Clips[2].Start, 1.6f), "on a frame");
		Test.Assert(bed.Sheet.HasSelectedSection);
		Test.Assert(bed.Sheet.SelectedSection.Index == 2);
	}
}
