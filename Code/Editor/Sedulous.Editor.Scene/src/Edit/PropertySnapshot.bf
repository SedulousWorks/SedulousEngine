using System;

namespace Sedulous.Editor.Scene;

/// One reflected field's value, remembered so a removed component that has no serialized
/// form can still come back with its values.
class PropertySnapshot
{
	public String Name = new .() ~ delete _;
	public Variant Value = .() ~ _.Dispose();
}
