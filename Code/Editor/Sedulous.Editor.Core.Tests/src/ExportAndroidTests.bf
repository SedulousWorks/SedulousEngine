using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The Android export: a preset checked before anything cooks, the app staged for Gradle with the
/// preset's values, and the whole export through a stand-in for the template's Gradle wrapper.
static class ExportAndroidTests
{
	/// An environment variable set for a scope and put back after it.
	class ScopedVariable
	{
		private String mName = new .() ~ delete _;
		private String mWas = new .() ~ delete _;
		private bool mHad;

		public this(StringView name, StringView value)
		{
			mName.Set(name);
			mHad = Environment.GetEnvironmentVariable(name, mWas) case .Ok;
			Environment.SetEnvironmentVariable(name, value);
		}

		public ~this()
		{
			// Empty, not a default view: Beef hands a null pointer to setenv, which faults.
			Environment.SetEnvironmentVariable(mName, mHad ? StringView(mWas) : "");
		}
	}

	private static void SaveText(StringView dir, StringView name, StringView text)
	{
		let path = PathJoin(dir, name, .. scope .());
		CreateDirectory(PathParent(path, .. scope .()));
		WriteFile(path, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	/// An Android template on disk: the player library, the notices and a Gradle project whose
	/// wrapper (`gradlew`, the given script) stands in for Gradle.
	private static void FakeTemplate(ExportTemplate template, StringView dir, StringView config, StringView gradlew)
	{
		RemoveDirectoryRecursive(dir);
		SaveText(dir, "libmain.so", "ELF");
		SaveText(dir, BuildLayout.cThirdPartyNotices, "notices");
		SaveText(dir, "android/settings.gradle", "// settings");
		SaveText(dir, "android/app/build.gradle", "// app");
		SaveText(dir, "android/gradlew", gradlew);
		template.Id.Set("android-test");
		template.Platform.Set("Android64");
		template.Config.Set(config);
		template.PlayerBinary.Set("libmain.so");
		template.Directory.Set(dir);
		ClearAndDeleteItems(template.Sidecars);
		for (let sidecar in StringView[4](BuildLayout.cThirdPartyNotices, "android/settings.gradle", "android/app/build.gradle", "android/gradlew"))
			template.Sidecars.Add(new String(sidecar));
		Test.Assert(ExportTemplates.SaveManifest(scope NativeFileSystem(dir), template) case .Ok);
	}

	private static bool Has(List<String> arguments, StringView argument)
	{
		for (let given in arguments)
		{
			if (given == argument)
				return true;
		}
		return false;
	}

	[Test]
	public static void AnAndroidPresetIsCheckedBeforeAnythingCooks()
	{
		let fx = scope ExportProjectFixture("scratch_android_check");
		let sdk = Scratch("scratch_android_check_sdk", .. scope .());
		defer RemoveDirectoryRecursive(sdk);
		CreateDirectory(sdk);
		let home = scope ScopedVariable("ANDROID_HOME", sdk);
		let password = scope ScopedVariable(ExportAndroid.cStorePasswordVariable, "");

		let preset = scope ExportPreset();
		preset.Name.Set("Android");
		preset.Platform.Set("Android64");
		let why = scope String();
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why) && why.Contains("application id"));
		preset.AndroidApplicationId.Set("com.studio.game");
		Test.Assert(ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()), why);

