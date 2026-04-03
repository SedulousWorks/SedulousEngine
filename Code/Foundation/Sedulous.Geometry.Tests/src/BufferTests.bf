using System;
using Sedulous.Geometry;
using Sedulous.Core.Mathematics;

namespace Sedulous.Geometry.Tests;

class BufferTests
{
	[Test]
	public static void TestVertexBufferCreation()
	{
		let buffer = new VertexBuffer(48);
		defer delete buffer;

		Test.Assert(buffer.VertexSize == 48);
		Test.Assert(buffer.VertexCount == 0);
	}

	[Test]
	public static void TestVertexBufferResize()
	{
		let buffer = new VertexBuffer(12);
		defer delete buffer;

		buffer.Resize(100);
		Test.Assert(buffer.VertexCount == 100);
	}

	[Test]
	public static void TestVertexBufferData()
	{
		let buffer = new VertexBuffer(sizeof(Vector3));
		defer delete buffer;

		buffer.Resize(2);
		buffer.SetVertexData<Vector3>(0, 0, Vector3(1, 2, 3));
		buffer.SetVertexData<Vector3>(1, 0, Vector3(4, 5, 6));

		let v0 = buffer.GetVertexData<Vector3>(0, 0);
		let v1 = buffer.GetVertexData<Vector3>(1, 0);

		Test.Assert(v0.X == 1 && v0.Y == 2 && v0.Z == 3);
		Test.Assert(v1.X == 4 && v1.Y == 5 && v1.Z == 6);
	}

	[Test]
	public static void TestVertexBufferAttributes()
	{
		let buffer = new VertexBuffer(24);
		defer delete buffer;

		buffer.AddAttribute("position", .Vec3, 0, 12);
		buffer.AddAttribute("normal", .Vec3, 12, 12);

		Test.Assert(buffer.Attributes.Count == 2);
		Test.Assert(buffer.Attributes[0].name == "position");
		Test.Assert(buffer.Attributes[1].offset == 12);
	}

	[Test]
	public static void TestIndexBufferUInt16()
	{
		let buffer = new IndexBuffer(.UInt16);
		defer delete buffer;

		Test.Assert(buffer.Format == .UInt16);
		Test.Assert(buffer.GetIndexSize() == 2);

		buffer.Resize(6);
		buffer.SetIndex(0, 0);
		buffer.SetIndex(1, 1);
		buffer.SetIndex(2, 2);

		Test.Assert(buffer.GetIndex(0) == 0);
		Test.Assert(buffer.GetIndex(1) == 1);
		Test.Assert(buffer.GetIndex(2) == 2);
	}

	[Test]
	public static void TestIndexBufferUInt32()
	{
		let buffer = new IndexBuffer(.UInt32);
		defer delete buffer;

		Test.Assert(buffer.Format == .UInt32);
		Test.Assert(buffer.GetIndexSize() == 4);

		buffer.Resize(3);
		buffer.SetIndex(0, 100000);

		Test.Assert(buffer.GetIndex(0) == 100000);
	}

	[Test]
	public static void TestIndexBufferDataSize()
	{
		let buffer16 = new IndexBuffer(.UInt16);
		defer delete buffer16;
		buffer16.Resize(100);
		Test.Assert(buffer16.GetDataSize() == 200);

		let buffer32 = new IndexBuffer(.UInt32);
		defer delete buffer32;
		buffer32.Resize(100);
		Test.Assert(buffer32.GetDataSize() == 400);
	}
}
