using System;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core;

/// The manager controller's answer for a directory: the gate, the probed manifest, valid
/// unless NotAProject, and the prompt copy for the two prompt gates.
class ProjectOpenDecision
{
	public ProjectOpenGate Gate = .NotAProject;
	public ProjectSettings Probed = new .() ~ delete _;
	public String PromptTitle = new .() ~ delete _;
	public String PromptBody = new .() ~ delete _;
}
