using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Engine.Project;

/// The shared, committed part of a project: the Project.xml payload.
///
/// Also the distribution manifest, which is the same shape without the editor's concerns.
/// It lives in the runtime rather than the editor so a shipping binary carries no editor
/// code to read the project it was built from.
///
/// A guid is the AUTHORITATIVE reference in every pair below and survives a rename or a
/// move; the string beside it is the readable mirror, and the fallback for a manifest
/// written before its guid existed.
///
/// FIELD ORDER IS THE WIRE: the generator walks the declaration, so inserting a field in the
/// middle changes what existing manifests mean. Append, and bump the version when the shape
/// has to change.
[Serializable(9)]
class ProjectSettings
{
	public String Name = new .() ~ delete _;
	/// The engine that last saved this project. Re-stamped on every save. Named for the WIRE
	/// KEY, which the generator derives from the field name.
	public String EngineVersion = new .() ~ delete _;

	public Guid DefaultSceneId;
	/// The default scene's source database path.
	public String DefaultScene = new .() ~ delete _;
	/// The startup script's source database path. Superseded by StartupScriptId.
	public String StartupScript = new .() ~ delete _;
	/// RESERVED: an optional native game module.
	public String NativeModule = new .() ~ delete _;

	/// The input map bound at startup. Nil for none.
	public Guid DefaultInputMapId;
	/// The mixer layout applied at startup. Nil for the built in one.
	public Guid DefaultBusLayoutId;
	/// The cooked theme the game UI defaults to. Nil for the built in one.
	public Guid DefaultUiThemeId;
	/// The cooked script class the player launches. Nil for none.
	public Guid StartupScriptId;
	/// The cooked font the game UI defaults to. Nil for the development fallback.
	public Guid DefaultUiFontId;
	/// The cooked document shown while the default scene loads. Nil for the built in splash.
	public Guid LoadingDocumentId;

	/// The scene pass sample count: one is off. Clamped to what the device can do at
	/// runtime, so a project asking for more than the hardware has still runs.
	public uint32 RenderMsaaSamples = 1;
}
