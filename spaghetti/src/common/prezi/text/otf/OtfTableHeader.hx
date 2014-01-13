package prezi.text.otf;

class OtfTableHeader
{
	public var tag (default, null):Int;
	public var checkSum (default, null):Int;
	public var offset (default, null):Int;
	public var length (default, null):Int;

	public function new(reader:IFontFileReader)
	{
		this.tag = reader.readULong();
		this.checkSum = reader.readULong();
		this.offset = reader.readULong();
		this.length = reader.readULong();
	}
}
