using System;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Replaying resolved draws into a command sink.
static class DrawEmitter
{
	/// Emits one resolved draw into any recording surface, a live pass or an off thread
	/// bundle alike.
	///
	/// PURE COMMAND EMISSION: it touches no shared state, so several of these can run at
	/// once. A draw with no pipeline or no indices is skipped rather than recorded, since the
	/// path is indexed only.
	public static void EmitDraw(IRenderCommandEncoder encoder, ResolvedDraw draw)
	{
		if ((draw.Pso == null) || (draw.IndexBuffer == null))
			return;

		encoder.SetPipeline(draw.Pso);

		if (draw.ViewSet != null)
		{
			if (draw.ViewDynamic)
			{
				var offset = draw.ViewOffset;
				encoder.SetBindGroup(0, draw.ViewSet, .(&offset, 1));
			}
			else
			{
				encoder.SetBindGroup(0, draw.ViewSet);
			}
		}

		if (draw.DrawSet != null)
		{
			if (draw.DrawDynamic)
			{
				var offset = draw.DrawOffset;
				encoder.SetBindGroup(1, draw.DrawSet, .(&offset, 1));
			}
			else
			{
				encoder.SetBindGroup(1, draw.DrawSet);
			}
		}

		if (draw.MaterialSet != null)
			encoder.SetBindGroup(2, draw.MaterialSet);
		if (draw.ClusterSet != null)
			encoder.SetBindGroup(3, draw.ClusterSet);

		if (draw.VertexBuffer0 != null)
			encoder.SetVertexBuffer(0, draw.VertexBuffer0, draw.VertexOffset0);
		if (draw.VertexBuffer1 != null)
			encoder.SetVertexBuffer(1, draw.VertexBuffer1, draw.VertexOffset1);
		if (draw.VertexBuffer2 != null)
			encoder.SetVertexBuffer(2, draw.VertexBuffer2, draw.VertexOffset2);

		encoder.SetIndexBuffer(draw.IndexBuffer, draw.IndexFormat, draw.IndexOffset);
		encoder.DrawIndexed(draw.IndexCount, draw.InstanceCount);
	}
}
