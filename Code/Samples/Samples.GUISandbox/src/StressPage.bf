using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Samples.GUISandbox;

/// The Stress page (E8a of Raptor's gui-lab-evolution.md): the worst case the GUI's performance
/// work is measured on. Its markup (pages/stress.xml) holds the controls; this builds the sections
/// into #stress-root at a load from 1 to 20: a long column of rows, text in several faces and
/// sizes, every box effect at once, running animations, a list and a table of 100,000 rows, deep
/// nesting, and many generated rules (Rules) for the cascade to match against.
class StressPage
{
	/// The rows of the list and of the table, whatever the load (they are virtualized).
	public const int32 cViewRows = 100000;
	/// Classes the rows take in turn, which the generated rules name.
	public const int32 cRowKinds = 50;

	private CachedFont mFont = null;
	/// In the page, which the sandbox owns: borrowed, all three.
	private Node mRoot = null;
	private Sedulous.GUI.Label mStats = null;
	private Node mAnimations = null;
	private int32 mLoad = 1;
	private bool mBuilt = false;
	private bool mAlt = false;
	private bool mAnimating = true;
	// The views' models: the sandbox keeps this page alive longer than its GUI, so the views (their
	// clients) go first.
	private StringListModel mListModel = null ~ delete _;
	private TableModel mTableModel = null ~ delete _;

	/// `font` is borrowed (null: the views' default).
	public this(CachedFont font)
	{
		mFont = font;
	}

	/// Rules for the page's sheet, appended to `outCss`: `count` of them, most matching nothing,
	/// as a large stylesheet's do, the rest matching rows through descendant and child selectors.
	public static void Rules(int32 count, String outCss)
	{
		for (int32 i = 0; i < count; i++)
		{
			let kind = i % cRowKinds;
			switch (i % 4)
			{
			case 0: outCss.AppendF(".stress-root .k{} > .cell {{ margin-left: 0px; }}\n", kind);
			case 1: outCss.AppendF(".alt .k{} .tag {{ letter-spacing: 0px; }}\n", kind);
			case 2: outCss.AppendF(".unused-{} .stress-row .note {{ color: #ff00ff; }}\n", i);
			default: outCss.AppendF(".stress-row.k{} + .stress-row > .cell {{ border-radius: 3px; }}\n", kind);
			}
		}
	}

	/// Finds its controls and its root under `page` and wires them.
	public void Attach(Node page)
	{
		mRoot = page.FindElement("stress-root");
		mStats = page.FindElement("stress-stats") as Sedulous.GUI.Label;
		let load = page.FindElement("stress-load") as NumberField;
		if (let build = page.FindElement("stress-build") as Sedulous.GUI.Button)
			build.SetOnClick(new () => { Build((load != null) ? (int32)load.Value : 1); });
		if (let restyle = page.FindElement("stress-restyle") as Sedulous.GUI.Button)
			restyle.SetOnClick(new () => { ToggleAlt(); });
		if (let animate = page.FindElement("stress-animate") as CheckBox)
			animate.SetOnToggled(new (on) => { SetAnimating(on); });
		if (load != null)
			load.Value = (double)mLoad;
	}

	/// The load the page is built at (1 to 20) the first time it is shown.
	public void SetLoad(int32 load)
	{
		mLoad = Math.Clamp(load, 1, 20);
	}
	public int32 Load => mLoad;
	public bool IsBuilt => mBuilt;

	/// Builds the sections again at `load`.
	public void Build(int32 load)
	{
		if (mRoot == null)
			return;
		SetLoad(load);
		// Each section's build time is printed: building is part of the worst case too.
		let watch = scope Stopwatch(true);
		void Timed(StringView what)
		{
			Console.WriteLine("GUISandbox stress: {} built in {:F1} ms", what, watch.Elapsed.TotalMilliseconds);
			watch.Restart();
		}
		mAnimations = null; // goes with the old sections
		mRoot.RemoveAllChildren();
		Timed("the old sections removed");
		BuildColumn(Section("Rows", "stress-column"), 400 * mLoad);
		Timed("rows");
		BuildText(Section("Text", "stress-text"), 40 * mLoad);
		Timed("text");
		BuildEffects(Section("Box effects", "stress-wrap"), 24 * mLoad);
		Timed("effects");
		BuildAnimations(Section("Animations", "stress-anim"), 150 * mLoad);
		Timed("animations");
		BuildViews(Section("A list and a table of 100,000 rows", "stress-views"));
		Timed("views");
		BuildDeep(Section("Nesting", "stress-deep"), Math.Min(100 * mLoad, 500));
		Timed("nesting");
		mBuilt = true;
	}

	/// Shows the last frame's costs on the page.
	public void ShowStats(FrameStats stats)
	{
		if (mStats == null)
			return;
		let text = scope String();
		text.AppendF("Last frame at load {}: ", mLoad);
		stats.Describe(text);
		mStats.Text = text;
	}

	/// A new `T` made the last child of `parent`, with `cls` when given. Borrowed: the tree holds it.
	private T Add<T>(Node parent, StringView cls = default) where T : UIWidget, new
	{
		let node = new T();
		if (!cls.IsEmpty)
			node.AddClass(cls);
		parent.AddChild(node);
		node.ReleaseRef(); // the tree's keeps it
		return node;
	}

