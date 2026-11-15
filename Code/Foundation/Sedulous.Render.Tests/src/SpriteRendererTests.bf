using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The sprite renderer's view slots.
class SpriteRendererTests
{
	/// Every run of a view draws, however many the view resolves. Each Resolve took a view slot
	/// from a ring of eight a frame: transparent sprites interleaved with other renderers' draws
	/// resolve one run at a time, and past the eighth run of a frame the rest drew nothing.
	[Test]
	public static void EveryRunOfAViewDraws()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 4;
		textureDesc.Height = 4;
		textureDesc.Usage = .Sampled;
		var texture = fixture.Device.CreateTexture(textureDesc).Value;
		defer fixture.Device.DestroyTexture(ref texture);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var textureView = fixture.Device.CreateTextureView(texture, viewDesc).Value;
		defer fixture.Device.DestroyTextureView(ref textureView);

		// The renderer, and its bind group over the texture, go before the texture.
		{
			let sprites = scope SpriteRenderer(fixture.Device, fixture.Shaders, 2);
			Test.Assert(sprites.Initialize() case .Ok);
			let sprite = scope SpriteRenderData();
			sprite.Texture = textureView;
			sprite.Category = RenderCategories.Transparent;
			var items = DrawItem[1](.(0, sprite));
			let context = RenderRecordContext();
			let draws = scope List<ResolvedDraw>();
			let runs = (uint32)12;
			sprites.PrepareFrame(runs, 0);
			for (uint32 run < runs)
				sprites.Resolve(context, .(&items[0], 1), draws);
			sprites.FinishFrame();
			Test.Assert(draws.Count == (int)runs);
			// One view, one slot.
			Test.Assert(sprites.ViewSlotsUsed == 1);
		}
	}
}
