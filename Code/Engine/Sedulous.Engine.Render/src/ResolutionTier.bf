using System;
using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// A quality tier with no Off: the resolution of the environment's prefiltered maps (the sky's
/// lighting, the reflection probes).
[Reflect(.StaticFields)]
enum ResolutionTier : uint32
{
	case Low = 0;
	case Medium = 1;
	case High = 2;
}
