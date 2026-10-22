using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

namespace Sedulous.Editor.Particles;

/// A property row editing a module's colour curve in place through a GradientEditor, which
/// pairs a colour with its alpha at each stop: the curve's colour and alpha stops go to it at
/// every time either has one (sampled from the gradient), and come back as a colour stop and
/// an alpha stop at each, its interpolation kept. Every stop change writes the curve back and
/// commits under the row's key. The curve pointer is into a module the page owns, valid until
/// the next inspector rebuild.
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

		let times = scope List<float>();
		for (int32 i < Math.Min(mCurve.ColorCount, ParticleCurve.MaxKeys))
			AddTime(times, mCurve.Colors[i].Time);
		for (int32 i < Math.Min(mCurve.AlphaCount, ParticleCurve.MaxKeys))
			AddTime(times, mCurve.Alphas[i].Time);
		let stops = scope List<GradientStop>();
		for (int i = 0; (i < times.Count) && (stops.Count < ParticleCurve.MaxKeys); i++)
			stops.Add(.(times[i], mCurve.Evaluate(times[i])));
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

	/// A sorted insert of a time not already there.
	private static void AddTime(List<float> times, float time)
	{
		for (let known in times)
		{
			if (Math.Abs(known - time) < 1e-5f)
				return;
		}
		var at = times.Count;
		while ((at > 0) && (times[at - 1] > time))
			at--;
		times.Insert(at, time);
	}

	private void WriteBack()
	{
		if (mGradient == null)
			return;
		let interpolation = mCurve.Interpolation;
		*mCurve = .();
		mCurve.Interpolation = interpolation;
		let n = Math.Min(mGradient.StopCount, ParticleCurve.MaxKeys);
		for (int32 i < n)
		{
			let s = mGradient.GetStop(i);
			mCurve.AddKey(s.Time, s.Color);
		}
		mPage.CommitEdit(mKey);
	}
}
