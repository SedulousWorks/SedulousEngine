using System;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.OpenDDL;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;

namespace Sedulous.Resources.Tests;

/// A sample resource representing game configuration data.
class GameConfigResource : Resource
{
	public String Title = new .() ~ delete _;
	public int32 ScreenWidth;
	public int32 ScreenHeight;
	public bool Fullscreen;
	public float MasterVolume;

	public override int32 SerializationVersion => 1;
	public override ResourceType ResourceType => .("gameconfig");

	protected override SerializationResult OnSerialize(Serializer s)
	{
		s.String("title", Title);
		s.Int32("screen_width", ref ScreenWidth);
		s.Int32("screen_height", ref ScreenHeight);
		s.Bool("fullscreen", ref Fullscreen);
		s.Float("master_volume", ref MasterVolume);
		return .Ok;
	}
}

class ResourceSample
{
	[Test]
	public static void TestSaveAndLoadResource()
	{
		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("test_resource.oddl");

		defer
		{
			// Cleanup
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		// Create a resource with test data
		let original = scope GameConfigResource();
		original.Name.Set("MyGameConfig");
		original.Title.Set("My Awesome Game");
		original.ScreenWidth = 1920;
		original.ScreenHeight = 1080;
		original.Fullscreen = true;
		original.MasterVolume = 0.75f;

		// Save to disk
		{
			let writer = OpenDDLSerializer.CreateWriter();
			defer delete writer;

			let result = original.Serialize(writer);
			Test.Assert(result == .Ok);

			let output = scope String();
			writer.GetOutput(output);

			// Write to file
			let writeResult = File.WriteAllText(tempPath, output);
			Test.Assert(writeResult == .Ok);
		}

		// Verify file exists
		Test.Assert(File.Exists(tempPath));

		// Read back from disk
		{
			let fileContent = scope String();
			let readResult = File.ReadAllText(tempPath, fileContent);
			Test.Assert(readResult == .Ok);

			// Parse OpenDDL
			let doc = scope DataDescription();
			let parseResult = doc.ParseText(fileContent);
			Test.Assert(parseResult == .Ok);

			// Deserialize
			let reader = OpenDDLSerializer.CreateReader(doc);
			defer delete reader;

			let loaded = scope GameConfigResource();
			let deserializeResult = loaded.Serialize(reader);
			Test.Assert(deserializeResult == .Ok);

			// Verify all data matches
			Test.Assert(loaded.Name == original.Name);
			Test.Assert(loaded.Title == original.Title);
			Test.Assert(loaded.ScreenWidth == original.ScreenWidth);
			Test.Assert(loaded.ScreenHeight == original.ScreenHeight);
			Test.Assert(loaded.Fullscreen == original.Fullscreen);
			Test.Assert(MathUtil.AreApproximatelyEqual(loaded.MasterVolume, original.MasterVolume));
		}
	}

	[Test]
	public static void TestResourceManagerRoundTrip()
	{
		let tempDir = scope String();
		Path.GetTempPath(tempDir);

		let resourcePath = scope String(tempDir);
		resourcePath.Append("game_config.oddl");

		defer
		{
			if (File.Exists(resourcePath))
				File.Delete(resourcePath);
		}

		// Create and save a resource manually first
		let original = scope GameConfigResource();
		original.Name.Set("TestConfig");
		original.Title.Set("Test Game");
		original.ScreenWidth = 2560;
		original.ScreenHeight = 1440;
		original.Fullscreen = false;
		original.MasterVolume = 0.5f;

		// Save to disk
		{
			let writer = OpenDDLSerializer.CreateWriter();
			defer delete writer;
			original.Serialize(writer);

			let output = scope String();
			writer.GetOutput(output);
			File.WriteAllText(resourcePath, output);
		}

		// Create a custom resource manager for GameConfigResource
		let manager = scope GameConfigResourceManager();

		// Load using the manager
		let loadResult = manager.Load(resourcePath);
		Test.Assert(loadResult case .Ok);

		var handle = loadResult.Value;
		defer { manager.Unload(ref handle); handle.Release(); }

		let loaded = (GameConfigResource)handle.Resource;
		Test.Assert(loaded != null);

		// Verify data
		Test.Assert(loaded.Name == original.Name);
		Test.Assert(loaded.Title == original.Title);
		Test.Assert(loaded.ScreenWidth == original.ScreenWidth);
		Test.Assert(loaded.ScreenHeight == original.ScreenHeight);
		Test.Assert(loaded.Fullscreen == original.Fullscreen);
	}
}

/// Resource manager for GameConfigResource.
class GameConfigResourceManager : ResourceManager<GameConfigResource>
{
	protected override Result<GameConfigResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		// Read content as string
		let content = scope String();
		let bytes = scope uint8[memory.Length];
		if (memory.TryRead(bytes) case .Err)
			return .Err(.ReadError);

		content.Append((char8*)bytes.Ptr, bytes.Count);

		// Parse OpenDDL
		let doc = scope DataDescription();
		if (doc.ParseText(content) != .Ok)
			return .Err(.InvalidFormat);

		// Deserialize
		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let resource = new GameConfigResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		resource.AddRef(); // Manager's ownership ref — released in Unload
		return .Ok(resource);
	}

	public override void Unload(GameConfigResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(GameConfigResource resource, StringView path)
	{
		let content = scope String();
		if (File.ReadAllText(path, content) case .Err)
			return .Err(.NotFound);

		let doc = scope DataDescription();
		if (doc.ParseText(content) != .Ok)
			return .Err(.InvalidFormat);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		resource.Serialize(reader);
		return .Ok;
	}
}
