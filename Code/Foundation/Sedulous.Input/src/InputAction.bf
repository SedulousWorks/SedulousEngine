using System;
using System.Collections;

using Sedulous.Core;

namespace Sedulous.Input;

/// One named thing a game asks about: "Jump", "Move", "Look".
///
/// Not `Action`, which would shadow corlib's `System.Action` delegate for every file in
/// this namespace. The engine's own concept keeps the qualified name.
[Scriptable(.AllPublic)]
class InputAction
{
	public String Name = new .() ~ delete _;
	public ActionKind Kind = .Button;

	/// Every physical source that can drive it. Several bindings FOLD into one value, so a
	/// key and a stick can serve the same action at once.
	public List<Binding> Bindings = new .() ~ delete _;

	public ActionProcessors Processors = .();

	/// Button actions only, which the validation enforces: shaping the press of an axis
	/// means nothing.
	public Interaction Interaction = .();
}
