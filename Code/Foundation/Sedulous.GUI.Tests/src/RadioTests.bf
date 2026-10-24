using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// RadioButton: the button core as a toggle a click never unchecks, alone or grouped (the groups
/// themselves are ButtonTests'), and its ring and dot.
class RadioTests
{
	[Test]
	public static void AClickChecksItAndASecondLeavesItChecked()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		defer root.ReleaseRef();
		let r = new RadioButton();
		defer r.ReleaseRef();
		root.AddChild(r);
		root.UpdateLayout();
		int32 changes = 0;
		r.SetOnToggled(new [&] (on) => { ++changes; });
		let d = root.EventDispatcher;
		Test.Assert(r.Tag == "radio");

		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(r.Checked);
		Test.Assert((r.WidgetStates & WidgetStateChecked) != 0);
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(r.Checked);
		Test.Assert(changes == 1);

		r.Checked = false; // code may clear it
		Test.Assert(!r.Checked);
	}

	[Test]
	public static void DrawsItsRingPlusTheDotWhenChecked()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		defer root.ReleaseRef();
		let r = new RadioButton();
		defer r.ReleaseRef();
		root.AddChild(r);
		int Draw(SceneRoot scene)
		{
			scene.UpdateLayout();
			let canvas = scope VGContext();
			let dc = scope DrawContext(canvas);
			scene.Draw(dc);
			return canvas.GetBatch().Vertices.Count;
		}
		let ring = Draw(root);
		Test.Assert(ring > 0);
		r.Checked = true;
		Test.Assert(Draw(root) > ring);
	}
}
