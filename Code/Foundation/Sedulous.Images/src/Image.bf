using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Images;

public enum PixelFormat
{
	// 8-bit formats
	R8,           // 1 byte per pixel
	RG8,          // 2 bytes per pixel
	RGB8,         // 3 bytes per pixel
	RGBA8,        // 4 bytes per pixel

	// 16-bit float formats
	R16F,         // 2 bytes per pixel
	RG16F,        // 4 bytes per pixel
	RGB16F,       // 6 bytes per pixel
	RGBA16F,      // 8 bytes per pixel

	// 32-bit float formats
	R32F,         // 4 bytes per pixel
	RG32F,        // 8 bytes per pixel
	RGB32F,       // 12 bytes per pixel
	RGBA32F,      // 16 bytes per pixel

	// Special formats
	BGR8,         // 3 bytes per pixel (common in some file formats)
	BGRA8,        // 4 bytes per pixel (common in Windows)
}

public class Image
{


	private uint8[] mData ~ delete _;
	private uint32 mWidth;
	private uint32 mHeight;
	private PixelFormat mFormat;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => mFormat;
	public Span<uint8> Data => mData;
	public uint32 PixelCount => mWidth * mHeight;
	public uint32 DataSize => PixelCount * (uint32)GetBytesPerPixel(mFormat);

	public this(uint32 width, uint32 height, PixelFormat format, uint8[] data = null)
	{
		mWidth = width;
		mHeight = height;
		mFormat = format;

		var dataSize = DataSize;
		mData = new uint8[dataSize];

		if (data != null && data.Count >= dataSize)
		{
			data[0..<dataSize].CopyTo(mData);
		}
		else
		{
			Clear();
		}
	}

	public this(Image other)
	{
		mWidth = other.mWidth;
		mHeight = other.mHeight;
		mFormat = other.mFormat;

		mData = new uint8[other.mData.Count];
		other.mData.CopyTo(mData);
	}

    // Clear image to default values
	public void Clear(Color? color = null)
	{
		if (color == null)
		{
			// Default: transparent black for RGBA, white for RGB, black for single channel
			switch (mFormat)
			{
			case .RGBA8, .RGBA16F, .RGBA32F, .BGRA8:
				FillColor(.(0, 0, 0, 0));
			case .RGB8, .RGB16F, .RGB32F, .BGR8:
				FillColor(.(255, 255, 255, 255));
			default:
				Internal.MemSet(mData.Ptr, 0, mData.Count);
			}
		}
		else
		{
			FillColor(color.Value);
		}
	}

    // Fill entire image with a color
	public void FillColor(Color color)
	{
		switch (mFormat)
		{
		case .R8:
			uint8 gray = (uint8)((color.R + color.G + color.B) / 3);
			Internal.MemSet(mData.Ptr, gray, mData.Count);

		case .RG8:
			for (int i = 0; i < mData.Count; i += 2)
			{
				mData[i] = color.R;
				mData[i + 1] = color.G;
			}

		case .RGB8:
			for (int i = 0; i < mData.Count; i += 3)
			{
				mData[i] = color.R;
				mData[i + 1] = color.G;
				mData[i + 2] = color.B;
			}

		case .RGBA8:
			for (int i = 0; i < mData.Count; i += 4)
			{
				mData[i] = color.R;
				mData[i + 1] = color.G;
				mData[i + 2] = color.B;
				mData[i + 3] = color.A;
			}

		case .BGR8:
			for (int i = 0; i < mData.Count; i += 3)
			{
				mData[i] = color.B;
				mData[i + 1] = color.G;
				mData[i + 2] = color.R;
			}

		case .BGRA8:
			for (int i = 0; i < mData.Count; i += 4)
			{
				mData[i] = color.B;
				mData[i + 1] = color.G;
				mData[i + 2] = color.R;
				mData[i + 3] = color.A;
			}

		default:
			// For float formats, convert color to float
			var floatColor = color.ToVector4();
			FillColorFloat(floatColor);
		}
	}

