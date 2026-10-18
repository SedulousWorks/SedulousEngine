using System;

namespace Sedulous.Script;

/// What every backend says about a script's errors, so a script reads the same message whichever
/// language it is in.
static class ScriptErrors
{
	/// A script used a handle whose object is gone (destroyed, or a component removed from its
	/// entity): any use but IsValid, which every component handle answers, is this error, raised
	/// where it happens.
	public const String ObjectGone = "the object is gone (destroyed, or a component no longer on its entity)";
}
