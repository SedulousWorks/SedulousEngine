using System;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Core.Mathematics;

namespace Sedulous.Audio.Tests;

class AudioListenerTests
{
	[Test]
	public static void TestDefaultPosition()
	{
		let listener = scope AudioListener();

		Test.Assert(listener.Position == Vector3.Zero);
	}

	[Test]
	public static void TestDefaultForward()
	{
		let listener = scope AudioListener();

		// Default forward is -Z
		Test.Assert(listener.Forward.X == 0);
		Test.Assert(listener.Forward.Y == 0);
		Test.Assert(listener.Forward.Z == -1);
	}

	[Test]
	public static void TestDefaultUp()
	{
		let listener = scope AudioListener();

		// Default up is +Y
		Test.Assert(listener.Up.X == 0);
		Test.Assert(listener.Up.Y == 1);
		Test.Assert(listener.Up.Z == 0);
	}

	[Test]
	public static void TestSetPosition()
	{
		let listener = scope AudioListener();
		listener.Position = .(10, 20, 30);

		Test.Assert(listener.Position.X == 10);
		Test.Assert(listener.Position.Y == 20);
		Test.Assert(listener.Position.Z == 30);
	}

	[Test]
	public static void TestSetForward()
	{
		let listener = scope AudioListener();
		listener.Forward = .(1, 0, 0);  // Looking right

		// Should be normalized
		Test.Assert(Math.Abs(listener.Forward.X - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(listener.Forward.Y) < 0.001f);
		Test.Assert(Math.Abs(listener.Forward.Z) < 0.001f);
	}

	[Test]
	public static void TestSetUp()
	{
		let listener = scope AudioListener();
		listener.Up = .(0, 0, 1);  // Up is +Z

		Test.Assert(Math.Abs(listener.Up.X) < 0.001f);
		Test.Assert(Math.Abs(listener.Up.Y) < 0.001f);
		Test.Assert(Math.Abs(listener.Up.Z - 1.0f) < 0.001f);
	}

	[Test]
	public static void TestWorldToLocal_SoundInFront()
	{
		let listener = scope AudioListener();
		// Listener at origin, looking down -Z
		listener.Position = Vector3.Zero;
		listener.Forward = .(0, 0, -1);
		listener.Up = .(0, 1, 0);

		// Sound 10 units in front (negative Z in world)
		let worldPos = Vector3(0, 0, -10);
		let localPos = listener.WorldToLocal(worldPos);

		// In local space: X=0 (center), Y=0
		// Z = -Dot(relativePos, forward) = -Dot((0,0,-10), (0,0,-1)) = -10
		// Negative Z = in front of listener
		Test.Assert(Math.Abs(localPos.X) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z + 10.0f) < 0.001f);  // Z = -10 (in front)
	}

	[Test]
	public static void TestWorldToLocal_SoundToRight()
	{
		let listener = scope AudioListener();
		listener.Position = Vector3.Zero;
		listener.Forward = .(0, 0, -1);
		listener.Up = .(0, 1, 0);

		// Sound 5 units to the right (+X in world)
		let worldPos = Vector3(5, 0, 0);
		let localPos = listener.WorldToLocal(worldPos);

		// In local space: X=5 (right), Y=0, Z=0
		Test.Assert(Math.Abs(localPos.X - 5.0f) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z) < 0.001f);
	}

	[Test]
	public static void TestWorldToLocal_SoundToLeft()
	{
		let listener = scope AudioListener();
		listener.Position = Vector3.Zero;
		listener.Forward = .(0, 0, -1);
		listener.Up = .(0, 1, 0);

		// Sound 5 units to the left (-X in world)
		let worldPos = Vector3(-5, 0, 0);
		let localPos = listener.WorldToLocal(worldPos);

		// In local space: X=-5 (left), Y=0, Z=0
		Test.Assert(Math.Abs(localPos.X + 5.0f) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z) < 0.001f);
	}

	[Test]
	public static void TestWorldToLocal_SoundAbove()
	{
		let listener = scope AudioListener();
		listener.Position = Vector3.Zero;
		listener.Forward = .(0, 0, -1);
		listener.Up = .(0, 1, 0);

		// Sound 3 units above
		let worldPos = Vector3(0, 3, 0);
		let localPos = listener.WorldToLocal(worldPos);

		// In local space: X=0, Y=3 (above), Z=0
		Test.Assert(Math.Abs(localPos.X) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y - 3.0f) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z) < 0.001f);
	}

	[Test]
	public static void TestWorldToLocal_ListenerMoved()
	{
		let listener = scope AudioListener();
		listener.Position = .(10, 0, 0);  // Listener at X=10
		listener.Forward = .(0, 0, -1);
		listener.Up = .(0, 1, 0);

		// Sound at origin
		let worldPos = Vector3.Zero;
		let localPos = listener.WorldToLocal(worldPos);

		// Sound is 10 units to the left of listener
		Test.Assert(Math.Abs(localPos.X + 10.0f) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z) < 0.001f);
	}

	[Test]
	public static void TestWorldToLocal_ListenerRotated()
	{
		let listener = scope AudioListener();
		listener.Position = Vector3.Zero;
		listener.Forward = .(1, 0, 0);  // Looking right (+X)
		listener.Up = .(0, 1, 0);

		// Sound at +X (in front of rotated listener)
		let worldPos = Vector3(10, 0, 0);
		let localPos = listener.WorldToLocal(worldPos);

		// In local space: X=0, Y=0, Z=-10 (negative Z = in front)
		Test.Assert(Math.Abs(localPos.X) < 0.001f);
		Test.Assert(Math.Abs(localPos.Y) < 0.001f);
		Test.Assert(Math.Abs(localPos.Z + 10.0f) < 0.001f);  // Z = -10 (in front)
	}
}
