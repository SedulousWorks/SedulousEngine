namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Interpolation modes available per-channel on CurveCanvas. Hermite is
/// first (=0) so a zero-initialized ChannelDescriptor defaults to Hermite,
/// which is the right pick for particle / animation curves.
public enum CurveInterpolation : uint8
{
	/// Cubic Hermite using per-key TangentIn / TangentOut.
	Hermite,
	/// Linear between adjacent keys; tangents ignored.
	Linear,
	/// Step / hold; value jumps to the next key's value at that key's Time.
	Step
}

/// Tangent-handle behavior on a Hermite key. Mirrored is the zero-init
/// default so freshly-constructed keys get a single visible "smoothness"
/// control out of the box.
public enum TangentMode : uint8
{
	/// Drag one handle and the opposite handle mirrors it (TangentIn ==
	/// TangentOut). The smooth default.
	Mirrored,
	/// Handles move independently. Use for sharp corners or asymmetric
	/// ease in/out. ("Broken" in some DCC tools.)
	Free,
	/// Both tangents pinned to zero - the curve flattens through the key.
	/// Handles are visible but ignore drag input (right-click to leave
	/// Flat mode).
	Flat,
}

/// Per-channel metadata pushed into CurveCanvas via SetChannels. Lets the
/// widget render N curves on the same canvas without knowing what the
/// channels represent (X/Y, R/G/B/A, gain/cutoff/resonance, ...).
///
/// All fields are designed so a zero-initialized descriptor (e.g. a
/// freshly-allocated `scope ChannelDescriptor[N]` slot) gives sensible
/// defaults: visible, unlocked, no value clamps, Hermite interpolation.
public struct ChannelDescriptor
{
	/// Short identifier shown in legend strips (e.g. "X", "R", "Gain").
	public String Name;

	/// Stroke color used for the polyline and key markers.
	public Color StrokeColor;

	/// Value used when a key is added to this channel implicitly - e.g.
	/// LinkedTime mode adds a key to every channel; the channel the user
	/// did NOT click uses this fallback value.
	public float DefaultValue;

	/// When true, the channel is hidden (not rendered or hit-tested).
	/// Inverted polarity so the zero-init default is "visible".
	public bool Hidden;

	/// When true, the channel rejects edits but still renders.
	public bool Locked;

	/// Inclusive value clamps applied on edit. If `MinValue >= MaxValue`
	/// (e.g. both zero from zero-init) the clamp is treated as disabled
	/// and values pass through unchanged. Auto-fit always reads actual
	/// key values, never these clamps.
	public float MinValue;
	public float MaxValue;

	/// Nominal value-axis range. When `DisplayMin < DisplayMax` the canvas
	/// frames at least [DisplayMin, DisplayMax] and only expands when keys
	/// fall outside it - it never shrinks below it, so the vertical framing
	/// stays stable across edits instead of collapsing when keys cluster.
	/// Zero-init (0,0) disables this and the canvas falls back to auto-fit
	/// with a proportional-margin floor. Independent of MinValue/MaxValue
	/// (those clamp edited values; these only frame the view).
	public float DisplayMin;
	public float DisplayMax;

	/// How this channel's curve interpolates between keys. Hermite = 0 so
	/// zero-init lands on the right pick for particle / animation curves.
	public CurveInterpolation Interpolation;

	/// Optional longer description (reserved for hover tooltips; not yet
	/// rendered by the canvas itself, but available to wrapping editors).
	public String Description;
}

/// Multi-channel interactive curve editor canvas. Model-agnostic: callers
/// describe their channels via SetChannels, push initial keys via
/// SetKeys(channelIdx, ...), and listen to OnKey* events to project
/// mutations back to their domain types. Reusable for any keyframe-based
/// authoring - particle curves, animation easing, audio envelopes,
/// tone-mapping LUTs, post-FX over time, gameplay tuning curves.
///
/// v1 interactions:
///   - Left click empty space      -> add a key to the active channel
///                                    (LinkedTime: adds to every channel
///                                    at the same Time)
///   - Left click on key           -> select that (channel, key);
///                                    drag moves it (LinkedTime: drag
///                                    moves Time for all channels at
///                                    that index; Value only for the
///                                    active one)
///   - Right click on key          -> delete (LinkedTime: removes the
///                                    matching index in every channel)
///
/// Tangent handles are rendered on the selected key only (left = In,
/// right = Out). Drag a handle to change the slope; right-click to cycle
/// TangentMode (Mirrored / Free / Flat).
public class CurveCanvas : View
{
	/// One keypoint. Times in [0, 1]; Values in user space. Tangents are
	/// slope (dy/dt) at the key. `Mode` controls how tangent edits propagate.
	public struct Key
	{
		public float Time;
		public float Value;
		public float TangentIn;
		public float TangentOut;
		public TangentMode Mode;

