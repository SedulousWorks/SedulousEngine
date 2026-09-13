using Sedulous.RHI;
using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// One render texture canvas's offscreen target, owned by the subsystem and keyed by the
/// scene and entity it belongs to.
class UICanvasTarget
{
	/// BORROWED, and part of the key rather than something this keeps alive.
	public Scene Scene = null;
	public EntityHandle Entity = default;

	/// What the scene samples.
	public ITexture Texture = null;
	public ITextureView View = null;

	/// The stencil twin the stencil then cover fills need. Null where the device offered no
	/// stencil format, and the canvas falls back to tessellated fills.
	public ITexture DepthStencil = null;
	public ITextureView DepthStencilView = null;

	/// The multisampled colour the pass renders into, resolved into the sampled texture
	/// above. Null falls back to rendering single sampled straight into it.
	public ITexture Msaa = null;
	public ITextureView MsaaView = null;
	public uint32 SampleCount = 1;

	public uint32 Width = 0;
	public uint32 Height = 0;
	public ResourceState State = .Undefined;
	public ResourceState MsaaState = .Undefined;

	/// Swept when the component behind it has gone.
	public bool Seen = false;
}
