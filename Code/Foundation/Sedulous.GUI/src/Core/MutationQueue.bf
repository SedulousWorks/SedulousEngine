using System;
using System.Collections;

namespace Sedulous.GUI;

/// Deferred operations drained at a safe sync point (in GUIContext.Update, after the actions and
/// the bindings). This is how tree edits made mid-traversal (notably Node.Close) are applied
/// without mutating the tree while it is being walked: eepp's SceneRoot close-queue role,
/// generalized to arbitrary deferred operations.
class MutationQueue
{
	private List<delegate void()> mOps = new .() ~ DeleteContainerAndItems!(_);

	/// OWNERSHIP of `op` transfers to the queue.
	public void Enqueue(delegate void() op) => mOps.Add(op);

	public bool IsEmpty => mOps.IsEmpty;

	/// Runs and clears every queued operation. One enqueued during draining runs on the next
	/// drain.
	public void Drain()
	{
		let batch = scope List<delegate void()>();
		batch.AddRange(mOps);
		mOps.Clear();
		for (let op in batch)
		{
			op();
			delete op;
		}
	}
}
