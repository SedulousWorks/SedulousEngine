using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// The settings describe themselves: the dialog and the MCP tools read these, so a setting added
/// with a [Setting] is offered by both, and one without is offered by neither.
class SettingFieldsTests
{
	/// A setting that names no category.
	private class Probe
	{
		[Setting("Unsorted")]
		public String Unsorted = new .() ~ delete _;
	}

	/// Each setting names the group it shows in, the Project Settings dialog's tab; one that
	/// names none (an export preset's) is General.
	[Test]
	public static void EachSettingNamesItsCategoryAndNoneIsGeneral()
	{
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let order = scope String();
		for (let field in fields)
		{
			let category = SettingFields.Category(field);
			if (!order.Contains(category))
			{
				if (!order.IsEmpty)
					order.Append(",");
				order.Append(category);
			}
			if (field.Name == "RenderMsaaSamples")
				Test.Assert(category == "Display");
			if (field.Name == "LoadingDocumentId")
				Test.Assert(category == "Startup");
			if (field.Name == "UiFontIds")
				Test.Assert(category == "UI");
		}
		Test.Assert(order == "General,Startup,Audio,UI,Display", order);

		Test.Assert(SettingFields.cDefaultCategory == "General");
		var probed = false;
		for (let field in typeof(Probe).GetFields())
		{
			if (field.Name != "Unsorted")
				continue;
			Test.Assert(SettingFields.Category(field) == "General");
			probed = true;
		}
		Test.Assert(probed);
	}

	[Test]
	public static void TheProjectSettingsListTheirSettingsInDeclarationOrderEachWithItsKind()
	{
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		let keys = scope String();
		for (let field in fields)
		{
			if (!keys.IsEmpty)
				keys.Append(",");
			SettingFields.Key(field, keys);
		}
		// The engine stamp and the path mirrors are not settings.
		Test.Assert(keys == "name,defaultSceneId,nativeModule,defaultInputMapId,defaultBusLayoutId,defaultUiThemeId,startupScriptId,defaultUiFontId,loadingDocumentId,renderMsaaSamples,uiFontIds,renderWidth,renderHeight,renderFit,windowWidth,windowHeight,windowMode,windowResizable,orientation", keys);

		SettingKind Kind(StringView name)
		{
			for (let field in fields)
			{
				if (field.Name == name)
				{
					SettingFields.KindOf(field, let kind);
					return kind;
				}
			}
			Test.FatalError(scope $"no setting {name}");
			return .Text;
		}
		Test.Assert(Kind("Name") == .Text);
		Test.Assert(Kind("DefaultSceneId") == .Asset);
		Test.Assert(Kind("UiFontIds") == .AssetList);
		Test.Assert(Kind("RenderMsaaSamples") == .Count);
		Test.Assert(Kind("RenderFit") == .Choice);
		Test.Assert(Kind("WindowResizable") == .Flag);
		Test.Assert(Kind("Orientation") == .Choice);

		for (let field in fields)
		{
			let setting = SettingFields.Setting(field).Value;
			Test.Assert(!setting.Label.IsEmpty);
			if (field.Name == "LoadingDocumentId")
			{
				Test.Assert(setting.Label == "Loading screen");
				Test.Assert(setting.AssetType == "UIDocumentAsset");
				Test.Assert(setting.EmptyText == "(built-in)");
			}
			if (field.Name == "WindowWidth")
			{
				SettingFields.CountRange(field, let least, let most);
				Test.Assert((least == 1) && (most == 16384));
			}
			if (field.Name == "RenderMsaaSamples")
			{
				SettingFields.CountRange(field, let least, let most);
				Test.Assert((least == 0) && (most == uint32.MaxValue), "unbounded: its levels are the render subsystem's");
			}
		}
	}

	[Test]
	public static void AChoiceIsReadAndWrittenByItsCaseAndNamesItsCases()
	{
		let settings = scope ProjectSettings();
		let fields = scope List<FieldInfo>();
		SettingFields.Of(typeof(ProjectSettings), fields);
		for (let field in fields)
		{
			if (field.Name == "WindowMode")
			{
				Test.Assert(SettingFields.ReadChoice(settings, field) == (int64)WindowMode.Windowed);
				SettingFields.WriteChoice(settings, field, (int64)WindowMode.Borderless);
				Test.Assert(settings.WindowMode == .Borderless);
				Test.Assert(SettingFields.ReadChoice(settings, field) == (int64)WindowMode.Borderless);
				let names = SettingFields.ChoiceNames(field.FieldType, .. scope .());
				Test.Assert(names == "Windowed, Fullscreen, Borderless", names);
			}
			if (field.Name == "RenderFit")
			{
				SettingFields.WriteChoice(settings, field, (int64)FitMode.IntegerScale);
				Test.Assert(settings.RenderFit == .IntegerScale);
			}
			if (field.Name == "WindowWidth")
			{
				*(uint32*)SettingFields.Address(settings, field) = 800;
				Test.Assert(settings.WindowWidth == 800);
			}
		}
	}

	[Test]
	public static void ThePathMirrorsFollowTheirGuids()
	{
		let settings = scope ProjectSettings();
		let scene = Guid.Create();
		settings.DefaultSceneId = scene;
		settings.StartupScript.Set("stale/path");
		settings.RefreshPathMirrors(scope (id, outPath) =>
			{
				if (id == scene)
					outPath.Append("Scenes/Main.scene");
			});
		Test.Assert(settings.DefaultScene == "Scenes/Main.scene");
		Test.Assert(settings.StartupScript.IsEmpty, "an unset guid clears its mirror");
	}
}
