namespace Bulkan;

extension VkClearColorValue
{
	public this(float r, float g, float b, float a = 1.0f) : this()
	{
		float32[0] = r;
		float32[1] = g;
		float32[2] = b;
		float32[3] = a;
	}

	public this(int32 r, int32 g, int32 b, int32 a = 255) : this()
	{
		int32[0] = r;
		int32[1] = g;
		int32[2] = b;
		int32[3] = a;
	}

	public this(uint32 r, uint32 g, uint32 b, uint32 a = 255) : this()
	{
		uint32[0] = r;
		uint32[1] = g;
		uint32[2] = b;
		uint32[3] = a;
	}
}
