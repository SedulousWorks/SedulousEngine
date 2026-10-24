using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A root 800 by 600 whose editors (200 by 24) the bed holds, a host recording their calls, and the
/// values it binds them to. The root goes with it.
class CurveEditorBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public RecordingEditHost Host = new .() ~ delete _;
	private List<Node> mMade = new .() ~ { for (let node in _) node.ReleaseRef(); delete _; };
	private List<PropertyInfo> mInfos = new .() ~ DeleteContainerAndItems!(_);
	// What the bound values are views of.
	public CurveKey[2] Keys = .(.(), .());
	public ColorGradient Gradient = new .() ~ delete _;

	public this()
	{
		Root = NewRoot(800.0f, 600.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Keys[0] = CurveBed.Key(0.0f, 0.0f);
		Keys[1] = CurveBed.Key(1.0f, 1.0f);
		Gradient.Colors.Add(GradientColorStop(0.0f, Color(1.0f, 0.0f, 0.0f, 1.0f)));
		Gradient.Colors.Add(GradientColorStop(1.0f, Color(0.0f, 0.0f, 1.0f, 1.0f)));
		Gradient.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
	}

	public T Editor<T>(PropertyInfo info, PropertyValue value) where T : PropertyEditor, new
	{
		let editor = new T();
		editor.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(editor);
		mMade.Add(editor);
		editor.Bind(Host, "p", info, value);
		Root.UpdateLayout();
		return editor;
	}

	public PropertyInfo Info(PropertyKind kind)
	{
		let info = new PropertyInfo();
		info.Name.Set("p");
		info.Kind = kind;
		mInfos.Add(info);
		return info;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public void Click(Node node)
	{
		let r = node.ScreenBounds;
		let at = Float2(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
		D.InjectMouseMove(at);
		D.InjectMouseDown(at, .Left);
		D.InjectMouseUp(at, .Left);
	}

	public PropertyValue CurveValue(bool mixed = false)
	{
		var value = PropertyValue();
		value.Value = Sedulous.GUI.Variant.FromCurve(Keys);
		value.Mixed = mixed;
		return value;
	}

	public PropertyValue AGradient()
	{
		var value = PropertyValue();
		value.Value = Sedulous.GUI.Variant(Gradient);
		return value;
	}
}

/// The property grid's curve and gradient editors: a row's preview (hatched when mixed) opens the full
/// view as a popup; every edit in it previews on the objects, the edit begun at the first; closing it
/// commits once, Escape gives the whole of it up; a read-only row opens nothing. The grid chooses them
/// by kind.
class CurveEditorTests
{
	[Test]
	public static void ChosenByKind()
	{
		let registry = scope PropertyEditorRegistry();
		RegisterDefaultPropertyEditors(registry);
		let bed = scope CurveEditorBed();
		let curve = registry.Create(registry.Choose(bed.Info(.Curve)));
		let gradient = registry.Create(registry.Choose(bed.Info(.Gradient)));
		Test.Assert(curve is CurvePropertyEditor);
		Test.Assert(gradient is GradientPropertyEditor);
		curve.ReleaseRef();
		gradient.ReleaseRef();
	}

	[Test]
	public static void ACurvesPreviewOpensItsViewItsEditsPreviewClosingCommitsOnce()
	{
		let bed = scope CurveEditorBed();
		let info = bed.Info(.Curve);
		info.MaxCount = 8;
		let editor = bed.Editor<CurvePropertyEditor>(info, bed.CurveValue());
		Test.Assert(editor.Preview.Value.AsCurve.Length == 2);
		Test.Assert(!editor.IsViewOpen);
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		Test.Assert(bed.Host.Calls.IsEmpty); // opening is not editing
		CheckNear(editor.TimeAxis.Duration, 1.0f);
		Test.Assert(editor.View.Source.GetKeys(0).Length == 2);

		// Two edits in the view: begun once, previewed each.
		Test.Assert(editor.View.InsertKey(0, 0.5f));
		Test.Assert(editor.View.InsertKey(0, 0.25f));
		Test.Assert(bed.Host.Calls.Count == 3);
		Test.Assert(bed.Host.Calls[0] == "begin p");
		Test.Assert(bed.Host.Calls[1] == "preview p=3 keys");
		Test.Assert(bed.Host.Last == "preview p=4 keys");
		Test.Assert(editor.Preview.Value.AsCurve.Length == 4); // the row shows it as it goes

		bed.D.ClosePopup(editor.View.Parent);
		Test.Assert(bed.Host.Last == "commit p=4 keys");
		Test.Assert(bed.Host.Calls.Count == 4);
	}

	[Test]
	public static void EscapeGivesTheWholeOfAnOpenViewUpClosingItUnchangedEditsNothing()
	{
		let bed = scope CurveEditorBed();
		let editor = bed.Editor<CurvePropertyEditor>(bed.Info(.Curve), bed.CurveValue());
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		Test.Assert(editor.View.InsertKey(0, 0.5f));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!editor.IsViewOpen);
		Test.Assert(bed.Host.Last == "cancel p");

		bed.Host.Clear();
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		Test.Assert(editor.View.Source.GetKeys(0).Length == 2); // the value bound, not the given-up edit
		bed.D.ClosePopup(editor.View.Parent);
		Test.Assert(bed.Host.Calls.IsEmpty);
	}

	[Test]
	public static void MixedIsHatchedReadOnlyOpensNothing()
	{
		let bed = scope CurveEditorBed();
		let editor = bed.Editor<CurvePropertyEditor>(bed.Info(.Curve), bed.CurveValue(true));
		Test.Assert(editor.Preview.IsMixed);
		let info = bed.Info(.Curve);
		info.ReadOnly = true;
		editor.Bind(bed.Host, "p", info, bed.CurveValue());
		Test.Assert(!editor.Preview.IsMixed);
		bed.Click(editor.Preview);
		Test.Assert(!editor.IsViewOpen);
	}

	[Test]
	public static void AGradientsBarOpensItsViewItsEditsPreviewClosingCommitsOnceEscapeGivesUp()
	{
		let bed = scope CurveEditorBed();
		let info = bed.Info(.Gradient);
		info.MaxCount = 3;
		let editor = bed.Editor<GradientPropertyEditor>(info, bed.AGradient());
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		Test.Assert(bed.Host.Calls.IsEmpty);
		Test.Assert(editor.View.AddStop(false, 0.5f));
		Test.Assert(!editor.View.AddStop(false, 0.25f)); // its most: three
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[0] == "begin p");
		Test.Assert(bed.Host.Last == "preview p=3 colours, 1 alphas");
		bed.D.ClosePopup(editor.View.Parent);
		Test.Assert(bed.Host.Last == "commit p=3 colours, 1 alphas");

		bed.Host.Clear();
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		Test.Assert(editor.View.AddStop(true, 0.5f));
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!editor.IsViewOpen);
		Test.Assert(bed.Host.Last == "cancel p");
	}

	[Test]
	public static void ARowsCurveStaysInItsBoxASteepTangentsOvershootClippedOrFramed()
	{
		let bed = scope CurveEditorBed();
		bed.Keys[0] = CurveBed.Key(0.0f, 0.0f, .Cubic);
		bed.Keys[0].TangentOut = 40.0f;
		bed.Keys[1] = CurveBed.Key(1.0f, 1.0f, .Cubic);
		bed.Keys[1].TangentIn = -40.0f;
		let info = bed.Info(.Curve);
		info.HasRange = true; // a range the curve leaves by far
		info.Min = 0.0;
		info.Max = 1.0;
		let editor = bed.Editor<CurvePropertyEditor>(info, bed.CurveValue());
		let @box = editor.Preview.ScreenBounds;
		Test.Assert(@box.Width > 0.0f);

		// The preview alone: what it draws, less what a clip cuts away, spans no more than its box.
		let vg = scope VGContext();
		let ctx = scope DrawContext(vg);
		editor.Preview.Draw(ctx);
		let batch = vg.GetBatch();
		float low = 1e9f;
		float high = -1e9f;
		for (let command in batch.Commands)
		{
			for (int32 k = 0; k < command.IndexCount; ++k)
			{
				let v = batch.Vertices[(int)batch.Indices[command.StartIndex + k]];
				var y = v.Position.Y;
				if (command.Scissored || (command.ClipMode == .Scissor))
					y = Math.Clamp(y, command.ClipRect.Y, command.ClipRect.Y + command.ClipRect.Height);
				low = Math.Min(low, y);
				high = Math.Max(high, y);
			}
		}
		Test.Assert(high > low);
		Test.Assert(high - low <= @box.Height + 2.0f);
	}

	[Test]
	public static void InThePopupAGradientsStopPulledOffTheStripGoes()
	{
		let bed = scope CurveEditorBed();
		let info = bed.Info(.Gradient);
		info.MaxCount = 6;
		let editor = bed.Editor<GradientPropertyEditor>(info, bed.AGradient());
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		bed.Root.UpdateLayout();
		let strip = editor.View.Strip;
		let r = strip.ScreenBounds;
		let stop = Float2(r.Right - 2.0f, r.Bottom - 4.0f); // the last colour stop
		bed.D.InjectMouseMove(stop);
		bed.D.InjectMouseDown(stop, .Left);
		bed.D.InjectMouseMove(.(stop.X, stop.Y + 10.0f));
		bed.D.InjectMouseMove(.(stop.X, stop.Y + 40.0f));
		bed.D.InjectMouseMove(.(stop.X, stop.Y + 80.0f));
		Test.Assert(editor.View.Value.Colors.Count == 1);
		bed.D.InjectMouseUp(.(stop.X, stop.Y + 80.0f), .Left);
		Test.Assert(editor.View.Value.Colors.Count == 1);
		Test.Assert(bed.Host.Last == "preview p=1 colours, 1 alphas");
	}

	[Test]
	public static void InThePopupShiftClickAddsAKeyToTheSelection()
	{
		let bed = scope CurveEditorBed();
		let info = bed.Info(.Curve);
		info.MaxCount = 8;
		let editor = bed.Editor<CurvePropertyEditor>(info, bed.CurveValue());
		bed.Click(editor.Preview);
		Test.Assert(editor.IsViewOpen);
		bed.Root.UpdateLayout();
		let view = editor.View;
		let r = view.ScreenBounds;
		Float2 At(float t, float v)
		{
			let local = view.KeyPoint(t, v);
			return .(r.X + local.X, r.Y + local.Y);
		}
		bed.D.InjectMouseMove(At(0.0f, 0.0f));
		bed.D.InjectMouseDown(At(0.0f, 0.0f), .Left);
		bed.D.InjectMouseUp(At(0.0f, 0.0f), .Left);
		Test.Assert(view.Selection.Length == 1);
		bed.D.InjectKeyDown((uint32)KeyCode.LeftShift, KeyModShift);
		bed.D.InjectMouseMove(At(1.0f, 1.0f), KeyModShift);
		bed.D.InjectMouseDown(At(1.0f, 1.0f), .Left, KeyModShift);
		bed.D.InjectMouseUp(At(1.0f, 1.0f), .Left, KeyModShift);
		bed.D.InjectKeyUp((uint32)KeyCode.LeftShift, 0);
		Test.Assert(view.Selection.Length == 2);
		Test.Assert(editor.IsViewOpen);
	}
}
