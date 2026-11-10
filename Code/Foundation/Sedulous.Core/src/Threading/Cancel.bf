using System;

namespace Sedulous.Core;

// Cooperative cancelling. Whoever may cancel holds a CancelSource;
// the work it started holds its CancelToken, which it asks at its checks (CancelToken.Requested)
// and returns ErrorCode.Cancelled when told. Work that runs where its canceller cannot reach (a cook
// in the pipeline, started by an editor window) takes a token, so the canceller needs no knowledge
// of the work and the work none of the canceller.
//
// The token is the shared flag itself, reference counted, so it stays valid after its source is
// gone: work that keeps it takes a reference. Code with nothing to cancel passes null, which never
// cancels.

/// Handed to work so it can be told to stop: the one flag a source and its work share. Null
/// stands for nothing to cancel.
class CancelToken : RefCounted
{
	private volatile bool mCancelled = false;

	/// Whether the source has cancelled: the work stops at its next check.
	public bool IsCancelled => mCancelled;

	/// Whether `token` has been cancelled; false for null, which never cancels.
	public static bool Requested(CancelToken token) => (token != null) && token.mCancelled;

	/// The source's (it reaches this as a friend): cancelling twice is cancelling once, and nothing
	/// undoes it.
	private void Cancel()
	{
		mCancelled = true;
	}
}

/// Held by whoever may cancel. Its token sees Cancel() from any thread.
class CancelSource
{
	/// One reference of ours; the work takes its own.
	private CancelToken mToken = new .() ~ _.ReleaseRef();

	public void Cancel() => mToken.[Friend]Cancel();
	public bool IsCancelled => mToken.IsCancelled;

	/// The token for the work, cancelled when this is. BORROWED: work that keeps it past this source
	/// takes a reference (AddRef, and ReleaseRef when done).
	public CancelToken Token => mToken;
}
