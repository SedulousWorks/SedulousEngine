using System;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents a rectangle with double-precision floating point components.
/// </summary>
struct RectangleD : IEquatable<RectangleD>, IInterpolatable<RectangleD>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="RectangleD"/> struct.
    /// </summary>
    /// <param name="position">The rectangle's position.</param>
    /// <param name="size">The rectangle's size.</param>
    public this(Point2D position, Size2D size)
        : this(position.X, position.Y, size.Width, size.Height)
    {

    }

    /// <summary>
    /// Initializes a new instance of the <see cref="RectangleD"/> structure.
    /// </summary>
    /// <param name="x">The x-coordinate of the rectangle's top-left corner.</param>
    /// <param name="y">The y-coordinate of the rectangle's top-right corner.</param>
    /// <param name="width">The rectangle's width.</param>
    /// <param name="height">The rectangle's height.</param>
    public this(double x, double y, double width, double height)
    {
        this.X = x;
        this.Y = y;
        this.Width = width;
        this.Height = height;
    }
    
    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by adding the specified <see cref="Point2D"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator +(RectangleD rect, Point2 point)
    {
        RectangleD result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by subtracting the specified <see cref="Point2D"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator -(RectangleD rect, Point2 point)
    {
        RectangleD result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by adding the specified <see cref="Point2D"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2F"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator +(RectangleD rect, Point2F point)
    {
        RectangleD result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by subtracting the specified <see cref="Point2D"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2F"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator -(RectangleD rect, Point2F point)
    {
        RectangleD result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by adding the specified <see cref="Point2D"/> to its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2D"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator +(RectangleD rect, Point2D point)
    {
        RectangleD result;

        result.X = rect.X + point.X;
        result.Y = rect.Y + point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Offsets the specified <see cref="RectangleD"/> by subtracting the specified <see cref="Point2D"/> from its location.
    /// </summary>
    /// <param name="rect">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="point">The <see cref="Point2D"/> by which to offset the rectangle.</param>
    /// <returns>A <see cref="RectangleD"/> that has been offset by the specified amount.</returns>
    public static RectangleD operator -(RectangleD rect, Point2D point)
    {
        RectangleD result;

        result.X = rect.X - point.X;
        result.Y = rect.Y - point.Y;
        result.Width = rect.Width;
        result.Height = rect.Height;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="RectangleD"/> structure to a <see cref="Rectangle"/> structure.
    /// </summary>
    /// <param name="rect">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator Rectangle(RectangleD rect)
    {
        Rectangle result;

        result.X = (int32)rect.X;
        result.Y = (int32)rect.Y;
        result.Width = (int32)rect.Width;
        result.Height = (int32)rect.Height;

        return result;
    }

    /// <summary>
    /// Explicitly converts a <see cref="RectangleD"/> structure to a <see cref="RectangleF"/> structure.
    /// </summary>
    /// <param name="rect">The structure to convert.</param>
    /// <returns>The converted structure.</returns>
    public static explicit operator RectangleF(RectangleD rect)
    {
        return RectangleF((float)rect.X, (float)rect.Y, (float)rect.Width, (float)rect.Height);
    }
    
    /// <summary>
    /// Offsets the specified rectangle by the specified amount.
    /// </summary>
    /// <param name="rectangle">The <see cref="RectangleD"/> to offset.</param>
    /// <param name="offsetX">The amount by which to offset the rectangle along the x-axis.</param>
    /// <param name="offsetY">The amount by which to offset the rectangle along the y-axis.</param>
    /// <returns>The offset <see cref="RectangleD"/>.</returns>
    public static RectangleD Offset(RectangleD rectangle, double offsetX, double offsetY)
    {
        RectangleD result;

        result.X = rectangle.X + offsetX;
        result.Y = rectangle.Y + offsetY;
        result.Width = rectangle.Width;
        result.Height = rectangle.Height;

        return result;
    }

    /// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleD"/> to offset.</param>
	/// <param name="offsetX">The amount by which to offset the rectangle along the x-axis.</param>
	/// <param name="offsetY">The amount by which to offset the rectangle along the y-axis.</param>
	/// <param name="result">The offset <see cref="RectangleD"/>.</param>
	public static void Offset(in RectangleD rectangle, double offsetX, double offsetY, out RectangleD result)
	{
	    result.X = rectangle.X + offsetX;
	    result.Y = rectangle.Y + offsetY;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;
	}

	/// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleD"/> to offset.</param>
	/// <param name="offset">The amount by which to offset the rectangle.</param>
	/// <returns>The offset <see cref="RectangleD"/>.</returns>
	public static RectangleD Offset(RectangleD rectangle, Point2D offset)
	{
	    RectangleD result;

	    result.X = rectangle.X + offset.X;
	    result.Y = rectangle.Y + offset.Y;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;

	    return result;
	}

	/// <summary>
	/// Offsets the specified rectangle by the specified amount.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleD"/> to offset.</param>
	/// <param name="offset">The amount by which to offset the rectangle.</param>
	/// <param name="result">The offset <see cref="RectangleD"/>.</param>
	public static void Offset(in RectangleD rectangle, in Point2D offset, out RectangleD result)
	{
	    result.X = rectangle.X + offset.X;
	    result.Y = rectangle.Y + offset.Y;
	    result.Width = rectangle.Width;
	    result.Height = rectangle.Height;
	}

	/// <summary>
	/// Inflates the specified rectangle by the specified horizontal and vertical values.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleD"/> to inflate.</param>
	/// <param name="horizontalAmount">The amount by which to inflate the rectangle horizontally.</param>
	/// <param name="verticalAmount">The amount by which to inflate the rectangle vertically.</param>
	/// <returns>The inflated <see cref="RectangleD"/>.</returns>
	public static RectangleD Inflate(RectangleD rectangle, double horizontalAmount, double verticalAmount)
	{
	    RectangleD result;

	    result.X = rectangle.X - horizontalAmount;
	    result.Y = rectangle.Y - verticalAmount;
	    result.Width = rectangle.Width + (2 * horizontalAmount);
	    result.Height = rectangle.Height + (2 * verticalAmount);

	    return result;
	}

	/// <summary>
	/// Inflates the specified rectangle by the specified horizontal and vertical values.
	/// </summary>
	/// <param name="rectangle">The <see cref="RectangleD"/> to inflate.</param>
	/// <param name="horizontalAmount">The amount by which to inflate the rectangle horizontally.</param>
	/// <param name="verticalAmount">The amount by which to inflate the rectangle vertically.</param>
	/// <param name="result">The inflated <see cref="RectangleD"/>.</param>
	public static void Inflate(in RectangleD rectangle, double horizontalAmount, double verticalAmount, out RectangleD result)
	{
	    result.X = rectangle.X - horizontalAmount;
	    result.Y = rectangle.Y - verticalAmount;
	    result.Width = rectangle.Width + (2 * horizontalAmount);
	    result.Height = rectangle.Height + (2 * verticalAmount);
	}

	/// <summary>
	/// Creates a rectangle which is the union of the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleD"/>.</param>
	/// <param name="rectangle2">The second <see cref="RectangleD"/>.</param>
	/// <returns>The <see cref="RectangleD"/> that was created.</returns>
	public static RectangleD Union(RectangleD rectangle1, RectangleD rectangle2)
	{
	    var minLeft = rectangle1.Left < rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var minTop = rectangle1.Top < rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var maxRight = rectangle1.Right > rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var maxBottom = rectangle1.Bottom > rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    RectangleD result;

	    result.X = minLeft;
	    result.Y = minTop;
	    result.Width = maxRight - minLeft;
	    result.Height = maxBottom - minTop;

	    return result;
	}

	/// <summary>
	/// Creates a rectangle which is the union of the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleD"/>.</param>
	/// <param name="rectangle2">The second <see cref="RectangleD"/>.</param>
	/// <param name="result">The <see cref="RectangleD"/> that was created.</param>
	public static void Union(in RectangleD rectangle1, in RectangleD rectangle2, out RectangleD result)
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
	/// <param name="rectangle1">The first <see cref="RectangleD"/> to intersect.</param>
	/// <param name="rectangle2">The second <see cref="RectangleD"/> to intersect.</param>
	/// <returns>The <see cref="RectangleD"/> that was created.</returns>
	public static RectangleD Intersect(RectangleD rectangle1, RectangleD rectangle2)
	{
	    var maxLeft = rectangle1.Left > rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var maxTop = rectangle1.Top > rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var minRight = rectangle1.Right < rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var minBottom = rectangle1.Bottom < rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    var isEmpty = (minRight <= maxLeft || minBottom <= maxTop);
	    if (isEmpty)
	        return RectangleD.Empty;

	    RectangleD result;

	    result.X = maxLeft;
	    result.Y = maxTop;
	    result.Width = minRight - maxLeft;
	    result.Height = minBottom - maxTop;

	    return result;
	}

	/// <summary>
	/// Creates a rectangle which represents the intersection between the specified rectangles.
	/// </summary>
	/// <param name="rectangle1">The first <see cref="RectangleD"/> to intersect.</param>
	/// <param name="rectangle2">The second <see cref="RectangleD"/> to intersect.</param>
	/// <param name="result">The <see cref="RectangleD"/> that was created.</param>
	public static void Intersect(in RectangleD rectangle1, in RectangleD rectangle2, out RectangleD result)
	{
	    var maxLeft = rectangle1.Left > rectangle2.Left ? rectangle1.Left : rectangle2.Left;
	    var maxTop = rectangle1.Top > rectangle2.Top ? rectangle1.Top : rectangle2.Top;
	    var minRight = rectangle1.Right < rectangle2.Right ? rectangle1.Right : rectangle2.Right;
	    var minBottom = rectangle1.Bottom < rectangle2.Bottom ? rectangle1.Bottom : rectangle2.Bottom;

	    var isEmpty = (minRight <= maxLeft || minBottom <= maxTop);
	    if (isEmpty)
	    {
	        result = RectangleD.Empty;
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
	public static RectangleD TransformAxisAligned(RectangleD rectangle, Matrix transform)
	{
	    var tl = Vector2((float)rectangle.Left, (float)rectangle.Top);
	    var tr = Vector2((float)rectangle.Right, (float)rectangle.Top);
	    var bl = Vector2((float)rectangle.Left, (float)rectangle.Bottom);
	    var br = Vector2((float)rectangle.Right, (float)rectangle.Bottom);

	    Vector2.Transform(tl, transform, out tl);
	    Vector2.Transform(tr, transform, out tr);
	    Vector2.Transform(bl, transform, out bl);
	    Vector2.Transform(br, transform, out br);

	    var minX = Math.Min(Math.Min(tl.X, tr.X), Math.Min(bl.X, br.X));
	    var maxX = Math.Max(Math.Max(tl.X, tr.X), Math.Max(bl.X, br.X));
	    var minY = Math.Min(Math.Min(tl.Y, tr.Y), Math.Min(bl.Y, br.Y));
	    var maxY = Math.Max(Math.Max(tl.Y, tr.Y), Math.Max(bl.Y, br.Y));

	    RectangleD result;

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
	public static void TransformAxisAligned(in RectangleD rectangle, in Matrix transform, out RectangleD result)
	{
	    var tl = Vector2((float)rectangle.Left, (float)rectangle.Top);
	    var tr = Vector2((float)rectangle.Right, (float)rectangle.Top);
	    var bl = Vector2((float)rectangle.Left, (float)rectangle.Bottom);
	    var br = Vector2((float)rectangle.Right, (float)rectangle.Bottom);

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
	/// <param name="rectangle">The <see cref="RectangleD"/> to evaluate.</param>
	/// <returns><see langword="true"/> if this rectangle intersects the specified rectangle; otherwise, <see langword="false"/>.</returns>
	public bool Intersects(RectangleD rectangle)
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
	/// <param name="rectangle">The <see cref="RectangleD"/> to evaluate.</param>
	/// <param name="result"><see langword="true"/> if this rectangle intersects the specified rectangle; otherwise, <see langword="false"/>.</param>
	public void Intersects(in RectangleD rectangle, out bool result)
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
	public bool Contains(double x, double y)
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
	public void Contains(in Point2D point, out bool result)
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
	public bool Contains(Point2D point)
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
	/// <param name="rectangle">The <see cref="RectangleD"/> to evaluate.</param>
	/// <param name="result"><see langword="true"/> if the rectangle completely contains the specified rectangle; otherwise, <see langword="false"/>.</param>
	public void Contains(in RectangleD rectangle, out bool result)
	{
	    result = 
	        this.X <= rectangle.X && rectangle.X + rectangle.Width <= this.X + this.Width &&
	        this.Y <= rectangle.Y && rectangle.Y + rectangle.Height <= this.Y + this.Height;
	}

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public RectangleD Interpolate(RectangleD target, float t)
    {
        RectangleD result;

        result.X = Tweening.Lerp(this.X, target.X, t);
        result.Y = Tweening.Lerp(this.Y, target.Y, t);
        result.Width = Tweening.Lerp(this.Width, target.Width, t);
        result.Height = Tweening.Lerp(this.Height, target.Height, t);

        return result;
    }

    /// <summary>
    /// Gets an empty rectangle.
    /// </summary>
    public static RectangleD Empty
    {
        get { return RectangleD(0, 0, 0, 0); }
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
    public double Top
    {
        get { return Y; }
    }

    /// <summary>
    /// Gets the x-coordinate of the left edge of the rectangle.
    /// </summary>
    public double Left
    {
        get { return X; }
    }

    /// <summary>
    /// Gets the y-coordinate of the bottom edge of the rectangle.
    /// </summary>
    public double Bottom
    {
        get { return Y + Height; }
    }

    /// <summary>
    /// Gets the x-coordinate of the right edge of the rectangle.
    /// </summary>
    public double Right
    {
        get { return X + Width; }
    }

    /// <summary>
    /// Gets the position of the rectangle's top-left corner.
    /// </summary>
    public Point2D Location
    {
        get { return Point2D(X, Y); }
        set mut
        {
            X = value.X;
            Y = value.Y;
        }
    }

    /// <summary>
    /// Gets the position of the rectangle's center.
    /// </summary>
    public Point2D Center
    {
        get { return Point2D(X + (Width / 2.0), Y + (Height / 2.0)); }
    }

    /// <summary>
    /// Gets the rectangle's size.
    /// </summary>
    public Size2D Size
    {
        get { return Size2D(Width, Height); }
        set mut
        {
            Width = value.Width;
            Height = value.Height;
        }
    }

    /// <summary>
    /// The x-coordinate of the rectangle's top-left corner.
    /// </summary>
    public double X;

    /// <summary>
    /// The y-coordinate of the rectangle's top-left corner.
    /// </summary>
    public double Y;

    /// <summary>
    /// The rectangle's width.
    /// </summary>
    public double Width;

    /// <summary>
    /// The rectangle's height.
    /// </summary>
    public double Height;
}
