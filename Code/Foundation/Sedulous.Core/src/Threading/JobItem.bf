using System;

namespace Sedulous.Core;

/// One unit of work queued on the pool.
///
/// A Beef delegate already type-erases the callable, so the item is just the delegate and
/// the counter it signals; no hand-rolled void* plus invoke and destroy function pointers.
///
/// The pool OWNS Work and deletes it once it has run.
struct JobItem
{
	public delegate void() Work;
	/// Decremented when the job completes; may be null.
	public Counter Signal;

	public this(delegate void() work, Counter signal)
	{
		Work = work;
		Signal = signal;
	}
}
