using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The two, three and four component editors. They share a base, so these check both that each
/// builds the right number of fields and that a field writes the right component.
class VectorEditorTests
{
	[Test]
	public static void AFloat2BuildsTwoFieldsAndWritesTheRightOne()
	{
		Float2 observed = .Zero;
		let editor = scope Float2Editor("Position", .(1.0f, 2.0f), -1000.0f, 1000.0f, 0.1f,
			new [&observed](value) => { observed = value; });

		Test.Assert(editor.Value.X == 1.0f);
		Test.Assert(editor.Value.Y == 2.0f);

		let row = editor.EditorView as FlexLayout;
		Test.Assert(row != null);
		Test.Assert(row.ChildCount == 2);

		let yField = row.GetChildAt(1) as NumericField;
		Test.Assert(yField != null);
		yField.SetValue(9.0);
		Test.Assert(editor.Value.Y == 9.0f);
		Test.Assert(editor.Value.X == 1.0f, "X is untouched");
		Test.Assert(observed.Y == 9.0f);

		editor.SetValue(.(4.0f, 5.0f));
		Test.Assert(yField.Value == 5.0);
	}

	[Test]
	public static void AFloat3BuildsThreeFieldsAndWritesTheRightOne()
	{
		Float3 observed = .Zero;
		let editor = scope Float3Editor("Position", .(1.0f, 2.0f, 3.0f), -1000.0f, 1000.0f, 0.1f,
			new [&observed](value) => { observed = value; });

		Test.Assert(editor.Value.X == 1.0f);
		Test.Assert(editor.Value.Z == 3.0f);

		let row = editor.EditorView as FlexLayout;
		Test.Assert(row != null);
		Test.Assert(row.ChildCount == 3);

		let yField = row.GetChildAt(1) as NumericField;
		Test.Assert(yField != null);
		yField.SetValue(9.0);
		Test.Assert(editor.Value.Y == 9.0f);
		Test.Assert(observed.Y == 9.0f);

		editor.SetValue(.(4.0f, 5.0f, 6.0f));
		Test.Assert(yField.Value == 5.0);
	}

	[Test]
	public static void AFloat4BuildsFourFieldsAndWritesTheRightOne()
	{
		Float4 observed = .Zero;
		let editor = scope Float4Editor("Rect", .(1.0f, 2.0f, 3.0f, 4.0f), -1000.0f, 1000.0f, 0.1f,
			new [&observed](value) => { observed = value; });

		Test.Assert(editor.Value.X == 1.0f);
		Test.Assert(editor.Value.W == 4.0f);

		let row = editor.EditorView as FlexLayout;
		Test.Assert(row != null);
		Test.Assert(row.ChildCount == 4);

		let wField = row.GetChildAt(3) as NumericField;
		Test.Assert(wField != null);
		wField.SetValue(9.0);
		Test.Assert(editor.Value.W == 9.0f);
		Test.Assert(observed.W == 9.0f);

		editor.SetValue(.(4.0f, 5.0f, 6.0f, 7.0f));
		Test.Assert(wField.Value == 7.0);
	}

	/// The whole row is ONE transaction: a person typing a position is doing one thing, so
	/// moving from X to Y must not close the edit and open another.
	[Test]
	public static void FocusMovingBetweenAxesIsOneEdit()
	{
		let editor = scope Float3Editor("Position", .Zero);

		var began = 0;
		var ended = 0;
		editor.OnEditBegin.Add(new [&began](sender) => { began++; });
		editor.OnEditEnd.Add(new [&ended](sender) => { ended++; });

		let row = editor.EditorView as FlexLayout;
		let x = row.GetChildAt(0) as NumericField;
		let y = row.GetChildAt(1) as NumericField;

		x.OnFocusGained();
		Test.Assert(began == 1);
		Test.Assert(editor.IsEditing);

		// Gaining before losing is the order a focus move actually arrives in.
		y.OnFocusGained();
		Test.Assert(began == 1, "still the same edit");
		x.OnFocusLost();
		Test.Assert(ended == 1);
	}
}