		public this(float time, float value, float tangentIn = 0, float tangentOut = 0,
			TangentMode mode = .Mirrored)
		{
			Time = time;
			Value = value;
			TangentIn = tangentIn;
			TangentOut = tangentOut;
			Mode = mode;
		}
	}

	private class Channel
	{
		public ChannelDescriptor Descriptor;
		public List<Key> Keys = new .() ~ delete _;
	}

	private List<Channel> mChannels = new .() ~ DeleteContainerAndItems!(_);

	private int32 mSelectedChannelIdx = -1;
	private int32 mSelectedKeyIdx = -1;
	private int32 mDraggingChannelIdx = -1;
	private int32 mDraggingKeyIdx = -1;
	private bool mInGesture;

	/// Which tangent handle (if any) the current drag is editing. Set
	/// from OnMouseDown when a handle is hit; cleared on OnMouseUp.
	/// While non-None, OnMouseMove updates the key's tangent instead of
	/// its position.
	private enum DraggingHandle : uint8 { None, In, Out }
	private DraggingHandle mDraggingHandle = .None;

	/// Max keypoints per channel. Default matches the particle limit.
	public int32 MaxKeys = 8;

	/// When true, all channels share a single Time axis: every channel has
	/// the same KeyCount and the i-th key has the same Time across all
	/// channels. Add / remove / Time-drag propagate to every channel;
	/// Value-drag affects only the active channel.
	public bool LinkedTime = false;

	/// When true, ValueMin / ValueMax are recomputed from current visible
	/// keys (with a small margin). When false, the explicit ValueMin /
	/// ValueMax are honored.
	public bool AutoFitValueRange = true;

	public float ValueMin = 0;
	public float ValueMax = 1;

	/// Fired when an edit gesture begins (mouse-down starting a drag, or
	/// click-add, or right-click delete).
	public Event<delegate void()> OnEditBegin ~ _.Dispose();

	/// Fired when the current edit gesture commits.
	public Event<delegate void()> OnEditEnd ~ _.Dispose();

	/// Fired when an existing key was repositioned. Payload: channel index,
	/// key index.
	public Event<delegate void(int32, int32)> OnKeyChanged ~ _.Dispose();

	/// Fired after a new key was inserted.
	public Event<delegate void(int32, int32)> OnKeyAdded ~ _.Dispose();

	/// Fired after an existing key was deleted; payload carries the OLD
	/// index (before removal) so callers can mirror it in their model.
	public Event<delegate void(int32, int32)> OnKeyRemoved ~ _.Dispose();

	public int32 ChannelCount => (int32)mChannels.Count;
	public int32 SelectedChannel => mSelectedChannelIdx;
	public int32 SelectedKeyIndex => mSelectedKeyIdx;

	public ChannelDescriptor GetChannelDescriptor(int32 idx) => mChannels[idx].Descriptor;
	public int32 GetKeyCount(int32 channelIdx) => (int32)mChannels[channelIdx].Keys.Count;
	public Key GetKey(int32 channelIdx, int32 keyIdx) => mChannels[channelIdx].Keys[keyIdx];

	/// Configure the channel set. Clears existing keys. Selection resets to
	/// channel 0 if any channels exist.
	public void SetChannels(Span<ChannelDescriptor> channels)
	{
		ClearChannels();
		for (let desc in channels)
		{
			let ch = new Channel();
			ch.Descriptor = desc;
			mChannels.Add(ch);
		}
		mSelectedChannelIdx = mChannels.Count > 0 ? 0 : -1;
		mSelectedKeyIdx = -1;
		mDraggingChannelIdx = -1;
		mDraggingKeyIdx = -1;
		Invalidate();
	}

	private void ClearChannels()
	{
		for (let ch in mChannels) delete ch;
		mChannels.Clear();
	}

	/// Replace one channel's keys. Does not enforce LinkedTime alignment -
	/// callers should push matched-time keys for all channels when using
	/// LinkedTime. After SetKeys, in-progress drag state on that channel
	/// is invalidated.
	public void SetKeys(int32 channelIdx, Span<Key> keys)
	{
		if (channelIdx < 0 || channelIdx >= mChannels.Count) return;
		let ch = mChannels[channelIdx];
		ch.Keys.Clear();
		for (let k in keys) ch.Keys.Add(k);
		if (mDraggingChannelIdx == channelIdx)
		{
			mDraggingChannelIdx = -1;
			mDraggingKeyIdx = -1;
		}
		if (mSelectedChannelIdx == channelIdx) mSelectedKeyIdx = -1;
		Invalidate();
	}

	// === Curve evaluation ===

