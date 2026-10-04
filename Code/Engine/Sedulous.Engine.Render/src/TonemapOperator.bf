using System;
using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// Which curve maps the scene's linear light onto the display.
///
/// Its cases are reflected: the MCP scene schema names them for an agent.
[Reflect(.StaticFields)]
[Scriptable(.AllPublic)]
enum TonemapOperator : uint32
{
	/// Clipped outright, which is the honest zero cost option.
	case Clamp = 0;
	/// A filmic curve that keeps highlights from going flat as they saturate.
	case AgX = 1;
}