	private Sedulous.GUI.Label AddLabel(Node parent, StringView cls, StringView text)
	{
		let label = Add<Sedulous.GUI.Label>(parent, cls);
		label.Text = text;
		return label;
	}

	/// A titled section whose body (returned) takes `cls`.
	private Node Section(StringView title, StringView cls)
	{
		let section = Add<Panel>(mRoot, "section");
		AddLabel(section, "section-title", title);
		return Add<Panel>(section, cls);
	}

	private void BuildColumn(Node column, int32 rows)
	{
		for (int32 i = 0; i < rows; i++)
		{
			let row = Add<Panel>(column, "stress-row");
			row.AddClass(scope $"k{i % cRowKinds}");
			AddLabel(row, "tag", scope $"Row {i}");
			Add<UIWidget>(row, "cell");
			Add<UIWidget>(row, "cell");
			AddLabel(row, "note", "a note that the sibling rules dim");
		}
	}

	private void BuildText(Node body, int32 count)
	{
		StringView[4] sizes = .("t1", "t2", "t3", "t4");
		for (int32 i = 0; i < count; i++)
		{
			if (i % 5 == 4)
			{
				let rich = Add<RichText>(body, "t");
				rich.AddClass(sizes[i % 4]);
				rich.WhiteSpace = .Normal;
				rich.Text = "Rich text with [b]bold[/b], [i]italic[/i] and [color=#e69138]coloured[/color] runs, wrapped at the page's width like the rest.";
				continue;
			}
			let label = AddLabel(body, "t", scope $"Line {i}: a sentence long enough to wrap onto a second line at the page's width, shaped and measured every time the text or its width changes.");
			label.AddClass(sizes[i % 4]);
			label.WhiteSpace = .Normal;
		}
	}

	private void BuildEffects(Node body, int32 count)
	{
		StringView[5] kinds = .("", "fx-glass", "fx-blur", "fx-multiply", "fx-group");
		for (int32 i = 0; i < count; i++)
		{
			let kind = kinds[i % 5];
			if (kind == "fx-group")
			{
				// A group fading as one picture, with children of its own.
				let group = Add<Panel>(body, "fx");
				group.AddClass(kind);
				AddLabel(group, "", "group");
				AddLabel(group, "", "of two");
				continue;
			}
			let cell = AddLabel(body, "fx", scope $"effect {i}");
			if (!kind.IsEmpty)
				cell.AddClass(kind);
		}
	}

	private void BuildAnimations(Node body, int32 count)
	{
		mAnimations = body;
		for (int32 i = 0; i < count; i++)
		{
			let cell = Add<UIWidget>(body, (i % 2 == 0) ? "spin" : "pulse");
			cell.SetInlineStyle("animation-delay", scope $"{(i * 37) % 1000}ms");
		}
		SetAnimating(mAnimating);
	}

	private void BuildViews(Node body)
	{
		if (mListModel == null)
		{
			// Made once: the rows are the same whatever the load.
			mListModel = new .();
			let texts = scope List<String>(cViewRows);
			defer texts.ClearAndDeleteItems();
			let rows = scope List<StringView>(cViewRows);
			for (int32 i = 0; i < cViewRows; i++)
			{
				let text = new String()..AppendF("List row {}", i);
				texts.Add(text);
				rows.Add(text);
			}
			mListModel.SetItems(rows);

			mTableModel = new .();
			StringView[3] columns = .("Name", "Score", "Group");
			mTableModel.SetColumns(columns);
			let name = scope String();
			let group = scope String();
			for (int32 i = 0; i < cViewRows; i++)
			{
				name..Clear().AppendF("Entry {}", i);
				group..Clear().AppendF("G{}", i % 12);
				// Views: the model keeps copies of them.
				Sedulous.GUI.Variant[3] cells = .(.(name), .((int64)((i * 7919) % 1000)), .(group));
				mTableModel.AddRow(cells);
			}
		}
		let list = Add<ListView>(body);
		list.Size = .(260.0f, 240.0f);
		list.Font = mFont;
		list.RowHeight = 22.0f;
		list.Model = mListModel;
		let table = Add<TableView>(body);
		table.Size = .(360.0f, 240.0f);
		table.Font = mFont;
		table.RowHeight = 22.0f;
		table.Model = mTableModel;
	}

	private void BuildDeep(Node body, int32 levels)
	{
		Node at = body;
		for (int32 i = 0; i < levels; i++)
			at = Add<Panel>(at, "deep");
		AddLabel(at, "", scope $"{levels} levels down");
	}

	private void ToggleAlt()
	{
		let root = mRoot as UIWidget;
		if (root == null)
			return;
		mAlt = !mAlt;
		if (mAlt)
			root.AddClass("alt");
		else
			root.RemoveClass("alt");
	}

	private void SetAnimating(bool animating)
	{
		mAnimating = animating;
		let body = mAnimations as UIWidget;
		if (body == null)
			return;
		if (animating)
			body.RemoveClass("still");
		else
			body.AddClass("still");
	}
}
