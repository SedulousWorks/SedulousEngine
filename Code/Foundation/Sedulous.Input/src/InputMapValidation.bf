using System;

namespace Sedulous.Input;

/// The data errors a map can carry, checked once and shared by every gate.
///
/// A kind mismatch is a DATA error, so it is surfaced here rather than zeroed at runtime:
/// an action declared Axis2D and bound to a key would otherwise read a silent (0, 0)
/// forever, and nothing on the way in would have said why. The asset save and the cook run
/// the same function, so a map that saves is a map that cooks.
static class InputMapValidation
{
	/// True when the map is coherent. `outError` takes the FIRST problem found, which is
	/// the one worth showing: the rest are usually the same mistake repeated.
	public static bool Validate(InputMap map, String outError = null)
	{
		bool Fail(StringView message)
		{
			if (outError != null)
				outError.Set(message);
			return false;
		}

		for (let set in map.Sets)
		{
			if (set.Name.IsEmpty)
				return Fail("action set with an empty name");

			for (let action in set.Actions)
			{
				if (action.Name.IsEmpty)
					return Fail("action with an empty name");

				// An interaction is a press state machine, so it has nothing to say about
				// an axis: allowing it would be a setting that silently does nothing.
				if ((action.Interaction.Kind != .None) && (action.Kind != .Button))
					return Fail("interaction on a non-Button action");

				for (let binding in action.Bindings)
				{
					let is2D = (binding.Source == .GamepadStick) || (binding.Source == .Composite2D)
						|| (binding.Source == .MouseDelta) || (binding.Source == .TouchStick);
					let isAxis = (binding.Source == .MouseAxis) || (binding.Source == .GamepadAxis);

					switch (action.Kind)
					{
					case .Button:
						if (is2D || isAxis)
							return Fail("analog binding on a Button action");

					case .Axis1D:
						if (is2D)
							return Fail("2D binding on an Axis1D action");

					case .Axis2D:
						if (!is2D)
							return Fail("non-2D binding on an Axis2D action");
					}
				}
			}
		}
		return true;
	}
}
