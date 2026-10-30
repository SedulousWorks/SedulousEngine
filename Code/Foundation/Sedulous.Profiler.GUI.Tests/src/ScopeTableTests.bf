using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Tests; // KnownSource

namespace Sedulous.Profiler.GUI.Tests;

/// The scope table and the scope's detail (X7 of Raptor's editor-gui spec): the call tree of the
/// frames chosen (each thread a group, the GPU's passes one, a scope's runs in one place one row,
/// self time its children's taken out); sorted by another heading a flat list of names; a filter
/// showing the names holding its text and the rows they hang from; a span cutting the scopes to it;
/// a click choosing a row's name, a click on an arrow folding it, on a heading sorting. The detail:
/// the name's calls and times, its callers, its children by name with its own time last, its calls'
/// spread over every frame held and its longest call in the frames chosen.
class ScopeTableTests
{
	/// A table 600 by 300 (headings 24 high, rows 22; the six number columns 72 wide from the end)
	/// and a detail beside it, over frames 0 (20 ms) and 1 (10 ms), both chosen.
	private class Bed
	{
		public KnownSource Source = new .() ~ delete _;
		public SceneRoot Root;
		public ProfileFocus Focus = new .() ~ _.ReleaseRef();
		public ScopeTable Table = new .() ~ _.ReleaseRef();
		public ScopeDetail Detail = new .() ~ _.ReleaseRef();
		public uint32 Frame, Update, Physics, Render, Job, Shadows;

