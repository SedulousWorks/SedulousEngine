using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

/// The default viewport tool: click picks an entity, Ctrl-click toggles it, empty space
/// clears, a drag on empty space is a marquee, and the transform gizmo over the selection
/// takes the pointer first.
///
/// A click with a picker asks the GPU for the surface under the pointer and applies the
/// answer when it lands, a few frames on; the CPU origin pick is the fallback for entities no
/// renderer draws (lights, cameras, empties) and for a GPU miss. The newest click wins over
/// an answer still in flight, and Ctrl is captured with the click.
///
/// The edit context is borrowed: the page owns it and the tool dies with the page.
class SelectTransformTool : IViewportTool
{
	/// A press dragged this many pixels, on either axis, becomes a marquee.
	public const int32 cMarqueeThreshold = 4;

	private SceneEditContext mEdit;
	private GizmoController mGizmos ~ delete _;
	/// The GPU pick seam; borrowed from the host, null means CPU picking only.
	private IViewportPicker mPicker = null;
	/// The GPU request in flight for a click; nought is none.
	private uint32 mPendingPick = 0;
	/// The CPU answer for that click, standing when the GPU saw nothing drawn there.
	private Guid mPendingCpuPick = .();
	/// The click's modifier, applied with the answer.
	private bool mPendingCtrl = false;

	/// A press on empty space dragged past the threshold becomes a rubber band rect; release
	/// selects every entity drawn inside it through the picker, or whose origin projects
	/// inside it without one. Ctrl adds to the selection. The click that started it is
	/// undone: its pick is dropped and the selection at press restored.
	private struct Marquee
	{
		/// A press on empty space, not yet dragged past the threshold.
		public bool Armed = false;
		/// Dragging the rect.
		public bool Active = false;
		public bool Ctrl = false;
		public int32 PressX = 0;
		public int32 PressY = 0;
		public int32 CurrentX = 0;
		public int32 CurrentY = 0;
	}
	private Marquee mMarquee = .();
	/// Restored when the drag becomes a marquee.
	private List<Guid> mSelectionAtPress = new .() ~ delete _;
	/// The GPU rect request in flight; nought is none.
	private uint32 mPendingMarquee = 0;
	private bool mMarqueeCtrl = false;

	private List<EntityHandle> mHits = new .() ~ delete _;
	private List<Guid> mPicked = new .() ~ delete _;

	public this(SceneEditContext edit)
	{
		mEdit = edit;
		mGizmos = new GizmoController(edit);
	}

	public StringView Id => "select";
	public StringView DisplayName => "Select";
	/// The default tool never reports unavailable.
	public bool IsAvailable => true;
	public GizmoController Gizmos => mGizmos;

	public void SetPicker(IViewportPicker picker) => mPicker = picker;
	public bool HasPendingPick => mPendingPick != 0;
	public bool IsMarqueeActive => mMarquee.Active;
	public bool HasPendingMarquee => mPendingMarquee != 0;

	public void OnActivate() {}

	/// A tool switch mid drag closes the drag out, so no command group is left half applied;
	/// a marquee mid drag is dropped, never applied.
	public void OnDeactivate()
	{
		var gizmoInput = GizmoFrameInput();
		gizmoInput.PointerValid = false;
		mGizmos.Update(gizmoInput);
		mMarquee.Armed = false;
		mMarquee.Active = false;
	}

	public bool Update(in ViewportToolInput input)
	{
		var gizmoInput = GizmoFrameInput();
		gizmoInput.Ray = .(input.Ray.Origin, input.Ray.Direction);
		gizmoInput.CameraPosition = input.CameraPosition;
		gizmoInput.CameraForward = input.CameraForward;
		gizmoInput.FovY = input.FovY;
		// A locked page still picks, but never drags.
		gizmoInput.PointerValid = input.PointerValid && !input.EditingLocked;
		gizmoInput.LeftPressed = input.LeftPressed;
		gizmoInput.LeftDown = input.LeftDown;
		gizmoInput.LeftReleased = input.LeftReleased;
		gizmoInput.Snap = input.Ctrl;
		if ((input.Keyboard != null) && gizmoInput.PointerValid)
		{
			gizmoInput.KeyTranslate = input.Keyboard.IsKeyPressed(.W);
			gizmoInput.KeyRotate = input.Keyboard.IsKeyPressed(.E);
			gizmoInput.KeyScale = input.Keyboard.IsKeyPressed(.R);
			gizmoInput.KeyToggleSpace = input.Keyboard.IsKeyPressed(.X);
		}
		let consumed = mGizmos.Update(gizmoInput);

		PollPick(); // a GPU answer from an earlier click or marquee lands here
		if (!consumed && input.PointerOver && input.LeftPressed)
		{
			// Arm the marquee BEFORE the click picks: if this press drags past the threshold
			// it becomes a rect select and the click is undone back to this snapshot.
			mMarquee.Armed = input.PointerValid && (input.ViewportWidth > 0)
				&& (input.ViewportHeight > 0);
			mMarquee.Active = false;
			mMarquee.Ctrl = input.Ctrl;
			mMarquee.PressX = input.PointerX;
			mMarquee.PressY = input.PointerY;
			mMarquee.CurrentX = input.PointerX;
			mMarquee.CurrentY = input.PointerY;
			mSelectionAtPress.Clear();
			mSelectionAtPress.AddRange(mEdit.EntitySelection.Items);
			PickOnClick(input);
		}
		else if (mMarquee.Armed)
		{
			UpdateMarquee(input);
		}
		return consumed || mMarquee.Active;
	}

