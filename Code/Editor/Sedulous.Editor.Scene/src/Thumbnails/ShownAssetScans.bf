using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The assets a scene's or a prefab's thumbnail shows, as the export's reference scan finds them
/// (the document loaded into a scratch scene, its prefabs spawned, nothing bound or built),
/// remembered per document version, since a scan loads the whole document. One per generator.
class ShownAssetScans
{
	private class Scan
	{
		/// The document's hash when it was scanned.
		public uint64 Document;
		public List<Guid> Assets = new .() ~ delete _;
	}

	private Dictionary<Guid, Scan> mScans = new .() ~ DeleteDictionaryAndValues!(_);

	/// Appends what `instance` shows to `outIds`, scanning it again only when it changed. With no
	/// project or no scanner wired, it shows nothing.
	public void Collect(EditorContext context, Instance instance, List<Guid> outIds)
	{
		let document = ThumbnailStaging.DocumentHash(instance);
		Scan known = null;
		if (!mScans.TryGetValue(instance.Id, out known) || (known.Document != document))
		{
			if (known == null)
			{
				known = new Scan();
				mScans[instance.Id] = known;
			}
			known.Document = document;
			known.Assets.Clear();
			if ((context != null) && (context.Project != null) && (context.SceneRefScanner != null))
			{
				let prefabs = scope List<Guid>(); // their contents are spawned into the scan already
				context.SceneRefScanner(instance, context.Project.SourceDb, known.Assets, prefabs);
			}
		}
		outIds.AddRange(known.Assets);
	}

	/// Whether the thumbnail waits for the cook: those of what it shows the cook has not made yet
	/// (none while a cook runs, which settles them) are asked for, since a thumbnail drawn now
	/// would miss them and stay so; it is drawn when the cook finishes.
	public bool WaitForUncooked(EditorContext context, Instance instance)
	{
		if (context == null)
			return false;
		let shown = scope List<Guid>();
		Collect(context, instance, shown);
		let waiting = scope List<Guid>();
		for (let id in shown)
		{
			if (context.WaitsForCook(id))
				waiting.Add(id);
		}
		if (waiting.IsEmpty)
			return false;
		context.RequestCookFor(waiting);
		return true;
	}
}
