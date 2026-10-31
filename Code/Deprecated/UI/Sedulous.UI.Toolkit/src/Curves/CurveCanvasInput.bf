using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CurveCanvas]]: the direct manipulation. Click to add or select, drag to move, drag a handle
/// to shape, right click to delete or to cycle a tangent mode, middle drag to pan and the wheel
/// to zoom the value axis.
extension CurveCanvas
{
	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Middle)
		{
			BeginValuePan(e);
			return;
		}

		if (mChannels.IsEmpty)
			return;

		// Handles take priority over key markers. They are only drawn for the selected key, and
		// they sit close enough to it that the key would otherwise swallow every press.
		if (HitHandle(e.X, e.Y, let outgoing))
		{
			if (e.Button == .Left)
			{
				GrabHandle(e, outgoing);
				return;
			}

			if (e.Button == .Right)
			{
				CycleTangentMode(e);
				return;
			}
		}

		if (e.Button == .Left)
			OnLeftDown(e);
		else if (e.Button == .Right)
			OnRightDown(e);
	}

	private void BeginValuePan(MouseEventArgs e)
	{
		mValuePanning = true;
		mValuePanStartY = e.Y;
		mValuePanStartMin = ValueMin;
		mValuePanStartMax = ValueMax;
		// A pan IS the user framing the view, so auto fit stops second guessing them.
		AutoFitValueRange = false;
		Capture();
		e.Handled = true;
	}

	private void GrabHandle(MouseEventArgs e, bool outgoing)
	{
		let key = mChannels[mSelectedChannel].Keys[mSelectedKey];

		// A flat key IGNORES the drag. Its handles are drawn so the mode is visible, and the
		// user changes the mode by right clicking before they can shape it.
		if (key.Mode == .Flat)
		{
			e.Handled = true;
			return;
		}

		mDraggingChannel = mSelectedChannel;
		mDraggingKey = mSelectedKey;
		mDraggingHandle = outgoing ? .Out : .In;
		BeginGesture();
		Capture();
		e.Handled = true;
		Invalidate();
	}

	private void CycleTangentMode(MouseEventArgs e)
	{
		if (mChannels[mSelectedChannel].Locked)
			return;

		BeginGesture();

		var key = mChannels[mSelectedChannel].Keys[mSelectedKey];
		switch (key.Mode)
		{
		case .Mirrored:
			key.Mode = .Free;

		case .Free:
			key.Mode = .Flat;
			key.TangentIn = 0.0f;
			key.TangentOut = 0.0f;

		case .Flat:
			key.Mode = .Mirrored;
			// In follows Out, so the two handles snap together where the user can see it
			// happen rather than jumping to some remembered pair.
			key.TangentIn = key.TangentOut;
		}
		mChannels[mSelectedChannel].Keys[mSelectedKey] = key;

		OnKeyChanged(mSelectedChannel, mSelectedKey);
		EndGesture();
		e.Handled = true;
		Invalidate();
	}

	private void OnLeftDown(MouseEventArgs e)
	{
		if (HitKey(e.X, e.Y, let hitChannel, let hitKey))
		{
			if (mChannels[hitChannel].Locked)
				return;

			let selectionMoved = (mSelectedChannel != hitChannel) || (mSelectedKey != hitKey);
			mSelectedChannel = hitChannel;
			mSelectedKey = hitKey;
			mDraggingChannel = hitChannel;
			mDraggingKey = hitKey;

			if (selectionMoved)
				OnSelectionChanged(hitChannel, hitKey);

			BeginGesture();
			Capture();
			e.Handled = true;
			Invalidate();
			return;
		}

		AddKeyAt(e);
	}

	private void AddKeyAt(MouseEventArgs e)
	{
		let activeChannel = ResolveActiveChannel();
		if (activeChannel < 0)
			return;

		if (mChannels[activeChannel].Keys.Count >= MaxKeys)
			return;

		let time = XToTime(e.X);
		let value = ClampToChannel(activeChannel, YToValue(e.Y));

		BeginGesture();

		if (!LinkedTime)
		{
			let index = InsertSortedKey(activeChannel, .(time, value));
			mSelectedChannel = activeChannel;
			mSelectedKey = index;
			mDraggingChannel = activeChannel;
			mDraggingKey = index;
			OnKeyAdded(activeChannel, index);
			OnSelectionChanged(activeChannel, index);
		}
		else
		{
			// EVERY channel is updated before ANY event fires, so a listener that reads the
			// other channels sees them all already carrying the new key.
			let addedIndices = scope List<int32>();
			int32 newIndex = -1;

			for (int32 c = 0; c < mChannels.Count; c++)
			{
				let channelValue = (c == activeChannel) ? value
					: ClampToChannel(c, mChannels[c].DefaultValue);
				let index = InsertSortedKey(c, .(time, channelValue));
				addedIndices.Add(index);

				if (c == activeChannel)
					newIndex = index;
			}

			mSelectedChannel = activeChannel;
			mSelectedKey = newIndex;
			mDraggingChannel = activeChannel;
			mDraggingKey = newIndex;

			for (int32 c = 0; c < addedIndices.Count; c++)
				OnKeyAdded(c, addedIndices[c]);

			OnSelectionChanged(mSelectedChannel, mSelectedKey);
		}

		Capture();
		e.Handled = true;
		Invalidate();
	}

	private void OnRightDown(MouseEventArgs e)
	{
		if (!HitKey(e.X, e.Y, let hitChannel, let hitKey))
			return;

		if (mChannels[hitChannel].Locked)
			return;

		BeginGesture();

		if (!LinkedTime)
		{
			mChannels[hitChannel].Keys.RemoveAt(hitKey);
			OnKeyRemoved(hitChannel, hitKey);
		}
		else
		{
			// Removed everywhere FIRST, then reported, for the same reason adding is.
			let removedChannels = scope List<int32>();
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (hitKey >= mChannels[c].Keys.Count)
					continue;

				mChannels[c].Keys.RemoveAt(hitKey);
				removedChannels.Add(c);
			}

			for (let c in removedChannels)
				OnKeyRemoved(c, hitKey);
		}

		if ((mSelectedChannel == hitChannel) && (mSelectedKey == hitKey))
		{
			mSelectedKey = -1;
			OnSelectionChanged(mSelectedChannel, -1);
		}

		EndGesture();
		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mValuePanning)
		{
			PanValue(e);
			return;
		}

		if ((mDraggingChannel < 0) || (mDraggingKey < 0)
			|| (mDraggingChannel >= mChannels.Count)
			|| (mDraggingKey >= mChannels[mDraggingChannel].Keys.Count))
			return;

		if (mDraggingHandle != .None)
		{
			DragHandle(e);
			return;
		}

		DragKey(e);
	}

	private void PanValue(MouseEventArgs e)
	{
		if (Height > 0.0f)
		{
			let delta = (e.Y - mValuePanStartY) * (mValuePanStartMax - mValuePanStartMin) / Height;
			ValueMin = mValuePanStartMin + delta;
			ValueMax = mValuePanStartMax + delta;
		}

		e.Handled = true;
		Invalidate();
	}

	/// The key stays put and the handle rotates around it.
	private void DragHandle(MouseEventArgs e)
	{
		let channel = mChannels[mDraggingChannel];
		var key = channel.Keys[mDraggingKey];

		var dx = e.X - TimeToX(key.Time);
		let dy = e.Y - ValueToY(key.Value);

		// CONSTRAINED to its own side of the key. Letting the incoming handle cross to the right
		// would flip the sign of the slope it represents and make the curve leap.
		let outgoing = mDraggingHandle == .Out;
		let minimumDx = 4.0f;
		if (outgoing && (dx < minimumDx))
			dx = minimumDx;
		if (!outgoing && (dx > -minimumDx))
			dx = -minimumDx;

		let slope = HandleScreenToDataSlope(dx, dy);
		if (outgoing)
		{
			key.TangentOut = slope;
			if (key.Mode == .Mirrored)
				key.TangentIn = slope;
		}
		else
		{
			key.TangentIn = slope;
			if (key.Mode == .Mirrored)
				key.TangentOut = slope;
		}

		channel.Keys[mDraggingKey] = key;
		OnKeyChanged(mDraggingChannel, mDraggingKey);
		e.Handled = true;
		Invalidate();
	}

	private void DragKey(MouseEventArgs e)
	{
		let dragChannel = mDraggingChannel;
		let newTime = XToTime(e.X);
		let newValue = ClampToChannel(dragChannel, YToValue(e.Y));

		if (!LinkedTime)
		{
			let channel = mChannels[dragChannel];
			var key = channel.Keys[mDraggingKey];
			key.Time = newTime;
			key.Value = newValue;

			// Removed and re-inserted rather than written in place, so dragging a key past its
			// neighbour reorders the list and the sorted invariant holds at every instant.
			channel.Keys.RemoveAt(mDraggingKey);
			let newIndex = InsertSortedKey(dragChannel, key);
			mDraggingKey = newIndex;
			mSelectedKey = newIndex;
		}
		else
		{
			// TIME moves on every channel, VALUE only on the one being dragged: that is what
			// linked time means.
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if (mDraggingKey >= mChannels[c].Keys.Count)
					continue;

				var key = mChannels[c].Keys[mDraggingKey];
				key.Time = newTime;
				if (c == dragChannel)
					key.Value = newValue;

				mChannels[c].Keys[mDraggingKey] = key;
			}

			ReSortLinked(dragChannel);
		}

		OnKeyChanged(dragChannel, mDraggingKey);

		if (LinkedTime)
		{
			for (int32 c = 0; c < mChannels.Count; c++)
			{
				if ((c != dragChannel) && (mDraggingKey < mChannels[c].Keys.Count))
					OnKeyChanged(c, mDraggingKey);
			}
		}

		e.Handled = true;
		Invalidate();
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if ((e.Button == .Middle) && mValuePanning)
		{
			mValuePanning = false;
			ReleaseCapture();
			e.Handled = true;
			return;
		}

		if (mDraggingChannel < 0)
			return;

		mDraggingChannel = -1;
		mDraggingKey = -1;
		mDraggingHandle = .None;
		ReleaseCapture();
		EndGesture();
		e.Handled = true;
	}

	/// The wheel zooms the VALUE axis only, anchored at the cursor. The time axis may be shared
	/// with a dopesheet, and zooming it from here would fight whatever owns it.
	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		if ((e.DeltaY == 0.0f) || (Height <= 0.0f))
			return;

		let anchor = YToValue(e.Y);
		let factor = (e.DeltaY > 0.0f) ? (1.0f / ValueZoomStep) : ValueZoomStep;
		let low = anchor + ((ValueMin - anchor) * factor);
		let high = anchor + ((ValueMax - anchor) * factor);

		// Limits at both ends: a range that collapses cannot be zoomed back out, and one that
		// explodes loses all precision.
		if (((high - low) < 1e-6f) || ((high - low) > 1e9f))
			return;

		AutoFitValueRange = false;
		ValueMin = low;
		ValueMax = high;
		e.Handled = true;
		Invalidate();
	}

	// ---- Helpers --------------------------------------------------------------------------------

	private void Capture()
	{
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);
	}

	private void ReleaseCapture()
	{
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
	}

	private void BeginGesture()
	{
		if (mInGesture)
			return;

		mInGesture = true;
		OnEditBegin();
	}

	private void EndGesture()
	{
		if (!mInGesture)
			return;

		mInGesture = false;
		OnEditEnd();
	}

	/// The channel a click with no key under it lands on: the selected one when it can take
	/// edits, else the first that can.
	private int32 ResolveActiveChannel()
	{
		if ((mSelectedChannel >= 0) && (mSelectedChannel < mChannels.Count))
		{
			let channel = mChannels[mSelectedChannel];
			if (!channel.Hidden && !channel.Locked)
				return mSelectedChannel;
		}

		for (int32 i = 0; i < mChannels.Count; i++)
		{
			if (!mChannels[i].Hidden && !mChannels[i].Locked)
				return i;
		}

		return -1;
	}

	private int32 InsertSortedKey(int32 channelIndex, Key key)
	{
		let keys = mChannels[channelIndex].Keys;
		var index = (int32)keys.Count;

		for (int32 i = 0; i < keys.Count; i++)
		{
			if (keys[i].Time > key.Time)
			{
				index = i;
				break;
			}
		}

		keys.Insert(index, key);
		return index;
	}

	/// After a linked drag, sorts the dragged channel and applies THE SAME PERMUTATION to every
	/// other one, so the i-th key still means the same moment on all of them. Sorting each
	/// channel independently would break that the instant two keys in one channel tied.
	private void ReSortLinked(int32 driverIndex)
	{
		let driver = mChannels[driverIndex];
		let n = (int32)driver.Keys.Count;
		if (n <= 1)
			return;

		// An insertion sort over an index array rather than over the keys, because the
		// permutation itself is what the other channels need.
		let order = scope List<int32>();
		for (int32 i = 0; i < n; i++)
			order.Add(i);

		for (int32 i = 1; i < n; i++)
		{
			let current = order[i];
			let currentTime = driver.Keys[current].Time;
			var j = i - 1;
			while ((j >= 0) && (driver.Keys[order[j]].Time > currentTime))
			{
				order[j + 1] = order[j];
				j--;
			}
			order[j + 1] = current;
		}

		let scratch = scope List<Key>();
		for (let channel in mChannels)
		{
			// DEFENSIVE: only channels that actually match the driver's key count are
			// permuted, since a host may have pushed one in mid rebuild.
			if (channel.Keys.Count != n)
				continue;

			scratch.Clear();
			for (let key in channel.Keys)
				scratch.Add(key);

			for (int32 i = 0; i < n; i++)
				channel.Keys[i] = scratch[order[i]];
		}

		// The dragged key moved with everything else, so its index has to follow.
		for (int32 i = 0; i < n; i++)
		{
			if (order[i] != mDraggingKey)
				continue;

			mDraggingKey = i;
			mSelectedKey = i;
			break;
		}
	}
}
