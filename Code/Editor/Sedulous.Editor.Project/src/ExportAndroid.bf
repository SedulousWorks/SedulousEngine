using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The Android export: the template carries the player as the library the app loads and the app's
/// Gradle project (android/, SDL's Java glue in android/sdl-java/); the export copies the project
/// into the project's cache, stages what the app carries beside it (the player as libmain.so, the
/// content and the engine's data as assets, the icon as a resource), runs the project's Gradle
/// wrapper with the preset's values and copies the APK or bundle out.
static class ExportAndroid
{
	/// The template's folder that holds the app's Gradle project.
	public const String cTemplateProject = "android/";
	public const String cStorePasswordVariable = "ANDROID_KEYSTORE_PASSWORD";
	public const String cKeyPasswordVariable = "ANDROID_KEY_PASSWORD";

	/// Whether `platform` is Android's: its export builds an app around the player.
	public static bool IsAndroidPlatform(StringView platform) => platform == BuildLayout.cAndroidPlatform;

	/// Where an Android preset's app is made, kept between exports: <project>/.cache/android/<preset>.
	public static void WorkDir(EditorProject project, ExportPreset preset, String outDir)
	{
		let name = ExportStaging.SanitizeName(preset.Name, .. scope .());
		PathJoin(project.Directory, scope $"{ProjectLayout.CacheDir}/android/{name}", outDir);
	}

	/// Why an Android preset cannot export, appended to `outWhy`, or true when it can: its
	/// application id, its icon, its keystore (there, with its key's alias and its password in
	/// ANDROID_KEYSTORE_PASSWORD), the Android SDK (ANDROID_HOME) Gradle needs, and, given one, a
	/// template carrying the app's project. Checked before anything is cooked.
	public static bool CheckExport(EditorProject project, ExportPreset preset, ExportTemplate template, String outWhy)
	{
		if (!ExportPreset.CheckAndroidApplicationId(preset.AndroidApplicationId, outWhy))
			return false;
		if (!preset.AndroidIcon.IsEmpty)
		{
			if (!preset.AndroidIcon.EndsWith(".png"))
			{
				outWhy.AppendF("the app icon '{}' is not a PNG", preset.AndroidIcon);
				return false;
			}
			if (!FileExists(PathJoin(project.Directory, preset.AndroidIcon, .. scope .())))
			{
				outWhy.AppendF("the app icon '{}' is not in the project", preset.AndroidIcon);
				return false;
			}
		}
		if (!preset.AndroidKeystore.IsEmpty)
		{
			if (!FileExists(PathJoin(project.Directory, preset.AndroidKeystore, .. scope .())))
			{
				outWhy.AppendF("the keystore '{}' is not there", preset.AndroidKeystore);
				return false;
			}
			if (preset.AndroidKeyAlias.IsEmpty)
			{
				outWhy.Append("a keystore needs the alias of the key that signs");
				return false;
			}
			let password = scope String();
			if ((Environment.GetEnvironmentVariable(cStorePasswordVariable, password) case .Err) || password.IsEmpty)
			{
				outWhy.AppendF("the keystore's password is not given: set {} (and {} when the key's own differs)",
					cStorePasswordVariable, cKeyPasswordVariable);
				return false;
			}
		}
		let sdk = scope String();
		if ((Environment.GetEnvironmentVariable("ANDROID_HOME", sdk) case .Err) || sdk.IsEmpty || !DirectoryExists(sdk))
		{
			outWhy.Append("an Android export runs Gradle, which needs the Android SDK: set ANDROID_HOME to it");
			return false;
		}
		if (template != null)
		{
			bool hasProject = false;
			for (let sidecar in template.Sidecars)
				hasProject |= sidecar.StartsWith(cTemplateProject);
			if (!hasProject)
			{
				outWhy.AppendF("template '{}' carries no Android app project", template.Id);
				return false;
			}
		}
		return true;
	}

