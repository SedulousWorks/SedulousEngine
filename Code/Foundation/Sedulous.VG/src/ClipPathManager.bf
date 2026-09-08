using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// A stack of stencil clip paths, emitting the geometry that writes them.
///
/// Each push takes the next stencil value, so nesting depth IS the value a draw tests
/// against: geometry inside two clips must pass both, which one comparison against the
/// deeper value achieves.
class ClipPathManager
{
	private List<int32> mStencilRefStack = new .() ~ delete _;
	private int32 mCurrentStencilRef = 0;

	public int32 CurrentStencilRef => mCurrentStencilRef;
	public int Depth => mStencilRefStack.Count;

	/// Pushes a clip path, emitting the geometry the renderer draws into the stencil
	/// buffer.
	///
	/// Tessellated WITHOUT antialiasing: a clip is a hard test, and a fringe of partial
	/// coverage would write stencil values for pixels only partly inside.
	public void PushClipPath(Path path, FillRule fillRule, VGBatch batch, float tolerance = 0.25f)
	{
		mStencilRefStack.Add(mCurrentStencilRef);
		mCurrentStencilRef++;

		let startIndex = (int32)batch.Indices.Count;
		FillTessellator.Tessellate(path, fillRule, .White, false, batch.Vertices, batch.Indices,
			tolerance);
		let indexCount = (int32)batch.Indices.Count - startIndex;

		// A clip path that tessellated to nothing still counts as pushed, so its pop
		// balances; it simply has no geometry to write.
		if (indexCount <= 0)
			return;

		var command = VGCommand();
		command.StartIndex = startIndex;
		command.IndexCount = indexCount;
		command.ClipMode = .Stencil;
		command.StencilRef = mCurrentStencilRef;
		batch.Commands.Add(command);
	}

	/// Pops back to the enclosing clip. An unbalanced pop resets to no clip rather than
	/// going negative.
	public void PopClip()
	{
		if (mStencilRefStack.IsEmpty)
		{
			mCurrentStencilRef = 0;
			return;
		}

		mCurrentStencilRef = mStencilRefStack.PopBack();
	}

	public void Clear()
	{
		mStencilRefStack.Clear();
		mCurrentStencilRef = 0;
	}
}
