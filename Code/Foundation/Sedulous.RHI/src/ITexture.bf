namespace Sedulous.RHI;

/// A GPU texture resource.
/// Destroyed via IDevice.DestroyTexture().
interface ITexture
{
	/// The descriptor this texture was created with.
	TextureDesc Desc { get; }

	/// The resource state this texture was created in.
	/// Backends set this based on how they allocate the resource
	/// (e.g., DX12 creates depth textures in DepthStencilWrite).
	ResourceState InitialState { get; }
}
