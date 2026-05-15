namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for ParticleCurveFloat. Wraps a single-channel
/// CurveCanvas and projects its key list back into the underlying
/// ParticleCurveFloat. The canvas does the rendering and interaction;
/// the editor handles binding.
class CurveFloatEditor : PropertyEditor
{
	private ParticleCurveFloat* mPtr;
	private CurveCanvas mCanvas;
	private bool mSyncing;
	private float mDisplayMin;
	private float mDisplayMax;

	public this(StringView name, ParticleCurveFloat* ptr, StringView category = default,
		float displayMin = 0, float displayMax = 0) : base(name, category)
	{
		mPtr = ptr;
		mDisplayMin = displayMin;
		mDisplayMax = displayMax;
	}

	protected override View CreateEditorView()
	{
		mCanvas = new CurveCanvas();
		mCanvas.MaxKeys = (int32)ParticleCurveFloat.MaxKeys;

		// A [Range] attribute on the field (forwarded as displayMin/Max)
		// overrides the default. Otherwise "over lifetime" float curves are
		// normalized/multiplier curves that sit in 0..1 by convention
		// (alpha, size/speed scale). Frame to the nominal range so the view
		// stays stable; the canvas expands automatically if a key is
		// dragged outside it.
		float dMin = 0, dMax = 1;
		if (mDisplayMin < mDisplayMax) { dMin = mDisplayMin; dMax = mDisplayMax; }
		let channels = scope ChannelDescriptor[1];
		channels[0] = .{
			Name = "Value",
			StrokeColor = .(180, 200, 255, 255),
			Interpolation = .Hermite,
			DisplayMin = dMin,
			DisplayMax = dMax
		};
		mCanvas.SetChannels(channels);

		PushKeysToCanvas();

		mCanvas.OnEditBegin.Add(new () => BeginEdit());
		mCanvas.OnEditEnd.Add(new () => EndEdit());
		mCanvas.OnKeyChanged.Add(new (channelIdx, keyIdx) => PullCanvasIntoPtr());
		mCanvas.OnKeyAdded.Add(new (channelIdx, keyIdx) => PullCanvasIntoPtr());
		mCanvas.OnKeyRemoved.Add(new (channelIdx, keyIdx) => PullCanvasIntoPtr());

		let wrap = new FlexLayout();
		wrap.Direction = .Vertical;
		wrap.AddView(mCanvas, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(140))
		});
		return wrap;
	}

	private void PushKeysToCanvas()
	{
		if (mSyncing || mCanvas == null) return;
		mSyncing = true;

		let count = mPtr.KeyCount;
		let keys = scope CurveCanvas.Key[count];
		for (int32 i = 0; i < count; i++)
		{
			let k = mPtr.Keys[i];
			keys[i] = .(k.Time, k.Value, k.TangentIn, k.TangentOut);
		}
		mCanvas.SetKeys(0, keys);
		mSyncing = false;
	}

	private void PullCanvasIntoPtr()
	{
		if (mSyncing) return;
		mSyncing = true;
		let count = Math.Min(mCanvas.GetKeyCount(0), (int32)ParticleCurveFloat.MaxKeys);
		for (int32 i = 0; i < count; i++)
		{
			let ck = mCanvas.GetKey(0, i);
			mPtr.Keys[i] = .(ck.Time, ck.Value, ck.TangentIn, ck.TangentOut);
		}
		mPtr.KeyCount = count;
		NotifyValueChanged();
		mSyncing = false;
	}

	public override void RefreshView()
	{
		PushKeysToCanvas();
	}
}
