using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// A view whose control state the test sets outright, so a selector can be matched against a
/// state no interaction has to produce.
class StateView : TestView
{
	public ControlState State = .Normal;

	public this() : base(50.0f, 30.0f) {}

	public override ControlState GetControlState() => State;
}
