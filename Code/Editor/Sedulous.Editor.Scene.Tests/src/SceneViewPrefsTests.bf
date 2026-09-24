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

	[Test]
	public static void TheCameraAndSelectionRoundTripAndLeaveTheTogglesAlone()
	{
		SceneEditorSerializables.RegisterAll();
		let scene = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
		let entityA = Guid(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8);
		let entityB = Guid(9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10);

		let store = scope Settings();
		// Nothing saved: no entry at all, so the page keeps its default framing.
		Test.Assert(SceneViewPrefs.Find(store, scene) == null);
		Test.Assert(!SceneViewPrefs.SaveView(null, scene, .(), Span<Guid>()));
		Test.Assert(!SceneViewPrefs.SaveView(store, Guid(), .(), Span<Guid>()));

		Test.Assert(SceneViewPrefs.Save(store, scene, .(false, true, true)));
		// An entry with toggles but no camera still reads as unframed.
		Test.Assert(!SceneViewPrefs.Find(store, scene).HasCamera);

		Guid[2] selection = .(entityA, entityB);
		Test.Assert(SceneViewPrefs.SaveView(store, scene, .(.(1.0f, 2.0f, 3.0f), 0.5f, -0.25f, 7.5f),
			.(&selection[0], selection.Count)));

		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);

		let pref = SceneViewPrefs.Find(loaded, scene);
		Test.Assert(pref != null);
		Test.Assert(pref.HasCamera);
		Test.Assert(pref.Camera.Position == Float3(1.0f, 2.0f, 3.0f));
		Test.Assert(pref.Camera.Yaw == 0.5f);
		Test.Assert(pref.Camera.Pitch == -0.25f);
		Test.Assert(pref.Camera.FocusDistance == 7.5f);
		Test.Assert(pref.Selection.Count == 2);
		Test.Assert(pref.Selection[0] == entityA);
		Test.Assert(pref.Selection[1] == entityB);
		// Saving the view never resurrects a toggle default, and the toggles never clear it.
		Test.Assert(!pref.ShowGrid && pref.ShowLodOverlay && pref.ShowColliders);
		Test.Assert(SceneViewPrefs.Save(loaded, scene, .(true, false, false)));
		Test.Assert(SceneViewPrefs.Find(loaded, scene).HasCamera);
		Test.Assert(SceneViewPrefs.Find(loaded, scene).Selection.Count == 2);
	}

	/// The entity origin crosses: on by default, and an off choice survives per scene while
	/// its siblings stay put.
	[Test]
	public static void TheMarkerToggleDefaultsOnAndSurvivesPerScene()
	{
		SceneEditorSerializables.RegisterAll();
		let sceneA = Guid(11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12);
		let sceneB = Guid(13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14);
		let fb = SceneViewState();
		Test.Assert(fb.ShowMarkers);

		let store = scope Settings();
		Test.Assert(SceneViewPrefs.Load(store, sceneA, fb).ShowMarkers);
		Test.Assert(SceneViewPrefs.Save(store, sceneA, .(true, true, true, false)));
		Test.Assert(SceneViewPrefs.Save(store, sceneB, .(true, false)));

		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);

		Test.Assert(!SceneViewPrefs.Load(loaded, sceneA, fb).ShowMarkers);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneA, fb).ShowColliders);
		Test.Assert(SceneViewPrefs.Load(loaded, sceneB, fb).ShowMarkers); // untouched: the default
	}

	/// The frame rate readout: off by default, round tripping per scene beside its siblings.
	[Test]
	public static void TheFpsToggleDefaultsOffAndSurvivesPerScene()
	{
		SceneEditorSerializables.RegisterAll();
		let sceneA = Guid(15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16);
		let sceneB = Guid(17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18);
		let fb = SceneViewState();
		Test.Assert(!fb.ShowFps);

		let store = scope Settings();
		Test.Assert(SceneViewPrefs.Save(store, sceneA, .(true, true, true, false, true)));
		Test.Assert(SceneViewPrefs.Save(store, sceneB, .(true, false)));

		let buffer = scope MemoryStream();
		let factory = XmlSerializerFactory();
		defer delete factory;
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);

		Test.Assert(SceneViewPrefs.Load(loaded, sceneA, fb).ShowFps);
		Test.Assert(!SceneViewPrefs.Load(loaded, sceneA, fb).ShowMarkers); // siblings intact
		Test.Assert(!SceneViewPrefs.Load(loaded, sceneB, fb).ShowFps);
	}

	/// The readout itself: a window with no frames says so rather than dividing by nought.
	[Test]
	public static void TheFrameRateTextReadsTheWindowsRateAndMeanFrameTime()
	{
		let text = scope String();
		FrameRateOverlay.Text(0.0, 0, text);
		Test.Assert(text == "-- fps");
		FrameRateOverlay.Text(0.5, 0, text);
		Test.Assert(text == "-- fps");
		FrameRateOverlay.Text(0.5, 30, text);
		Test.Assert(text == "60 fps  16.7 ms");
		FrameRateOverlay.Text(1.0, 144, text);
		Test.Assert(text == "144 fps  6.9 ms");
		FrameRateOverlay.Text(0.5, 12, text);
		Test.Assert(text == "24 fps  41.7 ms");
	}
}
