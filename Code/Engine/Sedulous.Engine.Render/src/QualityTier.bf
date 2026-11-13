using System;
using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// How much an effect may cost on a quality level. Off turns the effect off whatever a scene
/// asks; Low to High set its samples, steps or resolution. A tier never turns an effect on: a
/// scene without AO has none at High.
///
/// Its cases are reflected: the MCP tools name them for an agent.
[Reflect(.StaticFields)]
enum QualityTier : uint32
{
	case Off = 0;
	case Low = 1;
	case Medium = 2;
	case High = 3;
}