	/// Readies the app's build in `workDir`: the template's Gradle project in project/, and in
	/// staged/ what the app carries: the player as jniLibs/arm64-v8a/libmain.so, the exported game
	/// (`contentDir`: its packs and player.xml) in assets/Game, its shader pack and the engine's
	/// other data (from `dataRoot`) in assets/Data, the template's notices in assets, and the
	/// preset's icon as res/mipmap-xxxhdpi/ic_launcher.png.
	public static Result<void, ErrorCode> StageApp(EditorProject project, ExportPreset preset, ExportTemplate template,
		StringView contentDir, StringView dataRoot, StringView workDir)
	{
		let gradleProject = PathJoin(workDir, "project", .. scope .());
		let staged = PathJoin(workDir, "staged", .. scope .());
		let assets = PathJoin(staged, "assets", .. scope .());
		// What the last export staged goes; the project and Gradle's outputs stay, for its next build.
		for (let folder in StringView[3]("jniLibs", "assets", "res"))
		{
			let old = PathJoin(staged, folder, .. scope .());
			if (DirectoryExists(old))
				RemoveDirectoryRecursive(old);
		}

		// The app's Gradle project, from the template.
		for (let sidecar in template.Sidecars)
		{
			if (!sidecar.StartsWith(cTemplateProject))
				continue;
			if (!ExportTemplates.CopyFile(template.Directory, sidecar, gradleProject, StringView(sidecar, cTemplateProject.Length)))
			{
				GlobalLog(.Error, "Export: the Android project's '{}' did not copy from template '{}'", sidecar, template.Id);
				return .Err(.NotFound);
			}
		}

		// The player, as the library the app's activity loads.
		if (!ExportTemplates.CopyFile(template.Directory, template.PlayerBinary, PathJoin(staged, "jniLibs/arm64-v8a", .. scope .()), "libmain.so"))
			return .Err(.NotFound);

		// The game (its packs and player.xml) in assets/Game; the shader pack the content export
		// staged and the engine's other data in assets/Data, where the player reads them in place.
		let game = PathJoin(assets, "Game", .. scope .());
		if (!CopyTree(contentDir, game, "Data") ||
			!CopyTree(PathJoin(contentDir, "Data", .. scope .()), PathJoin(assets, "Data", .. scope .())) ||
			!CopyTree(PathJoin(dataRoot, "Engine", .. scope .()), PathJoin(assets, "Data/Engine", .. scope .()), "Shaders"))
		{
			GlobalLog(.Error, "Export: the app's assets did not stage under '{}'", assets);
			return .Err(.Internal);
		}
		DeleteFile(PathJoin(game, "export-report.txt", .. scope .())); // the report stays beside the dist
		for (let sidecar in template.Sidecars)
		{
			// The notices, which every app carries.
			if (!sidecar.StartsWith(cTemplateProject) && !ExportTemplates.CopyFile(template.Directory, sidecar, assets, sidecar))
				return .Err(.NotFound);
		}

		// The launcher icon.
		if (!preset.AndroidIcon.IsEmpty &&
			!ExportTemplates.CopyFile(project.Directory, preset.AndroidIcon, PathJoin(staged, "res/mipmap-xxxhdpi", .. scope .()), "ic_launcher.png"))
			return .Err(.NotFound);
		return .Ok;
	}

	/// The Gradle wrapper's arguments for the app staged in `workDir`: its project, the preset's
	/// values as properties (id, version, name, orientation, keystore and alias) and the tasks its
	/// package asks for, Debug for a Debug template and Release otherwise.
	public static void GradleArguments(EditorProject project, ExportPreset preset, ExportTemplate template, StringView workDir,
		List<String> outArguments)
	{
		let variant = (template.Config == "Debug") ? "Debug" : "Release";
		outArguments.Add(new .("-p"));
		outArguments.Add(PathJoin(workDir, "project", .. new .()));
		outArguments.Add(new .("--no-daemon")); // an export leaves no Gradle running
		outArguments.Add(new .("--quiet"));
		outArguments.Add(new $"-PsedulousStaged={PathJoin(workDir, "staged", .. scope .())}");
		outArguments.Add(new $"-PsedulousApplicationId={preset.AndroidApplicationId}");
		outArguments.Add(new $"-PsedulousVersionCode={preset.AndroidVersionCode}");
		outArguments.Add(new $"-PsedulousVersionName={preset.AndroidVersionName}");
		outArguments.Add(new $"-PsedulousLabel={preset.AndroidLabel.IsEmpty ? StringView(project.Settings.Name) : StringView(preset.AndroidLabel)}");
		outArguments.Add(new $"-PsedulousOrientation={ScreenOrientationOf(project, preset)}");
		if (!preset.AndroidKeystore.IsEmpty)
		{
			outArguments.Add(new $"-PsedulousKeystore={PathJoin(project.Directory, preset.AndroidKeystore, .. scope .())}");
			outArguments.Add(new $"-PsedulousKeyAlias={preset.AndroidKeyAlias}");
		}
		if (preset.AndroidPackage != .Bundle)
			outArguments.Add(new $"assemble{variant}");
		if (preset.AndroidPackage != .Apk)
			outArguments.Add(new $"bundle{variant}");
	}

