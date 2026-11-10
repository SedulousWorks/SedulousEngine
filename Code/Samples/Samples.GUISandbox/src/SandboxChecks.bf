using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.GUI.Testing;
using Sedulous.Image;
using Sedulous.Image.IO;

namespace Samples.GUISandbox;

/// The sandbox's checks, each a command-line mode: --keys (typed and pointed input), --sweep
/// and --soak (every widget clicked, every page walked by keys and the pad), --mirror-audit
/// (every page laid out both ways), --image-tests (every page drawn offscreen and compared with
/// its reference, or written as its reference with --approve-images) and --bench (a page's frame
/// cost by stage).
extension GUISandboxApp
{
	// === The image tests ===

	public const uint32 cImageWidth = 960;
	public const uint32 cImageHeight = 720;
	/// Frames on the fixed clock before a page's picture.
	public const int32 cImageFrames = 40;
	/// Where the references are, under the data folder.
	public const String cImageReferences = "Tests/GUI/Images";

	private bool mImageTests = false;
	/// Empty compares; "shared" or "backend" writes the references.
	private String mApprove = new .() ~ delete _;
	private String mImageOut = new .("build/gui-images") ~ delete _;
	private String mBackendName = new .("vulkan") ~ delete _;
	private List<String> mImagePages = new .() ~ DeleteContainerAndItems!(_);
	private int mImagePage = 0;
	private int32 mImageFrame = 0;
	private uint32 mImagesDone = 0;
	private uint32 mImageFailures = 0;

	// === The bench ===

	private String mBenchPage = new .() ~ delete _;
	private uint32 mBenchFrames = 0;
	private uint32 mBenchFrame = 0;
	private double mBenchDraw = 0.0;
	private double mBenchPrepare = 0.0;
	private double mBenchGpu = 0.0;
	private uint64 mBenchVertices = 0;
	private uint64 mBenchCommands = 0;
	private uint64 mBenchDrawn = 0;
	private uint64 mBenchCulled = 0;
	/// The damage's bounds, as a share of the window, summed over the frames.
	private double mBenchDamaged = 0.0;

	// === The sweep, the soak and the mirror audit ===

	/// A step of the sweep: a page to show first (empty: none), the game menu opened, or the page
	/// walked by Tab, the arrows and the pad instead of a click at a point.
	private class SweepStep
	{
		public String Page = new .() ~ delete _;
		public bool Menu = false;
		public bool Keys = false;
		public Float2 At = .();
		public String What = new .() ~ delete _;
	}

	private bool mSweep = false;
	private bool mSweepDone = false;
	private bool mMirrorAudit = false;
	private bool mMirrorAuditDone = false;
	private uint32 mMirrorMisplaced = 0;
	private List<SweepStep> mSweepSteps = new .() ~ DeleteContainerAndItems!(_);
	private int mSweepNext = 0;
	/// What warned or erred while the sweep ran: a logger beside the application's.
	private SweepLog mSweepLog = new .() ~ delete _;
	/// The application's logger while the sweep listens in beside it, and whether it owned it.
	private ILogger mOuterLogger = null;
	private bool mOuterLoggerOwned = false;
	private bool mSweepListening = false;
	/// > 0: soaking, not sweeping once.
	private float mSoakSeconds = 0.0f;
	private String mSoakCsv = new .("gui-soak.csv") ~ delete _;
	private float mSoakStart = -1.0f;
	private float mSoakNextRow = 0.0f;
	/// Frame times (ms) since the last row.
	private List<float> mSoakFrames = new .() ~ delete _;
	private bool mSoakWriting = false;

	// === Setters for the command line ===

