package prezi.text.otf;

interface ICffIndex
{
	public var count (default, null):Int;
	function lookup(index:Int):{ offset:Int, length:Int };
}
