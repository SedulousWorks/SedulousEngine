using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// Interface for brush types used to fill shapes
public interface IBrush
{
	/// Get the color at a specific point (for gradient interpolation)
	/// For solid brushes, this returns the same color regardless of position
	Color GetColorAt(Vector2 position, RectangleF bounds);

	/// Get the base/primary color of the brush
	Color BaseColor { get; }

	/// Whether this brush requires per-vertex color interpolation
	bool RequiresInterpolation { get; }

	/// Get texture for texture brushes (null for solid/gradient)
	Object Texture { get; }
}
