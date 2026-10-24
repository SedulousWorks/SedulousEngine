using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Bindings: a node's bindings follow what they read, on the GUI's frame; any reflected property
// binds by name, converted to its type; a widget's user-set state writes back; the GUI's data model
// holds named values; nothing subscribes by hand.

/// Bindings by name: a bound property follows what it read on the GUI's frame, a widget's user-set
/// state writes back, the conversions bindings make between values and properties' types, and a
/// text field written back.
class BindingTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-6;

	[Test]
	public static void ABoundLabelFollowsItsSourceOnTheGUIsFrame()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		root.AddChild(label);
		let data = root.Context.Data;
		data.Set("score", System.Variant.Create((int32)3));

		Test.Assert(label.BindProperty("text", new () => { return data.Get("score"); }));
		Test.Assert(label.Text == "3"); // bound at once

		data.Set("score", System.Variant.Create((int32)4));
		data.Set("score", System.Variant.Create((int32)5));
		Test.Assert(label.Text == "3"); // waits for the frame
		Test.Assert(root.NeedsFrame());
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(label.Text == "5");
		Test.Assert(root.Context.LastBindingCount == 1); // two changes, one run

		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.Context.LastBindingCount == 0);
		data.Set("score", System.Variant.Create(5.0)); // the same number: no change
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.Context.LastBindingCount == 0);
	}

	[Test]
	public static void OneWidgetsStateDrivesAnothersWithNoSubscription()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		let bar = new ProgressBar();
		defer bar.ReleaseRef();
		root.AddChild(slider);
		root.AddChild(label);
		root.AddChild(bar);
		let s = slider;
		Test.Assert(label.BindProperty("text", new () => { return System.Variant.Create((float)s.Value); }));
		Test.Assert(bar.BindProperty("value", new () => { return System.Variant.Create(s.Value); }));

		slider.Value = 0.25;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(label.Text == "0.25");
		Test.Assert(Near((float)bar.Value, 0.25f));
	}

	[Test]
	public static void AWidgetTheUserChangesWritesBackBothWaysWithoutALoop()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let slider = new Slider();
		defer slider.ReleaseRef();
		root.AddChild(slider);
		let data = root.Context.Data;
		data.Set("volume", System.Variant.Create(0.5));
		Test.Assert(slider.BindProperty("value", new () => { return data.Get("volume"); }));
		Test.Assert(slider.BindPropertyBack("value", new (v) => { data.Set("volume", v); }));
		Test.Assert(Near((float)slider.Value, 0.5f));

		slider.Value = 0.75; // the user drags it
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(data.Get("volume").VariantType == typeof(double)); // a range's value is a double
		Test.Assert(Near(data.Get("volume").Get<double>(), 0.75));
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(root.Context.LastBindingCount == 0); // settled

		data.Set("volume", System.Variant.Create(0.1)); // the game sets it
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(Near((float)slider.Value, 0.1f));
	}

	[Test]
	public static void OutsideASceneABindingRunsAtOnceItEndsWithItsNode()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let data = root.Context.Data;
		let label = new Label(); // not in the scene
		defer label.ReleaseRef();
		Test.Assert(label.BindProperty("text", new () => { return data.Get("name"); }));
		data.Set("name", System.Variant.Create("Ada"));
		Test.Assert(label.Text == "Ada");

		label.ClearBindings();
		data.Set("name", System.Variant.Create("Bo"));
		Test.Assert(label.Text == "Ada");

		{
			let gone = new Label();
			root.AddChild(gone);
			Test.Assert(gone.BindProperty("text", new () => { return data.Get("name"); }));
			data.Set("name", System.Variant.Create("Cy")); // queued
			root.RemoveChild(gone);
			gone.ReleaseRef();
		}
		root.Context.Update(SceneFixtures.Frame); // the queued binding went with its node
		Test.Assert(root.Context.LastBindingCount == 0);
	}

	[Test]
	public static void AnUnknownOrReadOnlyPropertyDoesNotBind()
	{
		let label = new Label();
		defer label.ReleaseRef();
		Test.Assert(!label.BindProperty("nonesuch", new () => { return default(System.Variant); }));
		Test.Assert(!label.BindPropertyBack("nonesuch", new (v) => { }));
		Test.Assert(label.BindingCount == 0);
	}

	[Test]
	public static void ANameReadBeforeItIsSetIsFollowedAndTakesItsFirstValue()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let label = new Label();
		defer label.ReleaseRef();
		root.AddChild(label);
		let data = root.Context.Data;
		Test.Assert(label.BindProperty("text", new () => { return data.Get("later"); }));
		Test.Assert(!data.Has("later"));
		data.Set("later", System.Variant.Create((int32)9));
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(label.Text == "9");
	}

	[Test]
	public static void ValuesConvertToThePropertysTypeAndCompareAcrossNumbers()
	{
		let text = scope String();
		FormatVariant(System.Variant.Create(3.0), text);
		Test.Assert(text == "3");
		text.Clear();
		FormatVariant(System.Variant.Create(0.25f), text);
		Test.Assert(text == "0.25");
		text.Clear();
		FormatVariant(System.Variant.Create(0.4f), text);
		Test.Assert(text == "0.4"); // not 0.4000000059604645
		text.Clear();
		FormatVariant(System.Variant.Create(2.0f), text);
		Test.Assert(text == "2");
		text.Clear();
		FormatVariant(System.Variant.Create(true), text);
		Test.Assert(text == "true");
		var f = ConvertVariant(System.Variant.Create(0.5), typeof(float));
		defer f.Dispose();
		Test.Assert(f.VariantType == typeof(float));
		Test.Assert(NodeFixtures.Near(f.Get<float>(), 0.5f));
		var spaced = TextVariant(" 42 ");
		defer spaced.Dispose();
		var i = ConvertVariant(spaced, typeof(int32));
		defer i.Dispose();
		Test.Assert(i.VariantType == typeof(int32));
		Test.Assert(i.Get<int32>() == 42);
		var word = TextVariant("abc");
		defer word.Dispose();
		var none = ConvertVariant(word, typeof(float));
		defer none.Dispose();
		Test.Assert(!none.HasValue);
		Test.Assert(VariantsEqual(System.Variant.Create((int32)2), System.Variant.Create(2.0)));
		var two = TextVariant("2");
		defer two.Dispose();
		Test.Assert(!VariantsEqual(System.Variant.Create((int32)2), two));
	}

	[Test]
	public static void ATextFieldWrittenBackKeepsItsCaret()
	{
		let field = new TextField();
		defer field.ReleaseRef();
		field.Text = "hello";
		field.Caret = 2;
		field.Text = "hello"; // a binding writing back what was typed
		Test.Assert(field.Caret == 2);
	}
}
