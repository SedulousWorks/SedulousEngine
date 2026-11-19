using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.VFS;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;
using Sedulous.Engine.Run;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The quality levels a run offers its scripts and the player's saved choice: the project's
/// levels in its order (one that does not resolve left out), the starting level (the saved
/// choice while the project lists it, else the project's), and a choice kept in the user's
/// settings and read back as the next run's starting level, as the player does across runs.
class QualityLevelsTests
{
	[Test]
	public static void TheRunOffersTheProjectsLevelsAndStartsAtTheSavedChoiceKeptAcrossRuns()
	{
		QualityUserSettings.RegisterAll();
		let root = "scratch_defaultapp_quality_db";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);

		let serializables = scope SerializableRegistry();
		RenderProfileResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;
		let database = scope ContentDatabase(mount, serializers, "asset", serializables);
		Guid Write(StringView name, uint32 msaa)
		{
			let source = scope RenderQualitySource();
			source.Values.Label.Set(name);
			source.Values.MsaaSamples = msaa;
			let instance = database.RootGroup.CreateInstance(name, "Sedulous.Engine.Render.RenderQualitySource");
			Test.Assert(instance != null);
			Test.Assert(instance.WriteObject(source) case .Ok);
			return instance.Id;
		}
		let low = Write("Low", 1);
		let high = Write("High", 4);
		let factory = scope RenderQualityFactory();
		// Declared after the factory and the database, so it goes first.
		let resources = scope ResourceManager(database, null);
		resources.AddFactory(factory);

		let settings = scope ProjectSettings();
		let missing = Guid(0x71, 0x72, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		settings.QualityLevelIds.Add(low);
		settings.QualityLevelIds.Add(missing); // listed, but nothing resolves it
		settings.QualityLevelIds.Add(high);
		settings.DefaultQualityId = high;

		// The first run: no saved choice, so the project's default; the missing level not offered.
		let facade = scope RenderQualityFacade();
		Test.Assert(QualityLevels.Offer(facade, settings, resources, .()) == high);
		Test.Assert(facade.Count() == 2);
		Test.Assert(facade.Label(0) == "Low");
		Test.Assert(facade.Label(1) == "High");
		Test.Assert(facade.CurrentId == high);

		// The player's script picks Low: the choice is kept in the user's settings, which are
		// written to their file.
		let user = scope Settings();
		facade.SetOnChoose(new [&] (id) => { QualityLevels.Keep(user, id); });
		Test.Assert(facade.Set("Low"));
		Test.Assert(QualityLevels.Saved(user) == low);
		let xml = XmlSerializerFactory();
		defer delete xml;
		let file = scope MemoryStream();
		Test.Assert(user.Save(file, xml) case .Ok);

		// The next run reads the file back and starts at the saved choice.
		let read = scope Settings();
		file.Seek(0, .Begin);
		Test.Assert(read.Load(file, xml) case .Ok);
		let next = scope RenderQualityFacade();
		Test.Assert(QualityLevels.Offer(next, settings, resources, QualityLevels.Saved(read)) == low);
		Test.Assert(next.CurrentId == low);

		// A saved level the project no longer lists is ignored for the project's default; a
		// project whose starting level does not resolve starts at the engine's own (nil).
		settings.QualityLevelIds.Clear();
		settings.QualityLevelIds.Add(high);
		Test.Assert(QualityLevels.Offer(next, settings, resources, low) == high);
		settings.QualityLevelIds[0] = missing;
		settings.DefaultQualityId = missing;
		Test.Assert(QualityLevels.Offer(next, settings, resources, .()) == Guid());
		Test.Assert(next.Count() == 0);
	}
}
