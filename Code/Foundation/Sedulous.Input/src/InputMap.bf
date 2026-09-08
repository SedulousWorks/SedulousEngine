using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Input;

/// A whole game's bindings: the sets, their actions, and the bindings under them.
///
/// Pure DATA. Evaluating it is the runtime's job, which is what lets an editor, a cooker
/// and a game all hold the same thing and mean the same by it.
class InputMap : ISerializable
{
	public List<ActionSet> Sets = new .() ~ DeleteContainerAndItems!(_);

	/// Self describing, so a map nests wherever a serializable does: the cooked resource
	/// wrapping one does not have to know its layout, and neither does anything else.
	public void Serialize(ISerializer ar) => InputMapSerialization.SerializeInputMap(ar, this);

	/// The set with this name, or null.
	public ActionSet FindSet(StringView name)
	{
		for (let set in Sets)
		{
			if (set.Name == name)
				return set;
		}
		return null;
	}

	/// Deep copies into `target`, which is how a pristine asset stays pristine: the
	/// overrides are applied to a copy, never to the thing that was loaded.
	public void CopyTo(InputMap target)
	{
		ClearAndDeleteItems!(target.Sets);
		for (let set in Sets)
		{
			let copy = new ActionSet();
			copy.Name.Set(set.Name);
			copy.Priority = set.Priority;

			for (let action in set.Actions)
			{
				let actionCopy = new InputAction();
				actionCopy.Name.Set(action.Name);
				actionCopy.Kind = action.Kind;
				actionCopy.Processors = action.Processors;
				actionCopy.Interaction = action.Interaction;
				actionCopy.Bindings.AddRange(action.Bindings);
				copy.Actions.Add(actionCopy);
			}
			target.Sets.Add(copy);
		}
	}
}
