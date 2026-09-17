using System;
using System.Collections;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// A minimal EXTERNAL renderer: it claims Opaque and draws nothing.
///
/// Exists so a test can register something other than the mesh renderer FIRST, which is what
/// gives that renderer dispatch id nought and breaks any code reading the id as a type.
class InertOpaqueRenderer : Renderer
{
	private static uint16[1] sCategories = .(RenderCategories.Opaque);

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

	public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws) {}
}