	private float Evaluate(int32 channelIdx, float t)
	{
		let ch = mChannels[channelIdx];
		if (ch.Keys.Count == 0) return 0;
		if (ch.Keys.Count == 1) return ch.Keys[0].Value;
		if (t <= ch.Keys[0].Time) return ch.Keys[0].Value;
		if (t >= ch.Keys[ch.Keys.Count - 1].Time) return ch.Keys[ch.Keys.Count - 1].Value;

		for (int32 i = 0; i < ch.Keys.Count - 1; i++)
		{
			let a = ch.Keys[i];
			let b = ch.Keys[i + 1];
			if (t >= a.Time && t <= b.Time)
			{
				let seg = b.Time - a.Time;
				if (seg < 0.0001f) return a.Value;
				let lt = (t - a.Time) / seg;
				switch (ch.Descriptor.Interpolation)
				{
				case .Linear: return a.Value + (b.Value - a.Value) * lt;
				case .Step:   return a.Value;
				case .Hermite:
					let lt2 = lt * lt;
					let lt3 = lt2 * lt;
					return (2 * lt3 - 3 * lt2 + 1) * a.Value
						+ (lt3 - 2 * lt2 + lt) * (a.TangentOut * seg)
						+ (-2 * lt3 + 3 * lt2) * b.Value
						+ (lt3 - lt2) * (b.TangentIn * seg);
				}
			}
		}
		return ch.Keys[ch.Keys.Count - 1].Value;
	}

	// === Auto-fit value range ===

	private void UpdateAutoFit()
	{
		if (!AutoFitValueRange) return;

		// Freeze the value range for the duration of an edit gesture.
		// Re-fitting from live key values mid-drag is a feedback loop:
		// YToValue maps the cursor through the range, the dragged value
		// then widens the range, and ValueToY re-projects every key - the
		// dragged point sticks ~margin from the edge (feels like it only
		// moves horizontally) while every other key collapses toward the
		// middle. HitKey fits the range just before BeginGesture, so the
		// frozen range is already correct for the keys at drag start; the
		// next draw after EndGesture re-fits.
		if (mInGesture) return;

		float lo = float.MaxValue, hi = float.MinValue;
		bool any = false;
		// Union of declared nominal display ranges across visible channels.
		float nomLo = float.MaxValue, nomHi = float.MinValue;
		bool hasNominal = false;
		for (let ch in mChannels)
		{
			if (ch.Descriptor.Hidden) continue;
			let d = ch.Descriptor;
			if (d.DisplayMin < d.DisplayMax)
			{
				if (d.DisplayMin < nomLo) nomLo = d.DisplayMin;
				if (d.DisplayMax > nomHi) nomHi = d.DisplayMax;
				hasNominal = true;
			}
			for (let k in ch.Keys)
			{
				if (k.Value < lo) lo = k.Value;
				if (k.Value > hi) hi = k.Value;
				any = true;
			}
		}

		// Channel-declared nominal range: frame to it and only expand to
		// admit keys that fall outside, never shrink below it. This keeps
		// the vertical framing stable across edits (no collapse-when-keys-
		// cluster spiral) and is the principled path for curves with a
		// known domain (alpha 0..1, multipliers, etc.).
		if (hasNominal)
		{
			var fLo = nomLo;
			var fHi = nomHi;
			if (any)
			{
				let pad = (nomHi - nomLo) * 0.05f;
				if (lo < fLo) fLo = lo - pad;
				if (hi > fHi) fHi = hi + pad;
			}
			ValueMin = fLo;
			ValueMax = fHi;
			return;
		}

		if (!any) { ValueMin = 0; ValueMax = 1; return; }

		let center = (lo + hi) * 0.5f;
		let span = hi - lo;

		// No nominal range declared: auto-fit with a span floor. A purely
		// proportional margin (span * 0.1) collapses the range to a sliver
		// when keys cluster in value: YToValue then maps the whole canvas
		// to that sliver, drag resolution drops to ~zero, every adjustment
		// lands on the same value, and auto-fit keeps it tiny - a feedback
		// loop that pins all keys to the canvas center and makes the curve
		// uneditable. The floor scales with magnitude so large-valued
		// curves aren't forced to an unusably tight zoom. This also
		// subsumes the old lo == hi (constant curve) special case.
		let minSpan = Math.Max(0.5f, Math.Abs(center) * 0.5f);
		if (span < minSpan)
		{
			ValueMin = center - minSpan * 0.5f;
			ValueMax = center + minSpan * 0.5f;
		}
		else
		{
			let margin = span * 0.1f;
			ValueMin = lo - margin;
			ValueMax = hi + margin;
		}
	}

	// === Coordinate transforms ===

	private float TimeToX(float t) => t * Width;
	private float ValueToY(float v)
	{
		let denom = (ValueMax - ValueMin);
		if (denom < 0.0001f) return Height * 0.5f;
		return Height * (1.0f - (v - ValueMin) / denom);
	}
	private float XToTime(float x) => Math.Clamp(x / Width, 0, 1);
	private float YToValue(float y)
	{
		let r = Math.Clamp(y / Height, 0, 1);
		return ValueMax - r * (ValueMax - ValueMin);
	}

