using System;
using Sedulous.Engine.Input;
using Sedulous.Input;
using Sedulous.Runtime;

namespace Sedulous.Engine.GUI.Tests;

/// An earlier pump in the same lane before the GUI: claims the pointer, when told to.
class GuiClaimingSubsystem : Subsystem
{
	/// BORROWED: the fixture's, which outlives it.
	private InputSubsystem mInput;

	public bool Claims = false;

	public this(InputSubsystem input)
	{
		mInput = input;
	}

	public override int32 UpdateOrder => -650;

	public override void BeginFrame(float deltaTime)
	{
		if (!Claims)
			return;
		var mask = ConsumptionMask();
		mask.Pointer = true;
		mInput.Runtime.SetConsumptionMask(mask);
	}
}
