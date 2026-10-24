using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A 660 by 200 dopesheet, names 160 wide, over 0 to 2 s at 250 px a second: time t on row r at
/// (160 + 250 t, 10 + 20 r). Its rows: Lamp, color, r, g, intensity, Camera, fov. The root goes with
/// it.
class SheetBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public TimeAxis Axis = new .() ~ _.ReleaseRef();
	public Dopesheet Sheet = new .() ~ _.ReleaseRef();
	public CurveSet Clip = new .() ~ delete _;
	public KeptCurveChanges Kept = new .() ~ delete _;

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
		CurveKey[2] r = .(CurveBed.Key(0.2f, 1.0f), CurveBed.Key(1.0f, 0.0f));
		Add("Lamp.color.r", r);
		CurveKey[2] g = .(CurveBed.Key(0.2f, 0.5f), CurveBed.Key(1.4f, 0.5f));
		Add("Lamp.color.g", g);
		CurveKey[1] intensity = .(CurveBed.Key(0.6f, 3.0f));
		Add("Lamp.intensity", intensity);
		CurveKey[1] fov = .(CurveBed.Key(1.0f, 60.0f));
		Add("Camera.fov", fov);
		Sheet.Source = Clip;
		Clip.SetOnCommit(new (change) => { Kept.Keep(change); });
		Root.UpdateLayout();
	}

	public ~this()
	{
		Sheet.Source = null;
	}

	public List<CurveChange> Commits => Kept.Changes;

	public void Add(StringView path, Span<CurveKey> keys)
	{
		Clip.AddCurve(scope CurveInfo(path), keys);
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static Float2 At(int row, float t) => .(160.0f + 250.0f * t, 10.0f + 20.0f * (float)row);
	public static Float2 Shifted(Float2 at, float dx, float dy) => .(at.X + dx, at.Y + dy);

	public void Press(Float2 at, uint32 modifiers = 0)
	{
		D.InjectMouseMove(at, modifiers);
		D.InjectMouseDown(at, .Left, modifiers);
	}

	public void Click(Float2 at, uint32 modifiers = 0)
	{
		Press(at, modifiers);
		D.InjectMouseUp(at, .Left, modifiers);
	}

	public void Drag(Float2 from, Float2 to, uint32 modifiers = 0)
	{
		Press(from, modifiers);
		D.InjectMouseMove(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f), modifiers);
		D.InjectMouseMove(to, modifiers);
		D.InjectMouseUp(to, .Left, modifiers);
	}

	public void Pause()
	{
		D.InjectMouseMove(.(690.0f, 290.0f));
		D.InjectMouseDown(.(690.0f, 290.0f), .Left);
		D.InjectMouseUp(.(690.0f, 290.0f), .Left);
	}

	public float Time(int channel, int index) => Clip.GetKeys(channel)[index].Time;
}

/// The dopesheet: a timeline source's channels as rows folded by their paths' segments, a parent row
/// showing the keys under it; keys selected by a click (a parent's selecting all under it at that
/// time) or a box, moved in time through the source (on frames, kept in the clip, the selection
/// following where the source put them, Escape giving it up), deleted, inserted by a double click; a
/// CurveSet feeding a dopesheet and a curve view at once.
class DopesheetTests
{
	[Test]
	public static void ChannelsFoldIntoRowsByTheirPathsSegmentsAClickOnANameFoldsOrOpensIt()
	{
		let bed = scope SheetBed();
		let rows = bed.Sheet.Rows;
		Test.Assert(rows.Count == 7);
		Test.Assert(rows[0].Path == "Lamp");
		Test.Assert(rows[0].HasChildren);
		Test.Assert(rows[0].Channel == -1);
		Test.Assert(rows[1].Name == "color");
		Test.Assert(rows[1].Depth == 1);
		Test.Assert(rows[2].Name == "r");
		Test.Assert(rows[2].Channel == 0);
		Test.Assert(rows[4].Path == "Lamp.intensity");
		Test.Assert(rows[4].Channel == 2);
		Test.Assert(rows[6].Path == "Camera.fov");
		Test.Assert(bed.Sheet.FindRow("Camera") == 5);

		bed.Click(.(40.0f, 30.0f)); // "color"'s name
		Test.Assert(bed.Sheet.IsFolded("Lamp.color"));
		Test.Assert(bed.Sheet.Rows.Count == 5);
		Test.Assert(bed.Sheet.Rows[2].Path == "Lamp.intensity");
		bed.Pause();
		bed.Click(.(40.0f, 30.0f));
		Test.Assert(bed.Sheet.Rows.Count == 7);
	}

