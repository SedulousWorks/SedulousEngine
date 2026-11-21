using System;
using Sedulous.Script.Resource;

namespace Sedulous.Editor.Scene;

/// How a script property row reaches its value: the effective value (the override, else
/// the class default), and the undoable set and remove of the override. Owned by the row's
/// closures through the view.
class ScriptPropertyAccess
{
	public delegate BehaviorPropertyValue() Effective ~ delete _;
	public delegate void(BehaviorPropertyValue value) SetOverride ~ delete _;
	public delegate void() RemoveOverride ~ delete _;
}
