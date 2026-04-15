using System;
using System.IO;
using System.Threading;
using System.Collections;
using Sedulous.OpenDDL;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;

namespace Sedulous.Resources.Tests;

class HotReloadTests
{
	/// Helper: save a GameConfigResource to an OpenDDL file.
	private static void SaveConfig(GameConfigResource config, StringView path)
	{
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		config.Serialize(writer);

		let output = scope String();
		writer.GetOutput(output);
		File.WriteAllText(path, output);
	}

	[Test]
	public static void TestReserializeIntoExistingResource()
	{
		// Create and serialize a resource
		let original = scope GameConfigResource();
		original.Name.Set("Config");
		original.Title.Set("Game A");
		original.ScreenWidth = 800;
		original.ScreenHeight = 600;

		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;
		original.Serialize(writer);

		let text1 = scope String();
		writer.GetOutput(text1);

		// Now create a "modified" version serialized text
		let modified = scope GameConfigResource();
		modified.Name.Set("Config");
		modified.Title.Set("Game B");
		modified.ScreenWidth = 1920;
		modified.ScreenHeight = 1080;

		let writer2 = OpenDDLSerializer.CreateWriter();
		defer delete writer2;
		modified.Serialize(writer2);

		let text2 = scope String();
		writer2.GetOutput(text2);

		// Re-serialize from modified text into existing instance
		let doc = scope DataDescription();
		Test.Assert(doc.ParseText(text2) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let target = scope GameConfigResource();
		target.Name.Set("Config");
		target.Title.Set("Game A");
		target.ScreenWidth = 800;

		target.Serialize(reader);

		// Verify updated values
		Test.Assert(target.Title == "Game B");
		Test.Assert(target.ScreenWidth == 1920);
		Test.Assert(target.ScreenHeight == 1080);
	}

	[Test]
	public static void TestResourceManagerReload()
	{
		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("hotreload_manager_test.oddl");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		// Save initial config
		let config = scope GameConfigResource();
		config.Name.Set("TestConfig");
		config.Title.Set("Original");
		config.ScreenWidth = 640;
		SaveConfig(config, tempPath);

		// Load via manager
		let manager = scope GameConfigResourceManager();
		let loadResult = manager.Load(tempPath);
		Test.Assert(loadResult case .Ok);

		var handle = loadResult.Value;
		defer { manager.Unload(ref handle); handle.Release(); }
		let loaded = (GameConfigResource)handle.Resource;

		Test.Assert(loaded.Title == "Original");
		Test.Assert(loaded.ScreenWidth == 640);

		// Modify file on disk
		let config2 = scope GameConfigResource();
		config2.Name.Set("TestConfig");
		config2.Title.Set("Reloaded");
		config2.ScreenWidth = 1920;
		SaveConfig(config2, tempPath);

		// Reload in-place
		let reloadResult = manager.ReloadFromFile(loaded, tempPath);
		Test.Assert(reloadResult case .Ok);

		// Verify same instance, updated data
		Test.Assert(loaded.Title == "Reloaded");
		Test.Assert(loaded.ScreenWidth == 1920);
	}

	[Test]
	public static void TestResourceSystemHotReload()
	{
		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("hotreload_system_test.oddl");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		// Save initial config
		let config = scope GameConfigResource();
		config.Name.Set("SysConfig");
		config.Title.Set("Before");
		config.ScreenWidth = 100;
		SaveConfig(config, tempPath);

		// Set up ResourceSystem
		let manager = scope GameConfigResourceManager();
		let system = scope ResourceSystem(null);
		system.AddResourceManager(manager);
		system.EnableHotReload(0.0); // No poll delay

		// Load resource
		let loadResult = system.LoadResource<GameConfigResource>(tempPath);
		Test.Assert(loadResult case .Ok);
		var loadHandle = loadResult.Value;
		defer loadHandle.Release();
		let loaded = loadHandle.Resource;

		Test.Assert(loaded.Title == "Before");

		// Set up listener
		let listener = scope TestChangeListener();
		system.AddChangeListener(listener);

		// Initial poll to establish baseline timestamps
		system.Update();

		// Modify file
		Thread.Sleep(50);
		let config2 = scope GameConfigResource();
		config2.Name.Set("SysConfig");
		config2.Title.Set("After");
		config2.ScreenWidth = 999;
		SaveConfig(config2, tempPath);

		// Poll for changes
		system.Update();

		// Verify listener was called
		Test.Assert(listener.ReloadCount == 1);
		Test.Assert(listener.LastPath == tempPath);

		// Verify resource data updated
		Test.Assert(loaded.Title == "After");
		Test.Assert(loaded.ScreenWidth == 999);
	}

	[Test]
	public static void TestHandlesSeeSameDataAfterReload()
	{
		let tempPath = scope String();
		Path.GetTempPath(tempPath);
		tempPath.Append("hotreload_handles_test.oddl");

		defer
		{
			if (File.Exists(tempPath))
				File.Delete(tempPath);
		}

		// Save initial config
		let config = scope GameConfigResource();
		config.Name.Set("HandleTest");
		config.Title.Set("V1");
		SaveConfig(config, tempPath);

		// Set up ResourceSystem
		let manager = scope GameConfigResourceManager();
		let system = scope ResourceSystem(null);
		system.AddResourceManager(manager);

		// Load resource — get two handles to same path
		var h1Result = system.LoadResource<GameConfigResource>(tempPath);
		Test.Assert(h1Result case .Ok);
		var h1 = h1Result.Value;
		defer h1.Release();

		// Loading same path again should return cached instance
		var h2Result = system.LoadResource<GameConfigResource>(tempPath);
		Test.Assert(h2Result case .Ok);
		var h2 = h2Result.Value;
		defer h2.Release();

		let res1 = h1.Resource;
		let res2 = h2.Resource;

		// Both point to same instance
		Test.Assert(res1 === res2);
		Test.Assert(res1.Title == "V1");

		// Modify file and reload via manager
		let config2 = scope GameConfigResource();
		config2.Name.Set("HandleTest");
		config2.Title.Set("V2");
		SaveConfig(config2, tempPath);

		let reloadResult = manager.ReloadFromFile(res1, tempPath);
		Test.Assert(reloadResult case .Ok);

		// Both handles see updated data (same underlying object)
		Test.Assert(res1.Title == "V2");
		Test.Assert(res2.Title == "V2");
	}
}

/// Test helper that records change notifications.
class TestChangeListener : IResourceChangeListener
{
	public int ReloadCount = 0;
	public String LastPath = new .() ~ delete _;
	public Type LastType;

	public void OnResourceReloaded(StringView path, Type resourceType, IResource resource)
	{
		ReloadCount++;
		LastPath.Set(path);
		LastType = resourceType;
	}
}
