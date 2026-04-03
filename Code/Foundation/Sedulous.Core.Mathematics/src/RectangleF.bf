using System;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a rectangle with single-precision floating point components.
/// </summary>
struct RectangleF : IEquatable<RectangleF>, IInterpolatable<RectangleF>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="RectangleF"/> struct.
    /// </summary>
    /// <param name="position">The rectangle's position.</param>
    /// <param name="size">The rectangle's size.</param>
    public this(Point2F position, Size2F size)
        : this(position.X, position.Y, size.Width, size.Height)
    {

    }

    /// <summary>
    /// Initializes a new instance of the <see cref="RectangleF"/> structure.
    /// </summary>
    /// <param name="x">The x-coordinate of the rectangle's top-left corner.</param>
    /// <param name="y">The y-coordinate of the rectangle's top-right corner.</param>
    /// <param name="width">The rectangle's width.</param>
    /// <param name="height">The rectangle's height.</param>
    public this(float x, float y, float width, float height)
    {
        this.X = x;
        this.Y = y;
        this.Width = width;
        this.Height = height;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="RectangleF"/> structure.
    /// </summary>
    /// <param name="position">The position of the rectangle's top-left corner.</param>
    /// <param name="size">The area of the rectangle.</param>
    public this(Vector2 position, Size2F size)
        : this(position.X, position.Y, size.Width, size.Height)
    {

    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by adding the specified <see cref="Point2F"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleF"/> that has been offset by the specified amount.</returns>
    public static RectangleF operator +(RectangleF rect, Point2 point)
    {
        RectangleF result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by subtracting the specified <see cref="Point2F"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleF"/> that has been offset by the specified amount.</returns>
    public static RectangleF operator -(RectangleF rect, Point2 point)
    {
        RectangleF result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by adding the specified <see cref="Point2F"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2F"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleF"/> that has been offset by the specified amount.</returns>
    public static RectangleF operator +(RectangleF rect, Point2F point)
    {
        RectangleF result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by subtracting the specified <see cref="Point2F"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2F"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleF"/> that has been offset by the specified amount.</returns>
    public static RectangleF operator -(RectangleF rect, Point2F point)
    {
        RectangleF result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by adding the specified <see cref="Point2D"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2D"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator +(RectangleF rect, Point2D point)
    {
        RectangleD result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleF"/> by subtracting the specified <see cref="Point2D"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="point">The <see cref="Point2D"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator -(RectangleF rect, Point2D point)
    {
        RectangleD result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }
    
    /// <summary>
    /// Explicitly converts a <see cref="RectangleF"/> structure to a <see cref="Rectangle"/> structure.
    /// </summary>
    /// <param name="rect">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Rectangle(RectangleF rect)
    {
        Rectangle result;

        result.X = (int32)rect.X;
        result.Y = (int32)rect.Y;
        result.Width = (int32)rect.Width;
        result.Height = (int32)rect.Height;

        return result;
    }

    /// <summary>
    /// Implicitly converts a <see cref="RectangleF"/> structure to a <see cref="RectangleD"/> structure.
    /// </summary>
    /// <param name="rect">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static implicit operator RectangleD(RectangleF rect)
    {
        RectangleD result;

        result.X = rect.X;
        result.Y = rect.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }
    
    /// <summary>
    /// Offsets the specified rectangle by the specified amount.
    /// </summary>
    /// <param name="rectangle">The <see cref="RectangleF"/> to offset.</param>
    /// <param name="offsetX">The amount by which to offset the rectangle along the x-axis.</param>
    /// <param name="offsetY">The amount by which to offset the rectangle along the y-axis.</param>
    /// <returns>The offset <see cref="RectangleF"/>.</returns>
    public static RectangleF Offset(RectangleF rectangle, float offsetX, float offsetY)
    {
        RectangleF result;

        result.X = rectangle.X + offsetX;
        result.Y = rectangle.Y + offsetY;
        result.Width = rectangle.Width;
        result.Height = rectangle.Height;

        return result;
    }

    /// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to offset.</param>
	/// <param name="offsetX">The amount by which to offset the rectangle along the x-axis.</param>
	/// <param name="offsetY">The amount by which to offset the rectangle along the y-axis.</param>
	/// <param name="result">The offset <see cref="RectangleF"/>.</param>
	public static void Offset(in RectangleF rectangle, float offsetX, float offsetY, out RectangleF result)
	{
	    result.X = rectangle.X + offsetX;
	    result.Y = rectangle.Y + offsetY;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;
	}

	/// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to offset.</param>
	/// <param name="offset">The amount by which to offset the rectangle.</param>
	/// <returns>The offset <see cref="RectangleF"/>.</returns>
	public static RectangleF Offset(RectangleF rectangle, Vector2 offset)
	{
	    RectangleF result;

	    result.X = rectangle.X + offset.X;
	    result.Y = rectangle.Y + offset.Y;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;

	    return result;
	}

	/// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to offset.</param>
	/// <param name="offset">The amount by which to offset the rectangle.</param>
	/// <param name="result">The offset <see cref="RectangleF"/>.</param>
	public static void Offset(in RectangleF rectangle, in Vector2 offset, out RectangleF result)
	{
	    result.X = rectangle.X + offset.X;
	    result.Y = rectangle.Y + offset.Y;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;
	}

	/// <summary>
	/// Inflates the specified rectangle by the specified horizontal and vertical values.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to inflate.</param>
	/// <param name="horizontalAmount">The amount by which to inflate the rectangle horizontally.</param>
	/// <param name="verticalAmount">The amount by which to inflate the rectangle vertically.</param>
	/// <returns>The inflated <see cref="RectangleF"/>.</returns>
	public static RectangleF Inflate(RectangleF rectangle, float horizontalAmount, float verticalAmount)
	{
	    RectangleF result;

	    result.X = rectangle.X - horizontalAmount;
	    result.Y = rectangle.Y - verticalAmount;
	    result.Width = rectangle.Width + (2 * horizontalAmount);
	    result.Height = rectangle.Height + (2 * verticalAmount);

	    return result;
	}

	/// <summary>
	/// Inflates the specified rectangle by the specified horizontal and vertical values.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to inflate.</param>
	/// <param name="horizontalAmount">The amount by which to inflate the rectangle horizontally.</param>
	/// <param name="verticalAmount">The amount by which to inflate the rectangle vertically.</param>
	/// <param name="result">The inflated <see cref="RectangleF"/>.</param>
	public static void Inflate(in RectangleF rectangle, float horizontalAmount, float verticalAmount, out RectangleF result)
	{
	    result.X = rectangle.X - horizontalAmount;
	    result.Y = rectangle.Y - verticalAmount;
	    result.Width = rectangle.Width + (2 * horizontalAmount);
	    result.Height = rectangle.Height + (2 * verticalAmount);
	}

	/// <summary>
	/// Creates a rectangle which is the union of the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleF"/>.</param>
	/// <param name="rectangle2">The second <see cref="RectangleF"/>.</param>
	/// <returns>The <see cref="RectangleF"/> that was created.</returns>
	public static RectangleF Union(RectangleF rectangle1, RectangleF rectangle2)
	{
	    var minLeft = rectangle1.Left < rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var minTop = rectangle1.Top < rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var maxRight = rectangle1.Right > rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var maxBottom = rectangle1.Bottom > rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    RectangleF result;

	    result.X = minLeft;
	    result.Y = minTop;
	    result.Width = maxRight - minLeft;
	    result.Height = maxBottom - minTop;

	    return result;
	}

	/// <summary>
	/// Creates a rectangle which is the union of the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleF"/>.</param>
	/// <param name="rectangle2">The second <see cref="RectangleF"/>.</param>
	/// <param name="result">The <see cref="RectangleF"/> that was created.</param>
	public static void Union(in RectangleF rectangle1, in RectangleF rectangle2, out RectangleF result)
	{
	    var minLeft = rectangle1.Left < rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var minTop = rectangle1.Top < rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var maxRight = rectangle1.Right > rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var maxBottom = rectangle1.Bottom > rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    result.X = minLeft;
	    result.Y = minTop;
	    result.Width = maxRight - minLeft;
	    result.Height = maxBottom - minTop;
	}

	/// <summary>
	/// Creates a rectangle which represents the intersection between the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleF"/> to intersect.</param>
	/// <param name="rectangle2">The second <see cref="RectangleF"/> to intersect.</param>
	/// <returns>The <see cref="RectangleF"/> that was created.</returns>
	public static RectangleF Intersect(RectangleF rectangle1, RectangleF rectangle2)
	{
	    var maxLeft = rectangle1.Left > rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var maxTop = rectangle1.Top > rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var minRight = rectangle1.Right < rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var minBottom = rectangle1.Bottom < rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    var isEmpty = (minRight <= maxLeft || minBottom <= maxTop);
	    if (isEmpty)
	        return RectangleF.Empty;
	    
	    RectangleF result;

	    result.X = maxLeft;
	    result.Y = maxTop;
	    result.Width = minRight - maxLeft;
	    result.Height = minBottom - maxTop;

	    return result;
	}

	/// <summary>
	/// Creates a rectangle which represents the intersection between the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleF"/> to intersect.</param>
	/// <param name="rectangle2">The second <see cref="RectangleF"/> to intersect.</param>
	/// <param name="result">The <see cref="RectangleF"/> that was created.</param>
	public static void Intersect(in RectangleF rectangle1, in RectangleF rectangle2, out RectangleF result)
	{
	    var maxLeft = rectangle1.Left > rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var maxTop = rectangle1.Top > rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var minRight = rectangle1.Right < rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var minBottom = rectangle1.Bottom < rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    var isEmpty = (minRight <= maxLeft || minBottom <= maxTop);
	    if (isEmpty)
	    {
	        result = RectangleF.Empty;
	    }
	    else
	    {
	        result.X = maxLeft;
	        result.Y = maxTop;
	        result.Width = minRight - maxLeft;
	        result.Height = minBottom - maxTop;
	    }
	}

	/// <summary>
	/// Transforms the specified rectangle and retrieves the axis-aligned bounding box of the result.
	/// </summary>
	/// <param name="rectangle">The rectangle to transform.</param>
	/// <param name="transform">The transform matrix.</param>
	/// <returns>The axis-aligned bounding box of <paramref name="rectangle"/> after it has been transformed.</returns>
	public static RectangleF TransformAxisAligned(RectangleF rectangle, Matrix transform)
	{
	    var tl = Vector2(rectangle.Left, rectangle.Top);
	    var tr = Vector2(rectangle.Right, rectangle.Top);
	    var bl = Vector2(rectangle.Left, rectangle.Bottom);
	    var br = Vector2(rectangle.Right, rectangle.Bottom);

	    Vector2.Transform(tl, transform, out tl);
	    Vector2.Transform(tr, transform, out tr);
	    Vector2.Transform(bl, transform, out bl);
	    Vector2.Transform(br, transform, out br);

	    var minX = Math.Min(Math.Min(tl.X, tr.X), Math.Min(bl.X, br.X));
	    var maxX = Math.Max(Math.Max(tl.X, tr.X), Math.Max(bl.X, br.X));
	    var minY = Math.Min(Math.Min(tl.Y, tr.Y), Math.Min(bl.Y, br.Y));
	    var maxY = Math.Max(Math.Max(tl.Y, tr.Y), Math.Max(bl.Y, br.Y));

	    RectangleF result;

	    result.X = minX;
	    result.Y = minY;
	    result.Width = maxX - minX;
	    result.Height = maxY - minY;

	    return result;
	}

	/// <summary>
	/// Transforms the specified rectangle and retrieves the axis-aligned bounding box of the result.
	/// </summary>
	/// <param name="rectangle">The rectangle to transform.</param>
	/// <param name="transform">The transform matrix.</param>
	/// <param name="result">The axis-aligned bounding box of <paramref name="rectangle"/> after it has been transformed.</param>
	public static void TransformAxisAligned(in RectangleF rectangle, in Matrix transform, out RectangleF result)
	{
	    var tl = Vector2(rectangle.Left, rectangle.Top);
	    var tr = Vector2(rectangle.Right, rectangle.Top);
	    var bl = Vector2(rectangle.Left, rectangle.Bottom);
	    var br = Vector2(rectangle.Right, rectangle.Bottom);

	    Vector2.Transform(tl, transform, out tl);
	    Vector2.Transform(tr, transform, out tr);
	    Vector2.Transform(bl, transform, out bl);
	    Vector2.Transform(br, transform, out br);

	    var minX = Math.Min(Math.Min(tl.X, tr.X), Math.Min(bl.X, br.X));
	    var maxX = Math.Max(Math.Max(tl.X, tr.X), Math.Max(bl.X, br.X));
	    var minY = Math.Min(Math.Min(tl.Y, tr.Y), Math.Min(bl.Y, br.Y));
	    var maxY = Math.Max(Math.Max(tl.Y, tr.Y), Math.Max(bl.Y, br.Y));

	    result.X = minX;
	    result.Y = minY;
	    result.Width = maxX - minX;
	    result.Height = maxY - minY;
	}

	/// <inheritdoc/>
	public override void ToString(String str) => str.Append( scope $"{{X:{X} Y:{Y}: Width:{Width} Height{Height}}}");

	/// <summary>
	/// Gets a value indicating whether this rectangle intersects the specified rectangle.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to evaluate.</param>
	/// <returns><see langword="true"/> if this rectangle intersects the specified rectangle; otherwise, <see langword="false"/>.</returns>
	public bool Intersects(RectangleF rectangle)
	{
	    return
	        rectangle.Left < this.Right && 
	        this.Left < rectangle.Right && 
	        rectangle.Top < this.Bottom && 
	        this.Top < rectangle.Bottom;
	}

	/// <summary>
	/// Gets a value indicating whether this rectangle intersects the specified rectangle.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to evaluate.</param>
	/// <param name="result"><see langword="true"/> if this rectangle intersects the specified rectangle; otherwise, <see langword="false"/>.</param>
	public void Intersects(in RectangleF rectangle, out bool result)
	{
	    result =
	        rectangle.Left < this.Right && 
	        this.Left < rectangle.Right && 
	        rectangle.Top < this.Bottom && 
	        this.Top < rectangle.Bottom;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle contains the specified point.
	/// </summary>
	/// <param name="x">The x-coordinate of the point to evaluate.</param>
	/// <param name="y">The y-coordinate of the point to evaluate.</param>
	/// <returns><see langword="true"/> if the rectangle contains the specified point; otherwise, <see langword="false"/>.</returns>
	public bool Contains(float x, float y)
	{
	    return
	        x >= this.X && x < this.X + this.Width &&
	        y >= this.Y && y < this.Y + this.Height;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle contains the specified point.
	/// </summary>
	/// <param name="point">The point to evaluate.</param>
	/// <param name="result">A value indicating whether the rectangle contains the specified point.</param>
	public void Contains(in Point2F point, out bool result)
	{
	    result =
	        point.X >= this.X && point.X < this.X + this.Width &&
	        point.Y >= this.Y && point.Y < this.Y + this.Height;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle contains the specified point.
	/// </summary>
	/// <param name="point">The point to evaluate.</param>
	/// <returns><see langword="true"/> if the rectangle contains the specified point; otherwise, <see langword="false"/>.</returns>
	public bool Contains(Point2F point)
	{
	    return
	        point.X >= this.X && point.X < this.X + this.Width &&
	        point.Y >= this.Y && point.Y < this.Y + this.Height;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle contains the specified point.
	/// </summary>
	/// <param name="point">A <see cref="Vector2"/> representing the point to evaluate.</param>
	/// <param name="result">A value indicating whether the rectangle contains the specified point.</param>
	public void Contains(in Vector2 point, out bool result)
	{
	    result = 
	        point.X >= this.X && point.X < this.X + this.Width &&
	        point.Y >= this.Y && point.Y < this.Y + this.Height;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle contains the specified point.
	/// </summary>
	/// <param name="point">A <see cref="Vector2"/> representing the point to evaluate.</param>
	/// <returns><see langword="true"/> if the rectangle contains the specified point; otherwise, <see langword="false"/>.</returns>
	public bool Contains(Vector2 point)
	{
	    return
	        point.X >= this.X && point.X < this.X + this.Width &&
	        point.Y >= this.Y && point.Y < this.Y + this.Height;
	}

	/// <summary>
	/// Gets a value indicating whether the rectangle completely contains the specified rectangle.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleF"/> to evaluate.</param>
	/// <param name="result"><see langword="true"/> if the rectangle completely contains the specified rectangle; otherwise, <see langword="false"/>.</param>
	public void Contains(in RectangleF rectangle, out bool result)
	{
	    result = 
	        this.X <= rectangle.X && rectangle.X + rectangle.Width <= this.X + this.Width &&
	        this.Y <= rectangle.Y && rectangle.Y + rectangle.Height <= this.Y + this.Height;
	}

    /// <summary>
    /// Gets a value indicating whether the rectangle completely contains the specified rectangle.
    /// </summary>
    /// <param name="rectangle">The <see cref="RectangleF"/> to evaluate.</param>
    /// <returns><see langword="true"/> if the rectangle completely contains the specified rectangle; otherwise, <see langword="false"/>.</returns>
    public bool Contains(RectangleF rectangle)
    {
        return
            this.X <= rectangle.X && rectangle.X + rectangle.Width <= this.X + this.Width &&
            this.Y <= rectangle.Y && rectangle.Y + rectangle.Height <= this.Y + this.Height;
    }

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public RectangleF Interpolate(RectangleF target, float t)
    {
        RectangleF result;

        result.X = Tweening.Lerp(this.X, target.X, t);
        result.Y = Tweening.Lerp(this.Y, target.Y, t);
        result.Width = Tweening.Lerp(this.Width, target.Width, t);
        result.Height = Tweening.Lerp(this.Height, target.Height, t);

        return result;
    }

    /// <summary>
    /// Gets an empty rectangle.
    /// </summary>
    public static RectangleF Empty
    {
        get { return RectangleF(0, 0, 0, 0); }
    }

    /// <summary>
    /// Gets a value indicating whether the rectangle is empty.
    /// </summary>
    public bool IsEmpty
    {
        get { return Width == 0 || Height == 0; }
    }

    /// <summary>
    /// Gets the y-coordinate of the top edge of the rectangle.
    /// </summary>
    public float Top
    {
        get { return Y; }
    }

    /// <summary>
    /// Gets the x-coordinate of the left edge of the rectangle.
    /// </summary>
    public float Left
    {
        get { return X; }
    }

    /// <summary>
    /// Gets the y-coordinate of the bottom edge of the rectangle.
    /// </summary>
    public float Bottom
    {
        get { return Y + Height; }
    }

    /// <summary>
    /// Gets the x-coordinate of the right edge of the rectangle.
    /// </summary>
    public float Right
    {
        get { return X + Width; }
    }

    /// <summary>
    /// Gets the position of the rectangle's top-left corner.
    /// </summary>
    public Point2F Location
    {
        get { return Point2F(X, Y); }
        set mut
        {
            X = value.X;
            Y = value.Y;
        }
    }

    /// <summary>
    /// Gets the position of the rectangle's center.
    /// </summary>
    public Point2F Center
    {
        get { return Point2F(X + (Width / 2.0f), Y + (Height / 2.0f)); }
    }

    /// <summary>
    /// Gets the rectangle's size.
    /// </summary>
    public Size2F Size
    {
        get { return Size2F(Width, Height); }
        set mut
        {
            Width = value.Width;
            Height = value.Height;
        }
    }

    /// <summary>
    /// The x-coordinate of the rectangle's top-left corner.
    /// </summary>
    public float X;

    /// <summary>
    /// The y-coordinate of the rectangle's top-left corner.
    /// </summary>
    public float Y;

    /// <summary>
    /// The rectangle's width.
    /// </summary>
    public float Width;

    /// <summary>
    /// The rectangle's height.
    /// </summary>
    public float Height;
}
