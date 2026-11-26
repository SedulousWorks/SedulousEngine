using System;

namespace Sedulous.Core;

/// Names what this thread is doing while the scope lives, so a crash report prints it beside the
/// backtrace ("In: Orb.onUpdate on 'orb'"), and restores what was named before as it goes, so
/// scopes nest. The text is copied (cut to fit) into the scope itself, which the crash handler
/// reads as it is: made with `scope`, it allocates nothing on the heap.
class CrashNoteScope
{
	/// The longest note kept, its terminator not counted; a longer one is cut.
	public const int cCapacity = 159;

	private char8[cCapacity + 1] mText;
	private char8* mPrevious;

	/// The note is the parts in order, so a caller names a call with no allocation (a prefix it
	/// keeps, and the call's own name).
	public this(StringView first, StringView second = default, StringView third = default, StringView fourth = default)
	{
		mPrevious = Runtime.ThreadCrashNote;
		int length = 0;
		Append(first, ref length);
		Append(second, ref length);
		Append(third, ref length);
		Append(fourth, ref length);
		mText[length] = '\0';
		Runtime.ThreadCrashNote = &mText[0];
	}

	public ~this()
	{
		Runtime.ThreadCrashNote = mPrevious;
	}

	/// What a crash on this thread would print now; null for nothing.
	public static char8* Current => Runtime.ThreadCrashNote;

	private void Append(StringView part, ref int length)
	{
		for (let c in part.RawChars)
		{
			if (length >= cCapacity)
				return;
			mText[length++] = c;
		}
	}
}
