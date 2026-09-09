using System;

namespace Sedulous.Json;

/// What a parse produced: the value, or the FIRST problem and where it was.
///
/// The first rather than the last, because the innermost failure is the one that explains the
/// document; everything after it is the unwind.
class JsonParseResult
{
	public bool Ok = false;
	/// Owned. A failed parse leaves a Null value here rather than a half built document.
	public JsonValue Value = new .() ~ delete _;
	/// Empty on success.
	public String Error = new .() ~ delete _;
	/// The byte offset of the error. Nought on success.
	public int Position = 0;

	/// Hands the value to the caller, leaving a fresh Null one behind.
	public JsonValue TakeValue()
	{
		let taken = Value;
		Value = new .();
		return taken;
	}

	/// Back to an empty success, which is what a reused result starts from.
	public void Clear()
	{
		Ok = false;
		delete Value;
		Value = new .();
		Error.Clear();
		Position = 0;
	}
}
