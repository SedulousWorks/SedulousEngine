namespace Sedulous.Engine.UI;

using Sedulous.Scenes;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

/// World-space UI component. Attached to an entity to display UI content
/// rendered to a texture and shown as a sprite in the 3D scene.
/// The UIComponentManager creates GPU resources on initialization and
/// renders dirty views to their textures each frame.
class UIComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.UInt32("PixelWidth", ref PixelWidth);
		s.UInt32("PixelHeight", ref PixelHeight);
		s.Float("WorldWidth", ref WorldWidth);
		s.Float("WorldHeight", ref WorldHeight);
		s.Bool("IsInteractive", ref IsInteractive);
		s.Bool("IsVisible", ref IsVisible);
	}

	// === Serialized properties ===

	/// Texture resolution width.
	public uint32 PixelWidth = 512;
	/// Texture resolution height.
	public uint32 PixelHeight = 512;
	/// World-space width of the UI quad.
	public float WorldWidth = 1.0f;
	/// World-space height of the UI quad.
	public float WorldHeight = 1.0f;
	/// Whether this view receives raycasted input.
	public bool IsInteractive = true;
	/// Whether this view is visible.
	public bool IsVisible = true;

	// === Runtime state (managed by UIComponentManager) ===

	/// The RootView in the shared UIContext. Add UI content here.
	public RootView Root;
	/// Per-view VG context for building geometry.
	public VGContext VG;
	/// Per-view VG renderer for GPU upload + render.
	public VGRenderer Renderer;
	/// Render target texture.
	public ITexture Texture;
	/// Render target view.
	public ITextureView TextureView;
	/// Whether the view needs re-rendering.
	public bool IsDirty = true;

	/// Mark the view as needing re-rendering.
	public void MarkDirty() { IsDirty = true; }
}