		public this()
		{
			Frame = Source.Name("Frame");
			Update = Source.Name("Update");
			Physics = Source.Name("Physics");
			Render = Source.Name("Render");
			Job = Source.Name("Job");
			Shadows = Source.Name("Shadows");
			let worker = Source.Thread("Worker");
			let f0 = Source.AddFrame(20); // ticks 1000 to 1020
			KnownSource.AddScope(f0, Physics, 2, 2, 10);
			KnownSource.AddScope(f0, Physics, 2, 11, 14);
			KnownSource.AddScope(f0, Update, 1, 1, 15);
			KnownSource.AddScope(f0, Render, 1, 15, 19);
			KnownSource.AddScope(f0, Frame, 0, 0, 20);
			KnownSource.AddScopeOn(f0, worker, Job, 0, 2, 9);
			KnownSource.AddPass(f0, Shadows, 3, 6);
			let f1 = Source.AddFrame(10); // ticks 1020 to 1030
			KnownSource.AddScope(f1, Physics, 2, 1, 5);
			KnownSource.AddScope(f1, Update, 1, 0, 8);
			KnownSource.AddScope(f1, Frame, 0, 0, 10);

			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1000.0f, 400.0f);
			Root.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Start;
				});
			Table.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(600.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Detail.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(380.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Root.AddChild(Table);
			Root.AddChild(Detail);
			Table.Focus = Focus;
			Detail.Focus = Focus;
			Focus.SetSource(Source);
			FrameRange both = .();
			both.First = 0;
			both.Last = 1;
			both.Empty = false;
			Focus.SetFrames(both);
			Root.UpdateLayout();
		}

		public ~this()
		{
			Focus.SetSource(null);
			Root.ReleaseRef();
		}

		public EventDispatcher D => Root.EventDispatcher;

		public void Click(Float2 at)
		{
			D.InjectMouseMove(at);
			D.InjectMouseDown(at, .Left);
			D.InjectMouseUp(at, .Left);
		}

		public void Pause() => Click(.(990.0f, 390.0f));

		public static Float2 RowAt(int row, float x = 100.0f) => .(x, 24.0f + 22.0f * (float)row + 11.0f);

		public void Labels(String outText)
		{
			for (let row in Table.Rows)
			{
				if (!outText.IsEmpty)
					outText.Append(" ");
				outText.Append(row.Label);
			}
		}

		/// The row labelled `label`; false: none.
		public bool RowOf(StringView label, out ScopeTable.Row outRow)
		{
			outRow = .();
			for (let row in Table.Rows)
			{
				if (row.Label == label)
				{
					outRow = row;
					return true;
				}
			}
			return false;
		}

		public void Cell(StringView label, ScopeColumn column, String outText)
		{
			ScopeTable.Row row;
			Test.Assert(RowOf(label, out row));
			Table.CellText(row, column, outText);
		}
	}

	[Test]
	public static void TheCallTreeOfTheFramesChosenAScopesRunsInOnePlaceOneRow()
	{
		let bed = scope Bed();
		Test.Assert(bed.Labels(.. scope .()) == "Main Frame Update Physics Render Worker Job GPU Shadows");
		ScopeTable.Row frame;
		Test.Assert(bed.RowOf("Frame", out frame));
		Test.Assert(frame.Calls == 2);
		Test.Assert(frame.Depth == 1);
		Test.Assert(bed.Cell("Frame", .Total, .. scope .()) == "30.00");
		Test.Assert(bed.Cell("Frame", .Self, .. scope .()) == "4.00"); // 30 less Update's 22 and Render's 4
		ScopeTable.Row physics;
		Test.Assert(bed.RowOf("Physics", out physics));
		Test.Assert(physics.Calls == 3);
		Test.Assert(bed.Cell("Physics", .Total, .. scope .()) == "15.00");
		Test.Assert(bed.Cell("Physics", .Mean, .. scope .()) == "5.00");
		Test.Assert(bed.Cell("Physics", .Max, .. scope .()) == "8.00");
		Test.Assert(bed.Cell("Physics", .Share, .. scope .()) == "50.0%");
		Test.Assert(bed.Cell("Main", .Total, .. scope .()).IsEmpty); // a group: no numbers
	}

	[Test]
	public static void AnotherHeadingSortsAFlatListOfNamesAgainTheOtherWay()
	{
		let bed = scope Bed();
		bed.Table.SortBy(.Total);
		Test.Assert(bed.Labels(.. scope .()) == "Frame Update Physics Job Render Shadows");
		bed.Table.SortBy(.Total, false);
		Test.Assert(bed.Labels(.. scope .()) == "Shadows Render Job Physics Update Frame");
		bed.Table.SortBy(.Calls);
		Test.Assert(bed.Table.Rows[0].Label == "Physics"); // three calls

		// By a click on the headings: Self (from the end, the fourth), then again the other way.
		bed.Table.SortBy(.Name);
		bed.Click(.(350.0f, 12.0f));
		Test.Assert(bed.Table.SortColumn == .Self);
		Test.Assert(bed.Table.SortsDescending);
		bed.Pause();
		bed.Click(.(350.0f, 12.0f));
		Test.Assert(!bed.Table.SortsDescending);
		bed.Pause();
		bed.Click(.(60.0f, 12.0f));
		Test.Assert(bed.Table.SortColumn == .Name);
	}

	[Test]
	public static void AFilterShowsTheNamesHoldingItsTextInTheTreeWithTheRowsTheyHangFrom()
	{
		let bed = scope Bed();
		bed.Table.SetFilter("PHYS");
		Test.Assert(bed.Labels(.. scope .()) == "Main Frame Update Physics");
		bed.Table.SortBy(.Total);
		Test.Assert(bed.Labels(.. scope .()) == "Physics");
	}

	[Test]
	public static void ASpanCutsTheScopesToItOneThatRanOnlyOutsideItGoes()
	{
		let bed = scope Bed();
		bed.Focus.SetSpan(1002, 1006);
		Test.Assert(!bed.RowOf("Render", ?));
		ScopeTable.Row physics;
		Test.Assert(bed.RowOf("Physics", out physics));
		Test.Assert(physics.Calls == 1);
		Test.Assert(bed.Cell("Physics", .Total, .. scope .()) == "4.00");
		Test.Assert(bed.Cell("Physics", .Share, .. scope .()) == "100.0%");
		Test.Assert(bed.Cell("Shadows", .Total, .. scope .()) == "3.00");
		bed.Focus.ClearSpan();
		Test.Assert(bed.RowOf("Render", ?));
	}

	[Test]
	public static void AClickOnARowChoosesItsNameOnItsArrowFoldsIt()
	{
		let bed = scope Bed();
		bed.Click(Bed.RowAt(3)); // Physics
		Test.Assert(bed.Focus.Name.Is(bed.Physics, false));
		bed.Pause();
		bed.Click(Bed.RowAt(8)); // Shadows, the GPU's
		Test.Assert(bed.Focus.Name.Is(bed.Shadows, true));
		bed.Pause();
		bed.Click(Bed.RowAt(1, 30.0f)); // Frame's arrow
		Test.Assert(bed.Labels(.. scope .()) == "Main Frame Worker Job GPU Shadows");
		Test.Assert(bed.Focus.Name.Is(bed.Shadows, true)); // folding chooses nothing
		bed.Pause();
		bed.Click(Bed.RowAt(1, 30.0f));
		Test.Assert(bed.Table.Rows.Length == 9);
	}

	[Test]
	public static void TheNameChosensCallsCallersChildrenAndSpreadItsLongestCall()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Detail.Describe.Any);
		bed.Focus.ChooseName(bed.Update, false);
		let update = bed.Detail.Describe;
		Test.Assert(update.Any);
		Test.Assert(update.Calls == 2);
		Test.Assert(update.TotalTicks == 22);
		Test.Assert(update.MaxTicks == 14);
		Test.Assert(update.Lanes == "Main");
		Test.Assert(update.Callers.Count == 1);
		Test.Assert(update.Callers[0] == "Frame (Main)");
		Test.Assert(update.Children.Count == 2);
		Test.Assert(update.Children[0].Name == "Physics");
		Test.Assert(update.Children[0].Ticks == 15);
		Test.Assert(update.Children[1].IsSelf);
		Test.Assert(update.Children[1].Ticks == 7);
		Test.Assert(update.HeldFrames == 2);
		Test.Assert(update.HeldCalls == 2);
		int64 begin, end;
		Test.Assert(bed.Detail.LongestCall(out begin, out end));
		Test.Assert(begin == 1001);
		Test.Assert(end == 1015);

		bed.Focus.ChooseName(bed.Job, false);
		let job = bed.Detail.Describe;
		Test.Assert(job.Callers.Count == 1);
		Test.Assert(job.Callers[0] == "The top of Worker");
		Test.Assert(job.Lanes == "Worker");

		// Its spread covers every frame held; only the frames chosen's calls are lit.
		bed.Focus.ChooseName(bed.Physics, false);
		bed.Focus.SetFrame(1);
		let physics = bed.Detail.Describe;
		Test.Assert(physics.Calls == 1);
		Test.Assert(physics.HeldCalls == 3);
		uint32 lit = 0;
		uint32 counted = 0;
		for (int b < physics.Bins.Count)
		{
			counted += physics.Bins[b];
			if (physics.Lit[b])
				lit++;
		}
		Test.Assert(counted == 3);
		Test.Assert(lit == 1);
		Test.Assert(bed.Detail.LongestCall(out begin, out end));
		Test.Assert(begin == 1021);
	}
}
