package prezi.text.otf;

/**
 * maxp - Maximum Profile
 * http://www.microsoft.com/typography/otspec/maxp.htm
 */
class OtfMaxpTable
{
	public var numGlyphs (default, null):Int;

	public function new(reader:IFontFileReader, header:OtfTableHeader)
	{
		reader.seek(header.offset);
		reader.readFixed(); // version
		this.numGlyphs = reader.readUShort();
	}
}
