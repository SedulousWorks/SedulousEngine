using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// A rect in VIEW pixels: viewport relative, y down, row nought the top, like the pointer.
struct PickRect
{
	public int32 X = 0;
	public int32 Y = 0;
	public uint32 Width = 1;
	public uint32 Height = 1;

	public this() {}

	public this(int32 x, int32 y, uint32 width, uint32 height)
	{
		X = x;
		Y = y;
		Width = width;
		Height = height;
	}
}

/// One decoded pick texel: the RenderData EntityId tag split back out.
struct PickHit
{
	public uint32 EntityIndex = 0;
	public uint32 Generation = 0;

	public this() {}

	public this(uint32 entityIndex, uint32 generation)
	{
		EntityIndex = entityIndex;
		Generation = generation;
	}
}

/// The answer to one request: the unique hits inside its rect, in first seen order, row major
/// over the rect. Not rendered means the view never rendered within the expiry window.
class PickResult
{
	public uint32 Id = PickSystem.cInvalidRequest;
	public List<PickHit> Hits = new .() ~ delete _;
	public bool Rendered = false;
}

/// The record callback a pick pass runs: `viewProj` is the CROPPED world to clip, `rect` the
/// request, whose size is the target's; `viewContext` is what DeclarePasses was handed.
delegate void PickRecordDelegate(IRenderPassEncoder pass, Float4x4 viewProj, PickRect rect,
	Object viewContext);

/// GPU picking: which entity is under a pixel, or inside a rect, of a view, answered by the GPU.
///
/// A pick is an ON REQUEST pass. The requesting view's draw list is re-emitted through each
/// renderer's ResolvePickIds, the depth only caster path with an id writing fragment, into a
/// tiny RG32Uint target the size of the requested rect: the camera projection is CROPPED so the
/// rect fills the whole target, and a click renders a one texel target, vertex work only. Its
/// own depth keeps the nearest surface per texel. x is the entity index plus one, nought being
/// nothing, and y the generation, so a hit resolves to an exact EntityHandle. The target is
/// copied into a GpuToCpu buffer by a graph copy pass and mapped once the device ring has LEFT
/// and RETURNED to the submitting slot, the same retire rule the thumbnail stage uses: never a
/// WaitIdle, never a stall.
///
/// Keyed by the opaque viewport key a RenderScene call carries, so a request binds to the
/// view of one viewport: a split screen, a camera preview inset or a thumbnail never answers it.
class PickSystem
{
	public const uint32 cInvalidRequest = 0;
	public const TextureFormat cIdFormat = .RG32Uint;
	public const uint32 cTexelBytes = 8;
	/// Texture to buffer copies: the row pitch WebGPU and D3D12 require.
	public const uint32 cRowAlignment = 256;
	/// A request that no view renders within this many frames completes as not rendered, so a
	/// hidden viewport never leaves its requester polling forever.
	public const uint32 cExpireFrames = 32;

	private enum SlotState : uint8
	{
		Free,
		/// Waiting for its view to render.
		Requested,
		/// The copy was submitted on SubmittedIndex.
		AwaitReadback,
		/// Decoded, waiting for TryTakeResult.
		Ready,
	}

	private class Slot
	{
		public SlotState State = .Free;
		public uint32 Id = cInvalidRequest;
		public void* ViewportKey = null;
		public PickRect Rect = .();
		public IBuffer Buffer = null;
		public uint64 Capacity = 0;
		public uint32 SubmittedIndex = 0;
		public bool SawOtherIndex = false;
		public bool Rendered = false;
		public uint32 Age = 0;
		public List<PickHit> Hits = new .() ~ delete _;
	}

	private IDevice mDevice;
	/// BORROWED; null means a released readback buffer waits the device idle instead.
	private GpuRetireQueue mRetire = null;
	private uint32 mNextId = 1;
	private List<Slot> mSlots = new .() ~ DeleteContainerAndItems!(_);

	public this(IDevice device)
	{
		mDevice = device;
	}

	/// Destruction is a teardown, the owner having waited the device idle, so the buffers are
	/// freed directly.
	public ~this()
	{
		for (let slot in mSlots)
		{
			if (slot.Buffer != null)
				mDevice.DestroyBuffer(ref slot.Buffer);
		}
	}

	/// Readback buffers retire through the queue, frames in flight safe.
	public void SetRetireQueue(GpuRetireQueue retire) => mRetire = retire;