	/// Runs the Gradle wrapper over the app StageApp readied and copies the APK and/or bundle to
	/// `outputDir` as <name>.apk / <name>.aab (the preset's player name, else the project's).
	public static Result<void, ErrorCode> BuildApp(EditorProject project, ExportPreset preset, ExportTemplate template,
		StringView workDir, StringView outputDir, ExportResult result)
	{
		let arguments = scope List<String>();
		defer { ClearAndDeleteItems!(arguments); }
		GradleArguments(project, preset, template, workDir, arguments);
		let views = scope List<StringView>();
		for (let argument in arguments)
			views.Add(argument);
#if BF_PLATFORM_WINDOWS
		let wrapper = PathJoin(workDir, "project/gradlew.bat", .. scope .());
#else
		let wrapper = PathJoin(workDir, "project/gradlew", .. scope .());
#endif
		let built = scope ProcessResult();
		Process.Run(wrapper, views, built);
		if (built.ExitCode != 0)
		{
			GlobalLog(.Error, "Export: the Android app's Gradle build failed ({}); it needs a JDK 17 (JAVA_HOME or java on the PATH) and, the first time, the network:\n{}",
				built.ExitCode, built.Output);
			result.Refusal.Set("the Android app's Gradle build failed (the log has its output)");
			return .Err(.Internal);
		}

		// Gradle's outputs, under the staged folder (the project's build.gradle puts them there).
		let variant = (template.Config == "Debug") ? "debug" : "release";
		let outputs = PathJoin(workDir, "staged/gradle/app/outputs", .. scope .());
		let name = AppName(project, preset, .. scope .());
		if (preset.AndroidPackage != .Bundle)
		{
			if (!ExportTemplates.CopyFile(outputs, scope $"apk/{variant}/app-{variant}.apk", outputDir, scope $"{name}.apk"))
			{
				GlobalLog(.Error, "Export: Gradle made no APK under '{}'", outputs);
				return .Err(.NotFound);
			}
			result.FilesStaged++;
		}
		if (preset.AndroidPackage != .Apk)
		{
			if (!ExportTemplates.CopyFile(outputs, scope $"bundle/{variant}/app-{variant}.aab", outputDir, scope $"{name}.aab"))
			{
				GlobalLog(.Error, "Export: Gradle made no bundle under '{}'", outputs);
				return .Err(.NotFound);
			}
			result.FilesStaged++;
		}
		return .Ok;
	}

	/// android:screenOrientation for how the game is held: the preset's own, else the project's.
	public static StringView ScreenOrientationOf(EditorProject project, ExportPreset preset)
	{
		let held = preset.OverridesOrientation ? preset.Orientation : project.Settings.Orientation;
		switch (held)
		{
		case .Landscape: return "userLandscape";
		case .Portrait: return "userPortrait";
		default: return "fullUser"; // Any: as the phone is held
		}
	}

	/// The file name the app's APK or bundle takes in the dist: the preset's player name, else
	/// the project's, without what a desktop player's name carries.
	public static void AppName(EditorProject project, ExportPreset preset, String outName)
	{
		ExportStaging.SanitizeName(preset.PlayerName.IsEmpty ? StringView(project.Settings.Name) : StringView(preset.PlayerName), outName);
	}

	/// Copies every file under `from` to `to`, folders made as needed, leaving out the top-level
	/// folder `skip` (empty: none). False when a file does not copy.
	private static bool CopyTree(StringView from, StringView to, StringView skip = default)
	{
		if (!DirectoryExists(from) || !CreateDirectory(to))
			return false;
		let files = scope List<String>();
		let folders = scope List<String>();
		defer { ClearAndDeleteItems!(files); ClearAndDeleteItems!(folders); }
		ListDirectory(from, scope [&](name, isDirectory) =>
			{
				if (!skip.IsEmpty && (name == skip))
					return;
				(isDirectory ? folders : files).Add(new String(name));
			});
		for (let file in files)
		{
			if (!ExportTemplates.CopyFile(from, file, to, file))
				return false;
		}
		for (let folder in folders)
		{
			if (!CopyTree(PathJoin(from, folder, .. scope .()), PathJoin(to, folder, .. scope .())))
				return false;
		}
		return true;
	}
}
