using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

namespace Sedulous.Editor.Scene;

/// A property row editing a module's float or float2 curve in place through a CurveCanvas;
/// every key change writes the curve back and commits under the row's key. The curve
/// pointer is into a module the page owns, valid until the next inspector rebuild.
class CurveFieldEditor : PropertyEditor
{
	private ParticleCurveFloat* mCurve1 = null;
	private ParticleCurveFloat2* mCurve2 = null;
	/// Borrowed.
	private ParticleEffectEditorPage mPage;
	private String mKey = new .() ~ delete _;
	/// Borrowed: the editor view owns it.
	private CurveCanvas mCanvas = null;

	public this(StringView name, ParticleCurveFloat* curve, ParticleEffectEditorPage page, StringView key, StringView category) : base(name, category)
	{
		mCurve1 = curve;
		mPage = page;
		mKey.Set(key);
	}

	public this(StringView name, ParticleCurveFloat2* curve, ParticleEffectEditorPage page, StringView key, StringView category) : base(name, category)
	{
		mCurve2 = curve;
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

		if (mCurve1 != null)
		{
			var ch = ChannelDescriptor();
			ch.Name = "V";
			ch.StrokeColor = .(0.45f, 0.75f, 1.0f, 1.0f);
			canvas.SetChannels(scope ChannelDescriptor[](ch));
			PushFloat1(canvas);
		}
		else if (mCurve2 != null)
		{
			canvas.LinkedTime = true;
			var x = ChannelDescriptor();
			x.Name = "X";
			x.StrokeColor = .(0.9f, 0.4f, 0.4f, 1.0f);
			var y = ChannelDescriptor();
			y.Name = "Y";
			y.StrokeColor = .(0.4f, 0.9f, 0.5f, 1.0f);
			canvas.SetChannels(scope ChannelDescriptor[](x, y));
			PushFloat2(canvas);
		}

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

	private void PushFloat1(CurveCanvas canvas)
	{
		let keys = scope List<CurveCanvas.Key>();
		for (int32 i < mCurve1.KeyCount)
		{
			let k = mCurve1.Keys[i];
			keys.Add(.(k.Time, k.Value, k.TangentIn, k.TangentOut));
		}
		if (keys.IsEmpty)
		{
			keys.Add(.(0.0f, 0.0f));
			keys.Add(.(1.0f, 1.0f));
		}
		canvas.SetKeys(0, keys);
	}

	private void PushFloat2(CurveCanvas canvas)
	{
		let kx = scope List<CurveCanvas.Key>();
		let ky = scope List<CurveCanvas.Key>();
		for (int32 i < mCurve2.KeyCount)
		{
			kx.Add(.(mCurve2.Times[i], mCurve2.Values[i].X, mCurve2.TangentsIn[i].X, mCurve2.TangentsOut[i].X));
			ky.Add(.(mCurve2.Times[i], mCurve2.Values[i].Y, mCurve2.TangentsIn[i].Y, mCurve2.TangentsOut[i].Y));
		}
		if (kx.IsEmpty)
		{
			kx.Add(.(0.0f, 0.1f));
			kx.Add(.(1.0f, 0.1f));
			ky.Add(.(0.0f, 0.1f));
			ky.Add(.(1.0f, 0.1f));
		}
		canvas.SetKeys(0, kx);
		canvas.SetKeys(1, ky);
	}

	private void WriteBack()
	{
		if (mCanvas == null)
			return;
		if (mCurve1 != null)
		{
			let n = Math.Min(mCanvas.GetKeyCount(0), ParticleCurve.MaxKeys);
			mCurve1.KeyCount = n;
			for (int32 i < n)
			{
				let k = mCanvas.GetKey(0, i);
				mCurve1.Keys[i] = .() { Time = k.Time, Value = k.Value, TangentIn = k.TangentIn, TangentOut = k.TangentOut };
			}
		}
		else if (mCurve2 != null)
		{
			let n = Math.Min(Math.Min(mCanvas.GetKeyCount(0), mCanvas.GetKeyCount(1)), ParticleCurve.MaxKeys);
			mCurve2.KeyCount = n;
			for (int32 i < n)
			{
				let kx = mCanvas.GetKey(0, i);
				let ky = mCanvas.GetKey(1, i);
				mCurve2.Times[i] = kx.Time;
				mCurve2.Values[i] = .(kx.Value, ky.Value);
				mCurve2.TangentsIn[i] = .(kx.TangentIn, ky.TangentIn);
				mCurve2.TangentsOut[i] = .(kx.TangentOut, ky.TangentOut);
			}
		}
		mPage.CommitEdit(mKey);
	}
}
