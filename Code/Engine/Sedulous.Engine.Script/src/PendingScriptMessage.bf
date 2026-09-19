using System;
using Sedulous.Scene;
using Sedulous.Script;

namespace Sedulous.Engine.Script;

/// One queued `on<Message>` delivery: the target, the handler name, the payload. The
/// payload is COPIED at send time, since a borrowed string would be gone by the drain.
class PendingScriptMessage
{
	public EntityHandle Target;
	public String Handler = new .() ~ delete _;
	public ScriptValue Payload = .Nil;
	public bool HasPayload = false;
	private String mOwnedText = null ~ delete _;

	public void SetPayload(ScriptValue value)
	{
		HasPayload = true;
		Payload = value;
		if (value.Kind == .String)
		{
			mOwnedText = new String(value.AsString);
			Payload = .FromString(mOwnedText);
		}
	}
}
