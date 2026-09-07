namespace Sedulous.RHI;

/// Colour and alpha blending, which are configured independently.
struct BlendState
{
	public BlendComponent Color = .();
	public BlendComponent Alpha = .();

	public this() {}

	public this(BlendComponent color, BlendComponent alpha)
	{
		Color = color; Alpha = alpha;
	}

	/// Ordinary alpha blending: srcAlpha times source, plus one minus srcAlpha times what
	/// is there.
	public static BlendState AlphaBlend => .(
		.(.SrcAlpha, .OneMinusSrcAlpha, .Add),
		.(.One, .OneMinusSrcAlpha, .Add));

	/// For source whose colour is already multiplied by its alpha, which composites
	/// correctly through intermediate targets where straight alpha does not.
	public static BlendState PremultipliedAlpha => .(
		.(.One, .OneMinusSrcAlpha, .Add),
		.(.One, .OneMinusSrcAlpha, .Add));

	/// Accumulate, as the bloom upsample chain does.
	public static BlendState Additive => .(
		.(.One, .One, .Add),
		.(.One, .One, .Add));

	public static BlendState Multiply => .(
		.(.Dst, .Zero, .Add),
		.(.DstAlpha, .Zero, .Add));
}
