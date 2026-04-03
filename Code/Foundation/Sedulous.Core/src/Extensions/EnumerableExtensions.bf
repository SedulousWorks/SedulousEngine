namespace System.Collections;

static
{
	public static bool SequenceEqual<TSource>(
	    this List<TSource> first, 
	    List<TSource> second) where TSource : class
	{
	    if (first == null) Runtime.ArgumentNullError(nameof(first));
	    if (second == null) Runtime.ArgumentNullError(nameof(second));

	    var e1 = first.GetEnumerator();
	    var e2 = second.GetEnumerator();
		{
	        while (e1.GetNext() case .Ok) 
	        {
	            if (!(e2.GetNext() case .Ok && e1.Current === e2.Current))
	            {
	                return false;
	            }
	        }
	        return e2.GetNext() case .Err;
	    }
	}

	public static bool SequenceEqual<TSource>(
	    this List<TSource> first, 
	    List<TSource> second) where TSource : ValueType
	{
	    if (first == null) Runtime.ArgumentNullError(nameof(first));
	    if (second == null) Runtime.ArgumentNullError(nameof(second));

	    var e1 = first.GetEnumerator();
	    var e2 = second.GetEnumerator();
		{
	        while (e1.GetNext() case .Ok) 
	        {
	            if (!(e2.GetNext() case .Ok && e1.Current == e2.Current))
	            {
	                return false;
	            }
	        }
	        return e2.GetNext() case .Err;
	    }
	}
}