	// ---- the device free pieces --------------------------------------------------------------

	/// Clamps a rect to the viewport; false when nothing is left, the rect being fully outside
	/// or empty.
	public static bool ClampRect(ref PickRect rect, uint32 viewportWidth, uint32 viewportHeight)
	{
		if ((viewportWidth == 0) || (viewportHeight == 0) || (rect.Width == 0) || (rect.Height == 0))
			return false;
		let x0 = Math.Max((int64)rect.X, 0);
		let y0 = Math.Max((int64)rect.Y, 0);
		let x1 = Math.Min((int64)rect.X + (int64)rect.Width, (int64)viewportWidth);
		let y1 = Math.Min((int64)rect.Y + (int64)rect.Height, (int64)viewportHeight);
		if ((x1 <= x0) || (y1 <= y0))
			return false;
		rect.X = (int32)x0;
		rect.Y = (int32)y0;
		rect.Width = (uint32)(x1 - x0);
		rect.Height = (uint32)(y1 - y0);
		return true;
	}

	/// A projection whose clip space is the pixel rect of a viewportWidth by viewportHeight
	/// view: the rect's centre maps to NDC nought and its edges to plus and minus one, so
	/// rendering with it into a rect sized target reproduces exactly those pixels of the full
	/// view. Depth is untouched, same near and far, same convention. Row vectors: clip is
	/// p * view * result.
	public static Float4x4 CropProjectionToRect(Float4x4 projection, PickRect rect,
		uint32 viewportWidth, uint32 viewportHeight)
	{
		if ((viewportWidth == 0) || (viewportHeight == 0) || (rect.Width == 0) || (rect.Height == 0))
			return projection;
		let fullW = (float)viewportWidth;
		let fullH = (float)viewportHeight;
		// The rect's centre in pixels, then in NDC: x right, y UP, pixel row nought the top.
		let cx = (float)rect.X + (float)rect.Width * 0.5f;
		let cy = (float)rect.Y + (float)rect.Height * 0.5f;
		let ndcCx = 2.0f * cx / fullW - 1.0f;
		let ndcCy = 1.0f - 2.0f * cy / fullH;
		let sx = fullW / (float)rect.Width;
		let sy = fullH / (float)rect.Height;
		// clip' = clip * crop: x' = sx * x - sx * ndcCx * w, y likewise, z and w untouched.
		// Scaling x and y and adding multiples of w commutes with the perspective divide, so
		// the divided result is exactly the NDC remap (ndc - centre) * scale.
		var crop = Float4x4.Identity();
		crop.M[0][0] = sx;
		crop.M[1][1] = sy;
		crop.M[3][0] = -sx * ndcCx;
		crop.M[3][1] = -sy * ndcCy;
		return projection * crop;
	}

	public static uint32 RowStride(uint32 width)
	{
		let tight = width * cTexelBytes;
		return (tight + (cRowAlignment - 1)) & ~(cRowAlignment - 1);
	}

	/// Decodes `height` rows of `width` RG32Uint texels, the rows `rowStrideBytes` apart, into
	/// unique hits, skipping the background, whose x is nought.
	public static void DecodeTexels(uint8* rows, uint32 width, uint32 height, uint32 rowStrideBytes,
		List<PickHit> outHits)
	{
		outHits.Clear();
		if ((rows == null) || (width == 0) || (height == 0))
			return;
		for (uint32 y < height)
		{
			let row = rows + (int)y * (int)rowStrideBytes;
			for (uint32 x < width)
			{
				let texel = (uint32*)(row + (int)x * (int)cTexelBytes);
				if (texel[0] == 0)
					continue; // the clear: nothing
				let hit = PickHit(texel[0] - 1, texel[1]);
				var seen = false;
				for (let h in outHits)
				{
					if ((h.EntityIndex == hit.EntityIndex) && (h.Generation == hit.Generation))
					{
						seen = true;
						break;
					}
				}
				if (!seen)
					outHits.Add(hit);
			}
		}
	}

	// ---- requests ----------------------------------------------------------------------------

