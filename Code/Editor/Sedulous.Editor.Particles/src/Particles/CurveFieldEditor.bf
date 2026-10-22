using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

namespace Sedulous.Editor.Particles;

/// A property row editing a module's float curve in place through a CurveCanvas, which edits
/// Hermite keys: a linear key goes to it with its segment's slope as both tangents, so it
/// draws straight, and edits come back as cubic keys, tangents as drawn. Every key change
/// writes the curve back and commits under the row's key. The curve pointer is into a module
/// the page owns, valid until the next inspector rebuild.
class CurveFieldEditor : PropertyEditor
{
	private ParticleCurveFloat* mCurve = null;
	/// Borrowed.
	private ParticleEffectEditorPage mPage;
	private String mKey = new .() ~ delete _;
	/// Borrowed: the editor view owns it.
	private CurveCanvas mCanvas = null;

	public this(StringView name, ParticleCurveFloat* curve, ParticleEffectEditorPage page, StringView key, StringView category) : base(name, category)
	{
		mCurve = curve;
		mPage = page;
		mKey.Set(key);
	}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		let canvas = new CurveCanvas();
		canvas.MaxKeys = ParticleCurve.MaxKeys;
		canvas.AutoFitValueRange = true;
		mCanvas = canvas;

		var ch = ChannelDescriptor();
		ch.Name = "V";
		ch.StrokeColor = .(0.45f, 0.75f, 1.0f, 1.0f);
		canvas.SetChannels(scope ChannelDescriptor[](ch));
		PushKeys(canvas);

		canvas.OnEditEnd.Add(new [=this]() => { WriteBack(); });
		canvas.OnKeyChanged.Add(new [=this](channel, key) => { WriteBack(); });
		canvas.OnKeyAdded.Add(new [=this](channel, key) => { WriteBack(); });
		canvas.OnKeyRemoved.Add(new [=this](channel, key) => { WriteBack(); });

		let wrap = new FlexLayout();
		wrap.Direction = .Vertical;
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(120.0f));
		wrap.AddView(canvas, style);
		return wrap;
	}

	/// The slope of the segment leaving key `index`, which a linear segment is drawn with.
	private float SegmentSlope(int32 index)
	{
		let a = mCurve.Keys[index];
		let b = mCurve.Keys[index + 1];
		let span = b.Time - a.Time;
		return (span > 1e-6f) ? (b.Value - a.Value) / span : 0.0f;
	}

	private void PushKeys(CurveCanvas canvas)
	{
		let keys = scope List<CurveCanvas.Key>();
		let n = Math.Min(mCurve.KeyCount, ParticleCurve.MaxKeys);
		for (int32 i < n)
		{
			let k = mCurve.Keys[i];
			var tangentIn = k.TangentIn;
			var tangentOut = k.TangentOut;
			// A linear or held segment as a Hermite one: both its ends at its slope.
			if ((k.Interpolation != .Cubic) && (i + 1 < n))
				tangentOut = SegmentSlope(i);
			if ((i > 0) && (mCurve.Keys[i - 1].Interpolation != .Cubic))
				tangentIn = SegmentSlope(i - 1);
			keys.Add(.(k.Time, k.Value, tangentIn, tangentOut));
		}
		if (keys.IsEmpty)
		{
			keys.Add(.(0.0f, 0.0f));
			keys.Add(.(1.0f, 1.0f));
		}
		canvas.SetKeys(0, keys);
	}

	private void WriteBack()
	{
		if (mCanvas == null)
			return;
		let n = Math.Min(mCanvas.GetKeyCount(0), ParticleCurve.MaxKeys);
		mCurve.KeyCount = n;
		for (int32 i < n)
		{
			let k = mCanvas.GetKey(0, i);
			mCurve.Keys[i] = .(k.Time, k.Value, .Cubic, k.TangentIn, k.TangentOut);
		}
		mPage.CommitEdit(mKey);
	}
}
