using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A curve set's commits, kept (each its own copy).
class KeptCurveChanges
{
	public List<CurveChange> Changes = new .() ~ DeleteContainerAndItems!(_);

	public void Keep(CurveChange change)
	{
		let copy = new CurveChange();
		for (let edit in change.Curves)
		{
			let kept = new CurveEdit();
			kept.Curve = edit.Curve;
			kept.Before.AddRange(edit.Before);
			kept.After.AddRange(edit.After);
			copy.Curves.Add(kept);
		}
		Changes.Add(copy);
	}
}

/// A 520 by 220 view over 0 to 1 s (500 px a second) and values -0.05 to 1.05 (200 px a unit): the
/// time t and value v at (500 t, 210 - 200 v), no key on its edge. The root goes with it.
class CurveBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public TimeAxis Axis = new .() ~ _.ReleaseRef();
	public CurveView View = new .() ~ _.ReleaseRef();
	public CurveSet Curves = new .() ~ delete _;
	public KeptCurveChanges Kept = new .() ~ delete _;

	public this()
	{
		Root = NewRoot(600.0f, 300.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		View.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(520.0f);
				s.Height = LayoutLength.Px(220.0f);
			});
		Root.AddChild(View);
		Axis.Duration = 1.0f;
		Axis.PixelsPerSecond = 500.0f;
		View.TimeAxis = Axis;
		View.SetValueRange(-0.05f, 1.05f);
		View.Source = Curves;
		Curves.SetOnCommit(new (change) => { Kept.Keep(change); });
		Root.UpdateLayout();
	}

	public ~this()
	{
		View.Source = null;
	}

	public List<CurveChange> Commits => Kept.Changes;
	public EventDispatcher D => Root.EventDispatcher;

	public static Float2 At(float t, float v) => .(500.0f * t, 210.0f - 200.0f * v);

	public void Press(Float2 at, uint32 modifiers = 0)
	{
		D.InjectMouseMove(at, modifiers);
		D.InjectMouseDown(at, .Left, modifiers);
	}

	public void Drag(Float2 from, Float2 to, uint32 modifiers = 0)
	{
		Press(from, modifiers);
		D.InjectMouseMove(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f), modifiers);
		D.InjectMouseMove(to, modifiers);
		D.InjectMouseUp(to, .Left, modifiers);
	}

	public void Click(Float2 at, uint32 modifiers = 0)
	{
		Press(at, modifiers);
		D.InjectMouseUp(at, .Left, modifiers);
	}

	/// A later press is not the second of a double.
	public void Pause()
	{
		D.InjectMouseMove(.(590.0f, 290.0f));
		D.InjectMouseDown(.(590.0f, 290.0f), .Left);
		D.InjectMouseUp(.(590.0f, 290.0f), .Left);
	}

	public Span<CurveKey> Keys(int curve = 0) => Curves.GetKeys(curve);

	public static CurveKey Key(float time, float value, CurveKeyInterpolation interp = .Linear, CurveTangentMode mode = .Broken)
	{
		var key = CurveKey();
		key.Time = time;
		key.Value = value;
		key.Interpolation = interp;
		key.TangentMode = mode;
		return key;
	}

	public static void Activate(Sedulous.GUI.Menu menu, StringView text)
	{
		let item = Item(menu, text);
		if (item == null)
		{
			Test.FatalError("no such item");
			return;
		}
		item.HandleActivate();
	}

	public static MenuItem Item(Sedulous.GUI.Menu menu, StringView text)
	{
		for (int i = 0; i < menu.ChildCount; ++i)
		{
			if (let item = menu.GetChildAt(i) as MenuItem)
			{
				if (item.Text == text)
					return item;
			}
		}
		return null;
	}

	/// Opens the view's menu at `at` (a right press and release).
	public void RightClick(Float2 at)
	{
		D.InjectMouseDown(at, .Right);
		D.InjectMouseUp(at, .Right);
	}
}

