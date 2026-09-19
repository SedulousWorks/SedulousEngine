namespace Sedulous.Engine.Script;

/// The neutral contact vocabulary the script layer speaks. A producer, physics through a
/// composition root bridge, maps its own kind onto this: the script subsystem never names a
/// physics type, so it does not depend on the physics library.
enum ScriptContactKind : uint8
{
	Begin,
	End,
	TriggerEnter,
	TriggerExit
}
