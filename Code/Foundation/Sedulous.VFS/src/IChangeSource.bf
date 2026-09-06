using System;
using System.Collections;

namespace Sedulous.VFS;

/// Per-mount notifier for content changes, polled by whoever cares.
interface IChangeSource
{
	void Track(StringView locator);
	void Untrack(StringView locator);

	/// Appends the locators that changed since the last poll. True if any did. The strings
	/// appended are owned by the caller.
	bool Poll(List<String> outChanged);
}