/// The curve view: a source's curves of Core's keys edited as gestures through it, one change each
/// (a drag previewed and committed on release, or cancelled by Escape); keys selected by a click or a
/// box, moved (sorted again as they pass, on frames, in a curve's range, Shift locking an axis), their
/// tangents set by their handles and their modes, added by a double click on a curve, set and deleted
/// from their menu; the wheel zooming and a middle drag panning.
class CurveViewTests
{
	[Test]
	public static void ACurveSetsEditPreviewsLiveCommitsOnceWithEachChangedCurvesKeysBeforeAndAfterOrCancels()
	{
		let set = scope CurveSet();
		CurveKey[2] a = .(CurveBed.Key(0.0f, 0.0f), CurveBed.Key(1.0f, 1.0f));
		set.AddCurve(scope CurveInfo(), a);
		set.AddCurve(scope CurveInfo(), a);
		let kept = scope KeptCurveChanges();
		set.SetOnCommit(new (change) => { kept.Keep(change); });
		let commits = kept.Changes;

		CurveKey[2] b = .(CurveBed.Key(0.0f, 0.5f), CurveBed.Key(1.0f, 1.0f));
		set.BeginKeysEdit();
		set.PreviewKeys(1, b);
		Test.Assert(set.GetKeys(1)[0].Value == 0.5f);
		set.CancelKeysEdit();
		Test.Assert(set.GetKeys(1)[0].Value == 0.0f);
		Test.Assert(commits.IsEmpty);

		set.BeginKeysEdit();
		set.PreviewKeys(1, b);
		set.PreviewKeys(1, b);
		set.CommitKeysEdit();
		Test.Assert(commits.Count == 1);
		Test.Assert(commits[0].Curves.Count == 1); // the untouched curve is not in it
		Test.Assert(commits[0].Curves[0].Curve == 1);
		Test.Assert(commits[0].Curves[0].Before[0].Value == 0.0f);
		Test.Assert(commits[0].Curves[0].After[0].Value == 0.5f);

		set.Apply(commits[0], true);
		Test.Assert(set.GetKeys(1)[0].Value == 0.0f);
		set.Apply(commits[0], false);
		Test.Assert(set.GetKeys(1)[0].Value == 0.5f);

		set.BeginKeysEdit(); // nothing changed: nothing told
		set.CommitKeysEdit();
		Test.Assert(commits.Count == 1);
	}