	private void UpdateMarquee(in ViewportToolInput input)
	{
		if (input.PointerValid)
		{
			mMarquee.CurrentX = input.PointerX; // the release frame's position counts too
			mMarquee.CurrentY = input.PointerY;
		}
		if (!input.LeftDown || input.LeftReleased || !input.PointerValid)
		{
			FinishMarquee(input);
			return;
		}
		if (!mMarquee.Active)
		{
			let dx = Math.Abs(mMarquee.CurrentX - mMarquee.PressX);
			let dy = Math.Abs(mMarquee.CurrentY - mMarquee.PressY);
			if ((dx < cMarqueeThreshold) && (dy < cMarqueeThreshold))
				return;
			mMarquee.Active = true;
			// The press was a click until now: drop its pick, in flight or already applied,
			// and put the selection back the way it was.
			mPendingPick = 0;
			mEdit.EntitySelection.Set(mSelectionAtPress);
		}
	}

	private void FinishMarquee(in ViewportToolInput input)
	{
		let wasActive = mMarquee.Active;
		mMarquee.Armed = false;
		mMarquee.Active = false;
		if (!wasActive)
			return; // a click: PickOnClick handled it
		let x0 = Math.Min(mMarquee.PressX, mMarquee.CurrentX);
		let y0 = Math.Min(mMarquee.PressY, mMarquee.CurrentY);
		let x1 = Math.Max(mMarquee.PressX, mMarquee.CurrentX);
		let y1 = Math.Max(mMarquee.PressY, mMarquee.CurrentY);
		if (mPicker != null)
		{
			let request = mPicker.RequestPick(x0, y0, (uint32)(x1 - x0 + 1), (uint32)(y1 - y0 + 1));
			if (request != 0)
			{
				mPendingMarquee = request; // the newest rect wins over one still in flight
				mMarqueeCtrl = mMarquee.Ctrl;
				return;
			}
		}
		CpuMarquee(input, x0, y0, x1, y1, mPicked);
		ApplyMarquee(mPicked, mMarquee.Ctrl);
	}

	private void ApplyMarquee(Span<Guid> picked, bool ctrl)
	{
		let selection = mEdit.EntitySelection;
		if (ctrl)
		{
			for (let id in picked)
			{
				if (!selection.Contains(id))
					selection.Add(id);
			}
			return;
		}
		if (picked.IsEmpty)
			selection.Clear();
		else
			selection.Set(picked);
	}

	/// The entities whose ORIGIN projects inside the rect of the view: the marquee without a
	/// picker.
	private void CpuMarquee(in ViewportToolInput input, int32 x0, int32 y0, int32 x1, int32 y1,
		List<Guid> outPicked)
	{
		outPicked.Clear();
		if ((input.ViewportWidth == 0) || (input.ViewportHeight == 0))
			return;
		// The view's basis from the camera forward, roll free like the editor camera, and its
		// frustum tangents from the field of view and the viewport aspect: enough to project
		// an origin to a pixel.
		let forward = Normalized(input.CameraForward);
		var right = Cross(forward, Float3(0.0f, 1.0f, 0.0f));
		if (Dot(right, right) < 1e-6f)
			right = .(1.0f, 0.0f, 0.0f); // looking straight up or down
		right = Normalized(right);
		let up = Cross(right, forward);
		let tanY = Tan(input.FovY * 0.5f);
		let tanX = tanY * ((float)input.ViewportWidth / (float)input.ViewportHeight);
		let w = (float)input.ViewportWidth;
		let h = (float)input.ViewportHeight;
		let scene = mEdit.Scene;
		let cameraPosition = input.CameraPosition;
		scene.ForEachEntity(scope [&](e) =>
		{
			let world = scene.GetWorldMatrix(e);
			let d = Float3(world.M[3][0], world.M[3][1], world.M[3][2]) - cameraPosition;
			let z = Dot(d, forward);
			if (z <= 1e-4f)
				return; // behind the camera
			let nx = Dot(d, right) / (z * tanX);
			let ny = Dot(d, up) / (z * tanY);
			let px = (nx * 0.5f + 0.5f) * w;
			let py = (0.5f - ny * 0.5f) * h;
			if ((px >= (float)x0) && (px < (float)(x1 + 1)) && (py >= (float)y0) && (py < (float)(y1 + 1)))
				outPicked.Add(scene.GetEntityId(e));
		});
	}

