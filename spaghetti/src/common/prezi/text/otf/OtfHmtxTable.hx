package prezi.text.otf;

/**
  * hmtx - Horizontal Metrics
  * http://www.microsoft.com/typography/otspec/hmtx.htm
 */
class OtfHmtxTable
{
	private var reader:IFontFileReader;
	private var numberOfHMetrics:Int;
	private var headerOffset:Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader, numberOfHMetrics)
	{
		this.reader = reader;
		this.numberOfHMetrics = numberOfHMetrics;
		headerOffset = header.offset;
	}

	public inline function advanceWidth(glyphCode:Int):Int
	{
		var glyphPos:Int = (glyphCode < numberOfHMetrics) ? glyphCode : numberOfHMetrics - 1;
		var offset = headerOffset + glyphPos * 4;
		return reader.peekUShort(offset);
	}
}
