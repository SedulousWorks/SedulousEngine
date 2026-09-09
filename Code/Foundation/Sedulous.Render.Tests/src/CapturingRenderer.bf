using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// A renderer that records the CONTEXT it was handed rather than drawing anything.
///
/// It resolves no draws at all, so a frame it takes part in produces no commands: what it is
/// for is asserting what the driver told a renderer, which is otherwise invisible from
/// outside.
class CapturingRenderer : Renderer
{
	private static uint16[1] sCategories = .(RenderCategories.Opaque);

	public bool SawColorPass = false;
	public bool SawDepthPass = false;
	public Float4x4 ColorViewMatrix = .Identity();
	public Float4x4 DepthViewMatrix = .Identity();
	public Float4x4 ColorViewProj = .Identity();
	public Float4x4 DepthViewProj = .Identity();
	public bool DepthFilledInstanceCache = false;
	public uint8 ColorSampleCount = 0;

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

	public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		SawColorPass = true;
		ColorViewMatrix = context.ViewMatrix;
		ColorViewProj = context.ViewProj;
		ColorSampleCount = context.SampleCount;
	}

	public override void ResolveDepthOnly(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		SawDepthPass = true;
		DepthViewMatrix = context.ViewMatrix;
		DepthViewProj = context.ViewProj;
		DepthFilledInstanceCache = context.FillInstanceCache;
	}
}