	/// Asks for the ids inside `rect` of the view that renders with `viewportKey`. The rect is
	/// clamped when the view declares; one that clamps to nothing completes with no hits.
	public uint32 Request(void* viewportKey, PickRect rect)
	{
		let slot = Acquire();
		slot.State = .Requested;
		slot.Id = mNextId++;
		if (mNextId == cInvalidRequest)
			mNextId = 1; // wrapped: nought stays the invalid id
		slot.ViewportKey = viewportKey;
		slot.Rect = rect;
		slot.SubmittedIndex = 0;
		slot.SawOtherIndex = false;
		slot.Rendered = false;
		slot.Age = 0;
		slot.Hits.Clear();
		return slot.Id;
	}

	/// Polls a request: true once, the hits moving into `outResult`, after which the id is
	/// forgotten.
	public bool TryTakeResult(uint32 id, PickResult outResult)
	{
		let slot = Find(id);
		if ((slot == null) || (slot.State != .Ready))
			return false;
		outResult.Id = id;
		outResult.Rendered = slot.Rendered;
		outResult.Hits.Clear();
		outResult.Hits.AddRange(slot.Hits);
		slot.Hits.Clear();
		slot.State = .Free;
		slot.Id = cInvalidRequest;
		slot.ViewportKey = null;
		return true;
	}

	public bool IsPending(uint32 id)
	{
		let slot = Find(id);
		return (slot != null) && (slot.State != .Ready);
	}

	/// The requests on `viewportKey` still waiting for a render: the passes the next frame
	/// declares.
	public uint32 PendingCount(void* viewportKey)
	{
		uint32 n = 0;
		for (let slot in mSlots)
		{
			if ((slot.State == .Requested) && (slot.ViewportKey == viewportKey))
				n++;
		}
		return n;
	}

	/// The requests declared this frame across every view, for the renderers' ring sizing.
	public uint32 PendingTotal()
	{
		uint32 n = 0;
		for (let slot in mSlots)
		{
			if (slot.State == .Requested)
				n++;
		}
		return n;
	}

	/// Drops every request on `viewportKey`, a viewport closing. An in flight readback still
	/// retires, its result discarded.
	public void Cancel(void* viewportKey)
	{
		for (let slot in mSlots)
		{
			if ((slot.ViewportKey != viewportKey) || (slot.State == .Free))
				continue;
			if (slot.State == .AwaitReadback)
			{
				// The copy is in flight: the slot and its buffer stay until it retires, and the
				// decoded result is thrown away then.
				slot.Id = cInvalidRequest;
				continue;
			}
			slot.State = .Free;
			slot.Id = cInvalidRequest;
			slot.ViewportKey = null;
			slot.Hits.Clear();
		}
	}

	// ---- frame hooks, driven by the RenderFrame ----------------------------------------------

	/// Retires the readbacks whose submission provably completed, the ring having left and
	/// returned to its slot, and decodes them; ages the waiting requests toward expiry.
	public void BeginFrame(uint32 frameIndex)
	{
		for (let slot in mSlots)
		{
			switch (slot.State)
			{
			case .AwaitReadback:
				if (frameIndex != slot.SubmittedIndex)
				{
					slot.SawOtherIndex = true;
					break;
				}
				if (!slot.SawOtherIndex)
					break;
				slot.Hits.Clear();
				if (slot.Buffer != null)
				{
					let mapped = (uint8*)slot.Buffer.Map();
					if (mapped != null)
					{
						DecodeTexels(mapped, slot.Rect.Width, slot.Rect.Height,
							RowStride(slot.Rect.Width), slot.Hits);
						slot.Buffer.Unmap();
					}
				}
				slot.Rendered = true;
				if (slot.Id == cInvalidRequest)
				{
					// Cancelled while in flight.
					slot.State = .Free;
					slot.ViewportKey = null;
					slot.Hits.Clear();
				}
				else
				{
					slot.State = .Ready;
				}
			case .Requested:
				slot.Age++;
				if (slot.Age > cExpireFrames)
				{
					slot.Rendered = false;
					slot.Hits.Clear();
					slot.State = .Ready;
				}
			case .Free, .Ready:
			}
		}
	}