	public void Draw(DebugDraw drawList)
	{
		mGizmos.Draw(drawList);
		if (!mMarquee.Active)
			return;
		let x0 = (float)Math.Min(mMarquee.PressX, mMarquee.CurrentX);
		let y0 = (float)Math.Min(mMarquee.PressY, mMarquee.CurrentY);
		let x1 = (float)Math.Max(mMarquee.PressX, mMarquee.CurrentX) + 1.0f;
		let y1 = (float)Math.Max(mMarquee.PressY, mMarquee.CurrentY) + 1.0f;
		let fill = Color(0.35f, 0.6f, 1.0f, 0.18f);
		let edge = Color(0.55f, 0.75f, 1.0f, 0.9f);
		drawList.DrawScreenRect(x0, y0, x1 - x0, y1 - y0, fill);
		drawList.DrawScreenRect(x0, y0, x1 - x0, 1.0f, edge);
		drawList.DrawScreenRect(x0, y1 - 1.0f, x1 - x0, 1.0f, edge);
		drawList.DrawScreenRect(x0, y0, 1.0f, y1 - y0, edge);
		drawList.DrawScreenRect(x1 - 1.0f, y0, 1.0f, y1 - y0, edge);
	}

	public StringView StatusText => mGizmos.IsActive ? mGizmos.StatusText : default;

	private void PickOnClick(in ViewportToolInput input)
	{
		let cpu = CpuPick(input);
		let pixelValid = (input.ViewportWidth > 0) && (input.ViewportHeight > 0)
			&& (input.PointerX >= 0) && (input.PointerY >= 0)
			&& ((uint32)input.PointerX < input.ViewportWidth)
			&& ((uint32)input.PointerY < input.ViewportHeight);
		if ((mPicker != null) && pixelValid)
		{
			let request = mPicker.RequestPick(input.PointerX, input.PointerY, 1, 1);
			if (request != 0)
			{
				// The newest click wins: an older answer still in flight is ignored when it
				// lands.
				mPendingPick = request;
				mPendingCpuPick = cpu;
				mPendingCtrl = input.Ctrl;
				return;
			}
		}
		ApplyPick(cpu, input.Ctrl);
	}

	private void PollPick()
	{
		if (mPicker == null)
			return;
		let scene = mEdit.Scene;
		if (mPendingMarquee != 0)
		{
			if (mPicker.TryTakePick(mPendingMarquee, mHits))
			{
				mPendingMarquee = 0;
				mPicked.Clear();
				for (let h in mHits)
				{
					if (scene.IsValid(h))
						mPicked.Add(scene.GetEntityId(h));
				}
				ApplyMarquee(mPicked, mMarqueeCtrl);
			}
		}
		if (mPendingPick == 0)
			return;
		if (!mPicker.TryTakePick(mPendingPick, mHits))
			return;
		mPendingPick = 0;
		var picked = mPendingCpuPick; // the GPU saw nothing drawn there: the CPU answer stands
		for (let h in mHits)
		{
			if (scene.IsValid(h))
			{
				picked = scene.GetEntityId(h);
				break;
			}
		}
		ApplyPick(picked, mPendingCtrl);
	}

	private void ApplyPick(Guid picked, bool ctrl)
	{
		let selection = mEdit.EntitySelection;
		if (picked != Guid())
		{
			if (ctrl)
				selection.Toggle(picked);
			else
				selection.Set(picked);
		}
		else if (!ctrl)
		{
			selection.Clear();
		}
	}

	/// The CPU pick: the nearest entity whose origin lies within a small, distance scaled
	/// radius of the click ray.
	private Guid CpuPick(in ViewportToolInput input)
	{
		let scene = mEdit.Scene;
		let origin = input.Ray.Origin;
		let dir = input.Ray.Direction;

		var best = Guid();
		var bestT = FloatMax;
		scene.ForEachEntity(scope [&](e) =>
		{
			let world = scene.GetWorldMatrix(e);
			let p = Float3(world.M[3][0], world.M[3][1], world.M[3][2]);
			let toCenter = p - origin;
			let t = Dot(toCenter, dir);
			if ((t <= 0.0f) || (t >= bestT))
				return;
			let closest = origin + dir * t;
			let d = p - closest;
			let radius = Max(0.15f, t * 0.02f);
			if (Dot(d, d) <= radius * radius)
			{
				bestT = t;
				best = scene.GetEntityId(e);
			}
		});
		return best;
	}
}
