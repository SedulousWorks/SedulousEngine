using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Physics.Resource;
using Sedulous.Physics.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Physics;

/// The collision shape page, on the preview pages' markup
/// (Data/Editor/PreviewPage.xml): the cooked collider's outline drawn in the preview, beside the
/// asset's fields, its source mesh a slot for what a mesh cooks to ([References]), each edit one
/// undo step. A shape with no mesh says so in a notice, and shows no collider (one cooked before
/// its mesh was cleared is not one it can make now); what it cooks from and how, and the
/// collider's size, are read only. The old page's Cook now is the bar's Cook, as every asset page
/// has it. What every asset page does is AssetObjectPage's.
class CollisionShapeEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/PreviewPage.xml";

	private PreviewPane mPane = null ~ delete _;
	/// The cooked product, retained; it follows re-cooks, so DrawOutline reads the current outline.
	private Proxy<CollisionShape> mShape = default;
	/// The outline's vertex count when the camera last framed it: a re-cook that changes it frames
	/// again.
	private int mFramedCount = 0;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(CollisionShapeAsset), cMarkupPath)
	{
		// The outline is drawn as unlit debug lines each frame, so the preview's scene needs no
		// entities or light.
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "collision.preview");
			mPane.OnFrame = new [=this] () => { FrameOutline(); };
		}
		if (Context.Resources != null)
		{
			mShape = Context.Resources.Bind<CollisionShape>(InstanceId);
			mShape.Retain();
		}
		ShowStatus();
	}

	public ~this()
	{
		mShape.Forget();
	}

	/// What a cook kind is called.
	public static StringView CookLabel(CollisionCookKind kind) => (kind == .ConvexHull) ? "Convex hull (dynamic)" : "Triangle mesh (static)";

	/// Whether the preview shows the cooked collider: there is one, and the asset still names a
	/// mesh to make it from (cleared, the last cook's collider is one it can no longer make).
	public static bool ShowsCollider(Guid sourceMesh, CollisionShape shape)
		=> !sourceMesh.IsNil && (shape != null) && (shape.Outline.Count >= 3);

	// The collider shown now (null: none to show).
	private CollisionShape ShownCollider
	{
		get
		{
			let asset = ObjectAs<CollisionShapeAsset>();
			let shape = mShape.Get;
			return ((asset != null) && ShowsCollider(asset.SourceMesh, shape)) ? shape : null;
		}
	}

	// === For tests ===

	public PreviewPane Pane => mPane;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
		DrawOutline();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	protected override void OnObjectChanged()
	{
		ShowStatus();
	}

	/// The notice and the facts: what it cooks from and how; the preview or why there is none.
	private void ShowStatus()
	{
		let asset = ObjectAs<CollisionShapeAsset>();
		if (asset == null)
			return;
		SetNotice("mesh", asset.SourceMesh.IsNil ? "No source mesh: pick one, then save to cook its collider." : "");
		SetFact("Cooks From", MeshName(asset.SourceMesh, .. scope .()));
		SetFact("Cooks As", CookLabel(asset.Cook));
		let shape = mShape.Get;
		if (!ShowsCollider(asset.SourceMesh, shape))
		{
			SetFact("Collider", asset.SourceMesh.IsNil ? "None: no source mesh" : "Not cooked yet");
			if (mPane != null)
				mPane.ShowEmpty("No collider yet", asset.SourceMesh.IsNil ? "Pick a source mesh, then save: its collider cooks and shows here."
					: "Save to cook the collider; it shows here once cooked.");
			return;
		}
		SetFact("Collider", scope String()..AppendF("{} triangles", shape.Outline.Count / 3));
		if (mPane != null)
			mPane.Show();
	}

	/// The source mesh as its row says it: its path, or why there is none, appended.
	private void MeshName(Guid id, String outText)
	{
		if (id.IsNil || (Context.Project == null))
		{
			outText.Append("Not set");
			return;
		}
		let instance = Context.Project.SourceDb.GetInstance(id);
		if (instance != null)
			instance.GetPath(outText);
		else
			outText.Append("(missing mesh)");
	}

	private void FrameOutline()
	{
		let shape = ShownCollider;
		if ((shape == null) || (mPane == null) || (mPane.Viewport == null))
			return;
		let tris = shape.Outline;
		var lo = tris[0];
		var hi = tris[0];
		for (let v in tris)
		{
			lo = .(Math.Min(lo.X, v.X), Math.Min(lo.Y, v.Y), Math.Min(lo.Z, v.Z));
			hi = .(Math.Max(hi.X, v.X), Math.Max(hi.Y, v.Y), Math.Max(hi.Z, v.Z));
		}
		mPane.Viewport.Frame((lo + hi) * 0.5f, Math.Max(0.25f, Length((hi - lo) * 0.5f)));
	}

	/// The outline triangles as a wireframe each frame (the debug scene clears each frame).
	private void DrawOutline()
	{
		let preview = (mPane != null) ? mPane.Viewport : null;
		if ((preview == null) || !preview.IsValid)
			return;
		let shape = ShownCollider;
		if (shape == null)
			return;
		let tris = shape.Outline; // a triangle list: three vertices each
		// Framed when the outline first appears or a re-cook changes its vertex count, and said.
		if (tris.Count != mFramedCount)
		{
			FrameOutline();
			mFramedCount = tris.Count;
			ShowStatus();
		}
		let draw = preview.SceneDebugDraw;
		let color = Color(0.30f, 0.95f, 0.55f, 1.0f);
		for (int i = 0; i + 2 < tris.Count; i += 3)
		{
			draw.DrawLine(tris[i], tris[i + 1], color);
			draw.DrawLine(tris[i + 1], tris[i + 2], color);
			draw.DrawLine(tris[i + 2], tris[i], color);
		}
	}
}
