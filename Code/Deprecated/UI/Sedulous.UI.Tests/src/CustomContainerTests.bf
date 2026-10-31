using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Style model v2 P0: a ViewGroup subclass reads the child's LayoutStyle DIRECTLY.
///
/// No per container parameter subclass and no registry: whatever fields a custom container
/// cares about are already on every child, which is the whole point of the uniform layout
/// style.
class CustomContainerTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// Stacks children top to bottom, offsetting each by its own Left and pinning a child with
	/// Gravity Right to the right edge.
	private class StaircaseLayout : ViewGroup
	{
		public this() {}

		protected override void OnMeasure(BoxConstraints constraints)
		{
			var height = 0.0f;
			var width = 0.0f;
			for (int i < ChildCount)
			{
				let child = GetChildAt(i);
				child.Measure(constraints.Loosen());
				let marginBox = child.MarginBoxSize;
				height += marginBox.Y;
				width = Max(width, child.Layout.Left.Value + marginBox.X);
			}
			MeasuredSize = .(constraints.ConstrainWidth(width),
				constraints.ConstrainHeight(height));
		}

		protected override void OnLayout(float left, float top, float width, float height)
		{
			var y = 0.0f;
			for (int i < ChildCount)
			{
				let child = GetChildAt(i);
				let marginBox = child.MarginBoxSize;
				let layout = child.Layout;
				let x = ((layout.Gravity & .Right) == .Right)
					? (width - marginBox.X) : layout.Left.Value;
				child.Layout(x, y, marginBox.X, marginBox.Y);
				y += marginBox.Y;
			}
		}
	}

	[Test]
	public static void ACustomContainerPositionsChildrenFromTheirLayoutStyle()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let stairs = new StaircaseLayout();
		let a = new TestView(50, 20);
		let b = new TestView(50, 20);
		let c = new TestView(50, 20);

		var layoutA = LayoutStyle();
		layoutA.Left = .(10, true);
		var layoutB = LayoutStyle();
		layoutB.Left = .(30, true);
		layoutB.Margin = .(Thickness(0, 5, 0, 5), true);
		var layoutC = LayoutStyle();
		layoutC.Gravity = .Right;

		stairs.AddView(a, layoutA);
		stairs.AddView(b, layoutB);
		stairs.AddView(c, layoutC);

		var fill = LayoutStyle();
		fill.Width = .(SizeSpec.Match(), true);
		root.AddView(stairs, fill);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 10));
		Test.Assert(Near(a.Bounds.Y, 0));
		Test.Assert(Near(b.Bounds.X, 30));
		Test.Assert(Near(b.Bounds.Y, 25), "twenty tall plus b's top margin of five");
		Test.Assert(Near(c.Bounds.X, 350), "pinned right: four hundred less fifty");
		Test.Assert(Near(c.Bounds.Y, 50), "twenty plus b's whole margin box of thirty");
	}
}
