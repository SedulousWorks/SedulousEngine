using System;

namespace Sedulous.Editor.Project;

/// The manager controller's answer for a directory: the gate, the project's header, valid unless
/// NotAProject, and the prompt copy for the two prompt gates.
class ProjectOpenDecision
{
	public ProjectOpenGate Gate = .NotAProject;
	public ProjectHeader Header = new .() ~ delete _;
	public String PromptTitle = new .() ~ delete _;
	public String PromptBody = new .() ~ delete _;
}
