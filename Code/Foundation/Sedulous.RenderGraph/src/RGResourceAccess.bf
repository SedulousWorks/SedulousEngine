using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// One access a pass declared: what it touches, how, and which part of it.
struct RGResourceAccess
{
	public RGHandle Handle = .Invalid;
	public RGAccessType Type = .ReadTexture;
	public RGSubresourceRange Subresource = .();

	public this() {}

	public this(RGHandle handle, RGAccessType type, RGSubresourceRange subresource = .())
	{
		Handle = handle;
		Type = type;
		Subresource = subresource;
	}

	public bool IsRead => RGAccess.IsRead(Type);
	public bool IsWrite => RGAccess.IsWrite(Type);
	public ResourceState ToResourceState() => RGAccess.ToResourceState(Type);
}
