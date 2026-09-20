using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Mcp;

namespace Sedulous.Editor.Mcp;

/// The open project's scene and prefab XML sources as a DYNAMIC resource set, listed live
/// from the source database: project://scene/<guid> and project://prefab/<guid>, read only,
/// the text byte identical to scene_read. Mutation stays with scene_write.
static class ProjectResources
{
	public const String cScenePrefix = "project://scene/";
	public const String cPrefabPrefix = "project://prefab/";

	public static void Register(McpServer server, ProjectSession session)
	{
		server.RegisterResourceProvider(new ResourceProvider(
			new (outResources) => List(session, outResources),
			new (uri, outText, outError) => Read(session, uri, outText, outError)));
	}

	private static void List(ProjectSession session, List<Resource> outResources)
	{
		// No project open: the set is empty, not an error.
		if (!session.IsOpen)
			return;
		ListGroup(session.Project.SourceDb.RootGroup, scope String(), outResources);
	}

	private static void ListGroup(Group group, String path, List<Resource> outResources)
	{
		for (let instance in group.Instances)
		{
			let isScene = McpTools.IsSceneDocument(instance);
			if (!isScene && !McpTools.IsPrefabDocument(instance))
				continue;
			let uri = scope String(isScene ? cScenePrefix : cPrefabPrefix);
			instance.Id.ToString(uri);
			let name = scope String(path);
			if (!name.IsEmpty)
				name.Append('/');
			name.Append(instance.Name);
			let description = scope $"{isScene ? "scene" : "prefab"} source XML (read-only; author changes via {isScene ? "scene_write" : "prefab_write"})";
			outResources.Add(new Resource(uri, name, "application/xml", description));
		}
		for (let child in group.Groups)
		{
			let childPath = scope String(path);
			if (!childPath.IsEmpty)
				childPath.Append('/');
			childPath.Append(child.Name);
			ListGroup(child, childPath, outResources);
		}
	}

	private static ResourceReadOutcome Read(ProjectSession session, StringView uri, String outText, String outError)
	{
		StringView guidText;
		if (uri.StartsWith(cScenePrefix))
			guidText = uri.Substring(cScenePrefix.Length);
		else if (uri.StartsWith(cPrefabPrefix))
			guidText = uri.Substring(cPrefabPrefix.Length);
		else
			return .NotMine;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return .Failed;
		}
		if (!(Guid.Parse(guidText) case .Ok(let id)))
		{
			outError.AppendF("invalid guid in uri '{}'", uri);
			return .Failed;
		}
		let instance = session.Project.SourceDb.GetInstance(id);
		if (instance == null)
		{
			outError.AppendF("no scene/prefab with guid '{}' (see resources/list)", guidText);
			return .Failed;
		}
		if (!McpTools.ReadSceneStream(instance, outText))
		{
			outError.AppendF("'{}' has no stored scene stream", instance.Name);
			return .Failed;
		}
		return .Ok;
	}
}