	[Test]
	public static void AParentRowShowsEveryKeyUnderItKeysAtOneTimeAsOne()
	{
		let bed = scope SheetBed();
		let times = scope List<float>();
		let keys = scope List<List<TimelineKeyRef>>();
		defer { ClearAndDeleteItems!(keys); }
		bed.Sheet.GetRowKeys(0, times, keys); // Lamp
		Test.Assert(times.Count == 4);
		CheckNear(times[0], 0.2f);
		Test.Assert(keys[0].Count == 2); // r's and g's
		CheckNear(times[1], 0.6f);
		CheckNear(times[3], 1.4f);
		bed.Sheet.GetRowKeys(2, times, keys); // r
		Test.Assert(times.Count == 2);
		CheckNear(bed.Sheet.KeyPoint(2, 1.0f).X, 410.0f);
		CheckNear(bed.Sheet.KeyPoint(2, 1.0f).Y, 50.0f);
	}

	[Test]
	public static void AClickSelectsAKeyAParentsEveryKeyUnderItAtThatTimeShiftAddsABoxSelects()
	{
		let bed = scope SheetBed();
		bed.Click(SheetBed.At(2, 1.0f)); // r's second
		Test.Assert(bed.Sheet.Selection.Length == 1);
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(0, 1)));
		bed.Pause();
		bed.Click(SheetBed.At(0, 0.2f)); // Lamp at 0.2: r's and g's first
		Test.Assert(bed.Sheet.Selection.Length == 2);
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(0, 0)));
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(1, 0)));
		bed.Pause();
		bed.Click(SheetBed.At(6, 1.0f), KeyModShift); // fov's, added
		Test.Assert(bed.Sheet.Selection.Length == 3);
		bed.Pause();
		bed.Click(SheetBed.At(6, 1.0f), KeyModShift); // and taken away
		Test.Assert(bed.Sheet.Selection.Length == 2);

		bed.Pause();
		bed.Drag(SheetBed.Shifted(SheetBed.At(2, 0.8f), 0.0f, -8.0f), SheetBed.Shifted(SheetBed.At(4, 1.2f), 0.0f, 8.0f)); // r..intensity, 0.8 to 1.2 s
		Test.Assert(bed.Sheet.Selection.Length == 1);
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(0, 1)));
		Test.Assert(bed.Commits.IsEmpty);
	}

	[Test]
	public static void ADragMovesTheSelectedKeysInTimeAsOneChangeOnFramesKeptInTheClipTheSelectionFollows()
	{
		let bed = scope SheetBed();
		bed.Click(SheetBed.At(0, 0.2f)); // r's and g's first
		bed.Pause();
		bed.Drag(SheetBed.At(0, 0.2f), SheetBed.Shifted(SheetBed.At(0, 1.2f), 0.0f, 15.0f)); // past r's second
		Test.Assert(bed.Commits.Count == 1);
		CheckNear(bed.Time(0, 0), 1.0f); // r: the moved key passed its second, now 1.0 then 1.2
		CheckNear(bed.Time(0, 1), 1.2f);
		CheckNear(bed.Time(1, 0), 1.2f); // g: 1.2 then 1.4
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(0, 1))); // r's moved key, now second
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(1, 0)));

		// On frames, and never past the clip's end.
		bed.Axis.FrameRate = 10.0f;
		bed.Pause();
		bed.Drag(SheetBed.At(3, 1.2f), SheetBed.At(3, 1.33f));
		CheckNear(bed.Time(1, 0), 1.3f);
		CheckNear(bed.Time(0, 1), 1.3f);
		bed.Pause();
		bed.Drag(SheetBed.At(3, 1.3f), .(690.0f, 70.0f)); // far right: the selected keys stop at 2 s
		Test.Assert(bed.Time(1, 1) <= 2.0f + 1e-4f);
		CheckNear(bed.Time(1, 1), 2.0f);
		Test.Assert(bed.Commits.Count == 3);
	}

	[Test]
	public static void EscapeGivesAMoveUpDeleteRemovesADoubleClickOnAChannelsRowInsertsAKeyThere()
	{
		let bed = scope SheetBed();
		bed.Press(SheetBed.At(4, 0.6f)); // intensity's
		bed.D.InjectMouseMove(SheetBed.At(4, 0.9f));
		CheckNear(bed.Time(2, 0), 0.9f); // previewed
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		CheckNear(bed.Time(2, 0), 0.6f);
		bed.D.InjectMouseUp(SheetBed.At(4, 0.9f), .Left);
		Test.Assert(bed.Commits.IsEmpty);
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(2, 0)));

		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.Clip.GetKeys(2).IsEmpty);
		Test.Assert(bed.Commits.Count == 1);

		bed.Pause();
		bed.Click(SheetBed.At(2, 0.6f));
		bed.Click(SheetBed.At(2, 0.6f)); // r at 0.6: on the line from 1 to 0
		Test.Assert(bed.Clip.GetKeys(0).Length == 3);
		CheckNear(bed.Clip.GetKeys(0)[1].Time, 0.6f);
		CheckNear(bed.Clip.GetKeys(0)[1].Value, 0.5f);
		Test.Assert(bed.Sheet.IsSelected(TimelineKeyRef(0, 1)));
		Test.Assert(bed.Commits.Count == 2);

		bed.Pause();
		bed.Click(SheetBed.At(0, 1.7f)); // a parent's row inserts nothing
		bed.Click(SheetBed.At(0, 1.7f));
		Test.Assert(bed.Commits.Count == 2);
	}

	[Test]
	public static void TheWheelOverTheNamesScrollsTheRowsOverTheKeysZoomsACurveViewOnTheSameClipFollows()
	{
		let bed = scope SheetBed();
		CurveKey[1] extra = .(CurveBed.Key(0.5f, 0.0f));
		for (int32 i = 0; i < 10; ++i)
			bed.Add("Extra.value", extra);
		// Ten more channels, renamed apart: a row each under Extra.
		bed.Clip.Info(4).Name.Set("Extra.a");
		for (int c = 5; c < 14; ++c)
		{
			bed.Clip.Info(c).Name.Clear();
			bed.Clip.Info(c).Name.AppendF("Extra.v{}", c);
		}
		bed.Clip.InfoChanged();
		Test.Assert(bed.Sheet.Rows.Count > 10);
		bed.D.InjectMouseMove(.(50.0f, 100.0f));
		bed.D.InjectMouseWheel(.(50.0f, 100.0f), .(0.0f, -1.0f));
		CheckNear(bed.Sheet.RowScroll, 60.0f);
		bed.D.InjectMouseWheel(.(50.0f, 100.0f), .(0.0f, 5.0f));
		Test.Assert(bed.Sheet.RowScroll == 0.0f);

		bed.D.InjectMouseWheel(SheetBed.At(0, 1.0f), .(0.0f, 1.0f));
		CheckNear(bed.Axis.PixelsPerSecond, 300.0f);
		CheckNear(bed.Sheet.TimeAtX(410.0f), 1.0f);

		// A curve view over the same clip: a move in the dopesheet is a move it shows.
		let view = new CurveView();
		defer view.ReleaseRef();
		view.TimeAxis = bed.Axis;
		view.Source = bed.Clip;
		bed.Axis.PixelsPerSecond = 250.0f;
		bed.Axis.Scroll = 0.0f;
		bed.Click(SheetBed.At(6, 1.0f)); // fov's
		bed.Pause();
		bed.Drag(SheetBed.At(6, 1.0f), SheetBed.At(6, 0.5f));
		CheckNear(view.Source.GetKeys(3)[0].Time, 0.5f);
		view.Source = null;
	}

	[Test]
	public static void TheTimelineViewsAreElementsMarkupPlacesADopesheetsNamesColumnSetThere()
	{
		let made = Load("<Panel><TimeRuler/><Dopesheet label-width=\"120\"/><CurveView/><GradientView/></Panel>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		Test.Assert(made.ChildCount == 4);
		Test.Assert(made.GetChildAt(0) is TimeRuler);
		let sheet = made.GetChildAt(1) as Dopesheet;
		Test.Assert(sheet != null);
		CheckNear(sheet.LabelWidth, 120.0f);
		Test.Assert(made.GetChildAt(2) is CurveView);
		Test.Assert(made.GetChildAt(3) is GradientView);
	}

	[Test]
	public static void RightToLeftItsNamesAreAtTheRightAndItsKeysStartAtTheLeftTimeStillLeftToRight()
	{
		let bed = scope SheetBed();
		bed.Root.SetLayoutDirection(.RightToLeft);
		bed.Root.UpdateLayout();
		let names = bed.Sheet.NamesBounds;
		let @box = bed.Sheet.ContentBounds;
		CheckNear(names.Right, @box.Right);
		CheckNear(names.Width, 160.0f);
		CheckNear(bed.Sheet.KeysLeft, @box.X);
		CheckNear(bed.Sheet.KeyPoint(2, 1.0f).X, @box.X + 250.0f);
		CheckNear(bed.Sheet.TimeAtX(@box.X + 250.0f), 1.0f);

		// A click on a name at the right folds its row.
		let at = bed.Sheet.ScreenBounds;
		bed.Click(.(at.Right - 40.0f, at.Y + 30.0f)); // "color"
		Test.Assert(bed.Sheet.IsFolded("Lamp.color"));
	}

	// What no Raptor test covers: a fold set from code, kept when the channels are read again.
	[Test]
	public static void AFoldSetFromCodeHoldsWhenTheChannelsChange()
	{
		let bed = scope SheetBed();
		bed.Sheet.SetFolded("Lamp", true);
		Test.Assert(bed.Sheet.Rows.Count == 3); // Lamp, Camera, fov
		CurveKey[1] one = .(CurveBed.Key(0.1f, 0.0f));
		bed.Add("Lamp.range", one);
		Test.Assert(bed.Sheet.Rows.Count == 3);
		Test.Assert(bed.Sheet.Rows[0].Folded);
		bed.Sheet.SetFolded("Lamp", false);
		Test.Assert(bed.Sheet.FindRow("Lamp.range") == 5);
	}
}
