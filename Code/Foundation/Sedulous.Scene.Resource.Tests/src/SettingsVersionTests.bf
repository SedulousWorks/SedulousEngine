using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// A settings block's version bump: refused when the system keeps no reader for the old
/// layout, read at the new fields' defaults when it does.
class SettingsVersionTests
{
	/// The WorldSystem's block at version 2, which appends a fog density, and reads version 1.
	private class WorldSystemV2 : SceneSystem
	{
		public WorldSettings Settings = .();
		public float Fog = 0.25f;

		public override Type SettingsType => typeof(WorldSettings);
		public override void* SettingsInstance => &Settings;
		public override StringView SettingsId => "test.World";
		public override uint32 SettingsDataVersion => 2;
		public override uint32 SettingsMinReadDataVersion => 1;

		public override void SerializeSettings(ISerializer ar)
		{
			SerializeValue(ar, "gravity", ref Settings.Gravity);
			SerializeValue(ar, "wind", ref Settings.Wind);
			if ((ar.Mode == .Read) && (ar.Version == 1))
				return;
			SerializeValue(ar, "fog", ref Fog);
		}
	}

	/// The same bump with no reader for the layout before.
	private class WorldSystemV2Strict : WorldSystemV2
	{
		public override uint32 SettingsMinReadDataVersion => 0;
	}

	private static void WriteVersionOne(MemoryStream buffer)
	{
		let source = scope Scene("world");
		let world = source.AddSystem<WorldSystem>();
		world.Settings.Gravity = -3.5f;
		let writer = scope BinarySerializer(buffer, .Write);
		SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		Test.Assert(writer.IsOk);
		buffer.Seek(0, .Begin);
	}

	[Test]
	public static void ABlockWithALegacyReaderReadsTheVersionBefore()
	{
		let buffer = scope MemoryStream();
		WriteVersionOne(buffer);

		let target = scope Scene();
		let world = target.AddSystem<WorldSystemV2>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Binary);
		Test.Assert(reader.IsOk, "version 1 is still read");
		Test.Assert(world.Settings.Gravity == -3.5f);
		Test.Assert(world.Fog == 0.25f, "the new field keeps its default");
	}

	[Test]
	public static void ABlockWithoutOneRefusesIt()
	{
		let buffer = scope MemoryStream();
		WriteVersionOne(buffer);

		let target = scope Scene();
		let world = target.AddSystem<WorldSystemV2Strict>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Binary);
		Test.Assert(!reader.IsOk, "a stored version 1 is refused, as the text path refuses it");
		Test.Assert(world.Settings.Gravity == WorldSettings().Gravity, "and not read as a guess at the old layout");
	}
}
