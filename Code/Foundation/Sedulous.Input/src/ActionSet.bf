using System;
using System.Collections;

namespace Sedulous.Input;

/// A CONTEXT: "Gameplay", "Menu", "Vehicle".
///
/// Priority decides which one answers when the same action name lives in several enabled
/// sets, higher winning. That is what lets a menu take "Cancel" while gameplay still holds
/// its own, without either knowing about the other.
class ActionSet
{
	public String Name = new .() ~ delete _;
	public int32 Priority = 0;
	public List<InputAction> Actions = new .() ~ DeleteContainerAndItems!(_);
}
