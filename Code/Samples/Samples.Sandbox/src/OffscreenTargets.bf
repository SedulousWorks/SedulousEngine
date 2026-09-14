using System;
using Sedulous.RHI;

namespace Samples.Sandbox;

/// One colour target per frame in flight.
///
/// ONE PER SLOT rather than one shared: frame N plus one must not render into the target whose
/// blit frame N is still reading, and a single target races on a resize.
class OffscreenTargets
{
	public const uint32 cSlots = 3;

	private ITexture[cSlots] mTextures = .(null, null, null);
	private ITextureView[cSlots] mViews = .(null, null, null);
	private ResourceState[cSlots] mStates = .(.Undefined, .Undefined, .Undefined);
	private uint32[cSlots] mWidths = .(0, 0, 0);
	private uint32[cSlots] mHeights = .(0, 0, 0);

	public ITexture Texture(uint32 slot) => mTextures[slot];
	public ITextureView View(uint32 slot) => mViews[slot];
	public ResourceState State(uint32 slot) => mStates[slot];
	public void SetState(uint32 slot, ResourceState state) => mStates[slot] = state;

	/// Creates or resizes one slot. Each tracks its own size, so a resize recreates each slot
	/// lazily as it comes round again rather than all of them at once.
	public bool Ensure(IDevice device, TextureFormat format, uint32 width, uint32 height,
		uint32 slot)
	{
		if ((mTextures[slot] != null) && (mWidths[slot] == width) && (mHeights[slot] == height))
			return true;

		device.WaitIdle();
		DestroySlot(device, slot);

		TextureDesc textureDesc = .();
		textureDesc.Format = format;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Usage = .RenderTarget | .Sampled | .CopySrc;
		textureDesc.Label = "sandbox.offscreen";
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return false;
		mTextures[slot] = texture;

		TextureViewDesc viewDesc = .();
		viewDesc.Format = format;
		if (!(device.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			DestroySlot(device, slot);
			return false;
		}
		mViews[slot] = view;

		mWidths[slot] = width;
		mHeights[slot] = height;
		mStates[slot] = .Undefined;
		return true;
	}

	/// The GPU has to be idle first, which is the caller's job on shutdown.
	public void Release(IDevice device)
	{
		if (device == null)
			return;

		for (uint32 slot < cSlots)
			DestroySlot(device, slot);
	}

	private void DestroySlot(IDevice device, uint32 slot)
	{
		if (mViews[slot] != null)
			device.DestroyTextureView(ref mViews[slot]);
		if (mTextures[slot] != null)
			device.DestroyTexture(ref mTextures[slot]);
		mWidths[slot] = 0;
		mHeights[slot] = 0;
	}
}
