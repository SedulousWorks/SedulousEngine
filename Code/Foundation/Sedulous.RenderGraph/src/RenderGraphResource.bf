using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

using static Sedulous.RHI.TextureFormatExt;

/// A resource managed by the render graph (texture or buffer)
public class RenderGraphResource
{
	/// Resource name (for debug)
	public String Name ~ delete _;
	/// Whether this is a texture or buffer
	public RGResourceType ResourceType;
	/// Lifetime: transient, persistent, or imported
	public RGResourceLifetime Lifetime;
	/// Generation counter for handle validation
	public uint32 Generation = 1;

	// --- Reference tracking (computed during compile) ---
	/// Number of passes that reference this resource
	public int32 RefCount;
	/// First pass that writes to this resource
	public PassHandle FirstWriter = .Invalid;
	/// Last pass that reads from this resource
	public PassHandle LastReader = .Invalid;
	/// First pass that uses this resource (for aliasing)
	public int32 FirstUsePass = -1;
	/// Last pass that uses this resource (for aliasing)
	public int32 LastUsePass = -1;

	// --- Texture data ---
	/// Render graph texture descriptor
	public RGTextureDesc TextureDesc;
	/// GPU texture handle
	public ITexture Texture;
	/// Default texture view
	public ITextureView TextureView;
	/// Depth-only texture view (for sampling depth in shaders when format is depth/stencil)
	public ITextureView DepthOnlyView;

	// --- Buffer data ---
	/// Render graph buffer descriptor
	public RGBufferDesc BufferDesc;
	/// GPU buffer handle
	public IBuffer Buffer;

	// --- State tracking ---
	/// Last known resource state (for barrier computation, persists across frames for persistent resources)
	public ResourceState LastKnownState = .Undefined;
	/// Optional final state to transition to after last use (for imported resources)
	public ResourceState? FinalState;
	/// When true, the barrier solver transitions this resource to ShaderRead
	/// after the last pass that writes to it. Used for resources sampled through
	/// bind groups created outside the graph (e.g., WorldUI textures sampled by sprites).
	public bool ReadableAfterWrite = false;

	// --- Persistent data ---
	/// Persistent resource wrapper (null for transient/imported)
	public PersistentResource PersistentData ~ delete _;

	public this(StringView name, RGResourceType resourceType, RGResourceLifetime lifetime)
	{
		Name = new String(name);
		ResourceType = resourceType;
		Lifetime = lifetime;
	}

	/// Allocate GPU resources for a transient texture
	public Result<void> AllocateTexture(IDevice device)
	{
		// Build RHI descriptor from render graph descriptor
		var rhiDesc = TextureDesc.ToTextureDesc(Name);

		// Ensure required usage flags are set based on how the resource is used
		rhiDesc.Usage |= .Sampled; // May be sampled
		if (TextureDesc.Format.IsDepthFormat())
			rhiDesc.Usage |= .DepthStencil;
		else
			rhiDesc.Usage |= .RenderTarget;

		if (device.CreateTexture(rhiDesc) case .Ok(let tex))
		{
			Texture = tex;
			LastKnownState = tex.InitialState;

			// Create default view
			if (device.CreateTextureView(tex, TextureViewDesc()) case .Ok(let view))
				TextureView = view;
			else
				return .Err;

			// Create depth-only view for depth/stencil textures (needed for shader sampling)
			if (TextureDesc.Format.IsDepthFormat() && TextureDesc.Format.HasStencil())
			{
				if (device.CreateTextureView(tex, TextureViewDesc()
				{
					Aspect = .DepthOnly,
					Label = "RGDepthOnlyView"
				}) case .Ok(let depthOnlyView))
					DepthOnlyView = depthOnlyView;
				else
					return .Err;
			}

			return .Ok;
		}

		return .Err;
	}

	/// Allocate GPU resources for a transient buffer
	public Result<void> AllocateBuffer(IDevice device)
	{
		var rhiDesc = BufferDesc();
		rhiDesc.Size = BufferDesc.Size;
		rhiDesc.Usage = BufferDesc.Usage;
		rhiDesc.Label = Name;

		if (device.CreateBuffer(rhiDesc) case .Ok(let buf))
		{
			Buffer = buf;
			LastKnownState = .Undefined;
			return .Ok;
		}

		return .Err;
	}

	/// Release GPU resources for a transient resource
	public void ReleaseTransient(IDevice device)
	{
		if (Lifetime != .Transient)
			return;

		if (DepthOnlyView != null)
			device.DestroyTextureView(ref DepthOnlyView);
		if (TextureView != null)
			device.DestroyTextureView(ref TextureView);
		if (Texture != null)
			device.DestroyTexture(ref Texture);
		if (Buffer != null)
			device.DestroyBuffer(ref Buffer);
	}

	/// Reset per-frame tracking data
	public void ResetTracking()
	{
		RefCount = 0;
		FirstWriter = .Invalid;
		LastReader = .Invalid;
		FirstUsePass = -1;
		LastUsePass = -1;
	}
}
