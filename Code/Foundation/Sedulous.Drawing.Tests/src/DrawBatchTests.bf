using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.Drawing.Tests;

class DrawBatchTests
{
	[Test]
	public static void New_IsEmpty()
	{
		let batch = scope DrawBatch();

		Test.Assert(batch.IsEmpty);
		Test.Assert(batch.VertexCount == 0);
		Test.Assert(batch.IndexCount == 0);
		Test.Assert(batch.CommandCount == 0);
	}

	[Test]
	public static void AddVertex_IncreasesCount()
	{
		let batch = scope DrawBatch();
		batch.Vertices.Add(.(0, 0, 0, 0, Color.White));

		Test.Assert(batch.VertexCount == 1);
	}

	[Test]
	public static void AddIndex_IncreasesCount()
	{
		let batch = scope DrawBatch();
		batch.Indices.Add(0);
		batch.Indices.Add(1);
		batch.Indices.Add(2);

		Test.Assert(batch.IndexCount == 3);
	}

	[Test]
	public static void AddCommand_IncreasesCount()
	{
		let batch = scope DrawBatch();
		batch.Commands.Add(.());

		Test.Assert(batch.CommandCount == 1);
	}

	[Test]
	public static void Clear_ResetsAllCounts()
	{
		let batch = scope DrawBatch();
		batch.Vertices.Add(.(0, 0, 0, 0, Color.White));
		batch.Indices.Add(0);
		batch.Commands.Add(.());

		batch.Clear();

		Test.Assert(batch.IsEmpty);
		Test.Assert(batch.VertexCount == 0);
		Test.Assert(batch.IndexCount == 0);
		Test.Assert(batch.CommandCount == 0);
	}

	[Test]
	public static void GetVertexData_ReturnsSpan()
	{
		let batch = scope DrawBatch();
		batch.Vertices.Add(.(10, 20, 0, 0, Color.Red));
		batch.Vertices.Add(.(30, 40, 0, 0, Color.Blue));

		let span = batch.GetVertexData();

		Test.Assert(span.Length == 2);
		Test.Assert(span[0].Position.X == 10);
		Test.Assert(span[1].Position.X == 30);
	}

	[Test]
	public static void GetIndexData_ReturnsSpan()
	{
		let batch = scope DrawBatch();
		batch.Indices.Add(0);
		batch.Indices.Add(1);
		batch.Indices.Add(2);

		let span = batch.GetIndexData();

		Test.Assert(span.Length == 3);
		Test.Assert(span[0] == 0);
		Test.Assert(span[1] == 1);
		Test.Assert(span[2] == 2);
	}

	[Test]
	public static void GetCommand_ReturnsCorrectCommand()
	{
		let batch = scope DrawBatch();
		var cmd = DrawCommand();
		cmd.TextureIndex = 5;
		cmd.IndexCount = 6;
		batch.Commands.Add(cmd);

		let retrieved = batch.GetCommand(0);

		Test.Assert(retrieved.TextureIndex == 5);
		Test.Assert(retrieved.IndexCount == 6);
	}

	[Test]
	public static void Reserve_IncreasesCapacity()
	{
		let batch = scope DrawBatch();

		batch.Reserve(1000, 3000, 50);

		Test.Assert(batch.Vertices.Capacity >= 1000);
		Test.Assert(batch.Indices.Capacity >= 3000);
		Test.Assert(batch.Commands.Capacity >= 50);
	}
}
