package prezi.text.harfbuzz;

import prezi.text.otf.IFontFileReader;

class EmscriptenFontFileReader implements IFontFileReader
{
	var harfbuzz:Dynamic;
	var heapName:String;
	var heapOffset:Int;
	var pos:Int;

	public function new(harfbuzz:HarfBuzzJs, heapOffset:Int)
	{
		this.harfbuzz = harfbuzz.raw;
		this.heapName = harfbuzz.heapName;
		this.heapOffset = heapOffset;
		this.pos = 0;
	}

	public function seek(pos):Void
	{
		this.pos = pos;
	}

	public function skip(count):Int
	{
		pos += count;
		return pos;
	}

	public function position():Int
	{
		return pos;
	}

	public function peekByte(offset):Int
	{
		return heap()[heapOffset + offset] & 0xFF;
	}

	public function readByte():Int
	{
		return peekByte(pos++);
	}

	public function peekChar(offset):Int
	{
		var u8;

		u8 = peekByte(offset);
		if (u8 < 0x80)
		{
			return u8;
		} else
		{
			return u8 - 0x100;
		}
	}

	public function readChar():Int
	{
		return peekChar(pos++);
	}

	public function peekUShort(offset):Int
	{
		return (heap()[heapOffset + offset] & 0xFF) << 8 | (heap()[heapOffset + offset + 1] & 0xFF);
	}

	public function readUShort():Int
	{
		var val;

		val = peekUShort(pos);
		pos += 2;
		return val;
	}

	public function peekShort(offset):Int
	{
		var u16;

		u16 = peekUShort(offset);
		if (u16 < 0x8000)
		{
			return u16;
		} else
		{
			return u16 - 0x10000;
		}
	}

	public function readShort():Int
	{
		var val;

		val = peekShort(pos);
		pos += 2;
		return val;
	}

	public function peekUInt24(offset):Int
	{
		return (heap()[heapOffset + offset] & 0xFF) << 16 | (heap()[heapOffset + offset + 1] & 0xFF) << 8 | (heap()[heapOffset + offset + 2] & 0xFF);
	}

	public function readUInt24():Int
	{
		var val;

		val = peekUInt24(pos);
		pos += 3;
		return val;
	}

	public function peekULong(offset):Int
	{
		return (heap()[heapOffset + offset] & 0xFF) << 24 | (heap()[heapOffset + offset + 1] & 0xFF) << 16 | (heap()[heapOffset + offset + 2] & 0xFF) << 8 | (heap()[heapOffset + offset + 3] & 0xFF);
	}

	public function readULong():Int
	{
		var val;

		val = peekULong(pos);
		pos += 4;
		return val;
	}

	public function peekLong(offset):Int
	{
		var u32;

		u32 = peekULong(offset);
		if (u32 < 0x80000000)
		{
			return u32;
		}
		else
		{
			return untyped __js__('u32 - 0x100000000');
		}
	}

	public function readLong():Int
	{
		var val;

		val = peekLong(pos);
		pos += 4;
		return val;
	}

	public function peekFixed(offset):Float
	{
		return peekLong(offset) / 0x10000;
	}

	public function readFixed():Float
	{
		var val;

		val = peekFixed(pos);
		pos += 4;
		return val;
	}

	public function peekF2Dot14(offset):Float
	{
		var frac:Float;
		var mantissa:Int;
		var val:Int;

		val = peekShort(offset);
		mantissa = (val >> 14) & 0x03;
		frac = (val & 0x3FFF) / 0x4000;
		if (mantissa >= 2)
		{
			mantissa -= 4;
		}
		return mantissa + frac;
	}

	public function readF2Dot14():Float
	{
		var val;

		val = peekF2Dot14(pos);
		pos += 2;
		return val;
	}

	public function peekFWord(offset):Int
	{
		return peekShort(offset);
	}

	public function readFWord():Int
	{
		return readShort();
	}

	public function peekUFWord(offset):Int
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

	inline function heap():Array<Int>
	{
		return untyped __js__('this.harfbuzz[this.heapName]');
	}
}
