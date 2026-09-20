using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

namespace Sedulous.Editor.Scene;

/// A property row editing a module's colour curve in place through a GradientEditor; every
/// stop change writes the curve back and commits under the row's key. The curve pointer is
/// into a module the page owns, valid until the next inspector rebuild.
class GradientFieldEditor : PropertyEditor
{
	private ParticleCurveColor* mCurve;
	/// Borrowed.
	private ParticleEffectEditorPage mPage;
	private String mKey = new .() ~ delete _;
	/// Borrowed: the editor view owns it.
	private GradientEditor mGradient = null;

	public this(StringView name, ParticleCurveColor* curve, ParticleEffectEditorPage page, StringView key, StringView category) : base(name, category)
	{
		mCurve = curve;
		mPage = page;
		mKey.Set(key);
	}

	public override void RefreshView() {}

	protected override View CreateEditorView()
	{
		let gradient = new GradientEditor();
		gradient.MaxStops = ParticleCurve.MaxKeys;
		mGradient = gradient;

		let stops = scope List<GradientStop>();
		for (int32 i < mCurve.KeyCount)
			stops.Add(.(mCurve.Keys[i].Time, mCurve.Keys[i].Color));
		if (stops.IsEmpty)
		{
			stops.Add(.(0.0f, .(1.0f, 1.0f, 1.0f, 1.0f)));
			stops.Add(.(1.0f, .(1.0f, 1.0f, 1.0f, 0.0f)));
		}
		gradient.SetStops(stops);

		gradient.OnEditEnd.Add(new [=this]() => { WriteBack(); });
		gradient.OnStopChanged.Add(new [=this](stop) => { WriteBack(); });
		gradient.OnStopAdded.Add(new [=this](stop) => { WriteBack(); });
		gradient.OnStopRemoved.Add(new [=this](stop) => { WriteBack(); });

		let wrap = new FlexLayout();
		wrap.Direction = .Vertical;
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(40.0f));
		wrap.AddView(gradient, style);
		return wrap;
	}

	private void WriteBack()
	{
		if (mGradient == null)
			return;
		let n = Math.Min(mGradient.StopCount, ParticleCurve.MaxKeys);
		mCurve.KeyCount = n;
		for (int32 i < n)
		{
			let s = mGradient.GetStop(i);
			mCurve.Keys[i] = .() { Time = s.Time, Color = s.Color };
		}
		mPage.CommitEdit(mKey);
	}
}
