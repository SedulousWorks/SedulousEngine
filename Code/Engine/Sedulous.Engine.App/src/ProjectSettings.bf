namespace Sedulous.Engine.App;

using System;
using System.IO;
using Sedulous.Serialization;
using Sedulous.RuntimeGraphics;

/// On-disk per-project render settings. Lives at
/// `<ProjectAssetDirectory>/project_settings.oddl` and is read by both
/// standalone (EngineApplication.Boot) and the editor (at project open).
///
/// Render settings only; window dims, backend selection, etc. stay in
/// app code so deployment-specific overrides are explicit. Editor's
/// Project Settings panel writes this file; standalone consumes it.
struct ProjectSettings
{
	public int32 TargetWidth = 0;
	public int32 TargetHeight = 0;
	public FitMode FitMode = .Letterbox;
}

/// Reads / writes ProjectSettings via the OpenDDL serializer. Public
/// surface is two static helpers - callers don't manage Serializer
/// lifecycle themselves. Missing files are not an error (Load returns
/// .Err so callers can decide; populating defaults).
static class ProjectSettingsIO
{
	public const String FileName = "project_settings.oddl";

	/// Read settings from `<dir>/project_settings.oddl`. Caller owns
	/// the serializer provider. Returns .Err if the file doesn't exist
	/// or fails to parse.
	public static Result<void> Load(StringView dir, ISerializerProvider provider, ref ProjectSettings settings)
	{
		if (dir.IsEmpty || provider == null)
			return .Err;

		let path = scope String();
		Path.InternalCombine(path, dir, FileName);
		if (!File.Exists(path))
			return .Err;

		let content = scope String();
		if (File.ReadAllText(path, content) case .Err)
			return .Err;

		let reader = provider.CreateReader(content);
		if (reader == null)
			return .Err;
		defer delete reader;

		Serialize(reader, ref settings);
		return .Ok;
	}

	/// Write settings to `<dir>/project_settings.oddl`. Overwrites if
	/// present. Creates the file if not.
	public static Result<void> Save(StringView dir, ISerializerProvider provider, ProjectSettings settings)
	{
		if (dir.IsEmpty || provider == null)
			return .Err;

		let path = scope String();
		Path.InternalCombine(path, dir, FileName);

		let writer = provider.CreateWriter();
		if (writer == null)
			return .Err;
		defer delete writer;

		var mutable = settings;
		Serialize(writer, ref mutable);

		let output = scope String();
		provider.GetOutput(writer, output);
		return File.WriteAllText(path, output);
	}

	/// Symmetric serializer. uint8 round-trip for FitMode keeps the
	/// schema simple; if we want human-readable enum names later the
	/// migration is just a string-to-enum mapping on read.
	private static void Serialize(Serializer s, ref ProjectSettings settings)
	{
		s.Int32("TargetWidth", ref settings.TargetWidth);
		s.Int32("TargetHeight", ref settings.TargetHeight);
		var fitMode = (uint8)settings.FitMode;
		s.UInt8("FitMode", ref fitMode);
		if (s.IsReading) settings.FitMode = (FitMode)fitMode;
	}
}
