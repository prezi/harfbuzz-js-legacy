package prezi.text.otf;

class CffIndex implements ICffIndex
{
	public var indexName (default, null):String;
	public var count (default, null):Int;
	private var reader:IFontFileReader;
	private var offSize:Int;
	private var offsetsOffset:Int;
	private var dataOffset:Int;

	public function new(indexName:String, reader:IFontFileReader, ?indexOffset:Int)
	{
		this.indexName = indexName;
		this.reader = reader;
		if (indexOffset != null)
		{
			reader.seek(indexOffset);
		}
		this.count = reader.readUShort();
		if (count > 0)
		{
			this.offSize = reader.readByte();
			this.offsetsOffset = reader.position();
			reader.skip(offSize * count);
			var endOffset = readOffset();
			this.dataOffset = reader.position() - 1;
			reader.seek(dataOffset + endOffset);
		}
	}

	public function lookup(index:Int):{ offset:Int, length:Int }
	{
		if (!(0 <= index && index < count))
		{
			throw "Cannot find element #{index} (we have #{@count} elements in #{@indexName} INDEX)";
		}

		var dataOffset = offsetOf(index);
		var length = offsetOf(index + 1) - dataOffset;

		return {
			offset: dataOffset,
			length: length
		};
	}

	private function offsetOf(index:Int):Int
	{
		var offsetOffset = offsetsOffset + index * offSize;
		var relativeDataOffset = peekOffset(offsetOffset);
		return dataOffset + relativeDataOffset;
	}

	private function peekOffset(offset:Int):Int
	{
		switch (offSize)
		{
			case 1:
				return reader.peekByte(offset);
			case 2:
				return reader.peekUShort(offset);
			case 3:
				return reader.peekUInt24(offset);
			case 4:
				return reader.peekULong(offset);
			default:
				throw "Invalid offset size: " + offSize;
		}
	}
	private inline function readOffset():Int
	{
		var value = peekOffset(reader.position());
		reader.skip(offSize);
		return value;
	}
}