		preset.AndroidIcon.Set("icon.jpg");
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains("not a PNG"));
		preset.AndroidIcon.Set("icon.png");
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains("not in the project"));
		SaveText(fx.ProjectDir, "icon.png", "png");
		Test.Assert(ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()), why);

		// A keystore: there, with its key's alias, and its password in the environment.
		preset.AndroidKeystore.Set("release.jks");
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains("is not there"));
		SaveText(fx.ProjectDir, "release.jks", "keys");
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains("alias"));
		preset.AndroidKeyAlias.Set("upload");
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains(ExportAndroid.cStorePasswordVariable));
		{
			let given = scope ScopedVariable(ExportAndroid.cStorePasswordVariable, "secret");
			Test.Assert(ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()), why);
		}
		preset.AndroidKeystore.Clear();

		// The SDK Gradle needs.
		{
			let none = scope ScopedVariable("ANDROID_HOME", PathJoin(sdk, "missing", .. scope .()));
			Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, null, why..Clear()) && why.Contains("ANDROID_HOME"));
		}

		// A template carrying no app project.
		let bare = scope ExportTemplate();
		bare.Id.Set("bare");
		bare.Sidecars.Add(new String(BuildLayout.cThirdPartyNotices));
		Test.Assert(!ExportAndroid.CheckExport(fx.Project, preset, bare, why..Clear()) && why.Contains("no Android app project"));

		// ExportOne refuses such a preset before it cooks: no Cooked-android appears.
		let templates = Scratch("scratch_android_check_templates", .. scope .());
		defer RemoveDirectoryRecursive(templates);
		FakeTemplate(scope ExportTemplate(), PathJoin(templates, "android-test", .. scope .()), "Release", "#!/bin/sh\n");
		fx.Templates.Refresh(templates, fx.ToolDir);
		preset.TemplateId.Set("android-test");
		preset.AndroidApplicationId.Set("game");
		let result = scope ExportResult();
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Err);
		Test.Assert(result.Refusal.Contains("application id"), result.Refusal);
		Test.Assert(!DirectoryExists(PathJoin(fx.ProjectDir, "Cooked-android", .. scope .())));
	}

	[Test]
	public static void AnAndroidAppIsStagedForGradleAndGivenThePresetsValues()
	{
		let fx = scope ExportProjectFixture("scratch_android_stage");
		fx.Project.Settings.Name.Set("Stage Test");
		let templateDir = Scratch("scratch_android_stage_template", .. scope .());
		let contentDir = Scratch("scratch_android_stage_content", .. scope .());
		let dataRoot = Scratch("scratch_android_stage_data", .. scope .());
		defer { RemoveDirectoryRecursive(templateDir); RemoveDirectoryRecursive(contentDir); RemoveDirectoryRecursive(dataRoot); }
		SaveText(fx.ProjectDir, "Branding/icon.png", "png");

		let template = scope ExportTemplate();
		FakeTemplate(template, templateDir, "Release", "#!/bin/sh\n");
		SaveText(contentDir, ProjectLayout.DistContentPak, "pak");
		SaveText(contentDir, ProjectLayout.DistManifestFile, "<root/>");
		SaveText(contentDir, "export-report.txt", "report");
		SaveText(contentDir, "Data/Engine/Shaders/shaders.dpak", "dpak");
		SaveText(dataRoot, "Engine/Fonts/face.ttf", "ttf");
		SaveText(dataRoot, "Engine/Shaders/source.hlsl", "hlsl");

		let preset = scope ExportPreset();
		preset.Name.Set("Phone");
		preset.Platform.Set("Android64");
		preset.AndroidApplicationId.Set("com.studio.stage");
		preset.AndroidVersionCode = 7;
		preset.AndroidVersionName.Set("2.1");
		preset.AndroidIcon.Set("Branding/icon.png");
		preset.OverridesOrientation = true;
		preset.Orientation = .Landscape;
		let work = ExportAndroid.WorkDir(fx.Project, preset, .. scope .());
		Test.Assert(work.EndsWith(".cache/android/Phone"), work);
		Test.Assert(ExportAndroid.StageApp(fx.Project, preset, template, contentDir, dataRoot, work) case .Ok);

		let workFs = scope NativeFileSystem(work);
		Test.Assert(workFs.Exists("project/settings.gradle") && workFs.Exists("project/app/build.gradle") && workFs.Exists("project/gradlew"));
		Test.Assert(workFs.Exists("staged/jniLibs/arm64-v8a/libmain.so"));
		Test.Assert(workFs.Exists(scope $"staged/assets/Game/{ProjectLayout.DistContentPak}") && workFs.Exists(scope $"staged/assets/Game/{ProjectLayout.DistManifestFile}"));
		Test.Assert(!workFs.Exists("staged/assets/Game/export-report.txt"));
		Test.Assert(!DirectoryExists(PathJoin(work, "staged/assets/Game/Data", .. scope .())));
		Test.Assert(workFs.Exists("staged/assets/Data/Engine/Shaders/shaders.dpak"));
		Test.Assert(workFs.Exists("staged/assets/Data/Engine/Fonts/face.ttf"));
		Test.Assert(!workFs.Exists("staged/assets/Data/Engine/Shaders/source.hlsl"), "the pack stands in for them");
		Test.Assert(workFs.Exists(scope $"staged/assets/{BuildLayout.cThirdPartyNotices}"));
		Test.Assert(workFs.Exists("staged/res/mipmap-xxxhdpi/ic_launcher.png"));

		// Gradle's arguments: the preset's values, and a release APK from a release template.
		let arguments = scope List<String>();
		defer { ClearAndDeleteItems!(arguments); }
		ExportAndroid.GradleArguments(fx.Project, preset, template, work, arguments);
		Test.Assert(Has(arguments, "-PsedulousApplicationId=com.studio.stage"));
		Test.Assert(Has(arguments, "-PsedulousVersionCode=7") && Has(arguments, "-PsedulousVersionName=2.1"));
		Test.Assert(Has(arguments, "-PsedulousLabel=Stage Test"), "the project's name when the preset gives none");
		Test.Assert(Has(arguments, "-PsedulousOrientation=userLandscape"));
		Test.Assert(Has(arguments, "assembleRelease") && !Has(arguments, "bundleRelease"));
		Test.Assert(!Has(arguments, "-PsedulousKeyAlias="));
		preset.AndroidPackage = .Both;
		preset.AndroidLabel.Set("Stage");
		preset.AndroidKeystore.Set("keys/release.jks");
		preset.AndroidKeyAlias.Set("upload");
		preset.OverridesOrientation = false;
		ClearAndDeleteItems!(arguments);
		ExportAndroid.GradleArguments(fx.Project, preset, template, work, arguments);
		Test.Assert(Has(arguments, "assembleRelease") && Has(arguments, "bundleRelease"));
		Test.Assert(Has(arguments, "-PsedulousLabel=Stage"));
		Test.Assert(Has(arguments, "-PsedulousOrientation=fullUser"), "the project's: any");
		Test.Assert(Has(arguments, scope $"-PsedulousKeystore={PathJoin(fx.ProjectDir, "keys/release.jks", .. scope .())}"));
		Test.Assert(Has(arguments, "-PsedulousKeyAlias=upload"));
		preset.AndroidPackage = .Bundle;
		let debugTemplate = scope ExportTemplate();
		FakeTemplate(debugTemplate, templateDir, "Debug", "#!/bin/sh\n");
		ClearAndDeleteItems!(arguments);
		ExportAndroid.GradleArguments(fx.Project, preset, debugTemplate, work, arguments);
		Test.Assert(Has(arguments, "bundleDebug") && !Has(arguments, "assembleDebug"));

		// A second staging replaces what the first staged.
		preset.AndroidIcon.Clear();
		Test.Assert(ExportAndroid.StageApp(fx.Project, preset, template, contentDir, dataRoot, work) case .Ok);
		Test.Assert(!workFs.Exists("staged/res/mipmap-xxxhdpi/ic_launcher.png"));
	}

