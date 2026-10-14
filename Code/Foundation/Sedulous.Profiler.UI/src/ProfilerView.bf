using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Profiler;
using Sedulous.UI;

namespace Sedulous.Profiler.UI;

/// The colours every view draws with: the CPU in blue, the GPU in amber, on a dark panel.
struct ProfilerPalette
{
	public Color Panel = .(0.05f, 0.06f, 0.08f, 0.82f);
	public Color Plot = .(1.0f, 1.0f, 1.0f, 0.05f);
	public Color Text = .(0.94f, 0.95f, 0.97f, 1.0f);
	public Color Dim = .(0.66f, 0.69f, 0.74f, 1.0f);
	public Color Cpu = .(0.36f, 0.70f, 1.0f, 1.0f);
	public Color Gpu = .(1.0f, 0.64f, 0.26f, 1.0f);
	public Color Budget = .(1.0f, 1.0f, 1.0f, 0.28f);

	public this() {}
}

/// A source with no frames: what a view reads before it is given one.
class EmptyProfileSource : IProfileSource
{
	public uint64 TickFrequency => 1;
	public bool HasFrames => false;
	public uint64 OldestFrame => 0;
	public uint64 NewestFrame => 0;
	public FrameRecord Frame(uint64 frameNumber) => null;
	public StringView NameOf(uint32 id) => default;
	public uint32 NameCount => 0;
	public Span<ThreadInfo> Threads => default;
	public Span<CounterInfo> Counters => default;
}

/// What every profiler view shares: the source it reads (the live store or a capture), how
/// many of the newest frames it looks at, the palette, and text drawn when the context has
/// fonts (a headless test's has none, and the view draws its shapes alone). A view computes
/// what it shows in Compute, from the source, and draws that; tests read the same model.
abstract class ProfilerView : View
{
	public const float FontSize = 11.0f;
	public const float LineHeight = 15.0f;

	private static EmptyProfileSource sEmpty = new .() ~ delete _;

	protected IProfileSource mSource;
	protected uint32 mFrameCount = 120;

	public ProfilerPalette Palette = .();

	public this()
	{
		IsHitTestVisible = false; // it shows, never takes the pointer from the game
	}

	/// What the view reads; null shows nothing. BORROWED: the source outlives the view.
	public IProfileSource Source
	{
		get => mSource;
		set
		{
			mSource = value;
			Refresh();
		}
	}

	/// How many of the newest frames it looks at.
	public uint32 FrameCount
	{
		get => mFrameCount;
		set
		{
			mFrameCount = Math.Max(value, 1);
			Refresh();
		}
	}

	/// Recomputes what it shows from the source (a new frame arrived) and asks for a draw.
	public void Refresh()
	{
		Compute();
		InvalidateVisual();
	}

	/// Fills the view's model from the source; called with a null source too.
	protected abstract void Compute();

	/// The source, or one with no frames, so a view reads the same either way.
	protected IProfileSource SourceOrEmpty => (mSource != null) ? mSource : sEmpty;

	protected FrameRange Range => (mSource != null) ? ProfileWindow.LastFrames(mSource, mFrameCount) : FrameRange();

	protected static void DrawLabel(UIDrawContext ctx, StringView text, Rectangle bounds, Color color,
		TextAlignment align = .Left)
	{
		if ((ctx.FontService == null) || text.IsEmpty)
			return;
		if (let font = ctx.FontService.GetFont(FontSize))
			ctx.VG.DrawText(text, font, bounds, align, .Middle, color);
	}
}
