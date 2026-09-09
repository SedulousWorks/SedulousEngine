using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Texture sheet animation: which cell of a grid a particle shows.
///
/// Sedulous carried the vertex fields for this and never populated them, so this is the half
/// that was missing rather than a new idea.
struct FlipbookSettings
{
	public bool Enabled = false;
	public int32 Columns = 1;
	public int32 Rows = 1;
	/// Frames per second, when the sheet is NOT swept over the lifetime.
	public float Fps = 0.0f;
	/// Whether the whole sheet is swept once across the particle's life, rather than looped
	/// at a rate. Sweeping is what an explosion wants; looping is what a flame wants.
	public bool OverLifetime = true;
	public int32 StartFrame = 0;

	public this() {}

	public int32 FrameCount => Columns * Rows;

	/// A single frame is not an animation, so it is not active.
	public bool IsActive => Enabled && (FrameCount > 1);

	/// The sub rectangle for a particle: the corner in the first two components and the size
	/// in the last two.
	public Float4 FrameUV(float lifeRatio, float age)
	{
		let count = FrameCount;
		var frame = OverLifetime ? (int32)(lifeRatio * (float)count) : (int32)(age * Fps);
		frame += StartFrame;
		// Twice, so a negative start frame wraps forward rather than staying negative.
		frame = ((frame % count) + count) % count;

		let column = frame % Columns;
		let row = frame / Columns;
		let sx = 1.0f / (float)Columns;
		let sy = 1.0f / (float)Rows;
		return .((float)column * sx, (float)row * sy, sx, sy);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "enabled", ref Enabled);
		SerializeValue(ar, "columns", ref Columns);
		SerializeValue(ar, "rows", ref Rows);
		SerializeValue(ar, "fps", ref Fps);
		SerializeValue(ar, "overLifetime", ref OverLifetime);
		SerializeValue(ar, "startFrame", ref StartFrame);
	}
}
