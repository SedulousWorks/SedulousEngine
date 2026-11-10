using System;

namespace Sedulous.Editor.Project;

/// How New Project's check line reads: green, amber (it goes ahead), or red (Create waits).
enum NewProjectCheckLevel
{
	Ok,
	Warning,
	Error,
}

/// What New Project's folder is for: a new project made there, or a sample downloaded into it.
enum NewProjectAction
{
	Create,
	Download,
}

/// New Project's check, kept current as the fields change: where the project goes, and what to
/// say about it (ProjectManagerController.CheckNewProject).
class NewProjectCheck
{
	public NewProjectCheckLevel Level = .Error;
	public String Message = new .() ~ delete _;
	/// The project's folder; empty when there is none yet.
	public String Target = new .() ~ delete _;
	/// The project's name, its spaces at either end trimmed.
	public String Name = new .() ~ delete _;
}
