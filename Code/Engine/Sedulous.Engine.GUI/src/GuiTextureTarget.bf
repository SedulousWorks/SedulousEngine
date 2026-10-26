using System;
using Sedulous.GUI;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.GUI;

/// A texture a canvas or a panel draws into: the sampled texture, and the multisampled colour
/// and stencil its pass resolves from (none: a plain pass straight into it). The render state's.
class GuiTextureTarget
{
	/// Whose: the texture root it is drawn from. Compared, never followed.
	public SceneRoot Root = null;
	/// BORROWED, compared by identity only: the scene may be gone by the sweep.
	public Scene Scene = null;
	public EntityHandle Entity = .Invalid;
	public ITexture Texture = null;
	public ITextureView View = null;
	/// Destroyed by the render state before the device goes (GuiRenderState.Release).
	public VGPassTargets Pass = new .() ~ delete _;
	public bool Multisampled = false;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public ResourceState State = .Undefined;
	/// Drawn this frame; an unseen one goes at the end of RenderTextures.
	public bool Seen = false;
}
