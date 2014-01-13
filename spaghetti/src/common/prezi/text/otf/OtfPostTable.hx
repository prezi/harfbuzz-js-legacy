package prezi.text.otf;

/**
 * post - PostScript
 * http://www.microsoft.com/typography/otspec/post.htm
 */
class OtfPostTable
{
	public var italicAngle (default, null):Float;
	public var underlinePosition (default, null):Int;
	public var underlineThickness (default, null):Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		reader.readFixed(); // version
		this.italicAngle = reader.readFixed();
		this.underlinePosition = reader.readFWord();
		this.underlineThickness = reader.readFWord();
	}
}