	[Test]
	public static void KeysAndTheCurveBetweenThemAreWhereTheAxisAndTheValueRangePutThem()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.2f, 0.25f), CurveBed.Key(0.8f, 0.75f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		CheckNear(bed.View.KeyPoint(0.2f, 0.25f).X, 100.0f);
		CheckNear(bed.View.KeyPoint(0.2f, 0.25f).Y, 160.0f);
		CheckNear(bed.View.TimeAtX(250.0f), 0.5f);
		CheckNear(bed.View.ValueAtY(110.0f), 0.5f);

		let near = CurveBed.At(0.8f, 0.75f);
		var hit = bed.View.HitTest(.(near.X + 3.0f, near.Y - 2.0f));
		Test.Assert(hit.What == .Key);
		Test.Assert(hit.Key == CurveKeyRef(0, 1));
		let between = CurveBed.At(0.5f, 0.5f);
		hit = bed.View.HitTest(.(between.X, between.Y + 4.0f)); // on the line between them
		Test.Assert(hit.What == .Curve);
		hit = bed.View.HitTest(CurveBed.At(0.5f, 0.9f));
		Test.Assert(hit.What == .None);

		bed.Curves.Info(0).Locked = true; // a locked curve is drawn, not hit
		bed.Curves.InfoChanged();
		Test.Assert(bed.View.HitTest(CurveBed.At(0.8f, 0.75f)).What == .None);
	}

	[Test]
	public static void AClickSelectsAKeyShiftAddsOneAClickOnNothingClearsABoxSelects()
	{
		let bed = scope CurveBed();
		CurveKey[3] keys = .(CurveBed.Key(0.1f, 0.1f), CurveBed.Key(0.3f, 0.2f), CurveBed.Key(0.6f, 0.8f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Click(CurveBed.At(0.1f, 0.1f));
		Test.Assert(bed.View.Selection.Length == 1);
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 0)));
		bed.Pause();
		bed.Click(CurveBed.At(0.6f, 0.8f), KeyModShift);
		Test.Assert(bed.View.Selection.Length == 2);
		bed.Pause();
		bed.Click(CurveBed.At(0.6f, 0.8f), KeyModShift); // again: taken away
		Test.Assert(bed.View.Selection.Length == 1);
		bed.Pause();
		bed.Click(CurveBed.At(0.5f, 0.1f)); // nothing there
		Test.Assert(bed.View.Selection.IsEmpty);
		bed.Pause();

		bed.Drag(CurveBed.At(0.05f, 0.3f), CurveBed.At(0.35f, 0.0f)); // around the first two
		Test.Assert(bed.View.Selection.Length == 2);
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 0)));
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 1)));
		Test.Assert(bed.Commits.IsEmpty); // selecting changes nothing
	}

	[Test]
	public static void ADragMovesTheSelectedKeysAsOneChangeSortedAgainAsTheyPassOnFramesInRange()
	{
		let bed = scope CurveBed();
		CurveKey[3] keys = .(CurveBed.Key(0.1f, 0.1f), CurveBed.Key(0.3f, 0.2f), CurveBed.Key(0.6f, 0.8f));
		let info = scope CurveInfo();
		info.HasRange = true;
		info.Min = 0.0f;
		info.Max = 1.0f;
		bed.Curves.AddCurve(info, keys);

		bed.Drag(CurveBed.At(0.1f, 0.1f), CurveBed.At(0.4f, 0.3f)); // the first passes the second
		Test.Assert(bed.Commits.Count == 1);
		Test.Assert(bed.Keys().Length == 3);
		CheckNear(bed.Keys()[0].Time, 0.3f);
		CheckNear(bed.Keys()[1].Time, 0.4f);
		CheckNear(bed.Keys()[1].Value, 0.3f);
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 1))); // the selection followed it

		// On frames: the pressed key lands on one.
		bed.Axis.FrameRate = 10.0f;
		bed.Pause();
		bed.Drag(CurveBed.At(0.6f, 0.8f), CurveBed.At(0.73f, 0.8f));
		CheckNear(bed.Keys()[2].Time, 0.7f);
		// In its range.
		bed.Pause();
		bed.Drag(CurveBed.At(0.7f, 0.8f), CurveBed.At(0.7f, 1.4f));
		CheckNear(bed.Keys()[2].Value, 1.0f);
		Test.Assert(bed.Commits.Count == 3);
	}

	[Test]
	public static void ShiftLocksADragToTheAxisItMovedAlongMostAndEscapeGivesItUp()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.2f, 0.5f), CurveBed.Key(0.8f, 0.5f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Drag(CurveBed.At(0.2f, 0.5f), CurveBed.At(0.4f, 0.55f), KeyModShift);
		CheckNear(bed.Keys()[0].Time, 0.4f);
		CheckNear(bed.Keys()[0].Value, 0.5f);

		bed.Pause();
		bed.Press(CurveBed.At(0.8f, 0.5f));
		bed.D.InjectMouseMove(CurveBed.At(0.7f, 0.2f));
		CheckNear(bed.Keys()[1].Value, 0.2f); // previewed
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		CheckNear(bed.Keys()[1].Value, 0.5f);
		CheckNear(bed.Keys()[1].Time, 0.8f);
		bed.D.InjectMouseUp(CurveBed.At(0.7f, 0.2f), .Left);
		Test.Assert(bed.Commits.Count == 1);
	}

	[Test]
	public static void AutoAndSmoothKeysFollowAMoveAHandleSetsTheTangentAndMakesAnAutoKeySmooth()
	{
		let bed = scope CurveBed();
		CurveKey[3] keys = .(CurveBed.Key(0.0f, 0.0f, .Cubic, .Auto), CurveBed.Key(0.5f, 0.5f, .Cubic, .Auto), CurveBed.Key(1.0f, 0.0f, .Cubic, .Auto));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		// Auto: each key's slope that between its neighbours, set by the move.
		bed.Drag(CurveBed.At(1.0f, 0.0f), CurveBed.At(1.0f, 1.0f));
		CheckNear(bed.Keys()[1].TangentOut, 1.0f); // (1 - 0) / (1 - 0)
		Test.Assert(bed.Keys()[1].TangentMode == .Auto);

		// The middle key selected shows both handles; its out handle dragged flat.
		bed.Pause();
		bed.Click(CurveBed.At(0.5f, 0.5f));
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 1)));
		let handle = bed.View.HandlePoint(bed.Keys()[1], true);
		Test.Assert(bed.View.HitTest(handle).What == .TangentOut);
		bed.Pause();
		bed.Click(CurveBed.At(0.5f, 0.5f));
		bed.Drag(handle, CurveBed.At(0.7f, 0.5f));
		CheckNear(bed.Keys()[1].TangentOut, 0.0f);
		CheckNear(bed.Keys()[1].TangentIn, 0.0f); // smooth: one slope through it
		Test.Assert(bed.Keys()[1].TangentMode == .Smooth);

		// Broken: the in handle alone.
		bed.View.SetTangentMode(.Broken);
		let @in = bed.View.HandlePoint(bed.Keys()[1], false);
		bed.Pause();
		bed.Click(CurveBed.At(0.5f, 0.5f));
		bed.Drag(@in, CurveBed.At(0.4f, 0.4f));
		CheckNear(bed.Keys()[1].TangentIn, 1.0f); // (0.5 - 0.4) / (0.5 - 0.4)
		CheckNear(bed.Keys()[1].TangentOut, 0.0f);
	}

	[Test]
	public static void AHandleShowsOnlyWhereACubicSegmentMeetsItsKey()
	{
		CurveKey[3] keys = .(CurveBed.Key(0.0f, 0.0f, .Linear), CurveBed.Key(0.5f, 0.5f, .Cubic), CurveBed.Key(1.0f, 0.0f));
		Test.Assert(!CurveView.HasHandle(keys, 0, true));
		Test.Assert(!CurveView.HasHandle(keys, 1, false)); // the linear segment arrives
		Test.Assert(CurveView.HasHandle(keys, 1, true));
		Test.Assert(CurveView.HasHandle(keys, 2, false));
		Test.Assert(!CurveView.HasHandle(keys, 2, true)); // the last key leaves nothing
	}

	[Test]
	public static void ADoubleClickOnACurveAddsAKeyOnItUnlessTheCurveIsFull()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.0f, 0.0f), CurveBed.Key(1.0f, 1.0f));
		let info = scope CurveInfo();
		info.MaxKeys = 3;
		bed.Curves.AddCurve(info, keys);
		bed.Click(CurveBed.At(0.5f, 0.5f));
		bed.Click(CurveBed.At(0.5f, 0.5f)); // the second press
		Test.Assert(bed.Keys().Length == 3);
		CheckNear(bed.Keys()[1].Time, 0.5f);
		CheckNear(bed.Keys()[1].Value, 0.5f);
		Test.Assert(bed.Keys()[1].Interpolation == .Linear); // the segment's it split
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 1)));
		Test.Assert(bed.Commits.Count == 1);

		bed.Pause();
		bed.Click(CurveBed.At(0.25f, 0.25f));
		bed.Click(CurveBed.At(0.25f, 0.25f));
		Test.Assert(bed.Keys().Length == 3); // full
		Test.Assert(bed.Commits.Count == 1);
	}

	[Test]
	public static void AKeysMenuSetsTheSelectedKeysInterpolationAndModeCheckedWhereTheyAgreeAndDeletes()
	{
		let bed = scope CurveBed();
		CurveKey[3] keys = .(CurveBed.Key(0.1f, 0.1f), CurveBed.Key(0.5f, 0.5f), CurveBed.Key(0.9f, 0.1f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Click(CurveBed.At(0.1f, 0.1f));
		bed.Pause();
		bed.Click(CurveBed.At(0.5f, 0.5f), KeyModShift);
		bed.D.InjectMouseMove(CurveBed.At(0.5f, 0.5f));
		bed.RightClick(CurveBed.At(0.5f, 0.5f));
		var menu = bed.View.KeyMenu;
		Test.Assert(menu != null);
		Test.Assert(bed.View.Selection.Length == 2); // a selected key keeps the selection
		Test.Assert(CurveBed.Item(menu, "Linear").Checked);
		Test.Assert(CurveBed.Item(menu, "Broken").Checked);
		CurveBed.Activate(menu, "Cubic");
		Test.Assert(bed.Keys()[0].Interpolation == .Cubic);
		Test.Assert(bed.Keys()[1].Interpolation == .Cubic);
		Test.Assert(bed.Keys()[2].Interpolation == .Linear);
		Test.Assert(bed.Commits.Count == 1);

		bed.View.SetTangentMode(.Flat);
		Test.Assert(bed.Commits.Count == 2);
		bed.RightClick(CurveBed.At(0.5f, 0.5f));
		menu = bed.View.KeyMenu;
		Test.Assert(menu != null);
		Test.Assert(CurveBed.Item(menu, "Flat").Checked);
		CurveBed.Activate(menu, "Delete");
		Test.Assert(bed.Keys().Length == 1);
		CheckNear(bed.Keys()[0].Time, 0.9f);
		Test.Assert(bed.View.Selection.IsEmpty);

		// Delete on the focused view.
		bed.Click(CurveBed.At(0.9f, 0.1f));
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.Keys().IsEmpty);
		Test.Assert(bed.Commits.Count == 4);
	}

	[Test]
	public static void TheMenuOverNothingFramesEveryCurveOrTheSelection()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.2f, 2.0f), CurveBed.Key(0.6f, 4.0f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Axis.Duration = 10.0f;
		bed.D.InjectMouseMove(.(400.0f, 20.0f));
		bed.RightClick(.(400.0f, 20.0f));
		let menu = bed.View.KeyMenu;
		Test.Assert(menu != null);
		Test.Assert(!CurveBed.Item(menu, "Frame selection").Enabled);
		CurveBed.Activate(menu, "Frame all");
		// Both keys inside, with a margin.
		Test.Assert(bed.View.ValueLow < 2.0f);
		Test.Assert(bed.View.ValueHigh > 4.0f);
		Test.Assert(bed.View.ValueHigh < 4.5f);
		let first = bed.View.KeyPoint(0.2f, 2.0f);
		let last = bed.View.KeyPoint(0.6f, 4.0f);
		Test.Assert(first.X > 0.0f);
		Test.Assert(last.X < 520.0f);
		Test.Assert(last.X - first.X > 400.0f);

		// The selection alone: its one key in the middle.
		CurveKeyRef[1] second = .(CurveKeyRef(0, 1));
		bed.View.SetSelection(second);
		bed.View.FrameSelection();
		CheckNear(bed.View.KeyPoint(0.6f, 4.0f).X, 260.0f, 0.02);
		CheckNear(bed.View.KeyPoint(0.6f, 4.0f).Y, 110.0f, 0.02);
	}

	[Test]
	public static void TheWheelZoomsAboutThePointerCtrlOnlyTimeAndShiftOnlyValueAMiddleDragPans()
	{
		let bed = scope CurveBed();
		bed.Axis.Duration = 10.0f;
		bed.Axis.Scroll = 0.0f;
		let at = Float2(250.0f, 110.0f); // 0.5 s, 0.5
		bed.D.InjectMouseMove(at);
		bed.D.InjectMouseWheel(at, .(0.0f, 1.0f));
		CheckNear(bed.Axis.PixelsPerSecond, 600.0f);
		CheckNear(bed.View.TimeAtX(250.0f), 0.5f);
		CheckNear(bed.View.ValueAtY(110.0f), 0.5f);
		CheckNear(bed.View.ValueHigh - bed.View.ValueLow, 1.1f / 1.2f);

		bed.D.InjectMouseWheel(at, .(0.0f, -1.0f), KeyModCtrl); // time only
		CheckNear(bed.Axis.PixelsPerSecond, 500.0f);
		CheckNear(bed.View.ValueHigh - bed.View.ValueLow, 1.1f / 1.2f);
		bed.D.InjectMouseWheel(at, .(0.0f, -1.0f), KeyModShift); // value only
		CheckNear(bed.Axis.PixelsPerSecond, 500.0f);
		CheckNear(bed.View.ValueHigh - bed.View.ValueLow, 1.1f);

		let low = bed.View.ValueLow;
		bed.Axis.Scroll = 1.0f;
		bed.D.InjectMouseDown(at, .Middle);
		bed.D.InjectMouseMove(.(at.X - 100.0f, at.Y + 40.0f));
		bed.D.InjectMouseUp(.(at.X - 100.0f, at.Y + 40.0f), .Middle);
		CheckNear(bed.Axis.Scroll, 1.2f);
		CheckNear(bed.View.ValueLow, low + 0.2f); // dragged down 40 px: the values move up
	}

	[Test]
	public static void AnUndoThatTakesKeysAwayTakesThemFromTheSelection()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.0f, 0.0f), CurveBed.Key(1.0f, 1.0f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Click(CurveBed.At(0.5f, 0.5f));
		bed.Click(CurveBed.At(0.5f, 0.5f));
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 1)));
		bed.Pause();
		bed.Click(CurveBed.At(1.0f, 1.0f));
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 2)));
		bed.Curves.Apply(bed.Commits[0], true);
		Test.Assert(bed.Keys().Length == 2);
		Test.Assert(bed.View.Selection.IsEmpty);
	}

	[Test]
	public static void AShiftClickOnAKeyJustSelectedTakesItAwayThoughItComesAsADoubleClick()
	{
		let bed = scope CurveBed();
		CurveKey[2] keys = .(CurveBed.Key(0.2f, 0.2f), CurveBed.Key(0.8f, 0.8f));
		bed.Curves.AddCurve(scope CurveInfo(), keys);
		bed.Click(CurveBed.At(0.2f, 0.2f));
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 0)));
		bed.Click(CurveBed.At(0.2f, 0.2f), KeyModShift); // the second press, near in time and place
		Test.Assert(!bed.View.IsSelected(CurveKeyRef(0, 0)));
		bed.Click(CurveBed.At(0.2f, 0.2f), KeyModShift); // and back
		Test.Assert(bed.View.IsSelected(CurveKeyRef(0, 0)));
		Test.Assert(bed.Keys().Length == 2); // nothing added
	}

	// Further cases: a curve set as a timeline: its curves the channels by their names,
	// a key inserted on the curve and keys moved past each other, the moved ones followed.
	[Test]
	public static void ACurveSetIsATimelineItsCurvesTheChannelsAKeyInsertedAndKeysMoved()
	{
		let set = scope CurveSet();
		CurveKey[2] a = .(CurveBed.Key(0.0f, 0.0f), CurveBed.Key(1.0f, 2.0f));
		set.AddCurve(scope CurveInfo("Lamp.size"), a);
		Test.Assert(set.ChannelCount == 1);
		Test.Assert(set.GetChannelPath(0, .. scope String()) == "Lamp.size");
		TimelineKeyRef made;
		Test.Assert(set.InsertKey(0, 0.5f, out made));
		Test.Assert(made == TimelineKeyRef(0, 1));
		CheckNear(set.GetKeys(0)[1].Value, 1.0f); // on the curve
		Test.Assert(set.GetKeys(0)[1].Interpolation == .Linear); // the segment's it split

		set.BeginKeysMove();
		TimelineKeyRef[1] first = .(TimelineKeyRef(0, 0));
		let moved = scope List<TimelineKeyRef>();
		set.PreviewKeysMove(first, 0.75f, moved);
		Test.Assert(moved.Count == 1);
		Test.Assert(moved[0] == TimelineKeyRef(0, 1)); // past the inserted key
		set.CommitKeysMove();
		let times = scope List<float>();
		set.GetKeyTimes(0, times);
		Test.Assert(times.Count == 3);
		CheckNear(times[0], 0.5f);
		CheckNear(times[1], 0.75f);
	}
}