	private void FillColorFloat(Vector4 color)
	{
		switch (mFormat)
		{
		case .R32F:
			float gray = (color.X + color.Y + color.Z) / 3.0f;
			var floatData = (float*)mData.Ptr;
			for (int i = 0; i < PixelCount; i++)
				floatData[i] = gray;

		case .RGBA32F:
			var vec4Data = (Vector4*)mData.Ptr;
			for (int i = 0; i < PixelCount; i++)
				vec4Data[i] = color;

        // Add other float format cases as needed
		default:
			break;
		}
	}

    // Get pixel color at coordinates
	public Color GetPixel(uint32 x, uint32 y)
	{
		if (x >= mWidth || y >= mHeight)
			return .Black;

		var offset = GetPixelOffset(x, y);

		switch (mFormat)
		{
		case .R8:
			uint8 gray = mData[offset];
			return .(gray, gray, gray, 255);

		case .RGB8:
			return .(mData[offset], mData[offset + 1], mData[offset + 2], 255);

		case .RGBA8:
			return .(mData[offset], mData[offset + 1], mData[offset + 2], mData[offset + 3]);

		case .BGR8:
			return .(mData[offset + 2], mData[offset + 1], mData[offset], 255);

		case .BGRA8:
			return .(mData[offset + 2], mData[offset + 1], mData[offset], mData[offset + 3]);

		default:
			// Handle float formats
			return GetPixelFloat(x, y);
		}
	}

	private Color GetPixelFloat(uint32 x, uint32 y)
	{
		var offset = GetPixelOffset(x, y);

		switch (mFormat)
		{
		case .R32F:
			float gray = *((float*)&mData[offset]);
			uint8 grayByte = (uint8)(Math.Clamp(gray * 255.0f, 0, 255));
			return .(grayByte, grayByte, grayByte, 255);

		case .RGBA32F:
			var color = *((Vector4*)&mData[offset]);
			return .(
				(uint8)(Math.Clamp(color.X * 255.0f, 0, 255)),
				(uint8)(Math.Clamp(color.Y * 255.0f, 0, 255)),
				(uint8)(Math.Clamp(color.Z * 255.0f, 0, 255)),
				(uint8)(Math.Clamp(color.W * 255.0f, 0, 255))
			);

		default:
			return .Black;
		}
	}

    // Set pixel color at coordinates
	public void SetPixel(uint32 x, uint32 y, Color color)
	{
		if (x >= mWidth || y >= mHeight)
			return;

		var offset = GetPixelOffset(x, y);

		switch (mFormat)
		{
		case .R8:
			mData[offset] = (uint8)((color.R + color.G + color.B) / 3);

		case .RGB8:
			mData[offset] = color.R;
			mData[offset + 1] = color.G;
			mData[offset + 2] = color.B;

		case .RGBA8:
			mData[offset] = color.R;
			mData[offset + 1] = color.G;
			mData[offset + 2] = color.B;
			mData[offset + 3] = color.A;

		case .BGR8:
			mData[offset] = color.B;
			mData[offset + 1] = color.G;
			mData[offset + 2] = color.R;

		case .BGRA8:
			mData[offset] = color.B;
			mData[offset + 1] = color.G;
			mData[offset + 2] = color.R;
			mData[offset + 3] = color.A;

		default:
			SetPixelFloat(x, y, color.ToVector4());
		}
	}

	private void SetPixelFloat(uint32 x, uint32 y, Vector4 color)
	{
		var offset = GetPixelOffset(x, y);

		switch (mFormat)
		{
		case .R32F:
			float gray = (color.X + color.Y + color.Z) / 3.0f;
			*((float*)&mData[offset]) = gray;

		case .RGBA32F:
			*((Vector4*)&mData[offset]) = color;

		default:
			break;
		}
	}

    // Flip image vertically
	public void FlipVertical()
	{
		var rowSize = mWidth * (uint32)GetBytesPerPixel(mFormat);
		var tempRow = scope uint8[rowSize];

		for (uint32 y = 0; y < mHeight / 2; y++)
		{
			var topRow = y * rowSize;
			var bottomRow = (mHeight - 1 - y) * rowSize;

			// Swap rows
			Internal.MemCpy(tempRow.Ptr, &mData[topRow], rowSize);
			Internal.MemCpy(&mData[topRow], &mData[bottomRow], rowSize);
			Internal.MemCpy(&mData[bottomRow], tempRow.Ptr, rowSize);
		}
	}

