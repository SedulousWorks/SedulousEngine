namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class ViewTransformTests
{
	[Test]
	public static void Default_IsIdentity()
	{
		let t = ViewTransform();
		Test.Assert(t.IsIdentity);
	}

	[Test]
	public static void WithTranslation_NotIdentity()
	{
		var t = ViewTransform();
		t.Translation = .(10, 20);
		Test.Assert(!t.IsIdentity);
	}

	[Test]
	public static void WithRotation_NotIdentity()
	{
		var t = ViewTransform();
		t.Rotation = 0.5f;
		Test.Assert(!t.IsIdentity);
	}

	[Test]
	public static void WithScale_NotIdentity()
	{
		var t = ViewTransform();
		t.Scale = .(2, 2);
		Test.Assert(!t.IsIdentity);
	}

	[Test]
	public static void Identity_DefaultOriginIsCenter()
	{
		let t = ViewTransform();
		Test.Assert(t.Origin.X == 0.5f);
		Test.Assert(t.Origin.Y == 0.5f);
	}

	[Test]
	public static void Identity_Constant()
	{
		Test.Assert(ViewTransform.Identity.IsIdentity);
	}
}
