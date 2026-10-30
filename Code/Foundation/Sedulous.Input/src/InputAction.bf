using System;
using System.Collections;

using Sedulous.Core;

namespace Sedulous.Input;

/// One named thing a game asks about: "Jump", "Move", "Look".
///
/// Not `Action`, which would shadow corlib's `System.Action` delegate for every file in
/// this namespace. The engine's own concept keeps the qualified name.
/// Reflected: the editor's input map page lists its fields as the grid's rows.
[Reflect(.Type | .NonStaticFields | .DefaultConstructor)]
[Scriptable(.AllPublic)]
class InputAction
{
	public String Name = new .() ~ delete _;
	public ActionKind Kind = .Button;

	/// Button actions only, which the validation enforces: shaping the press of an axis
	/// means nothing. Declared beside the kind: the editor lists its rows in this order (when it
	/// fires, beside what it is); the save is written by hand, so the order is no file's.
	public Interaction Interaction = .();

	/// Every physical source that can drive it. Several bindings FOLD into one value, so a
	/// key and a stick can serve the same action at once.
	public List<Binding> Bindings = new .() ~ delete _;

	public ActionProcessors Processors = .();
}
