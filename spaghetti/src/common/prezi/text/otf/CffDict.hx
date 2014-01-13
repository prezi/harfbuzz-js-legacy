package prezi.text.otf;

class CffDict
{
	private var reader:IFontFileReader;
	private var operatorEncoding:Array<Int->Void>;
	private var operandStack:Array<Float>;
	private var dictStartOffset:Int;

	public function new(reader:IFontFileReader)
	{
		this.reader = reader;

		// Operators and operands may be distinguished by inspection of
		// their first byte: 0–21 specify operators and 28, 29, 30, and
		// 32–254 specify operands (numbers). Byte values 22–27, 31,
		// and 255 are reserved. An operator may be preceded by up to a
		// maximum of 48 operands.
		this.operatorEncoding = [];
		for (i in 0...(21 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { doOperator(b0); };
		}

		for (i in 32...(246 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushByte(b0); };
		}
		for (i in 247...(250 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushSmallInt1(b0); };
		}
		for (i in 251...(254 + 1))
		{
			operatorEncoding[i] = function(b0:Int) { pushSmallInt2(b0); };
		}
		operatorEncoding[28] = function(b0:Int) { pushShortInt(b0); };
		operatorEncoding[29] = function(b0:Int) { pushLongInt(b0); };
		operatorEncoding[30] = function(b0:Int) { pushReal(b0); };

		reset();
	}

	private function reset()
	{
		// Allocate stack and clear it
		this.operandStack = [];
		this.dictStartOffset = 0;
	}

	public function process(offset:Int, length:Int):Dynamic
	{
		// Store DICT start offset to resolve (self) offsets
		dictStartOffset = offset;

		// Save original position
		var originalPosition = reader.position();

		// Move to the CharString
		reader.seek(offset);

		// Process tokens until we run out of tokens
		var end = offset + length;
		while (reader.position() < end)
		{
			processNextToken();
		}

		// Move back to calling position
		reader.seek(originalPosition);

		return null;
	}

	private function processNextToken()
	{
		var opCode = reader.readByte();
		// console.log "--] Token: #{opCode} at #{(reader.position() - 1).hex()}"
		var operator = operatorEncoding[opCode];
		if (operator == null)
			throw "Unknown token " + opCode + " at " + reader.position();
		operator(opCode);
	}

	private function doOperator(b0:Int)
	{
		var operator:Void->Void;
		if (b0 == 12)
		{
			var opCode = reader.readByte();
			// console.log "--> Doing operation: #{b0}, #{opCode} at #{(reader.position() - 2).hex()}"
			operator = getExtendedOperators()[opCode];
			if (operator == null)
			{
				throw "Unknown extended opcode: " + b0 + "," + opCode + " at " + reader.position();
			}
		}
		else
		{
			var opCode = b0;
			// console.log "--> Doing operation: #{opCode} at #{(reader.position() - 1).hex()}"
			operator = getOperators()[opCode];
			if (operator == null)
			{
				throw "Unknown opcode: " + opCode + " at " + reader.position();
			}
		}
		// stackString = ""
		// for element in operandStack
		// 	stackString += " " + if element.hex then element.hex() else element.toString()
		// console.log "-->: Stack: " + stackString
		operator();
	}

	private function getOperators():Array<Void->Void>
	{
		return [];
	}

	private function getExtendedOperators():Array<Void->Void>
	{
		return [];
	}

	//
	// Argument stack handling
	//

	private function pushByte(b0:Int)
	{
		push(b0 - 139);
	}

	private function pushSmallInt1(b0:Int)
	{
		var b1 = reader.readByte();
		push((b0 - 247) * 256 + b1 + 108);
	}

	private function pushSmallInt2(b0:Int)
	{
		var b1 = reader.readByte();
		push(- (b0 - 251) * 256 - b1 - 108);
	}

	private function pushShortInt(b0:Int)
	{
		push(reader.readShort());
	}

	private function pushLongInt(b0:Int)
	{
		push(reader.readLong());
	}

	private function pushFixed1616(b0:Int)
	{
		push(reader.readFixed());
	}

	private static var REAL_NIBBLES:Array<String> =
		['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', 'E', 'E-', null, '-'];

	private function pushReal(b0:Int)
	{
		var number = "";
		while (true)
		{
			var b = reader.readByte();
			var nibble0 = (b & 0xf0) >> 4;
			var nibble1 = b & 0x0f;
			if (nibble0 == 0xf)
			{
				break;
			}
			number += REAL_NIBBLES[nibble0];
			if (nibble1 == 0xf)
			{
				break;
			}
			number += REAL_NIBBLES[nibble1];
		}
		push(Std.parseFloat(number));
	}

	private inline function push(value:Float)
	{
		operandStack.push(value);
	}

	private inline function pop():Float
	{
		return operandStack.pop();
	}

	private function popall():Array<Float>
	{
		var stack = operandStack;
		operandStack = [];
		return stack;
	}
}
