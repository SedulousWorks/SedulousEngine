using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// An icon at the size it is drawn, rasterized here as the GPU samples the batch (each pixel's
/// centre, coverage interpolated across a triangle, drawn over in order, a centre on an edge two
/// triangles share drawn by one of them): a symmetric icon comes out symmetric, and its edges are
/// anti-aliased (partial coverage), not stepped.
class SVGIconRasterTests
{
	/// The batch's triangles into a `size` x `size` alpha grid, sampled at pixel centres.
	private static void Rasterize(VGBatch batch, int size, List<float> outAlpha)
	{
		outAlpha.Clear();
		for (int i < size * size)
			outAlpha.Add(0.0f);
		for (int t = 0; (t + 2) < batch.Indices.Count; t += 3)
		{
			let a = batch.Vertices[batch.Indices[t]];
			let b = batch.Vertices[batch.Indices[t + 1]];
			let c = batch.Vertices[batch.Indices[t + 2]];
			let area = (b.Position.X - a.Position.X) * (c.Position.Y - a.Position.Y) - (c.Position.X - a.Position.X) * (b.Position.Y - a.Position.Y);
			if (Abs(area) < 1e-9f)
				continue;
			for (int y < size)
			{
				for (int x < size)
				{
					// Nudged off the centre, as the GPU's fill rule breaks a tie: a centre exactly on a
					// shared edge would otherwise be drawn by both triangles.
					let p = Float2((float)x + 0.5f + 1e-4f, (float)y + 0.5f + 3e-4f);
					let w0 = ((b.Position.X - p.X) * (c.Position.Y - p.Y) - (c.Position.X - p.X) * (b.Position.Y - p.Y)) / area;
					let w1 = ((c.Position.X - p.X) * (a.Position.Y - p.Y) - (a.Position.X - p.X) * (c.Position.Y - p.Y)) / area;
					let w2 = 1.0f - w0 - w1;
					if ((w0 < 0.0f) || (w1 < 0.0f) || (w2 < 0.0f))
						continue;
					let coverage = w0 * a.Coverage + w1 * b.Coverage + w2 * c.Coverage;
					let src = coverage * (w0 * a.Color.A + w1 * b.Color.A + w2 * c.Color.A);
					let at = y * size + x;
					outAlpha[at] = src + outAlpha[at] * (1.0f - src); // over
				}
			}
		}
	}

	private static void Picture(List<float> alpha, int size, String outText)
	{
		for (int y < size)
		{
			for (int x < size)
				outText.AppendF("{0,4}", (int)(alpha[y * size + x] * 100.0f + 0.5f));
			outText.Append('\n');
		}
	}

	[Test]
	public static void SymmetricStrokedIconsAreSymmetricAndAntiAliasedAtIconSize()
	{
		// The editor's close and plus icons: round-capped strokes, corner to corner and across.
		StringView[2] icons = .(
			"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 16 16\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 4l8 8M12 4l-8 8\"/></svg>",
			"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 16 16\" fill=\"none\" stroke=\"#ffffff\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M8 3v10M3 8h10\"/></svg>");
		int[2] sizes = .(16, 14);
		for (let icon in icons)
		{
			Test.Assert(SVGLoader.Load(icon) case .Ok(let document), "the icon did not load");
			defer delete document;
			for (let size in sizes)
			{
				let context = scope VGContext();
				SVGRenderer.Render(context, document, .(0.0f, 0.0f, (float)size, (float)size));
				let alpha = scope List<float>();
				Rasterize(context.GetBatch(), size, alpha);
				let picture = scope String()..AppendF("size {}\n", size);
				Picture(alpha, size, picture);
				var worstMirror = 0.0f;
				var partial = 0;
				for (int y < size)
				{
					for (int x < size)
					{
						let here = alpha[y * size + x];
						worstMirror = Max(worstMirror, Abs(here - alpha[y * size + (size - 1 - x)])); // left to right
						worstMirror = Max(worstMirror, Abs(here - alpha[(size - 1 - y) * size + x])); // top to bottom
						if ((here > 0.1f) && (here < 0.9f))
							partial++;
					}
				}
				Test.Assert(worstMirror < 0.15f, picture);
				Test.Assert(partial >= 8, picture); // its edges graded
			}
		}
	}
}
