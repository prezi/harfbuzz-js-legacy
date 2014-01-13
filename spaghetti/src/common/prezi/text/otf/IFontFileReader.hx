package prezi.text.otf;

interface IFontFileReader
{
	function seek(position:Int):Void;
	function skip(count:Int):Int;
	function position():Int;

	function peekByte(offset:Int):Int;
	function readByte():Int;
	function peekChar(offset:Int):Int;
	function readChar():Int;
	function peekUShort(offset:Int):Int;
	function readUShort():Int;
	function peekShort(offset:Int):Int;
	function readShort():Int;
	function peekUInt24(offset:Int):Int;
	function readUInt24():Int;
	function peekULong(offset:Int):Int;
	function readULong():Int;
	function peekLong(offset:Int):Int;
	function readLong():Int;
	function peekFixed(offset:Int):Float;
	function readFixed():Float;
	function peekF2Dot14(offset:Int):Float;
	function readF2Dot14():Float;
	function peekFWord(offset:Int):Int;
	function readFWord():Int;
	function peekUFWord(offset:Int):Int;
	function readUFWord():Int;
	function readLongDateTime():Int;
}
