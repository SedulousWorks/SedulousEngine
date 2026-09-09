namespace Sedulous.Render;

/// Which forward pass emits a category.
enum PassAffinity : uint8
{
	/// The multiple target opaque pass.
	case Opaque;
	/// The colour only pass after temporal antialiasing.
	case Blended;
	/// After tone mapping, so the colours reach the screen as authored.
	case PostTonemap;
	/// Emitted by no forward pass: the sky, the decals and the lights have passes of their
	/// own or are shading inputs rather than draws.
	case None;
}
