using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Scene.Tests;

class SceneViewPrefsTests
{
	[Test]
	public static void ThePerSceneViewStateRoundTripsThroughTheSettingsStore()
	{
		SceneEditorSerializables.RegisterAll();
		let sceneA = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let sceneB = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);

		let store = scope Settings();
		// No entry yet: the caller's fallback (the page's current state) comes back untouched.
		let fb = SceneViewState(true, false);
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowGrid == true);
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowLodOverlay == false);

		// Upsert two scenes with different state; a nil guid or null store is a no-op.
		Test.Assert(SceneViewPrefs.Save(store, sceneA, .(false, true, true)));
		Test.Assert(SceneViewPrefs.Save(store, sceneB, .(true, false)));
		Test.Assert(!SceneViewPrefs.Save(store, Guid(), .(false, false)));
		Test.Assert(!SceneViewPrefs.Save(null, sceneA, .(false, false)));

		// Each scene keeps its OWN state; the fallback is ignored once saved.
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowGrid == false);
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowLodOverlay == true);
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowColliders == true);
		Test.Assert(SceneViewPrefs.Load(store, sceneB, fb).ShowGrid == true);
		Test.Assert(SceneViewPrefs.Load(store, sceneB, fb).ShowLodOverlay == false);

		// A second save of the same scene updates in place.
		Test.Assert(SceneViewPrefs.Save(store, sceneA, .(true, true)));
		Test.Assert(store.Section<SceneViewSettings>().Prefs.Count == 2);

		// Persist as XML, the file the app writes, and reload: the state survives.
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneA, fb).ShowGrid == true);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneA, fb).ShowLodOverlay == true);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneB, fb).ShowGrid == true);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneB, fb).ShowLodOverlay == false);
	}
}
