namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Billboard orientation mode for a sprite.
public enum SpriteOrientation : int32
{
	/// Quad faces the camera directly (view-aligned). Use for HUD-like icons,
	/// damage numbers, particle billboards.
	CameraFacing = 0,

	/// Quad rotates only around the world Y axis to face the camera horizontally.
	/// Use for upright foliage or lollipop-style billboards.
	CameraFacingY = 1,

	/// Quad has a fixed world orientation (world X right, world Y up).
	/// Use for signs, posters, world-space UI panels.
	WorldAligned = 2
}

/// Render data for a sprite — a textured, colored, world-positioned quad.
///
/// Allocated from RenderContext.FrameAllocator — trivially destructible.
/// Submitted to RenderCategories.Transparent (back-to-front sorted).
public class SpriteRenderData : RenderData
{
	/// World-space size in world units (width, height).
	public Vector2 Size;

	/// Tint color applied over the texture sample (RGBA linear, pre-multiplied alpha ok).
	public Vector4 Tint;

	/// UV rectangle within the texture (u, v, width, height) in [0,1] space.
	/// Full texture = (0, 0, 1, 1).
	public Vector4 UVRect;

	/// Billboard orientation mode.
	public SpriteOrientation Orientation;

	/// Material bind group (texture + sampler at set 2). Sprites sharing this
	/// bind group are batched into a single instanced draw.
	public IBindGroup MaterialBindGroup;

	/// Material batch key (typically bind-group pointer cast to uint) — used to
	/// group consecutive sprites into a single DrawInstanced call.
	public uint32 MaterialKey;
}
