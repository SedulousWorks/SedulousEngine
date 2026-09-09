using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// What the shadow passes expose to the forward pass.
struct ShadowBinding
{
	/// The cascade depth ARRAY, holding every view's layers.
	public ITextureView SampleView = null;
	/// Declared as a read, which orders the cascade writes ahead of the shading.
	public RGHandle Handle = .Invalid;

	/// THIS view's cascades.
	public ShadowCascades Cascades = .();
	/// And its first layer of the shared array.
	public uint32 LayerBase = 0;

	public bool Valid = false;

	/// The local light atlas: ONE physical atlas shared by every view, with its tile space and
	/// its entry buffer PARTITIONED PER SCENE, because an editor renders several scenes side
	/// by side in one frame and extraction assigns each caster's index relative to its scene.
	public RGHandle AtlasHandle = .Invalid;
	public bool AtlasValid = false;
	public uint32 LocalShadowEntryBase = 0;

	public this() {}

	public bool HasCascades => Valid && (SampleView != null);

	/// True whenever the cascade map EXISTS this frame, even for a view whose scene has no
	/// directional caster.
	///
	/// The set is bound frame globally and the shader samples it unconditionally, so EVERY
	/// pass has to declare the read: one that does not executes against layers another view's
	/// cascade pass has just left in an attachment layout.
	public bool MapBound => SampleView != null;
}