	// === Hit testing ===

	private const float KeyHitRadius = 8;
	private const float KeyDrawRadius = 4;
	/// Pixel distance from key to tangent-handle endpoint. Fixed in
	/// screen space so handles stay legible regardless of zoom.
	private const float HandleScreenLen = 32;
	private const float HandleHitRadius = 7;
	private const float HandleDrawRadius = 4;

	/// Computes the screen position of one tangent handle. `outgoing`
	/// = false picks the incoming handle (left of key); true picks the
	/// outgoing handle (right of key). The handle sits at a fixed
	/// `HandleScreenLen` distance from the key, oriented along the
	/// data slope projected to screen.
	private void ComputeHandlePos(int32 channelIdx, int32 keyIdx, bool outgoing,
		out float hx, out float hy)
	{
		let k = mChannels[channelIdx].Keys[keyIdx];
		let kx = TimeToX(k.Time);
		let ky = ValueToY(k.Value);
		let pV = (ValueMax > ValueMin + 0.0001f) ? Height / (ValueMax - ValueMin) : 0;
		let slope = outgoing ? k.TangentOut : k.TangentIn;
		// Direction vector in screen space: outgoing = (+Width, -S*pV),
		// incoming = (-Width, +S*pV). Length normalized to HandleScreenLen.
		let dx = outgoing ? Width : -Width;
		let dy = outgoing ? (-slope * pV) : (slope * pV);
		let norm = Math.Sqrt(dx * dx + dy * dy);
		if (norm < 0.0001f)
		{
			hx = kx + (outgoing ? HandleScreenLen : -HandleScreenLen);
			hy = ky;
			return;
		}
		hx = kx + HandleScreenLen * dx / norm;
		hy = ky + HandleScreenLen * dy / norm;
	}

	/// Inverse of ComputeHandlePos's slope projection: given a desired
	/// handle screen position relative to the key, returns the data
	/// slope (dy/dt) that places the handle there. Caller is expected
	/// to clamp the screen dx sign per handle (incoming = negative,
	/// outgoing = positive).
	private float HandleScreenToDataSlope(float screenDx, float screenDy)
	{
		if (Math.Abs(screenDx) < 0.0001f) return 0;
		let pV = (ValueMax > ValueMin + 0.0001f) ? Height / (ValueMax - ValueMin) : 1;
		if (pV < 0.0001f) return 0;
		// screen_slope = dy/dx along the handle's outgoing direction.
		// For outgoing handle: screen_slope = -S * pV / Width, so S = -screen_slope * Width / pV.
		// For incoming handle: dx is negative, dy positive -> -(dy / dx) * Width / pV = same formula.
		let screenSlope = screenDy / screenDx;
		return -screenSlope * Width / pV;
	}

	/// True iff (x, y) is within HandleHitRadius of either tangent
	/// handle on the currently selected key. Out-params identify which
	/// handle. No-op when no key is selected or its mode hides handles.
	private bool HitHandle(float x, float y, out bool outgoing)
	{
		outgoing = false;
		if (mSelectedChannelIdx < 0 || mSelectedKeyIdx < 0) return false;
		if (mSelectedChannelIdx >= mChannels.Count) return false;
		let ch = mChannels[mSelectedChannelIdx];
		if (ch.Descriptor.Hidden || ch.Descriptor.Locked) return false;
		if (ch.Descriptor.Interpolation != .Hermite) return false;
		if (mSelectedKeyIdx >= ch.Keys.Count) return false;

		float hx, hy;
		ComputeHandlePos(mSelectedChannelIdx, mSelectedKeyIdx, true, out hx, out hy);
		var dx = x - hx;
		var dy = y - hy;
		if (dx * dx + dy * dy <= HandleHitRadius * HandleHitRadius)
		{
			outgoing = true;
			return true;
		}
		ComputeHandlePos(mSelectedChannelIdx, mSelectedKeyIdx, false, out hx, out hy);
		dx = x - hx;
		dy = y - hy;
		if (dx * dx + dy * dy <= HandleHitRadius * HandleHitRadius)
		{
			outgoing = false;
			return true;
		}
		return false;
	}

	/// Cycles the selected key's TangentMode: Mirrored -> Free -> Flat.
	/// When entering Mirrored, snaps TangentIn to TangentOut so the
	/// transition is visible immediately. When entering Flat, zeroes
	/// both tangents. Caller fires OnKeyChanged.
	private void CycleSelectedTangentMode()
	{
		if (mSelectedChannelIdx < 0 || mSelectedKeyIdx < 0) return;
		let ch = mChannels[mSelectedChannelIdx];
		if (mSelectedKeyIdx >= ch.Keys.Count) return;
		var k = ch.Keys[mSelectedKeyIdx];
		switch (k.Mode)
		{
		case .Mirrored: k.Mode = .Free;
		case .Free:
			k.Mode = .Flat;
			k.TangentIn = 0;
			k.TangentOut = 0;
		case .Flat:
			k.Mode = .Mirrored;
			// Sync In to Out so the handles snap together visibly.
			k.TangentIn = k.TangentOut;
		}
		ch.Keys[mSelectedKeyIdx] = k;
	}

