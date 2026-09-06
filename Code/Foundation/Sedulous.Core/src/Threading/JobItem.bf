using System;

namespace Sedulous.Core;

/// One unit of work queued on the pool.
///
/// Raptor type-erases the callable by hand, into a void* plus invoke and destroy
/// function pointers, because a C++ lambda has no common type. A Beef delegate already
/// is that erasure, so the item is just the delegate and the counter it signals.
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
