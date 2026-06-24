namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for ParticleCurveVector2. One CurveCanvas with two
/// LinkedTime channels (X red, Y green). Add/remove/Time-drag propagate
/// to both channels; Value-drag affects only the active channel. The
/// underlying ParticleCurveVector2 stores shared Times + parallel Values
/// + parallel Tangents, so the channel layout maps one-to-one.
class CurveVector2Editor : PropertyEditor
{
	private ParticleCurveVector2* mPtr;
	private CurveCanvas mCanvas;
	private bool mSyncing;
	private float mDisplayMin;
	private float mDisplayMax;

	public this(StringView name, ParticleCurveVector2* ptr, StringView category = default,
		float displayMin = 0, float displayMax = 0) : base(name, category)
	{
		mPtr = ptr;
		mDisplayMin = displayMin;
		mDisplayMax = displayMax;
	}

	protected override View CreateEditorView()
	{
		mCanvas = new CurveCanvas();
		mCanvas.MaxKeys = (int32)ParticleCurveVector2.MaxKeys;
		mCanvas.LinkedTime = true;

		// A [Range] attribute on the field (forwarded as displayMin/Max)
		// overrides the default. Otherwise Vector2-over-lifetime components
		// can be signed (offsets, directions), so frame a symmetric nominal
		// [-1, 1]; the canvas expands automatically when a key is dragged
		// past it.
		float dMin = -1, dMax = 1;
		if (mDisplayMin < mDisplayMax) { dMin = mDisplayMin; dMax = mDisplayMax; }
		let channels = scope ChannelDescriptor[2];
		channels[0] = .{
			Name = "X",
			StrokeColor = .(220, 80, 80, 255),
			Interpolation = .Hermite,
			Description = "X component over normalized lifetime",
			DisplayMin = dMin,
			DisplayMax = dMax
		};
		channels[1] = .{
			Name = "Y",
			StrokeColor = .(80, 200, 80, 255),
			Interpolation = .Hermite,
			Description = "Y component over normalized lifetime",
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
			Width = .Match, Height = .Fixed(.Px(160))
		});
		return wrap;
	}

	private void PushKeysToCanvas()
	{
		if (mSyncing || mCanvas == null) return;
		mSyncing = true;

		let count = mPtr.KeyCount;
		let xKeys = scope CurveCanvas.Key[count];
		let yKeys = scope CurveCanvas.Key[count];
		for (int32 i = 0; i < count; i++)
		{
			xKeys[i] = .(mPtr.Times[i], mPtr.Values[i].X, mPtr.TangentsIn[i].X, mPtr.TangentsOut[i].X);
			yKeys[i] = .(mPtr.Times[i], mPtr.Values[i].Y, mPtr.TangentsIn[i].Y, mPtr.TangentsOut[i].Y);
		}
		mCanvas.SetKeys(0, xKeys);
		mCanvas.SetKeys(1, yKeys);
		mSyncing = false;
	}

	private void PullCanvasIntoPtr()
	{
		if (mSyncing) return;
		mSyncing = true;
		// LinkedTime guarantees X and Y channels have matched counts and times.
		let count = Math.Min(mCanvas.GetKeyCount(0), (int32)ParticleCurveVector2.MaxKeys);
		for (int32 i = 0; i < count; i++)
		{
			let kx = mCanvas.GetKey(0, i);
			let ky = mCanvas.GetKey(1, i);
			mPtr.Times[i] = kx.Time;
			mPtr.Values[i] = .(kx.Value, ky.Value);
			mPtr.TangentsIn[i] = .(kx.TangentIn, ky.TangentIn);
			mPtr.TangentsOut[i] = .(kx.TangentOut, ky.TangentOut);
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
