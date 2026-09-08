namespace Sedulous.VG;

/// Which phase of a stencil then cover fill a command is.
///
/// A simple path draws its colour immediately. One with holes, self intersections, or an
/// even odd rule cannot: it needs the winding accumulated first. Such a fill emits a
/// winding pass, which is colour masked and lets the stencil count, and then a cover pass,
/// a bounding quad that draws colour where the stencil says inside and zeroes it behind
/// itself. That needs a stencil attachment the host provides.
///
/// FILLS AND CLIPPING SHARE ONE EIGHT BIT STENCIL. Bit seven is the clip mask; bits zero
/// to six accumulate fill winding. A fill's cover zeroes only the winding bits, and a
/// clipped cover restores the clip bit rather than clearing it.
enum VGFillPhase : uint8
{
	/// An ordinary draw, touching no stencil.
	case Direct;
	/// The winding pass: colour masked fans accumulate into the stencil.
	case StencilWrite;
	/// The cover pass: draw where the stencil says inside, clearing it after.
	case StencilCover;
	/// Turn accumulated clip winding into the clip mask bit. Colour masked.
	case ClipApply;
	/// Zero the clip mask over the clip bounds. Colour masked.
	case ClipClear;
}
