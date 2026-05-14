namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for ParticleCurveColor. Wraps GradientEditor and
/// projects its stop list back into the underlying ParticleCurveColor.
/// Double-clicking a stop opens an HDRColorPicker dialog so authors can
/// pick HDR-range Vector4 colors directly without the 8-bit round-trip.
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

	/// Open an HDRColorPicker for the indicated stop. On OK, the live
	/// updates fired during the picker's drag are already committed via
	/// UpdateStopColor. Cancel restores the prior color.
	private void OpenColorPicker(int32 idx)
	{
		let ctx = mEditor?.Context;
		if (ctx == null) return;
		if (idx < 0 || idx >= mEditor.StopCount) return;

		let stop = mEditor.GetStop(idx);
		let originalColor = stop.Color;

		BeginEdit();

		let picker = new HDRColorPicker();
		picker.SetColor(originalColor);
		picker.SetOriginalColor(originalColor);
		picker.OnColorChanged.Add(new (p, c) =>
		{
			mEditor.UpdateStopColor(idx, c);
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

	public override void RefreshView()
	{
		PushStopsToEditor();
	}
}
