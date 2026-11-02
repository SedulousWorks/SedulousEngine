using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;

namespace Sedulous.Engine.Physics.Tests;

/// What the physics components show a reader. The body, character and joint handles are the
/// physics world's, made when simulation starts: nothing a person can read or set, so the
/// inspector and the MCP tools must not offer them.
class ComponentFieldsTests
{
	private static bool Hidden(Type type, StringView name)
	{
		if (!(type.GetField(scope String(name)) case .Ok(let field)))
			return false;
		return field.HasCustomAttribute<HiddenAttribute>();
	}

	[Test]
	public static void ThePhysicsWorldsHandlesAreHidden()
	{
		Test.Assert(Hidden(typeof(RigidBodyComponent), "Body"));
		Test.Assert(Hidden(typeof(CharacterComponent), "Character"));
		Test.Assert(Hidden(typeof(JointComponent), "Joint"));
	}
}
