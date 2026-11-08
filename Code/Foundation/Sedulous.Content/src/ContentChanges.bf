using System;
using System.Collections;

namespace Sedulous.Content;

/// What ContentDatabase.Refresh found: the records added, changed and removed by id, and the
/// envelopes it could not read yet, by path.
class ContentChanges
{
	/// A record whose envelope appeared, now in the index.
	public List<Guid> Added = new .() ~ delete _;
	/// A record whose envelope or one of its data streams changed, still in the index.
	public List<Guid> Changed = new .() ~ delete _;
	/// A record whose envelope went, out of the index now.
	public List<Guid> Removed = new .() ~ delete _;
	/// An envelope present but unreadable (one still being written, or broken): its old record
	/// is kept as it was, and a later refresh of the path tries again.
	public List<String> Unreadable = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => Added.IsEmpty && Changed.IsEmpty && Removed.IsEmpty && Unreadable.IsEmpty;

	public void Clear()
	{
		Added.Clear();
		Changed.Clear();
		Removed.Clear();
		ClearAndDeleteItems!(Unreadable);
	}
}
