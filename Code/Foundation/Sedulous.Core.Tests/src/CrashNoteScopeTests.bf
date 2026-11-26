using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// A crash note names what the thread is doing while its scope lives: nested scopes restore the
/// outer note, a long note is cut to fit, and none is left after the last scope.
class CrashNoteScopeTests
{
	[Test]
	public static void ACrashNoteNamesWhatTheThreadIsDoingNestedCutToFitAndGoneAfter()
	{
		Test.Assert(CrashNoteScope.Current == null);
		{
			scope CrashNoteScope("Orb", ".", "onUpdate", " on 'orb'");
			Test.Assert(StringView(CrashNoteScope.Current) == "Orb.onUpdate on 'orb'");
			{
				scope CrashNoteScope("Gate.onOpen");
				Test.Assert(StringView(CrashNoteScope.Current) == "Gate.onOpen");
			}
			Test.Assert(StringView(CrashNoteScope.Current) == "Orb.onUpdate on 'orb'");
		}
		Test.Assert(CrashNoteScope.Current == null);

		let longer = scope String();
		for (int i = 0; i < 40; i++)
			longer.Append("abcdefgh");
		{
			scope CrashNoteScope(longer);
			let current = StringView(CrashNoteScope.Current);
			Test.Assert(current.Length == CrashNoteScope.cCapacity); // cut to its buffer, still terminated
			Test.Assert(longer.StartsWith(current));
		}
		Test.Assert(CrashNoteScope.Current == null);
	}
}
