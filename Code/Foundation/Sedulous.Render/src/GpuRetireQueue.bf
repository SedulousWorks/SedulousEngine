using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Deferred GPU destruction across the frames in flight.
///
/// The web safe replacement for waiting on the device when something has to grow: on the web
/// that wait pumps the browser's event loop MID FRAME, which expires the canvas texture and
/// drops the whole frame's submission. A replaced resource is RETIRED instead: it stays alive
/// until every frame that could still reference it has aged out, and is freed on a later tick.
///
/// One queue per owner. A consumer with no queue wired falls back to draining the device, so
/// standalone and test use keeps working.
class GpuRetireQueue
{
	private struct Entry
	{
		public ITexture Texture;
		public ITextureView View;
		public IBindGroup BindGroup;
		public IBuffer Buffer;
		public int32 FramesLeft;
	}

	private IDevice mDevice = null;
	private int32 mAge = 3;
	private List<Entry> mEntries = new .() ~ delete _;

	public void Initialize(IDevice device, int32 framesInFlight)
	{
		mDevice = device;
		// One more than the ring: something retired DURING a frame is safe once that frame's
		// whole ring has come round again.
		mAge = Math.Max(framesInFlight, 1) + 1;
	}

	public void Retire(IBuffer buffer)
	{
		if (buffer != null)
			mEntries.Add(.() { Buffer = buffer, FramesLeft = mAge });
	}

	public void Retire(ITexture texture)
	{
		if (texture != null)
			mEntries.Add(.() { Texture = texture, FramesLeft = mAge });
	}

	public void Retire(ITextureView view)
	{
		if (view != null)
			mEntries.Add(.() { View = view, FramesLeft = mAge });
	}

	public void Retire(IBindGroup bindGroup)
	{
		if (bindGroup != null)
			mEntries.Add(.() { BindGroup = bindGroup, FramesLeft = mAge });
	}

	/// Ages everything by a frame and frees whatever has outlived every frame in flight.
	///
	/// ONCE per frame, before or after that frame's submissions: the extra frame of margin
	/// covers either placement.
	public void Tick()
	{
		if (mDevice == null)
			return;

		for (int i = mEntries.Count - 1; i >= 0; i--)
		{
			var entry = mEntries[i];
			entry.FramesLeft--;
			mEntries[i] = entry;

			if (entry.FramesLeft > 0)
				continue;

			Free(ref entry);
			mEntries.RemoveAt(i);
		}
	}

	/// Destroys everything NOW, at shutdown, once the caller has idled the GPU.
	public void Flush()
	{
		if (mDevice == null)
		{
			mEntries.Clear();
			return;
		}

		for (var entry in ref mEntries)
			Free(ref entry);
		mEntries.Clear();
	}

	public int PendingCount => mEntries.Count;

	/// Views before their textures, and bind groups before the buffers they reference: a
	/// backend that validates rejects the other order.
	private void Free(ref Entry entry)
	{
		if (entry.View != null)
			mDevice.DestroyTextureView(ref entry.View);
		if (entry.Texture != null)
			mDevice.DestroyTexture(ref entry.Texture);
		if (entry.BindGroup != null)
			mDevice.DestroyBindGroup(ref entry.BindGroup);
		if (entry.Buffer != null)
			mDevice.DestroyBuffer(ref entry.Buffer);
	}
}