	/// --sweep: every page, then the game menu, each widget hovered, clicked and right-clicked,
	/// and each page walked by keys and the pad, one step a frame, each printed first (a crash's
	/// last line names its widget); then exit, failing if anything warned or erred while it ran.
	public void SetSweep(bool sweep) => mSweep = sweep;
	/// --mirror-audit: each page laid out left to right and then right to left, in one language
	/// (its text measures the same both ways); every widget must stand at the mirror of its
	/// left-to-right place within the page. Prints each that does not; exits 1 if any did.
	public void SetMirrorAudit(bool on) => mMirrorAudit = on;
	/// --soak <minutes> [--soak-csv <path>]: the sweep's steps over and over for that long, a CSV
	/// row every ten seconds (frame time percentiles, resident memory).
	public void SetSoak(float minutes)
	{
		mSoakSeconds = Math.Max(0.0f, minutes) * 60.0f;
		mSweep = mSoakSeconds > 0.0f;
	}
	public void SetSoakCsv(StringView path) => mSoakCsv.Set(path);
	/// --image-tests: each page drawn offscreen at a fixed size on a fixed clock, compared with its
	/// reference; --approve-images writes the pictures as the references instead.
	public void SetImageTests(bool on) => mImageTests = on;
	/// "shared": the references every backend compares with; "backend": this backend's own.
	public void SetApproveImages(StringView how)
	{
		mImageTests = true;
		mApprove.Set(how);
	}
	public void SetImageOut(StringView directory) => mImageOut.Set(directory);
	/// --bench <page> [frames]: the page drawn offscreen at the image tests' size, its title's text
	/// changed each frame (the smallest change a frame can carry), and the frames' average cost
	/// printed by stage: the GUI's draw, the renderer's prepare, the GPU's work.
	public void SetBench(StringView page, uint32 frames)
	{
		mBenchPage.Set(page);
		mBenchFrames = Math.Max(frames, 1U);
	}
	public void SetBackendName(StringView name) => mBackendName.Set(name);

	/// The image tests and the bench draw offscreen on a fixed clock: the window shows nothing.
	private bool DrawsOffscreen => mImageTests || !mBenchPage.IsEmpty;

	/// What Main returns: a check's verdict (77, skipped, when no device came up), else the run's.
	public int ImageExitCode(int runCode)
	{
		if (mMirrorAudit)
			return mMirrorAuditDone ? ((mMirrorMisplaced == 0) ? 0 : 1) : 77;
		if (!mImageTests)
			return mSweep ? SweepExitCode() : runCode;
		if (mImagesDone == 0)
			return 77;
		return (mImageFailures == 0) ? 0 : 1;
	}

	/// The sweep's verdict: 77 (skipped) when it never ran (no device), else whether anything warned.
	public int SweepExitCode()
	{
		if (!mSweepDone)
			return 77;
		if (mSweepLog.Problems != 0)
			Console.WriteLine("GUISandbox sweep: {} warnings or errors", mSweepLog.Problems);
		return (mSweepLog.Problems == 0) ? 0 : 1;
	}

	// === --keys ===

