using System;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// asset_create's work, the same on every host: the group resolved (made when missing), a
/// taken name refused, the creator run. Main thread: it writes the source database.
static class AssetCreation
{
	/// The new instance, or null with the reason in `outError`.
	public static Instance Run(EditorProject project, CreateRequest request, String outError)
	{
		let root = project.SourceDb.RootGroup;
		let picked = request.GroupPath.IsEmpty ? null : McpTools.ResolveGroupPath(root, request.GroupPath);
		if (!request.Name.IsEmpty)
		{
			// Where the creator will put it; a name taken there is refused, not suffixed: an
			// agent that names an asset means that name.
			let target = request.Creator.TargetFor(picked, root);
			if ((target != null) && (target.GetInstance(request.Name) != null))
			{
				outError.AppendF("an asset named '{}' already exists in '{}'", request.Name,
					McpTools.GroupPath(target, .. scope .()));
				return null;
			}
		}
		let instance = request.Creator.Create(picked, root, project.SourcesRoot(.. scope .()), request.Name);
		if (instance == null)
			outError.AppendF("the {} creator made nothing (a write was refused)", request.Creator.Label);
		return instance;
	}
}
