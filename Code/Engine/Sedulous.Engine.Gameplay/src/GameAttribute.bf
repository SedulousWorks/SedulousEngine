using System;

namespace Sedulous.Engine.Gameplay;

/// Marks a Game subclass. GameplayServices.SetGame refuses a class without it, as a compile
/// error naming the class.
///
/// It asks for the class's instance fields reflected, public and private alike: a game holds
/// its state in its own fields, and the editor's play tools (pie_run's `game` probe) read them
/// by name while it runs. A reflection request reaches only the class that carries it, never a
/// subclass, which is why the base cannot ask for it and each game class states it.
///
/// A game has no identity on disk and no Serialize: it is never saved. What is generated is the
/// registration of the enums its fields hold with EnumCases, so a probe names an enum field's
/// case without the enum being reflected.
[AttributeUsage(.Class, .NotInherited | .ReflectAttribute | .DisallowAllowMultiple,
	ReflectUser = .Type | .NonStaticFields)]
struct GameAttribute : Attribute, IComptimeTypeApply
{
	[Comptime]
	public void ApplyToType(Type type)
	{
		let body = scope String();
		Sedulous.Core.EnumCases.AppendRegistration(type, body);
		if (!body.IsEmpty)
			Compiler.EmitTypeBody(type, body);
	}
}
