using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// One resource the graph manages: what it is, what backs it, and what is known about its
/// state.
///
/// The fields are public data the graph manipulates directly rather than a wall of accessors:
/// this is the graph's own bookkeeping, and the compile pass rewrites most of it every frame.
class RenderGraphResource
{
	// ---- identity ----
	public String Name = new .() ~ delete _;
	public RGResourceType ResourceType;
	public RGResourceLifetime Lifetime;
	public uint32 Generation = 1;

	// ---- reference tracking, worked out during compile ----
	public int32 RefCount = 0;
	public PassHandle FirstWriter = .Invalid;
	public PassHandle LastReader = .Invalid;
	/// The execution range this resource is live over, which is what aliasing turns on.
	public int32 FirstUsePass = -1;
	public int32 LastUsePass = -1;

	// ---- texture ----
	public RGTextureDesc TextureDesc = .();
	public ITexture Texture = null;
	public ITextureView TextureView = null;
	/// The depth ONLY view of a combined depth stencil format, which is what a sampler binds:
	/// a view spanning both aspects cannot be sampled.
	public ITextureView DepthOnlyView = null;
	/// The identity of whatever physically backs this now. It changes when a transient is
	/// allocated a DIFFERENT texture, on a resize say, so a consumer caching a bind group
	/// over the view keys on this rather than on the view's address: a reused address would
	/// otherwise alias a destroyed texture.
	public uint64 TextureGeneration = 0;

	// ---- buffer ----
	public RGBufferDesc BufferDesc = .();
	public IBuffer Buffer = null;

	// ---- state ----
	public ResourceState LastKnownState = .Undefined;
	/// What to transition to after the last use, for an imported resource whose owner expects
	/// it in a particular state.
	public ResourceState? FinalState = null;
	/// Whether to transition to a shader read after the last writer, so a later frame, or a
	/// consumer outside the graph, can sample it.
	public bool ReadableAfterWrite = false;

	/// Null unless the lifetime is persistent. NOT OWNED: the caller created it and keeps it.
	public PersistentResource PersistentData = null;

	public this(StringView name, RGResourceType type, RGResourceLifetime lifetime)
	{
		Name.Set(name);
		ResourceType = type;
		Lifetime = lifetime;
	}

	/// Creates the GPU texture and its views.
	///
	/// ALL OR NOTHING: the fields are assigned only once every view exists. Leaving the
	/// texture set beside a null view poisons the transient pool and desynchronises the
	/// render pass attachments, which is a resize turning the frame to corruption rather
	/// than to an error.
	public Result<void> AllocateTexture(IDevice device)
	{
		var desc = TextureDesc.ToTextureDesc(Name);
		// It may be sampled, whatever else it is.
		desc.Usage |= .Sampled;
		desc.Usage |= TextureFormats.IsDepthFormat(TextureDesc.Format) ? .DepthStencil : .RenderTarget;

		if (!(device.CreateTexture(desc) case .Ok(let texture)))
			return .Err;

		if (!(device.CreateTextureView(texture, .()) case .Ok(let view)))
		{
			var doomed = texture;
			device.DestroyTexture(ref doomed);
			return .Err;
		}

		ITextureView depthOnly = null;
		if (TextureFormats.IsDepthFormat(TextureDesc.Format)
			&& TextureFormats.HasStencil(TextureDesc.Format))
		{
			var depthDesc = TextureViewDesc();
			depthDesc.Aspect = .DepthOnly;
			depthDesc.Label = "RGDepthOnlyView";

			if (!(device.CreateTextureView(texture, depthDesc) case .Ok(let created)))
			{
				var doomedView = view;
				var doomed = texture;
				device.DestroyTextureView(ref doomedView);
				device.DestroyTexture(ref doomed);
				return .Err;
			}
			depthOnly = created;
		}

		Texture = texture;
		TextureView = view;
		DepthOnlyView = depthOnly;
		LastKnownState = texture.InitialState;
		return .Ok;
	}

	public Result<void> AllocateBuffer(IDevice device)
	{
		var rhiDesc = Sedulous.RHI.BufferDesc();
		rhiDesc.Size = BufferDesc.Size;
		rhiDesc.Usage = BufferDesc.Usage;
		rhiDesc.Label = Name;

		if (!(device.CreateBuffer(rhiDesc) case .Ok(let buffer)))
			return .Err;

		Buffer = buffer;
		LastKnownState = .Undefined;
		return .Ok;
	}

	/// Frees what the graph created. A persistent or imported resource is the caller's, so
	/// this does nothing for those.
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

	/// What the ALLOCATED texture has, falling back to what was asked for: a subresource
	/// range's open ended counts resolve against these.
	public uint32 TotalMipLevels
	{
		get
		{
			if (Texture != null)
				return Texture.Desc.MipLevelCount;
			return (ResourceType == .Texture) ? TextureDesc.MipLevelCount : 1;
		}
	}

	public uint32 TotalArrayLayers
	{
		get
		{
			if (Texture != null)
				return Texture.Desc.ArrayLayerCount;
			return (ResourceType == .Texture) ? TextureDesc.ArrayLayerCount : 1;
		}
	}

	/// Clears what the compile pass works out, which is rebuilt from the declarations every
	/// frame.
	public void ResetTracking()
	{
		RefCount = 0;
		FirstWriter = .Invalid;
		LastReader = .Invalid;
		FirstUsePass = -1;
		LastUsePass = -1;
	}
}