	private bool HitKey(float x, float y, out int32 channelIdx, out int32 keyIdx)
	{
		channelIdx = -1;
		keyIdx = -1;
		UpdateAutoFit();

		// Prefer the currently selected channel so overlapping keys disambiguate
		// in favor of "the one you were just using".
		if (mSelectedChannelIdx >= 0 && mSelectedChannelIdx < mChannels.Count)
		{
			if (HitKeyInChannel(mSelectedChannelIdx, x, y, out keyIdx))
			{
				channelIdx = mSelectedChannelIdx;
				return true;
			}
		}
		for (int32 c = 0; c < mChannels.Count; c++)
		{
			if (c == mSelectedChannelIdx) continue;
			if (HitKeyInChannel(c, x, y, out keyIdx))
			{
				channelIdx = c;
				return true;
			}
		}
		return false;
	}

	private bool HitKeyInChannel(int32 channelIdx, float x, float y, out int32 keyIdx)
	{
		keyIdx = -1;
		let ch = mChannels[channelIdx];
		if (ch.Descriptor.Hidden) return false;
		for (int32 i = 0; i < ch.Keys.Count; i++)
		{
			let kx = TimeToX(ch.Keys[i].Time);
			let ky = ValueToY(ch.Keys[i].Value);
			let dx = x - kx;
			let dy = y - ky;
			if (dx * dx + dy * dy <= KeyHitRadius * KeyHitRadius)
			{
				keyIdx = i;
				return true;
			}
		}
		return false;
	}

	// === Mouse ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (mChannels.Count == 0) return;

		// Tangent handles take priority over key markers - they're only
		// drawn for the selected key, so the hit-test is cheap and
		// unambiguous, and overlapping cases are rare except at flat
		// tangents where the In/Out handles cluster near the key.
		bool handleOutgoing;
		if (e.Button == .Left && HitHandle(e.X, e.Y, out handleOutgoing))
		{
			let ch = mChannels[mSelectedChannelIdx];
			let k = ch.Keys[mSelectedKeyIdx];
			// Flat keys ignore drag - user must right-click to switch
			// mode first. Keeps the "Flat" mode actually flat.
			if (k.Mode == .Flat) { e.Handled = true; return; }
			mDraggingChannelIdx = mSelectedChannelIdx;
			mDraggingKeyIdx = mSelectedKeyIdx;
			mDraggingHandle = handleOutgoing ? .Out : .In;
			BeginGesture();
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			Invalidate();
			return;
		}

		if (e.Button == .Right && HitHandle(e.X, e.Y, out handleOutgoing))
		{
			let ch = mChannels[mSelectedChannelIdx];
			if (ch.Descriptor.Locked) return;
			BeginGesture();
			CycleSelectedTangentMode();
			OnKeyChanged(mSelectedChannelIdx, mSelectedKeyIdx);
			EndGesture();
			e.Handled = true;
			Invalidate();
			return;
		}