	/// --keys: the named keystrokes, one every 15 frames once the GUI is up.
	private void TypeKeys(SceneRoot root)
	{
		if (mKeys.IsEmpty || (mFrames < 10) || (((mFrames - 10) % 15) != 0))
			return;
		let keys = scope List<StringView>();
		SplitTopLevel(mKeys, ' ', keys);
		let index = (int)((mFrames - 10) / 15);
		if (index >= keys.Count)
			return;
		// Pointer steps (logical units, as a screenshot is): click:x,y rclick:x,y move:x,y down:x,y
		// up:x,y, and two fingers' pinch:, turn: and pan2:; or at the middle of what a selector or
		// a text finds: click:#ok, click:text=Show, move:text~=Sett (no spaces: a step ends at one).
		let step = keys[index];
		let colon = step.IndexOf(':');
		if (colon >= 0)
		{
			let verb = step.Substring(0, colon);
			let place = step.Substring(colon + 1);
			let comma = place.IndexOf(',');
			let scale = root.DisplayScale;
			let xText = (comma >= 0) ? place.Substring(0, comma) : place;
			let yText = (comma >= 0) ? place.Substring(comma + 1) : StringView();
			Float2 at = .(float.Parse(xText).GetValueOrDefault() * scale, float.Parse(yText).GetValueOrDefault() * scale);
			let numeric = !place.IsEmpty && (place[0].IsDigit || (place[0] == '-'));
			if (!numeric)
			{
				let found = scope List<Node>();
				Finder.Parse(place).All(root, found);
				if (found.IsEmpty)
				{
					Console.WriteLine("GUISandbox: --keys: {} found nothing", place);
					return;
				}
				let bounds = found[0].ScreenBounds;
				at = .(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			}
			let d = root.EventDispatcher;
			if (verb == "move")
				d.InjectMouseMove(at);
			else if (verb == "down")
				d.InjectMouseDown(at, .Left);
			else if (verb == "up")
				d.InjectMouseUp(at, .Left);
			else if ((verb == "click") || (verb == "rclick"))
			{
				Sedulous.GUI.MouseButton button = (verb == "click") ? .Left : .Right;
				d.InjectMouseMove(at);
				d.InjectMouseDown(at, button);
				d.InjectMouseUp(at, button);
			}
			else if ((verb == "pinch") || (verb == "turn") || (verb == "pan2"))
			{
				// Two fingers about it: pinch spreads them from 100 to 200 apart, turn turns them a
				// quarter, pan2 moves them together 60 across and 30 down (logical units).
				let half = 50.0f * scale;
				let spread = (verb == "pinch") ? 2.0f : 1.0f;
				let turn = (verb == "turn") ? Math.PI_f * 0.5f : 0.0f;
				Float2 by = (verb == "pan2") ? .(60.0f * scale, 30.0f * scale) : .(0.0f, 0.0f);
				d.InjectTouchDown(1, Finger(at, by, half, spread, turn, 0.0f, -1.0f));
				d.InjectTouchDown(2, Finger(at, by, half, spread, turn, 0.0f, 1.0f));
				for (int i = 1; i <= 8; i++)
				{
					let t = (float)i / 8.0f;
					d.InjectTouchMove(1, Finger(at, by, half, spread, turn, t, -1.0f));
					d.InjectTouchMove(2, Finger(at, by, half, spread, turn, t, 1.0f));
				}
				d.InjectTouchUp(2, Finger(at, by, half, spread, turn, 1.0f, 1.0f));
				d.InjectTouchUp(1, Finger(at, by, half, spread, turn, 1.0f, -1.0f));
			}
			mMenuWantsUpdate = true;
			return;
		}
		let parsed = ParseKeystroke(step);
		if (parsed.HasValue)
		{
			let stroke = parsed.Value;
			if (stroke.Pad)
				root.EventDispatcher.InjectPadButton((PadButton)stroke.Code);
			else
				root.EventDispatcher.InjectKeyDown(stroke.Code, stroke.Modifiers);
			mMenuWantsUpdate = true;
		}
	}

	/// One of the two fingers of a gesture at `t` (0 to 1) of its way, on `side` (-1 or 1).
	private static Float2 Finger(Float2 at, Float2 by, float half, float spread, float turn, float t, float side)
	{
		let reach = half * (1.0f + (spread - 1.0f) * t) * side;
		return .(at.X + by.X * t + reach * Math.Cos(turn * t), at.Y + by.Y * t + reach * Math.Sin(turn * t));
	}

	// === The sweep and the soak ===

	/// The widgets under `node` a sweep visits: shown, sized, in the tree's order.
	private static void CollectSweep(Node node, List<Node> outNodes)
	{
		if (!node.Visible)
			return;
		if ((node.Size.X > 0.0f) && (node.Size.Y > 0.0f) && (node is UIWidget))
			outNodes.Add(node);
		for (int i = 0; i < node.ChildCount; i++)
			CollectSweep(node.GetChildAt(i), outNodes);
	}

	/// From here on a warning fails the sweep: its logger listens beside the application's.
	private void ListenForProblems()
	{
		if (mSweepListening)
			return;
		mOuterLogger = DetachGlobalLogger(out mOuterLoggerOwned);
		let composite = new CompositeLogger();
		composite.Add(mOuterLogger); // not owned: given back when the sweep ends
		composite.Add(mSweepLog);
		InitGlobalLogger(composite, true);
		mSweepListening = true;
	}

	/// The application's logger back as it was.
	private void StopListeningForProblems()
	{
		if (!mSweepListening)
			return;
		ShutdownGlobalLogger(); // the composite, not what it held
		if (mOuterLogger != null)
			InitGlobalLogger(mOuterLogger, mOuterLoggerOwned);
		mOuterLogger = null;
		mSweepListening = false;
	}

	private void Sweep()
	{
		if (mFrames < 10)
			return;
		if (mSweepSteps.IsEmpty && (mSweepNext == 0))
		{
			// Plan it: each page shown in turn, its widgets' centres as they lie once shown.
			for (let page in mPages)
			{
				if (page.Id == "stress")
					continue; // thousands of widgets: a smoke test of every one would take minutes
				ShowPage(page.Id);
				mRoot.UpdateLayout();
				let nodes = scope List<Node>();
				CollectSweep(page.Node, nodes);
				for (let node in nodes)
				{
					let bounds = node.ScreenBounds;
					if (bounds.Y + bounds.Height * 0.5f > (float)mHeight)
						continue; // below the fold
					let step = new SweepStep();
					step.Page.Set(page.Id);
					step.At = .(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
					node.DebugName(step.What);
					mSweepSteps.Add(step);
				}
				let keys = new SweepStep();
				keys.Page.Set(page.Id);
				keys.Keys = true;
				keys.What.Set("keys and pad");
				mSweepSteps.Add(keys);
			}
			ShowPage(mStartPage);
			let menu = new SweepStep();
			menu.Menu = true;
			menu.What.Set("open the game menu");
			mSweepSteps.Add(menu);
			Console.WriteLine("GUISandbox sweep: {} steps", mSweepSteps.Count);
			ListenForProblems();
		}
		if ((mSoakSeconds > 0.0f) && (mSweepNext >= mSweepSteps.Count) && (mTotalTime - mSoakStart < mSoakSeconds))
			mSweepNext = 0; // soaking: round again
		if (mSweepNext >= mSweepSteps.Count)
		{
			StopListeningForProblems();
			mSweepDone = true;
			Console.WriteLine("GUISandbox sweep: done");
			Exit();
			return;
		}
		let step = mSweepSteps[mSweepNext++];
		Console.WriteLine("GUISandbox sweep {}: {} {} at {:F0}, {:F0}", mSweepNext, step.Page, step.What, step.At.X, step.At.Y);
		if (step.Menu)
		{
			OpenMenu();
			return;
		}
		if (step.Page != mCurrent)
			ShowPage(step.Page);
		if (step.Keys)
		{
			// Through the page by Tab, the arrows and the pad: what a keyboard or pad player reaches.
			let keys = mRoot.EventDispatcher;
			Sedulous.GUI.KeyCode[?] codes = .(.Tab, .Tab, .Down, .Right, .Up, .Left, .Space);
			for (let code in codes)
			{
				keys.InjectKeyDown((uint32)code);
				keys.InjectKeyUp((uint32)code);
			}
			keys.InjectPadButton(.South);
			keys.InjectPadButton(.East);
			keys.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Escape);
			return;
		}
		// Device pixels: the root's transform maps them (its display scale).
		Float2 at = .(step.At.X * mRoot.DisplayScale, step.At.Y * mRoot.DisplayScale);
		let d = mRoot.EventDispatcher;
		d.InjectMouseMove(at);
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
		d.InjectMouseDown(at, .Right);
		d.InjectMouseUp(at, .Right);
		d.InjectKeyDown((uint32)Sedulous.GUI.KeyCode.Escape); // close what a click opened
	}

	/// The process's resident memory in MiB (Linux; 0 elsewhere).
	private static double ResidentMiB()
	{
		let statm = scope String();
		if (File.ReadAllText("/proc/self/statm", statm) case .Err)
			return 0.0;
		var parts = statm.Split(' ');
		if (!(parts.GetNext() case .Ok))
			return 0.0;
		if (!(parts.GetNext() case .Ok(let resident)))
			return 0.0;
		return (double)uint64.Parse(resident).GetValueOrDefault() * 4096.0 / (1024.0 * 1024.0);
	}

	private void SoakFrame()
	{
		if (mSoakStart < 0.0f)
		{
			mSoakStart = mTotalTime;
			mSoakNextRow = mTotalTime + 10.0f;
			mSoakWriting = File.WriteAllText(mSoakCsv, "seconds,frames,p50_ms,p95_ms,p99_ms,resident_mib\n") case .Ok;
			Console.WriteLine("GUISandbox soak: {:F1} minutes, rows in {}", mSoakSeconds / 60.0f, mSoakCsv);
		}
		mSoakFrames.Add(mDeltaTime * 1000.0f);
		if ((mTotalTime < mSoakNextRow) || mSoakFrames.IsEmpty)
			return;
		mSoakNextRow += 10.0f;
		let sorted = scope List<float>();
		sorted.AddRange(mSoakFrames);
		sorted.Sort();
		let p50 = Percentile(sorted, 0.5f);
		let p95 = Percentile(sorted, 0.95f);
		let p99 = Percentile(sorted, 0.99f);
		let resident = ResidentMiB();
		Console.WriteLine("GUISandbox soak {:F0}s: p50 {:F2} ms, p95 {:F2} ms, p99 {:F2} ms, {:F1} MiB resident",
			mTotalTime - mSoakStart, p50, p95, p99, resident);
		if (mSoakWriting)
		{
			let row = scope String()..AppendF("{:F1},{},{:F3},{:F3},{:F3},{:F2}\n", mTotalTime - mSoakStart, sorted.Count, p50, p95, p99, resident);
			File.WriteAllText(mSoakCsv, row, true).IgnoreError(); // a row at a time: a crash keeps the rows before it
		}
		mSoakFrames.Clear();
		if (mTotalTime - mSoakStart >= mSoakSeconds)
			mSoakWriting = false;
	}

	/// The sorted frame times' value `share` of the way up.
	private static float Percentile(List<float> sorted, float share)
	{
		return sorted[Math.Min(sorted.Count - 1, (int)(share * (float)sorted.Count))];
	}

	// === The mirror audit ===

	/// Styled and laid out as a frame would, without drawing.
	private void Settle()
	{
		LayOutShell();
		mGui.Update(TimeSpan(TimeSpan.TicksPerSecond / 60));
		mStyles.MediaContext = mRoot.MediaContext;
		mStyles.ApplyTree(mRoot);
		mRoot.UpdateLayout();
	}

	/// The widgets a mirror audit checks: shown and sized, outside what is placed physically on
	/// purpose (a dock's sides, a popup or a window at a point, a canvas's children at theirs; what
	/// a window or a canvas's child holds is checked), what runs one way whatever the page (a
	/// direction set on it) and an item view's rows, which it recycles from item to item (the unit
	/// tests check theirs).
	private static void CollectMirrored(Node node, List<Node> outNodes, bool placed = false)
	{
		if (!node.Visible || !node.Displayed || node.InTopLayer)
			return;
		if (!placed && (node.Size.X > 0.0f) && (node.Size.Y > 0.0f) && (node is UIWidget) && !(node is Sedulous.GUI.Window))
			outNodes.Add(node);
		if ((node.LayoutStyle.Kind == .Dock) || (node is ItemView))
			return;
		for (int i = 0; i < node.ChildCount; i++)
		{
			let child = node.GetChildAt(i);
			let direction = child.GetLayoutDirection(); // the page's own is the audit's
			if ((direction != .LeftToRight) && (direction != .RightToLeft))
				CollectMirrored(child, outNodes, node.PlacesChildren);
		}
	}

	/// A widget's layout box within its parent before the page turned right to left.
	private struct Placed
	{
		public Node Node;
		public Float2 At;
		public Float2 Size;

		public this(Node node, Float2 at, Float2 size)
		{
			Node = node;
			At = at;
			Size = size;
		}
	}

	private void MirrorAudit()
	{
		// Each widget's layout box within its parent (before its own transform, which CSS keeps
		// physical, and its parent's scroll): in right to left, at the mirror of where it was.
		uint32 widgets = 0;
		for (let page in mPages)
		{
			if ((page.Id == "stress") || (page.Id == "motion"))
				continue; // thousands of widgets all alike; things on the move
			ShowPage(page.Id);
			page.Node.SetLayoutDirection(.LeftToRight);
			for (int i < 3)
				Settle(); // rows measured once styled, a frame on
			let nodes = scope List<Node>();
			CollectMirrored(page.Node, nodes);
			let before = scope List<Placed>();
			for (let node in nodes)
			{
				if ((node != page.Node) && (node.Parent != null))
					before.Add(.(node, node.Position, node.Size));
			}
			page.Node.SetLayoutDirection(.RightToLeft);
			for (int i < 3)
				Settle();
			for (let p in before)
			{
				widgets++;
				let at = p.Node.Position;
				let want = p.Node.Parent.Size.X - p.At.X - p.Size.X;
				if ((Math.Abs(at.X - want) <= 1.0f) && (Math.Abs(p.Node.Size.X - p.Size.X) <= 1.0f) && (Math.Abs(at.Y - p.At.Y) <= 1.0f))
					continue;
				mMirrorMisplaced++;
				let what = p.Node.DebugName(.. scope String());
				if (let label = p.Node as Sedulous.GUI.Label)
					what.AppendF(" \"{}\"", label.Text.Substring(0, Math.Min(label.Text.Length, 24)));
				Console.WriteLine("GUISandbox mirror: {} {} in {} at x {:F1}, wanted {:F1} (left to right {:F1}, {:F1} wide; y {:F1} from {:F1})",
					page.Id, what, p.Node.Parent.DebugName(.. scope String()), at.X, want, p.At.X, p.Size.X, at.Y, p.At.Y);
			}
			page.Node.SetLayoutDirection(.Inherit);
		}
		ShowPage(mStartPage);
		Console.WriteLine("GUISandbox mirror: {} widgets, {} misplaced", widgets, mMirrorMisplaced);
		mMirrorAuditDone = true;
		Exit();
	}

	// === The image tests ===

	/// The image tests: each page shown, run on a fixed clock at a fixed size and scale 1, drawn
	/// offscreen and read back through the RHI, so the backend in use is the one tested; the
	/// picture goes to --image-out, and is compared with its reference under
	/// Data/Tests/GUI/Images: its own backend's when there is one, else the one the backends
	/// share. A miss writes a diff beside the picture. --approve-images writes the shared reference
	/// (or, with "backend", this backend's own), which is for after the user has looked at the
	/// pictures: the references are pictures this engine drew.
	private void RunImageTests()
	{
		if (mImagePages.IsEmpty && (mImagePage == 0))
		{
			for (let page in mPages)
			{
				if (page.Id == "stress")
					continue; // its numbers are the machine's
				mImagePages.Add(new String(page.Id));
				if (page.Id == "language")
					mImagePages.Add(new String("language@ar")); // and right to left, in Arabic
			}
			if ((mOffscreen == null) || !mOffscreen.IsReady)
			{
				Console.WriteLine("GUISandbox: image tests: no offscreen target");
				Exit();
				return;
			}
			CreateDirectory(mImageOut);
		}
		if (mImagePage >= mImagePages.Count)
		{
			Console.WriteLine("GUISandbox: image tests on {}: {} pictures, {} failed", mBackendName, mImagesDone, mImageFailures);
			Exit();
			return;
		}
		// "<page>@<language>": the page in that language; any other in English. Pictured as
		// <page>.<language>.
		let entry = mImagePages[mImagePage];
		let at = entry.LastIndexOf('@');
		let another = at >= 0;
		StringView pageId = another ? entry.Substring(0, at) : (StringView)entry;
		StringView language = another ? entry.Substring(at + 1) : StringView("en");
		let id = scope String();
		if (another)
			id.AppendF("{}.{}", pageId, language);
		else
			id.Set(entry);
		if (mImageFrame == 0)
		{
			if ((mLocalization.Language != language) || mLocalization.Pseudolocalization.Enabled)
				SetLanguage(language);
			ShowPage(pageId);
		}
		// A fixed size and scale and a fixed clock: the same frames on every machine.
		mRoot.DisplayScale = 1.0f;
		mRoot.ViewportSize = .((float)cImageWidth, (float)cImageHeight);
		Settle();
		if (++mImageFrame < cImageFrames)
			return;
		mImageFrame = 0;
		mImagePage++;

		let name = scope $"{id}.{mBackendName}";
		let picturePath = scope $"{mImageOut}/{name}.png";
		let picture = scope Sedulous.Image.Image();
		// A frame first, uncaptured, when a picture is waiting to be baked: the capture shows the
		// page as every frame after its first does.
		if (let baker = mGuiHost.Baker)
		{
			let bakes = baker.Generation;
			mOffscreen.Draw(mRoot);
			if (baker.Generation != bakes)
				mRoot.NeedsFrame(); // the root redraws from the bakes
		}
		if (!mOffscreen.Picture(mRoot, picturePath, picture))
		{
			Console.WriteLine("GUISandbox: image {}: could not be drawn", name);
			mImageFailures++;
			return;
		}
		mImagesDone++;
		let shared = DataFile(scope $"{cImageReferences}/{id}.png", .. scope String());
		let own = DataFile(scope $"{cImageReferences}/{name}.png", .. scope String());
		if (!mApprove.IsEmpty)
		{
			let to = (mApprove == "backend") ? own : shared;
			CreateDirectory(DataFile(cImageReferences, .. scope String()));
			let saved = ImageIO.SaveImage(picture, to, .PNG) case .Ok;
			Console.WriteLine("GUISandbox: image {}: {} {}", name, saved ? "approved as" : "could not write", to);
			if (!saved)
				mImageFailures++;
			return;
		}
		let referencePath = File.Exists(own) ? own : shared;
		let reference = scope Sedulous.Image.Image();
		if (!File.Exists(referencePath) || (ImageIO.LoadImage(referencePath, reference) case .Err))
		{
			Console.WriteLine("GUISandbox: image {}: FAIL, no reference (look at {}, then --approve-images)", name, picturePath);
			mImageFailures++;
			return;
		}
		let rgba = reference.ConvertFormat(.RGBA8);
		defer delete rgba;
		let diff = scope Sedulous.Image.Image();
		let result = CompareImages(picture, rgba, 8, 0.001, diff);
		if (result.Matches)
		{
			Console.WriteLine("GUISandbox: image {}: ok ({} pixels past 8, largest difference {})", name, result.Differing, result.LargestDelta);
			return;
		}
		mImageFailures++;
		let diffPath = scope $"{mImageOut}/{name}.diff.png";
		if (result.SameSize)
			ImageIO.SaveImage(diff, diffPath, .PNG).IgnoreError();
		Console.WriteLine("GUISandbox: image {}: FAIL against {}: {}{} of {} pixels past 8 (largest {}); see {}", name, referencePath,
			result.SameSize ? "" : "not the same size; ", result.Differing, result.Pixels, result.LargestDelta, diffPath);
	}

	// === The bench ===

	/// The bench: settle the page, then time frames that each change the page title's text.
	private void RunBench()
	{
		const uint32 cSettle = 30;
		if (mBenchFrame == 0)
		{
			if ((mOffscreen == null) || !mOffscreen.IsReady)
			{
				Console.WriteLine("GUISandbox: bench: no offscreen target");
				Exit();
				return;
			}
			ShowPage(mBenchPage);
		}
		mRoot.DisplayScale = 1.0f;
		mRoot.ViewportSize = .((float)cImageWidth, (float)cImageHeight);
		let measured = (mBenchFrame >= cSettle) ? mBenchFrame - cSettle : 0;
		if (mBenchFrame >= cSettle)
		{
			for (let page in mPages)
			{
				if ((page.Id != mBenchPage) || (page.Node == null) || (page.Node.ChildCount == 0))
					continue;
				if (let title = page.Node.GetChildAt(0) as Sedulous.GUI.Label) // the page's title
					title.Text = scope $"{mBenchPage} {measured}";
			}
		}
		Settle();
		GuiOffscreen.Times times;
		if (!mOffscreen.Draw(mRoot, out times))
		{
			Console.WriteLine("GUISandbox: bench: a frame could not be drawn");
			Exit();
			return;
		}
		if (mBenchFrame++ < cSettle)
			return;
		let stats = mRoot.LastFrameStats;
		mBenchDraw += stats.DrawMs;
		mBenchPrepare += times.Prepare;
		mBenchGpu += times.Gpu;
		mBenchVertices += stats.Vertices;
		mBenchCommands += stats.Commands;
		mBenchDrawn += stats.NodesDrawn;
		mBenchCulled += stats.NodesCulled;
		let damage = mRoot.LastDamageBounds;
		mBenchDamaged += (double)(damage.Width * damage.Height) / (double)(cImageWidth * cImageHeight);
		if (measured + 1 < mBenchFrames)
			return;
		let n = (double)mBenchFrames;
		Console.WriteLine("GUISandbox bench {} on {}, {} frames, {}x{}, each changing one label: draw {:F3} ms, prepare {:F3} ms, gpu+wait {:F3} ms; {:F0} nodes drawn, {:F0} culled, {:F0} vertices, {:F0} commands; damage {:F1}% of the window",
			mBenchPage, mBackendName, mBenchFrames, cImageWidth, cImageHeight, mBenchDraw / n, mBenchPrepare / n, mBenchGpu / n,
			(double)mBenchDrawn / n, (double)mBenchCulled / n, (double)mBenchVertices / n, (double)mBenchCommands / n, 100.0 * mBenchDamaged / n);
		Exit();
	}
}