    // Flip image horizontally
	public void FlipHorizontal()
	{
		var bytesPerPixel = GetBytesPerPixel(mFormat);
		var tempPixel = scope uint8[bytesPerPixel];

		for (uint32 y = 0; y < mHeight; y++)
		{
			for (uint32 x = 0; x < mWidth / 2; x++)
			{
				var leftOffset = GetPixelOffset(x, y);
				var rightOffset = GetPixelOffset(mWidth - 1 - x, y);

				// Swap pixels
				Internal.MemCpy(tempPixel.Ptr, &mData[leftOffset], bytesPerPixel);
				Internal.MemCpy(&mData[leftOffset], &mData[rightOffset], bytesPerPixel);
				Internal.MemCpy(&mData[rightOffset], tempPixel.Ptr, bytesPerPixel);
			}
		}
	}

    // Create a copy with different format
	public Result<Image> ConvertFormat(PixelFormat newFormat)
	{
		if (newFormat == mFormat)
			return new Image(this);

		var newImage = new Image(mWidth, mHeight, newFormat);

		// Convert pixel by pixel
		for (uint32 y = 0; y < mHeight; y++)
		{
			for (uint32 x = 0; x < mWidth; x++)
			{
				var color = GetPixel(x, y);
				newImage.SetPixel(x, y, color);
			}
		}

		return newImage;
	}

