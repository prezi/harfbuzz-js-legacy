package prezi.text.otf;

using haxe.io.Bytes;

class TestFontFileReader implements IFontFileReader
{
	private var data:Bytes;
	private var skipHeaderBytes:Int;
	private var pos:Int;

	public function new(data:Bytes, skipHeaderBytes:Int = 0)
	{
		this.data = data;
		this.skipHeaderBytes = skipHeaderBytes;
	}

	public function seek(pos:Int)
	{
		this.pos = pos;
	}

	public function skip(count:Int):Int
	{
		pos += count;
		return pos;
	}

	public function position():Int
	{
		return pos;
	}

	public function peekByte(offset:Int):Int
	{
		return data.get(skipHeaderBytes + offset) & 0xFF;
	}
	public function readByte():Int
	{
		return peekByte(pos++);
	}

	public function peekChar(offset:Int):Int
	{
		// b > Math.pow(2, 7) - 1 ? b - Math.pow(2, 8) : b
		var u8 = peekByte(offset);
		return (u8 < 0x80) ? u8 : u8 - 0x100;
	}
	public function readChar():Int
	{
		return peekChar(pos++);
	}

	public function peekUShort(offset:Int):Int
	{
		return (data.get(skipHeaderBytes + offset) & 0xFF) << 8 | (data.get(skipHeaderBytes + offset + 1) & 0xFF);
	}
	public function readUShort():Int
	{
		var val = peekUShort(pos);
		pos += 2;
		return val;
	}

	public function peekShort(offset:Int):Int
	{
		// b > Math.pow(2, 15) - 1 ? b - Math.pow(2, 16) : b;
		var u16 = peekUShort(offset);
		return (u16 < 0x8000) ? u16 : u16 - 0x10000;
	}
	public function readShort():Int
	{
		var val = peekShort(pos);
		pos += 2;
		return val;
	}

	public function peekUInt24(offset:Int):Int
	{
		return (data.get(skipHeaderBytes + offset) & 0xFF) << 16 | (data.get(skipHeaderBytes + offset + 1) & 0xFF) << 8 | (data.get(skipHeaderBytes + offset + 2) & 0xFF);
	}
	public function readUInt24():Int
	{
		var val = peekUInt24(pos);
		pos += 3;
		return val;
	}

	public function peekULong(offset:Int):Int
	{
		// Note: we don't have 32-bit unsigned, so this will be signed, too
		return (data.get(skipHeaderBytes + offset) & 0xFF) << 24 | (data.get(skipHeaderBytes + offset + 1) & 0xFF) << 16 | (data.get(skipHeaderBytes + offset + 2) & 0xFF) << 8 | (data.get(skipHeaderBytes + offset + 3) & 0xFF);
	}
	public function readULong():Int
	{
		var val = peekULong(pos);
		pos += 4;
		return val;
	}

	public function peekLong(offset:Int):Int
	{
		// b > Math.pow(2, 31) - 1 ? b - Math.pow(2, 32) : b;
		var u32 = peekULong(offset);
		// Instead of this we simply return the ULong: it's 32-bit signed already
		// return (u32 < 0x80000000) ? u32 : u32 - 0x100000000;
		return u32;
	}
	public function readLong():Int
	{
		var val = peekLong(pos);
		pos += 4;
		return val;
	}

	public function peekFixed(offset:Int):Float
	{
		return peekLong(offset) / 0x10000;
	}
	public function readFixed():Float
	{
		var val = peekFixed(pos);
		pos += 4;
		return val;
	}

	public function peekF2Dot14(offset:Int):Float
	{
		var val = peekShort(offset);
		var mantissa = (val >> 14) & 0x03;
		var frac = (val & 0x3FFF) / 0x4000;
		if (mantissa >= 2)
		{
			mantissa -= 4;
		}
		return mantissa + frac;
	}
	public function readF2Dot14():Float
	{
		var val = peekF2Dot14(pos);
		pos += 2;
		return val;
	}

	public function peekFWord(offset:Int):Int
	{
		return peekShort(offset);
	}
	public function readFWord():Int
	{
		return readShort();
	}

	public function peekUFWord(offset:Int):Int
	{
		return peekUShort(offset);
	}
	public function readUFWord():Int
	{
		return readUShort();
	}

	public function readLongDateTime():Int
	{
		pos += 8;
		return 0;
	}
}