		if (e.Button == .Left)
		{
			int32 hitCh, hitKey;
			if (HitKey(e.X, e.Y, out hitCh, out hitKey))
			{
				if (mChannels[hitCh].Descriptor.Locked) return;
				mSelectedChannelIdx = hitCh;
				mSelectedKeyIdx = hitKey;
				mDraggingChannelIdx = hitCh;
				mDraggingKeyIdx = hitKey;
				BeginGesture();
				Context?.FocusManager.SetCapture(this);
				e.Handled = true;
				Invalidate();
				return;
			}

			// Empty click - add a key.
			let activeIdx = ResolveActiveChannel();
			if (activeIdx < 0) return;
			let activeCh = mChannels[activeIdx];
			if (activeCh.Keys.Count >= MaxKeys) return;

			let t = XToTime(e.X);
			let v = ClampToChannel(activeIdx, YToValue(e.Y));

			BeginGesture();
			if (LinkedTime)
			{
				// Update every channel BEFORE firing any events so listeners
				// always see a consistent state across channels (the wrapper
				// editor for LinkedTime reads all channels in lockstep).
				let addedIndices = scope int32[mChannels.Count];
				int32 newIdx = -1;
				for (int32 c = 0; c < mChannels.Count; c++)
				{
					let chVal = (c == activeIdx) ? v : ClampToChannel(c, mChannels[c].Descriptor.DefaultValue);
					addedIndices[c] = InsertSortedKey(c, .(t, chVal));
					if (c == activeIdx) newIdx = addedIndices[c];
				}
				mSelectedChannelIdx = activeIdx;
				mSelectedKeyIdx = newIdx;
				mDraggingChannelIdx = activeIdx;
				mDraggingKeyIdx = newIdx;
				for (int32 c = 0; c < mChannels.Count; c++)
					OnKeyAdded(c, addedIndices[c]);
			}
			else
			{
				let idx = InsertSortedKey(activeIdx, .(t, v));
				mSelectedChannelIdx = activeIdx;
				mSelectedKeyIdx = idx;
				mDraggingChannelIdx = activeIdx;
				mDraggingKeyIdx = idx;
				OnKeyAdded(activeIdx, idx);
			}
			Context?.FocusManager.SetCapture(this);
			e.Handled = true;
			Invalidate();
		}
		else if (e.Button == .Right)
		{
			int32 hitCh, hitKey;
			if (HitKey(e.X, e.Y, out hitCh, out hitKey))
			{
				if (mChannels[hitCh].Descriptor.Locked) return;
				BeginGesture();
				if (LinkedTime)
				{
					// Same consistency concern as the LinkedTime add path:
					// remove from every channel first, then fire events.
					let removedChannels = scope List<int32>();
					for (int32 c = 0; c < mChannels.Count; c++)
					{
						if (hitKey < mChannels[c].Keys.Count)
						{
							mChannels[c].Keys.RemoveAt(hitKey);
							removedChannels.Add(c);
						}
					}
					for (let c in removedChannels)
						OnKeyRemoved(c, hitKey);
				}
				else
				{
					mChannels[hitCh].Keys.RemoveAt(hitKey);
					OnKeyRemoved(hitCh, hitKey);
				}
				if (mSelectedChannelIdx == hitCh && mSelectedKeyIdx == hitKey)
					mSelectedKeyIdx = -1;
				EndGesture();
				e.Handled = true;
				Invalidate();
			}
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDraggingChannelIdx < 0 || mDraggingKeyIdx < 0) return;
		let dragCh = mDraggingChannelIdx;
		if (dragCh >= mChannels.Count) return;
		if (mDraggingKeyIdx >= mChannels[dragCh].Keys.Count) return;

		// Tangent-handle drag: keep the key in place and rotate the
		// handle around it. Mode controls whether the opposite handle
		// follows along.
		if (mDraggingHandle != .None)
		{
			let ch = mChannels[dragCh];
			var k = ch.Keys[mDraggingKeyIdx];
			let kx = TimeToX(k.Time);
			let ky = ValueToY(k.Value);
			var dx = e.X - kx;
			var dy = e.Y - ky;
			// Constrain dx to the handle's side so the user can't flip
			// the In handle to the right (and vice versa) - that would
			// invert the slope sign and feel like a teleport.
			let outgoing = (mDraggingHandle == .Out);
			let minDx = 4.0f;
			if (outgoing && dx < minDx) dx = minDx;
			if (!outgoing && dx > -minDx) dx = -minDx;
			let newSlope = HandleScreenToDataSlope(dx, dy);
			if (outgoing)
			{
				k.TangentOut = newSlope;
				if (k.Mode == .Mirrored) k.TangentIn = newSlope;
			}
			else
			{
				k.TangentIn = newSlope;
				if (k.Mode == .Mirrored) k.TangentOut = newSlope;
			}
			ch.Keys[mDraggingKeyIdx] = k;
			OnKeyChanged(dragCh, mDraggingKeyIdx);
			e.Handled = true;
			Invalidate();
			return;
		}

		let newTime = XToTime(e.X);
		let newValue = ClampToChannel(dragCh, YToValue(e.Y));