    // Factory method: Create solid color image
	public static Image CreateSolidColor(uint32 width, uint32 height, Color color, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);
		image.FillColor(color);
		return image;
	}

    // Factory method: Create checkerboard pattern
	public static Image CreateCheckerboard(uint32 size = 256, Color color1 = .White, Color color2 = .Black,
		uint32 checkSize = 32, PixelFormat format = .RGBA8)
	{
		var image = new Image(size, size, format);

		for (uint32 y = 0; y < size; y++)
		{
			for (uint32 x = 0; x < size; x++)
			{
				bool isColor1 = ((x / checkSize) + (y / checkSize)) % 2 == 0;
				image.SetPixel(x, y, isColor1 ? color1 : color2);
			}
		}

		return image;
	}

    // Factory method: Create gradient
	public static Image CreateGradient(uint32 width, uint32 height, Color topColor, Color bottomColor,
		PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		for (uint32 y = 0; y < height; y++)
		{
			float t = (float)y / (float)(height - 1);

			Color color = .(
				(uint8)Math.Lerp(topColor.R, bottomColor.R, t),
				(uint8)Math.Lerp(topColor.G, bottomColor.G, t),
				(uint8)Math.Lerp(topColor.B, bottomColor.B, t),
				(uint8)Math.Lerp(topColor.A, bottomColor.A, t)
			);

			for (uint32 x = 0; x < width; x++)
			{
				image.SetPixel(x, y, color);
			}
		}

		return image;
	}

	// ========== NORMAL MAP CREATION METHODS ==========

    // Factory method: Create flat normal map (all normals pointing up)
	public static Image CreateFlatNormalMap(uint32 width = 256, uint32 height = 256, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		// Normal pointing straight up: (0, 0, 1) -> (128, 128, 255) in texture space
		Color normalUp = Color(128, 128, 255, 255);
		image.FillColor(normalUp);

		return image;
	}

    // Factory method: Create wave pattern normal map
	public static Image CreateWaveNormalMap(uint32 width = 256, uint32 height = 256,
		float waveFrequencyX = 8.0f, float waveFrequencyY = 6.0f,
		float amplitude = 0.3f, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
				float fx = (float)x / width;
				float fy = (float)y / height;

				// Create height variations using sine waves
				float heightValue = Math.Sin(fx * Math.PI_f * waveFrequencyX) * amplitude +
					Math.Sin(fy * Math.PI_f * waveFrequencyY) * amplitude * 0.7f;

				// Calculate normal from height gradient
				float heightRight = Math.Sin((fx + 1.0f / width) * Math.PI_f * waveFrequencyX) * amplitude +
					Math.Sin(fy * Math.PI_f * waveFrequencyY) * amplitude * 0.7f;
				float heightDown = Math.Sin(fx * Math.PI_f * waveFrequencyX) * amplitude +
					Math.Sin((fy + 1.0f / height) * Math.PI_f * waveFrequencyY) * amplitude * 0.7f;

				// Calculate gradients
				float dx = heightRight - heightValue;
				float dy = heightDown - heightValue;

				// Create normal vector
				Vector3 normal = Vector3.Normalize(Vector3(-dx * 20, -dy * 20, 1.0f));

				// Convert from [-1,1] to [0,255] range
				uint8 r = (uint8)((normal.X * 0.5f + 0.5f) * 255);
				uint8 g = (uint8)((normal.Y * 0.5f + 0.5f) * 255);
				uint8 b = (uint8)((normal.Z * 0.5f + 0.5f) * 255);

				image.SetPixel(x, y, Color(r, g, b, 255));
			}
		}

		return image;
	}

    // Factory method: Create brick pattern normal map
	public static Image CreateBrickNormalMap(uint32 width = 256, uint32 height = 256,
		uint32 bricksX = 8, uint32 bricksY = 4,
		float mortarDepth = 0.3f, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		uint32 brickWidth = width / bricksX;
		uint32 brickHeight = height / bricksY;
        uint32 mortarWidth = Math.Max(brickWidth / 16, 2); // Mortar width (minimum 2 pixels)

		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
                // Determine brick position
				uint32 brickY = y / brickHeight;

				// Offset every other row for brick pattern
				uint32 adjustedX = x;
				if (brickY % 2 == 1)
					adjustedX = (x + brickWidth / 2) % width;

				// Distance to brick edge
				uint32 localX = adjustedX % brickWidth;
				uint32 localY = y % brickHeight;

				// Check if we're in mortar area
				bool isHorizontalMortar = localY < mortarWidth || localY >= (brickHeight - mortarWidth);
				bool isVerticalMortar = localX < mortarWidth || localX >= (brickWidth - mortarWidth);
				bool isMortar = isHorizontalMortar || isVerticalMortar;

				Vector3 normal;
				if (isMortar)
				{
					// Mortar is significantly depressed
					normal = Vector3(0, 0, 1.0f - mortarDepth * 2.0f);
				}
				else
				{
					// Brick surface - slightly raised with subtle texture
					float brickVariation = Math.Sin(localX * 0.2f) * Math.Sin(localY * 0.15f) * 0.1f;
					normal = Vector3(0, 0, 1.0f + brickVariation);
				}

				normal = Vector3.Normalize(normal);

				// Convert to texture space
				uint8 r = (uint8)((normal.X * 0.5f + 0.5f) * 255);
				uint8 g = (uint8)((normal.Y * 0.5f + 0.5f) * 255);
				uint8 b = (uint8)((normal.Z * 0.5f + 0.5f) * 255);

				image.SetPixel(x, y, Color(r, g, b, 255));
			}
		}

		return image;
	}

    // Factory method: Create circular bump normal map
	public static Image CreateCircularBumpNormalMap(uint32 width = 256, uint32 height = 256,
		float bumpHeight = 0.5f, float falloff = 2.0f,
		PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		float centerX = width * 0.5f;
		float centerY = height * 0.5f;
		float maxRadius = Math.Min(width, height) * 0.4f;

		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
				float dx = x - centerX;
				float dy = y - centerY;
				float distance = Math.Sqrt(dx * dx + dy * dy);

				Vector3 normal;
                if (distance < maxRadius && distance > 0.001f) // Avoid division by zero
				{
                    // Calculate normalized distance [0..1]
					float normalizedDist = distance / maxRadius;
                    
                    // Calculate height derivative (how steep the slope is) - MUCH STRONGER
                    // For height function: h(r) = (1-r)^falloff * bumpHeight
                    // Derivative: dh/dr = -falloff * (1-r)^(falloff-1) * bumpHeight
					float heightDerivative = -falloff * Math.Pow(1.0f - normalizedDist, falloff - 1) * bumpHeight * 3.0f / maxRadius;

                    // Normal components from gradient
					float nx = (dx / distance) * heightDerivative;
					float ny = (dy / distance) * heightDerivative;

					normal = Vector3.Normalize(Vector3(nx, ny, 1.0f));
				}
				else
				{
                    normal = Vector3(0, 0, 1); // Flat outside the bump or at center
				}

                // Convert to texture space
				uint8 r = (uint8)((normal.X * 0.5f + 0.5f) * 255);
				uint8 g = (uint8)((normal.Y * 0.5f + 0.5f) * 255);
				uint8 b = (uint8)((normal.Z * 0.5f + 0.5f) * 255);

				image.SetPixel(x, y, Color(r, g, b, 255));
			}
		}

		return image;
	}

    // Factory method: Create noise-based normal map
	public static Image CreateNoiseNormalMap(uint32 width = 256, uint32 height = 256,
		float scale = 0.1f, float amplitude = 0.2f,
		int32 seed = 12345, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

        // Create a simple noise heightfield using a hash-based approach
		var heightMap = scope float[width * height];

		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
                // Simple value noise using hash function instead of Random
				float noise = 0;
				float freq = scale;
				float amp = amplitude;

				for (int octave = 0; octave < 4; octave++)
				{
					float fx = x * freq;
					float fy = y * freq;

                    // Simple noise function using hash
					uint32 ix = (uint32)fx;
					uint32 iy = (uint32)fy;
					float fracX = fx - ix;
					float fracY = fy - iy;

					// Sample corners using hash function
					float a = HashToFloat(seed + (int32)ix + (int32)iy * 1000 + (int32)octave * 10000);
					float b = HashToFloat(seed + (int32)(ix + 1) + (int32)iy * 1000 + (int32)octave * 10000);
					float c = HashToFloat(seed + (int32)ix + (int32)(iy + 1) * 1000 + (int32)octave * 10000);
					float d = HashToFloat(seed + (int32)(ix + 1) + (int32)(iy + 1) * 1000 + (int32)octave * 10000);

                    // Smooth interpolation (smoothstep for better noise)
					float smoothX = fracX * fracX * (3 - 2 * fracX);
					float smoothY = fracY * fracY * (3 - 2 * fracY);

					// Bilinear interpolation
					float i1 = Math.Lerp(a, b, smoothX);
					float i2 = Math.Lerp(c, d, smoothX);
					float value = Math.Lerp(i1, i2, smoothY);

					noise += value * amp;
					freq *= 2;
					amp *= 0.5f;
				}

				heightMap[y * width + x] = noise;
			}
		}

		// Convert heightmap to normal map
		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
                // Sample neighboring heights
				float heightL = heightMap[y * width + Math.Max(x - 1, 0)];
				float heightR = heightMap[y * width + Math.Min(x + 1, width - 1)];
				float heightU = heightMap[Math.Max(y - 1, 0) * width + x];
				float heightD = heightMap[Math.Min(y + 1, height - 1) * width + x];

                // Calculate gradients
				float dx = heightR - heightL;
				float dy = heightD - heightU;

                // Create normal
				Vector3 normal = Vector3.Normalize(Vector3(-dx * 8, -dy * 8, 1.0f));

                // Convert to texture space
				uint8 r = (uint8)((normal.X * 0.5f + 0.5f) * 255);
				uint8 g = (uint8)((normal.Y * 0.5f + 0.5f) * 255);
				uint8 b = (uint8)((normal.Z * 0.5f + 0.5f) * 255);

				image.SetPixel(x, y, Color(r, g, b, 255));
			}
		}

		return image;
	}

    // Helper method: Simple hash function to convert int to float [-1, 1]
	private static float HashToFloat(int32 value)
	{
        // Simple hash function based on integer overflow behavior
		uint32 hash = (uint32)value;
        hash = hash * 1103515245u + 12345u; // Linear congruential generator constants
        hash = (hash >> 16) ^ hash; // XOR with shifted version
        hash = hash * 0x85ebca6bu; // Multiply by large prime
        hash = (hash >> 13) ^ hash; // XOR with shifted version again

        // Convert to float in range [-1, 1]
		return ((hash & 0x7FFFFFFF) / (float)0x7FFFFFFF) * 2.0f - 1.0f;
	}

    // Factory method: Create test pattern normal map (for debugging)
	public static Image CreateTestPatternNormalMap(uint32 width = 256, uint32 height = 256, PixelFormat format = .RGBA8)
	{
		var image = new Image(width, height, format);

		for (uint32 y = 0; y < height; y++)
		{
			for (uint32 x = 0; x < width; x++)
			{
				float fx = (float)x / width;
				float fy = (float)y / height;

				Vector3 normal;

				// Create different patterns in different quadrants
				if (fx < 0.5f && fy < 0.5f)
				{
					// Top-left: Flat (baseline)
					normal = Vector3(0, 0, 1);
				}
				else if (fx >= 0.5f && fy < 0.5f)
				{
					// Top-right: X-direction bumps
					float bump = Math.Sin(fx * Math.PI_f * 16) * 0.5f;
					normal = Vector3.Normalize(Vector3(bump, 0, 1));
				}
				else if (fx < 0.5f && fy >= 0.5f)
				{
					// Bottom-left: Y-direction bumps
					float bump = Math.Sin(fy * Math.PI_f * 16) * 0.5f;
					normal = Vector3.Normalize(Vector3(0, bump, 1));
				}
				else
				{
					// Bottom-right: Circular pattern
					float centerX = 0.75f;
					float centerY = 0.75f;
					float dx = fx - centerX;
					float dy = fy - centerY;
					float dist = Math.Sqrt(dx * dx + dy * dy);

					if (dist < 0.2f)
					{
						float angle = Math.Atan2(dy, dx);
						normal = Vector3.Normalize(Vector3(
							Math.Cos(angle) * 0.3f,
							Math.Sin(angle) * 0.3f,
							1.0f
						));
					}
					else
					{
						normal = Vector3(0, 0, 1);
					}
				}

                // Convert to texture space
				uint8 r = (uint8)((normal.X * 0.5f + 0.5f) * 255);
				uint8 g = (uint8)((normal.Y * 0.5f + 0.5f) * 255);
				uint8 b = (uint8)((normal.Z * 0.5f + 0.5f) * 255);

				image.SetPixel(x, y, Color(r, g, b, 255));
			}
		}

		return image;
	}

    // Helper method: Create normal from height value (for heightmap conversion)
	public static Vector3 CalculateNormalFromHeight(float heightL, float heightR, float heightU, float heightD, float scale = 1.0f)
	{
		float dx = (heightR - heightL) * scale;
		float dy = (heightD - heightU) * scale;
		return Vector3.Normalize(Vector3(-dx, -dy, 1.0f));
	}

	// ========== END NORMAL MAP METHODS ==========

    // Helper: Get bytes per pixel for format
	public static int GetBytesPerPixel(PixelFormat format)
	{
		switch (format)
		{
		case .R8: return 1;
		case .RG8: return 2;
		case .RGB8, .BGR8: return 3;
		case .RGBA8, .BGRA8: return 4;
		case .R16F: return 2;
		case .RG16F: return 4;
		case .RGB16F: return 6;
		case .RGBA16F: return 8;
		case .R32F: return 4;
		case .RG32F: return 8;
		case .RGB32F: return 12;
		case .RGBA32F: return 16;
		default: return 4;
		}
	}

    // Helper: Get pixel offset in data array
	private int GetPixelOffset(uint32 x, uint32 y)
	{
		return (int)((y * mWidth + x) * GetBytesPerPixel(mFormat));
	}

    // Helper: Check if format has alpha channel
	public bool HasAlpha()
	{
		switch (mFormat)
		{
		case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F:
			return true;
		default:
			return false;
		}
	}

    // Helper: Get channel count
	public int GetChannelCount()
	{
		switch (mFormat)
		{
		case .R8, .R16F, .R32F: return 1;
		case .RG8, .RG16F, .RG32F: return 2;
		case .RGB8, .BGR8, .RGB16F, .RGB32F: return 3;
		case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F: return 4;
		default: return 0;
		}
	}
}