using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Script;

/// One queued handler delivery: the target, the handler name, the arguments. A message
/// carries at most one; a contact carries the other entity, the point, the normal and the
/// speed. A string argument is COPIED at queue time, since a borrowed one would be gone by
/// the drain.
class PendingScriptMessage
{
	public const int cMaxArgs = 4;

	public EntityHandle Target;
	public String Handler = new .() ~ delete _;
	public ScriptValue[cMaxArgs] Args = .();
	public int ArgCount = 0;
	private List<String> mOwnedText = null ~ DeleteContainerAndItems!(_);

	public Span<ScriptValue> Arguments => .(&Args[0], ArgCount);

	public void AddArg(ScriptValue value)
	{
		if (ArgCount >= cMaxArgs)
			return;
		var stored = value;
		if (value.Kind == .String)
		{
			if (mOwnedText == null)
				mOwnedText = new .();
			let copy = new String(value.AsString);
			mOwnedText.Add(copy);
			stored = .FromString(copy);
		}
		Args[ArgCount++] = stored;
	}
}
