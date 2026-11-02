using System;
using System.Reflection;
using Sedulous.Core;

namespace Sedulous.Engine.Render.Tests;

/// What the render components show a reader. A raw pointer is borrowed per frame state (a
/// skinning palette, a pose pool): nothing a person can read or set, so the inspector and the
/// MCP tools must not offer it.
class ComponentFieldsTests
{
	// The public pointer fields of `type`, and how many of them are [Hidden].
	private static void PointerFields(Type type, out int count, out int hidden)
	{
		count = 0;
		hidden = 0;
		for (let field in type.GetFields())
		{
			if (!field.IsPublic || field.IsStatic || !field.FieldType.IsPointer)
				continue;
			count++;
			if (field.HasCustomAttribute<HiddenAttribute>())
				hidden++;
		}
	}

	[Test]
	public static void AMeshComponentsBorrowedPointersAreHidden()
	{
		int count = 0;
		int hidden = 0;
		PointerFields(typeof(MeshComponent), out count, out hidden);
		Test.Assert(count == 2, "the bone matrices and last frame's");
		Test.Assert(hidden == count);

		PointerFields(typeof(InstancedMeshComponent), out count, out hidden);
		Test.Assert(count == 2, "the pose pool and last frame's");
		Test.Assert(hidden == count);
	}
}
