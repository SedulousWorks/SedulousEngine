using System;
using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// How a camera maps view space to the screen.
[Scriptable(.AllPublic)]
enum CameraProjection : uint8
{
	/// A frustum widening with depth (FovYRadians).
	case Perspective = 0;
	/// A box of fixed size (OrthoHeight): a top-down map, an isometric view.
	case Orthographic = 1;
}
