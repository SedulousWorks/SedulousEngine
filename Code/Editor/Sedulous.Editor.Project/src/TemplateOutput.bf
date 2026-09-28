namespace Sedulous.Editor.Core;

/// Where CreateTemplate writes the bundle.
enum TemplateOutput
{
	/// Into <destRoot>/<id> under the templates root, usable immediately.
	Install,
	/// Directly into <destRoot>: a self contained bundle to zip and distribute.
	ExportFolder
}
