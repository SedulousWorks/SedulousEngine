namespace Sedulous.RHI;

/// A GPU texture, with its mip levels and array layers.
interface ITexture
{
	TextureDesc Desc { get; }

	/// The state the texture is in before the first barrier touches it, so a backend knows
	/// what it is transitioning FROM. Settable because ownership of a texture's state moves
	/// as it is handed between systems.
	ResourceState InitialState { get; set; }
}
