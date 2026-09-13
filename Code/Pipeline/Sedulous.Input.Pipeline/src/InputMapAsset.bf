using System;
using Sedulous.Core.Serialization;
using Sedulous.Input;
using Sedulous.Pipeline.Core;

namespace Sedulous.Input.Pipeline;

/// The authored input map. Authored in the editor, so the file name a plain asset carries goes
/// unused.
[Serializable]
class InputMapAsset : Asset
{
	public InputMap Map = new .() ~ delete _;

	/// Seeds the conventional starter set, so the editor page never opens on a void: one
	/// gameplay set with the four actions nearly every game has, their bindings left empty.
	public void SeedDefaultContent()
	{
		let gameplay = new ActionSet();
		gameplay.Name.Set("Gameplay");

		let names = StringView[4]("Move", "Look", "Jump", "Fire");
		let kinds = ActionKind[4](.Axis2D, .Axis2D, .Button, .Button);
		for (int i < 4)
		{
			let action = new InputAction();
			action.Name.Set(names[i]);
			action.Kind = kinds[i];
			gameplay.Actions.Add(action);
		}

		Map.Sets.Add(gameplay);
	}
}