#if BF_PLATFORM_LINUX
	[CLink]
	private static extern int32 chmod(char8* path, uint32 mode);

	/// The whole export with a stand-in for Gradle: a wrapper that makes the APK where Gradle puts
	/// it and writes down the arguments it had.
	[Test]
	public static void AnAndroidPresetExportsItsAppThroughTheTemplatesGradleWrapper()
	{
		let fx = scope ExportProjectFixture("scratch_android_export");
		fx.Project.Settings.Name.Set("Sky Test");
		Test.Assert(fx.Project.SaveSettings() case .Ok);
		let sdk = Scratch("scratch_android_export_sdk", .. scope .());
		let templates = Scratch("scratch_android_export_templates", .. scope .());
		defer { RemoveDirectoryRecursive(sdk); RemoveDirectoryRecursive(templates); }
		CreateDirectory(sdk);
		let home = scope ScopedVariable("ANDROID_HOME", sdk);

		let bundle = PathJoin(templates, "android-test", .. scope .());
		FakeTemplate(scope ExportTemplate(), bundle, "Release", """
			#!/bin/sh
			for a in "$@"; do case "$a" in -PsedulousStaged=*) staged="${a#-PsedulousStaged=}";; esac; done
			mkdir -p "$staged/gradle/app/outputs/apk/release"
			echo apk > "$staged/gradle/app/outputs/apk/release/app-release.apk"
			printf '%s\\n' "$@" > "$staged/gradle-arguments.txt"

			""");
		Test.Assert(chmod(PathJoin(bundle, "android/gradlew", .. scope .()).CStr(), 493) == 0); // 0755
		fx.Templates.Refresh(templates, fx.ToolDir);

		let preset = scope ExportPreset();
		preset.Name.Set("Phone");
		preset.Platform.Set("Android64");
		preset.OutputSubdir.Set("android");
		preset.TemplateId.Set("android-test");
		preset.AndroidApplicationId.Set("com.studio.sky");
		let result = scope ExportResult();
		let dataRoot = ExportProjectFixture.DataRoot(.. scope .());
		Test.Assert(ExportDriver.ExportOne(fx.Project, preset, fx.Templates, fx.Builders, fx.OutRoot, dataRoot, false, result) case .Ok, result.Refusal);

		// The dist is the app; the game went inside it.
		let dist = scope NativeFileSystem(result.OutputDir);
		Test.Assert(dist.Exists("Sky-Test.apk"));
		Test.Assert(!dist.Exists(ProjectLayout.DistContentPak) && !dist.Exists("libmain.so"));
		let work = ExportAndroid.WorkDir(fx.Project, preset, .. scope .());
		let workFs = scope NativeFileSystem(work);
		Test.Assert(workFs.Exists(scope $"staged/assets/Game/{ProjectLayout.DistContentPak}") && workFs.Exists(scope $"staged/assets/Game/{ProjectLayout.DistManifestFile}"));
		Test.Assert(workFs.Exists("staged/assets/Data/Engine/Shaders/shaders.dpak"));
		let said = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(work, "staged/gradle-arguments.txt", .. scope .()), said) case .Ok);
		let arguments = StringView((char8*)said.Ptr, said.Count);
		Test.Assert(arguments.Contains("-PsedulousApplicationId=com.studio.sky") && arguments.Contains("assembleRelease") && arguments.Contains("--no-daemon"));
	}
#endif
}