	/// Declares one pick pass and one readback copy per request pending on `viewportKey`, for
	/// the view whose camera is (`view`, `projection`) over a viewportWidth by viewportHeight
	/// viewport. `record` runs inside each pass with `viewContext` handed back to it. Answers
	/// how many were declared.
	public uint32 DeclarePasses(RenderGraph graph, void* viewportKey, Float4x4 view,
		Float4x4 projection, uint32 viewportWidth, uint32 viewportHeight, TextureFormat depthFormat,
		uint32 frameIndex, PickRecordDelegate record, Object viewContext)
	{
		if (record == null)
			return 0;
		uint32 declared = 0;
		for (let slot in mSlots)
		{
			if ((slot.State != .Requested) || (slot.ViewportKey != viewportKey))
				continue;
			var rect = slot.Rect;
			if (!ClampRect(ref rect, viewportWidth, viewportHeight))
			{
				// Nothing of the rect is inside the view: answered without a pass.
				slot.Rect = rect;
				slot.Hits.Clear();
				slot.Rendered = true;
				slot.State = .Ready;
				continue;
			}
			let rowStride = RowStride(rect.Width);
			let bytes = (uint64)rowStride * rect.Height;
			if (!EnsureBuffer(slot, bytes))
			{
				slot.Hits.Clear();
				slot.Rendered = false;
				slot.State = .Ready;
				continue;
			}
			slot.Rect = rect;

			let cropped = CropProjectionToRect(projection, rect, viewportWidth, viewportHeight);
			let viewProj = view * cropped;

			var idDesc = RGTextureDesc(cIdFormat, rect.Width, rect.Height);
			idDesc.Usage = .RenderTarget | .CopySrc;
			let ids = graph.CreateTransient("pick.ids", idDesc);
			var depthDesc = RGTextureDesc(depthFormat, rect.Width, rect.Height);
			depthDesc.Usage = .DepthStencil;
			let depth = graph.CreateTransient("pick.depth", depthDesc);
			let readback = graph.ImportBuffer("pick.readback", slot.Buffer);

			let width = rect.Width;
			let height = rect.Height;
			graph.AddRenderPass("pick.ids", scope [=](builder) =>
			{
				// A uint target: the clear's float zeros are the integer nought, no entity.
				builder.SetColorTarget(0, ids, .Clear, .Store, ClearColor(0, 0, 0, 0));
				builder.SetDepthTarget(depth, .Clear, .DontCare);
				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();
				builder.SetExecute(new [=](pass) => { record(pass, viewProj, rect, viewContext); });
			});
			let buffer = slot.Buffer;
			graph.AddCopyPass("pick.readback", scope [=](builder) =>
			{
				builder.CopySrc(ids);
				builder.CopyDst(readback);
				builder.NeverCull();
				builder.SetCopyExecute(new [=](encoder) =>
				{
					let src = graph.GetTexture(ids);
					if ((src == null) || (buffer == null))
						return;
					var region = BufferTextureCopyRegion();
					region.BytesPerRow = rowStride;
					region.RowsPerImage = height;
					region.TextureExtent = .(width, height, 1);
					encoder.CopyTextureToBuffer(src, buffer, region);
				});
			});
			slot.State = .AwaitReadback;
			slot.SubmittedIndex = frameIndex;
			slot.SawOtherIndex = false;
			declared++;
		}
		return declared;
	}

	// ---- internals ---------------------------------------------------------------------------

	private Slot Find(uint32 id)
	{
		if (id == cInvalidRequest)
			return null;
		for (let slot in mSlots)
		{
			if ((slot.State != .Free) && (slot.Id == id))
				return slot;
		}
		return null;
	}

	private Slot Acquire()
	{
		for (let slot in mSlots)
		{
			if (slot.State == .Free)
				return slot;
		}
		let fresh = new Slot();
		mSlots.Add(fresh);
		return fresh;
	}

	private bool EnsureBuffer(Slot slot, uint64 bytes)
	{
		if ((slot.Buffer != null) && (slot.Capacity >= bytes))
			return true;
		ReleaseBuffer(slot);
		var desc = BufferDesc();
		desc.Size = bytes;
		desc.Usage = .CopyDst;
		desc.Memory = .GpuToCpu;
		desc.Label = "pick.readback";
		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
		{
			slot.Buffer = null;
			slot.Capacity = 0;
			return false;
		}
		slot.Buffer = buffer;
		slot.Capacity = bytes;
		return true;
	}

	private void ReleaseBuffer(Slot slot)
	{
		if (slot.Buffer == null)
			return;
		if (mRetire != null)
		{
			mRetire.Retire(slot.Buffer);
			slot.Buffer = null;
		}
		else
		{
			mDevice.WaitIdle();
			mDevice.DestroyBuffer(ref slot.Buffer);
		}
		slot.Capacity = 0;
	}
}
