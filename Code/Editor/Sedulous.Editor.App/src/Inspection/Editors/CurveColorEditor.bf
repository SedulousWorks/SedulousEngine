namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for ParticleCurveColor. Wraps GradientEditor and
/// projects its stop list back into the underlying ParticleCurveColor.
/// Double-clicking a stop opens the existing ColorPicker dialog for that
/// stop's color; commit writes the new color back through UpdateStopColor.
///
/// v1 limitation: ColorPicker is 8-bit RGBA so HDR values (channels > 1)
/// get clamped on edit. The underlying ParticleCurveColor still stores
/// HDR Vector4 values - they survive round-trips that don't touch the
/// picker. An HDR color picker would unblock authoring HDR ramps.
class CurveColorEditor : PropertyEditor
{
	private ParticleCurveColor* mPtr;
	private GradientEditor mEditor;
	private bool mSyncing;

	public this(StringView name, ParticleCurveColor* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		mEditor = new GradientEditor();
		mEditor.MaxStops = (int32)ParticleCurveColor.MaxKeys;

		PushStopsToEditor();

		mEditor.OnEditBegin.Add(new () => BeginEdit());
		mEditor.OnEditEnd.Add(new () => EndEdit());
		mEditor.OnStopChanged.Add(new (idx) => PullEditorIntoPtr());
		mEditor.OnStopAdded.Add(new (idx) => PullEditorIntoPtr());
		mEditor.OnStopRemoved.Add(new (idx) => PullEditorIntoPtr());
		mEditor.OnStopColorRequested.Add(new (idx) => OpenColorPicker(idx));

		let wrap = new FlexLayout();
		wrap.Direction = .Vertical;
		wrap.AddView(mEditor, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(60))
		});
		return wrap;
	}

	private void PushStopsToEditor()
	{
		if (mSyncing || mEditor == null) return;
		mSyncing = true;
		let count = mPtr.KeyCount;
		let stops = scope GradientEditor.Stop[count];
		for (int32 i = 0; i < count; i++)
			stops[i] = .(mPtr.Keys[i].Time, mPtr.Keys[i].Color);
		mEditor.SetStops(stops);
		mSyncing = false;
	}

	private void PullEditorIntoPtr()
	{
		if (mSyncing) return;
		mSyncing = true;
		let count = Math.Min(mEditor.StopCount, (int32)ParticleCurveColor.MaxKeys);
		for (int32 i = 0; i < count; i++)
		{
			let s = mEditor.GetStop(i);
			mPtr.Keys[i] = .(s.Time, s.Color);
		}
		mPtr.KeyCount = count;
		NotifyValueChanged();
		mSyncing = false;
	}

	/// Open the existing 8-bit ColorPicker for the indicated stop. On OK,
	/// write the picked color back to the gradient editor (which fires
	/// OnStopChanged -> PullEditorIntoPtr). Cancel restores the prior color.
	private void OpenColorPicker(int32 idx)
	{
		let ctx = mEditor?.Context;
		if (ctx == null) return;
		if (idx < 0 || idx >= mEditor.StopCount) return;

		let stop = mEditor.GetStop(idx);
		let originalColor = stop.Color;

		BeginEdit();

		let picker = new ColorPicker();
		picker.SetColor(Vector4ToColor(originalColor));
		picker.SetOriginalColor(Vector4ToColor(originalColor));
		picker.OnColorChanged.Add(new (p, c) =>
		{
			mEditor.UpdateStopColor(idx, ColorToVector4(c));
		});

		let dialog = new Dialog("Stop Color");
		dialog.SetContent(picker);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		dialog.OnClosed.Add(new (d, result) =>
		{
			if (result == .OK)
				EndEdit();
			else
			{
				mEditor.UpdateStopColor(idx, originalColor);
				CancelEdit();
			}
		});
		dialog.Show(ctx);
	}

	private static Color Vector4ToColor(Vector4 c)
	{
		let r = (uint8)Math.Clamp((int32)(c.X * 255), 0, 255);
		let g = (uint8)Math.Clamp((int32)(c.Y * 255), 0, 255);
		let b = (uint8)Math.Clamp((int32)(c.Z * 255), 0, 255);
		let a = (uint8)Math.Clamp((int32)(c.W * 255), 0, 255);
		return .(r, g, b, a);
	}

	private static Vector4 ColorToVector4(Color c)
	{
		return .(c.R / 255.0f, c.G / 255.0f, c.B / 255.0f, c.A / 255.0f);
	}

	public override void RefreshView()
	{
		PushStopsToEditor();
	}
}
