using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Manages stencil-based clip path stack.
/// Emits geometry to write to the stencil buffer for arbitrary path clipping.
public class ClipPathManager
{
	private List<int32> mStencilRefStack = new .() ~ delete _;
	private int32 mCurrentStencilRef = 0;

	/// Current stencil reference value
	public int32 CurrentStencilRef => mCurrentStencilRef;

	/// Push a clip path. Emits stencil-write geometry into the batch
	/// and increments the stencil reference value.
	public void PushClipPath(Path path, FillRule fillRule, VGBatch batch, float tolerance = 0.25f)
	{
		mStencilRefStack.Add(mCurrentStencilRef);
		mCurrentStencilRef++;

		// Emit a stencil-write command: tessellate the clip path
		// The renderer should draw this geometry to increment the stencil buffer
		let startIndex = (int32)batch.Indices.Count;
		FillTessellator.Tessellate(path, fillRule, Color.White, false, batch.Vertices, batch.Indices, tolerance);
		let indexCount = (int32)batch.Indices.Count - startIndex;

		if (indexCount > 0)
		{
			var cmd = VGCommand();
			cmd.StartIndex = startIndex;
			cmd.IndexCount = indexCount;
			cmd.ClipMode = .Stencil;
			cmd.StencilRef = mCurrentStencilRef;
			batch.Commands.Add(cmd);
		}
	}

	/// Pop the current clip path, decrementing the stencil reference
	public void PopClip()
	{
		if (mStencilRefStack.Count > 0)
			mCurrentStencilRef = mStencilRefStack.PopBack();
		else
			mCurrentStencilRef = 0;
	}

	/// Reset the clip path stack
	public void Clear()
	{
		mStencilRefStack.Clear();
		mCurrentStencilRef = 0;
	}

	/// Current clip stack depth
	public int Depth => mStencilRefStack.Count;
}
