module bf;

import std::io, std::collections::list;

struct Bf
{
	char[30_000] data;
	usz          pos;
	InStream     reader;
	OutStream    writer;
}

fn Bf* Bf.init(&self, InStream reader = io::stdin(), OutStream writer = io::stdout())
{
	*self = { .data = {}, .pos = 0, .reader = reader, .writer = writer };
	return self;
}

fn char Bf.get(&self) @inline => self.data[self.pos];
fn void Bf.set(&self, char c) @inline => self.data[self.pos] = c;

<*
 '>' Increment data pointer by one.
*>
fn void Bf.move_right(&self) => self.pos++;

<*
 '<' Decrement data pointer by one. Undefined when at 0.
*>
fn void Bf.move_left(&self) => self.pos--;

<*
 '+' Increment byte at data pointer by one modulo 256.
*>
fn void Bf.inc(&self) => self.set((char)(((int)self.get() + 1 + 256) % 256));

<*
 '-' Decrement byte at the data pointer by one module 256.
*>
fn void Bf.dec(&self) => self.set((char)(((int)self.get() - 1 + 256) % 256));

<*
 ',' Accept one byte of input and store it in the data pointer.
*>
fn void? Bf.getchar(&self) => self.set(self.reader.read_byte()!);

<*
 '.' output the byte at the data pointer
*>
fn void? Bf.putchar(&self)
{
	// io::printfn("decimal: %d", self.get());
	// io::printfn("char:    %c", self.get());
	self.writer.write_byte(self.get())!;
	if (&self.writer.flush) self.writer.flush()!;
}

fn bool valid(char c) => "<>+-.,[]".contains_char(c);

fn int? Bf.interpret(&self, String s) => @pool()
{
	List{usz} jumps;
	jumps.tinit();

	for (usz i = 0; i < s.len; i++)
	{
		if (!valid(s[i])) continue;
		switch (s[i])
		{
			case '>': self.move_right();
			case '<': self.move_left();
			case '+': self.inc();
			case '-': self.dec();
			case ',': self.getchar()!;
			case '.': self.putchar()!;
			case '[':
				if (self.get() == 0)
				{
					// Jump forward to end of matching ']'
					i++; // Consume '['
					int depth = 1;
					while (i < s.len && depth != 0)
					{
						switch (s[i])
						{
							case '[': depth++;
							case ']': depth--;
						}
						i++;
					}
					// io::printfn("zero data pointer -> jump forward ");
					// io::printfn("jumped forward to pos %d at instruction %c", i, i < s.len ? s[i] : 'X');
				}
				else
				{
					// Starting loop
					jumps.push(i);
					// io::printfn("starting loop; push position %d to jumps", i);
				}
			case ']':
				if (self.get() != 0)
				{
					// Jump backwards to begin of matching '['
					i = jumps.last()!;
					// io::printfn("non-zero data pointer -> jump backwards ");
					// io::printfn("jumped backwards to pos %d at instruction %c", i, s[i]);
				}
				else
				{
					// Leaving loop
					jumps.pop()!;
					// io::printfn("leaving loop");
				}
			default: continue;
		}
	}
	// io::printfn("first 10 data elements: %s", self.data[:10]);
	return 0;
}

fn void test_hello_world() @test => @assert_leak()
{

	String input    = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.";
	String expected = "Hello World!\n";

	char[32] buf;
	ByteWriter bw;
	bw.init_with_buffer(buf[..]);

	Bf interpreter;
	interpreter.init(writer: &bw);
	interpreter.interpret(input)!!;
	assert(buf[:13] == expected[..]);
}
