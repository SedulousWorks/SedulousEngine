using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The colour property row. Opening its dialog needs a root and a popup layer, so what is
/// pinned here is the value and the swatch that shows it.
class ColorEditorTests
{
	[Test]
	public static void AColourRoundTripsThroughItsSwatch()
	{
		let editor = scope ColorEditor("Tint", Color.Rgb(255, 0, 0));

		Test.Assert(editor.Value.R == 1.0f);
		Test.Assert(editor.Value.G == 0.0f);

		let swatch = editor.EditorView as ColorView;
		Test.Assert(swatch != null);
		Test.Assert(swatch.Color.Value.R == 1.0f);

		editor.SetValue(Color.Rgb(0, 255, 0));
		Test.Assert(editor.Value.G == 1.0f);
		Test.Assert(swatch.Color.Value.G == 1.0f, "the swatch followed");
	}

	/// The swatch is a HAND cursor, because nothing else says a colour square is a button.
	[Test]
	public static void TheSwatchLooksClickable()
	{
		let editor = scope ColorEditor("Tint", Color.White);
		Test.Assert(editor.EditorView.Cursor == .Hand);
	}
}
