package prezi.text.otf;

/**
  * hhea - Horizontal Header
  * http://www.microsoft.com/typography/otspec/this.htm
 */
class OtfHheaTable
{
	public var ascent (default, null):Int;
	public var descent (default, null):Int;
	public var lineGap (default, null):Int;
	public var numberOfHMetrics (default, null):Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		reader.readFixed(); // version
		this.ascent = reader.readFWord();
		this.descent = reader.readFWord();
		this.lineGap = reader.readFWord();
		reader.readUFWord(); // advanceWidthMax
		reader.readFWord(); // minLeftSideBearing
		reader.readFWord(); // minRightSideBearing
		reader.readFWord(); // xMaxExtent
		reader.readShort(); // caretSlopeRise
		reader.readShort(); // caretSlopeRun
		reader.readShort(); // caretOffset
		reader.readShort(); // reserver
		reader.readShort(); // reserver
		reader.readShort(); // reserver
		reader.readShort(); // reserver
		reader.readShort(); // metricDataFormat (always 0)
		this.numberOfHMetrics = reader.readUShort();
	}
}