		if (LinkedTime)
		{
			// Update Time on all channels at this index; Value only on active.
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (mDraggingKeyIdx >= mChannels[c].Keys.Count) continue;
				var k = mChannels[c].Keys[mDraggingKeyIdx];
				k.Time = newTime;
				if (c == dragCh) k.Value = newValue;
				mChannels[c].Keys[mDraggingKeyIdx] = k;
			}
			ReSortLinked(dragCh);
		}
		else
		{
			let ch = mChannels[dragCh];
			var k = ch.Keys[mDraggingKeyIdx];
			k.Time = newTime;
			k.Value = newValue;
			ch.Keys[mDraggingKeyIdx] = k;
			let moved = ch.Keys[mDraggingKeyIdx];
			ch.Keys.RemoveAt(mDraggingKeyIdx);
			let newIdx = InsertSortedKey(dragCh, moved);
			mDraggingKeyIdx = newIdx;
			mSelectedKeyIdx = newIdx;
		}

		OnKeyChanged(dragCh, mDraggingKeyIdx);
		if (LinkedTime)
		{
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (c != dragCh && mDraggingKeyIdx < mChannels[c].Keys.Count)
					OnKeyChanged(c, mDraggingKeyIdx);
			}
		}

		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (mDraggingChannelIdx >= 0)
		{
			mDraggingChannelIdx = -1;
			mDraggingKeyIdx = -1;
			mDraggingHandle = .None;
			Context?.FocusManager.ReleaseCapture();
			EndGesture();
			e.Handled = true;
		}
	}

	// === Gesture ===

	private void BeginGesture()
	{
		if (!mInGesture) { mInGesture = true; OnEditBegin(); }
	}

	private void EndGesture()
	{
		if (mInGesture) { mInGesture = false; OnEditEnd(); }
	}

	// === Helpers ===

	private int32 ResolveActiveChannel()
	{
		if (mSelectedChannelIdx >= 0 && mSelectedChannelIdx < mChannels.Count)
		{
			let d = mChannels[mSelectedChannelIdx].Descriptor;
			if (!d.Hidden && !d.Locked)
				return mSelectedChannelIdx;
		}
		for (int32 i = 0; i < mChannels.Count; i++)
		{
			let d = mChannels[i].Descriptor;
			if (!d.Hidden && !d.Locked) return i;
		}
		return -1;
	}

	private int32 InsertSortedKey(int32 channelIdx, Key k)
	{
		let ch = mChannels[channelIdx];
		int32 idx = (int32)ch.Keys.Count;
		for (int32 i = 0; i < ch.Keys.Count; i++)
		{
			if (ch.Keys[i].Time > k.Time) { idx = i; break; }
		}
		ch.Keys.Insert(idx, k);
		return idx;
	}

	private float ClampToChannel(int32 channelIdx, float v)
	{
		let d = mChannels[channelIdx].Descriptor;
		// MinValue >= MaxValue (including the zero-init 0,0 case) means
		// "no clamp configured" - pass the value through.
		if (d.MinValue >= d.MaxValue) return v;
		return Math.Clamp(v, d.MinValue, d.MaxValue);
	}

	/// In LinkedTime mode after a drag, the driver channel may have moved
	/// its key past a neighbor's Time. Sort the driver in place and apply
	/// the same permutation to every other channel so they stay aligned.
	private void ReSortLinked(int32 driverIdx)
	{
		let driverCh = mChannels[driverIdx];
		let n = (int32)driverCh.Keys.Count;
		if (n <= 1) return;

		// Build a permutation: indices[i] = old position of the i-th sorted key.
		let indices = scope int32[n];
		for (int32 i = 0; i < n; i++) indices[i] = i;
		for (int32 i = 1; i < n; i++)
		{
			let cur = indices[i];
			let curTime = driverCh.Keys[cur].Time;
			int32 j = i - 1;
			while (j >= 0 && driverCh.Keys[indices[j]].Time > curTime)
			{
				indices[j + 1] = indices[j];
				j--;
			}
			indices[j + 1] = cur;
		}

		// Apply the permutation to every channel.
		for (let ch in mChannels)
		{
			if (ch.Keys.Count != n) continue; // Defensive: only re-sort matched channels.
			let oldKeys = scope Key[n];
			for (int32 i = 0; i < n; i++) oldKeys[i] = ch.Keys[i];
			for (int32 i = 0; i < n; i++) ch.Keys[i] = oldKeys[indices[i]];
		}

		// Translate the dragging index through the permutation.
		for (int32 i = 0; i < n; i++)
		{
			if (indices[i] == mDraggingKeyIdx)
			{
				mDraggingKeyIdx = i;
				mSelectedKeyIdx = i;
				break;
			}
		}
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		UpdateAutoFit();

		// Background.
		ctx.VG.FillRect(.(0, 0, Width, Height), .(28, 28, 33, 255));

		// Grid: 4 divisions on each axis (5 lines). Vertical lines mark
		// Time 0..1; horizontal lines mark Value ValueMax..ValueMin. Labels
		// make the auto-fit vertical scale legible - without them a range
		// re-fit after a drag looks like the curve jumped for no reason.
		const int32 DIVS = 4;
		let gridColor = Color(50, 50, 58, 255);
		let labelColor = Color(120, 122, 132, 255);
		let font = ctx.FontService?.GetFont(9);

		for (int32 i = 0; i <= DIVS; i++)
		{
			let x = (i / (float)DIVS) * Width;
			ctx.VG.FillRect(.(x, 0, 1, Height), gridColor);
		}
		for (int32 i = 0; i <= DIVS; i++)
		{
			let y = (i / (float)DIVS) * Height;
			ctx.VG.FillRect(.(0, Math.Min(y, Height - 1), Width, 1), gridColor);
		}

		if (font != null)
		{
			// Y-axis value labels (top = ValueMax, bottom = ValueMin).
			// First/last are kept inside the canvas instead of straddling
			// the edge by aligning them Top / Bottom respectively.
			for (int32 i = 0; i <= DIVS; i++)
			{
				let frac = i / (float)DIVS;
				let val = ValueMax - frac * (ValueMax - ValueMin);
				let lineY = frac * Height;
				let txt = scope $"{val:0.##}";
				if (i == 0)
					ctx.VG.DrawText(txt, font, .(2, 1, 42, 14), .Left, .Top, labelColor);
				else if (i == DIVS)
					ctx.VG.DrawText(txt, font, .(2, Height - 15, 42, 14), .Left, .Bottom, labelColor);
				else
					ctx.VG.DrawText(txt, font, .(2, lineY - 7, 42, 14), .Left, .Middle, labelColor);
			}

			// X-axis time labels along the bottom.
			for (int32 i = 0; i <= DIVS; i++)
			{
				let frac = i / (float)DIVS;
				let lineX = frac * Width;
				let txt = scope $"{frac:0.##}";
				if (i == 0)
					ctx.VG.DrawText(txt, font, .(2, Height - 13, 32, 12), .Left, .Bottom, labelColor);
				else if (i == DIVS)
					ctx.VG.DrawText(txt, font, .(Width - 34, Height - 13, 32, 12), .Right, .Bottom, labelColor);
				else
					ctx.VG.DrawText(txt, font, .(lineX - 16, Height - 13, 32, 12), .Center, .Bottom, labelColor);
			}
		}

		// Draw each visible channel - polyline first, then markers.
		for (int32 c = 0; c < mChannels.Count; c++)
		{
			let ch = mChannels[c];
			if (ch.Descriptor.Hidden || ch.Keys.Count == 0) continue;

			const int32 SAMPLES = 128;
			ctx.VG.BeginPath();
			for (int32 i = 0; i <= SAMPLES; i++)
			{
				let t = i / (float)SAMPLES;
				let v = Evaluate(c, t);
				let x = TimeToX(t);
				let y = ValueToY(v);
				if (i == 0) ctx.VG.MoveTo(x, y);
				else ctx.VG.LineTo(x, y);
			}
			ctx.VG.Stroke(ch.Descriptor.StrokeColor, 1.5f);

			for (int32 i = 0; i < ch.Keys.Count; i++)
			{
				let cx = TimeToX(ch.Keys[i].Time);
				let cy = ValueToY(ch.Keys[i].Value);
				let isSel = (c == mSelectedChannelIdx && i == mSelectedKeyIdx);
				ctx.VG.FillCircle(.(cx, cy), KeyDrawRadius,
					isSel ? .(255, 220, 100, 255) : ch.Descriptor.StrokeColor);
				if (isSel)
				{
					ctx.VG.BeginPath();
					for (int32 a = 0; a <= 32; a++)
					{
						let theta = (a / 32.0f) * 2.0f * Math.PI_f;
						let px = cx + (KeyDrawRadius + 2) * Math.Cos(theta);
						let py = cy + (KeyDrawRadius + 2) * Math.Sin(theta);
						if (a == 0) ctx.VG.MoveTo(px, py);
						else ctx.VG.LineTo(px, py);
					}
					ctx.VG.Stroke(.(255, 220, 100, 255), 1.5f);
				}
			}

			// Tangent handles - drawn only on the selected key of a
			// Hermite channel. Mirrored mode reuses one color; Free
			// uses distinct In/Out colors so the user can tell at a
			// glance the handles are independent; Flat is dimmed to
			// signal handles are uneditable until mode changes.
			if (c == mSelectedChannelIdx && mSelectedKeyIdx >= 0 && mSelectedKeyIdx < ch.Keys.Count
				&& ch.Descriptor.Interpolation == .Hermite)
			{
				let k = ch.Keys[mSelectedKeyIdx];
				let kx = TimeToX(k.Time);
				let ky = ValueToY(k.Value);

				Color colIn, colOut;
				switch (k.Mode)
				{
				case .Mirrored:
					colIn  = .(180, 200, 255, 255);
					colOut = .(180, 200, 255, 255);
				case .Free:
					colIn  = .(255, 140, 120, 255);
					colOut = .(120, 220, 160, 255);
				case .Flat:
					colIn  = .(120, 122, 132, 255);
					colOut = .(120, 122, 132, 255);
				}

				float ohx, ohy, ihx, ihy;
				ComputeHandlePos(c, mSelectedKeyIdx, true, out ohx, out ohy);
				ComputeHandlePos(c, mSelectedKeyIdx, false, out ihx, out ihy);

				ctx.VG.DrawLine(.(kx, ky), .(ihx, ihy), colIn, 1);
				ctx.VG.DrawLine(.(kx, ky), .(ohx, ohy), colOut, 1);
				ctx.VG.FillRect(.(ihx - HandleDrawRadius, ihy - HandleDrawRadius,
					HandleDrawRadius * 2, HandleDrawRadius * 2), colIn);
				ctx.VG.FillRect(.(ohx - HandleDrawRadius, ohy - HandleDrawRadius,
					HandleDrawRadius * 2, HandleDrawRadius * 2), colOut);
			}
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(
			constraints.ConstrainWidth(200),
			constraints.ConstrainHeight(120));
	}
}
