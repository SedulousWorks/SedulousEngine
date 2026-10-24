using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Separator and Spacer: oriented by their parent's flex direction; a separator's line stretched
/// across, as thick as its thickness; a spacer flexible or of a fixed size.
class SeparatorTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A panel `w` by `h`, the last child of `parent`, which holds it (borrowed).
	private static Panel Fixed(Node parent, float w, float h)
	{
		let p = new Panel();
		p.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(w);
				s.Height = LayoutLength.Px(h);
			});
		parent.AddChild(p);
		p.ReleaseRef();
		return p;
	}

	/// A root holding a 200 by 100 line of `direction`, its items centred across. The root goes with
	/// the bed.
	private class Bed
	{
		public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
		public Panel Line = new .() ~ _.ReleaseRef();

		public this(FlexDirection direction)
		{
			Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
			Line.EditLayoutStyle(scope (s) =>
				{
					s.Direction = direction;
					s.Width = LayoutLength.Px(200.0f);
					s.Height = LayoutLength.Px(100.0f);
					s.AlignItems = .Center;
				});
			Root.AddChild(Line);
		}
	}

	[Test]
	public static void InAColumnItLiesAcrossTheColumnInARowItStandsTheRowsHeight()
	{
		let column = scope Bed(.Column);
		Fixed(column.Line, 50.0f, 20.0f);
		let across = new Separator();
		defer across.ReleaseRef();
		column.Line.AddChild(across);
		column.Root.UpdateLayout();
		Test.Assert(!across.IsVertical);
		Test.Assert(Near(across.Size.X, 200.0f));
		Test.Assert(Near(across.Size.Y, 1.0f));

		let row = scope Bed(.Row);
		Fixed(row.Line, 50.0f, 20.0f);
		let up = new Separator();
		defer up.ReleaseRef();
		up.Thickness = 2.0f;
		row.Line.AddChild(up);
		row.Root.UpdateLayout();
		Test.Assert(up.IsVertical);
		Test.Assert(Near(up.Size.X, 2.0f));
		Test.Assert(Near(up.Size.Y, 100.0f)); // stretched, though the row centres its items
	}

	[Test]
	public static void ASpacerFlexibleTakesTheRoomLeftSizedItHoldsItsLength()
	{
		let row = scope Bed(.Row);
		Fixed(row.Line, 40.0f, 20.0f);
		let gap = new Spacer();
		defer gap.ReleaseRef();
		row.Line.AddChild(gap);
		let last = Fixed(row.Line, 40.0f, 20.0f);
		row.Root.UpdateLayout();
		Test.Assert(Near(gap.Size.X, 120.0f));
		Test.Assert(Near(last.Position.X, 160.0f)); // pushed to the end

		gap.Space = 12.0f;
		row.Root.UpdateLayout();
		Test.Assert(Near(gap.Size.X, 12.0f));
		Test.Assert(Near(last.Position.X, 52.0f));

		let column = scope Bed(.Column);
		let tall = new Spacer();
		defer tall.ReleaseRef();
		tall.Space = 30.0f;
		column.Line.AddChild(tall);
		column.Root.UpdateLayout();
		Test.Assert(Near(tall.Size.Y, 30.0f));
	}

	[Test]
	public static void MarkupAndSheetsSetASeparatorsThicknessAndASpacersSize()
	{
		let tree = MarkupFixtures.Load("<Panel flex-direction=\"row\"><Separator thickness=\"3\"/><Spacer size=\"8\"/></Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert(tree.ChildCount == 2);
		Test.Assert(Near((tree.GetChildAt(0) as Separator).Thickness, 3.0f));
		Test.Assert(Near((tree.GetChildAt(1) as Spacer).Space, 8.0f));
	}
}
