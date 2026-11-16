using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor level export preferences, a settings section, NOT project local: the
/// templates root override. Non empty wins over $SEDULOUS_TEMPLATES_DIR and the built in
/// <user-data>/templates default, pointing the editor at a shared or checked out templates
/// directory.
///
/// It also holds the tools an Android export runs: the Android SDK's folder and a JDK's, each
/// empty (the default) for the environment's (ANDROID_HOME, JAVA_HOME or java on the PATH).
[Serializable(1)]
class EditorExportSettings
{
	public String TemplatesRoot = new .() ~ delete _;
	/// "" means $ANDROID_HOME.
	[Appended]
	public String AndroidSdk = new .() ~ delete _;
	/// "" means $JAVA_HOME, else java on the PATH.
	[Appended]
	public String JavaHome = new .() ~ delete _;
}

/// The environment variables an Android export's tools read, as the process was started with
/// them, kept so a setting cleared later gives them back: the SDK (Gradle's Android plugin and the
/// export's check) and the JDK (the Gradle wrapper).
class ExportToolEnvironment
{
	public const String cAndroidHomeVariable = "ANDROID_HOME";
	public const String cJavaHomeVariable = "JAVA_HOME";

	public String AndroidHome = new .() ~ delete _;
	public bool HadAndroidHome;
	public String JavaHome = new .() ~ delete _;
	public bool HadJavaHome;

	/// What this process has now.
	public void ReadCurrent()
	{
		HadAndroidHome = Environment.GetEnvironmentVariable(cAndroidHomeVariable, AndroidHome..Clear()) case .Ok;
		HadJavaHome = Environment.GetEnvironmentVariable(cJavaHomeVariable, JavaHome..Clear()) case .Ok;
	}

	/// Sets this process's ANDROID_HOME and JAVA_HOME from `settings`, where the exports it runs
	/// and their Gradle builds read them: a folder the settings name, else what the process was
	/// started with (this).
	public void Apply(EditorExportSettings settings)
	{
		// Empty, never a default view: Beef hands a null pointer to setenv, which faults.
		Environment.SetEnvironmentVariable(cAndroidHomeVariable,
			!settings.AndroidSdk.IsEmpty ? StringView(settings.AndroidSdk) : (HadAndroidHome ? StringView(AndroidHome) : ""));
		Environment.SetEnvironmentVariable(cJavaHomeVariable,
			!settings.JavaHome.IsEmpty ? StringView(settings.JavaHome) : (HadJavaHome ? StringView(JavaHome) : ""));
	}
}
