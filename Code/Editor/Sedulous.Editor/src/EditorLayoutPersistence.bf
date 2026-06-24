namespace Sedulous.Editor;

using System;
using System.IO;
using Sedulous.UI.Toolkit;
using Sedulous.Serialization;
using Sedulous.UI;

/// Saves and restores the editor's dock layout to/from a file.
/// Uses the Sedulous.Serialization framework (OpenDDL) to serialize
/// the DockLayoutNode tree structure.
static class EditorLayoutPersistence
{
	/// Saves the dock manager's layout to a file.
	public static Result<void> SaveLayout(DockManager dockManager, StringView path, ISerializerProvider provider)
	{
		let layout = dockManager.ExportLayout();
		if (layout == null) return .Ok; // Nothing to save
		defer delete layout;

		let writer = provider.CreateWriter();
		if (writer == null) return .Err;
		defer delete writer;

		SerializeNode(writer, layout);

		let text = scope String();
		provider.GetOutput(writer, text);
		return File.WriteAllText(path, text);
	}

	/// Restores the dock manager's layout from a file.
	/// Panels must already be registered with the DockManager (via AddPanel)
	/// before calling this.
	public static Result<void> RestoreLayout(DockManager dockManager, StringView path, ISerializerProvider provider)
	{
		if (!File.Exists(path)) return .Err;

		let text = scope String();
		if (File.ReadAllText(path, text) case .Err) return .Err;

		let reader = provider.CreateReader(text);
		if (reader == null) return .Err;
		defer delete reader;

		let layout = DeserializeNode(reader);
		if (layout == null) return .Err;
		defer delete layout;

		dockManager.ApplyLayout(layout);
		return .Ok;
	}

	// === Serialization ===

	private static void SerializeNode(Serializer s, DockLayoutNode node)
	{
		var nodeType = (int32)node.Type;
		s.Int32("type", ref nodeType);

		if (node.Type == .Split)
		{
			var direction = (int32)node.Direction;
			s.Float("ratio", ref node.SplitRatio);
			s.Int32("direction", ref direction);

			if (node.First != null)
			{
				s.BeginObject("first");
				SerializeNode(s, node.First);
				s.EndObject();
			}

			if (node.Second != null)
			{
				s.BeginObject("second");
				SerializeNode(s, node.Second);
				s.EndObject();
			}
		}
		else // TabGroup
		{
			var count = (int32)node.PanelIds.Count;
			s.BeginArray("panels", ref count);
			for (let id in node.PanelIds)
			{
				s.BeginObject("");
				s.String("id", id);
				s.EndObject();
			}
			s.EndArray();

			var activeTab = (int32)node.ActiveTabIndex;
			s.Int32("activeTab", ref activeTab);
		}
	}

	private static DockLayoutNode DeserializeNode(Serializer s)
	{
		let node = new DockLayoutNode();

		var nodeType = (int32)0;
		s.Int32("type", ref nodeType);
		node.Type = (DockLayoutNodeType)nodeType;

		if (node.Type == .Split)
		{
			s.Float("ratio", ref node.SplitRatio);

			var direction = (int32)0;
			s.Int32("direction", ref direction);
			node.Direction = (Orientation)direction;

			if (s.BeginObject("first") == .Ok)
			{
				node.First = DeserializeNode(s);
				s.EndObject();
			}

			if (s.BeginObject("second") == .Ok)
			{
				node.Second = DeserializeNode(s);
				s.EndObject();
			}
		}
		else // TabGroup
		{
			var count = (int32)0;
			if (s.BeginArray("panels", ref count) == .Ok)
			{
				for (int32 i = 0; i < count; i++)
				{
					s.BeginObject("");
					let id = new String();
					s.String("id", id);
					node.PanelIds.Add(id);
					s.EndObject();
				}
				s.EndArray();
			}

			var activeTab = (int32)0;
			s.Int32("activeTab", ref activeTab);
			node.ActiveTabIndex = activeTab;
		}

		return node;
	}
}
