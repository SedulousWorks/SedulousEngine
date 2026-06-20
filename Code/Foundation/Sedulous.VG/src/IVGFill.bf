using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Interface for fill styles used to color vector graphics shapes
public interface IVGFill
{
	/// Get the color at a specific point (for gradient interpolation)
	Color GetColorAt(Vector2 position, RectangleF bounds);

	/// Get the base/primary color of the fill
	Color BaseColor { get; }

	/// Whether this fill requires per-vertex color interpolation
	bool RequiresInterpolation { get; }
}
