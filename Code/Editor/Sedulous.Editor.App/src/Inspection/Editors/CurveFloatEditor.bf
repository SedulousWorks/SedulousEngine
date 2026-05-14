namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

/// Property editor for ParticleCurveFloat. Wraps a single CurveCanvas and
/// projects its key list back into the underlying ParticleCurveFloat. The
/// canvas does the rendering and interaction; the editor handles binding.
class CurveFloatEditor : PropertyEditor
{
	private ParticleCurveFloat* mPtr;
	private CurveCanvas mCanvas;
	private bool mSyncing;

	public this(StringView name, ParticleCurveFloat* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		mCanvas = new CurveCanvas();
		mCanvas.MaxKeys = (int32)ParticleCurveFloat.MaxKeys;

		PushKeysToCanvas();

		mCanvas.OnEditBegin.Add(new () => BeginEdit());
		mCanvas.OnEditEnd.Add(new () => EndEdit());
		mCanvas.OnKeyChanged.Add(new (idx) => SyncKeyFromCanvas(idx));
		mCanvas.OnKeyAdded.Add(new (idx) => InsertKeyFromCanvas(idx));
		mCanvas.OnKeyRemoved.Add(new (idx) => RemoveKey(idx));

		// Give the curve canvas a reasonable inline height inside the grid row.
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
		mCanvas.SetKeys(keys);
		mSyncing = false;
	}

	private void SyncKeyFromCanvas(int32 idx)
	{
		if (mSyncing) return;
		mSyncing = true;
		let ck = mCanvas.GetKey(idx);
		// Replace in place; mPtr.KeyCount and ordering are managed by the
		// canvas's sort, so we mirror its layout exactly.
		mPtr.Keys[idx] = .(ck.Time, ck.Value, ck.TangentIn, ck.TangentOut);
		// Time changes can re-sort - the canvas already re-sorts internally,
		// so re-pull all keys to keep mPtr in lockstep.
		PullCanvasIntoPtr();
		NotifyValueChanged();
		mSyncing = false;
	}

	private void InsertKeyFromCanvas(int32 idx)
	{
		if (mSyncing) return;
		mSyncing = true;
		// Canvas already has the new key; copy its full layout into mPtr.
		PullCanvasIntoPtr();
		NotifyValueChanged();
		mSyncing = false;
	}

	private void RemoveKey(int32 idx)
	{
		if (mSyncing) return;
		mSyncing = true;
		PullCanvasIntoPtr();
		NotifyValueChanged();
		mSyncing = false;
	}

	private void PullCanvasIntoPtr()
	{
		let count = Math.Min(mCanvas.KeyCount, (int32)ParticleCurveFloat.MaxKeys);
		for (int32 i = 0; i < count; i++)
		{
			let ck = mCanvas.GetKey(i);
			mPtr.Keys[i] = .(ck.Time, ck.Value, ck.TangentIn, ck.TangentOut);
		}
		mPtr.KeyCount = count;
	}

	public override void RefreshView()
	{
		PushKeysToCanvas();
	}
}
