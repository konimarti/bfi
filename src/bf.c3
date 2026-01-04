module bf;

import std::io, std::collections::list;

fn char mod256(int v, int step) @inline => (char)((v + step + 256) % 256);

fn int? interpret(String s, InStream r = io::stdin(), OutStream w = io::stdout()) => @pool()
{
	char[30_000] data;
	char *pos = &data[0];
	int depth;

	List{usz} jumps;
	jumps.tinit();

	for (usz i = 0; i < s.len; i++)
	{
		switch (s[i])
		{
			case '>': pos++;
			case '<': pos--;
			case '+': *pos = mod256(*pos, 1);
			case '-': *pos = mod256(*pos, -1);
			case ',': *pos = r.read_byte()!;
			case '.': w.write_byte(*pos)!; if (&w.flush) w.flush()!;
			case '[':
				if (*pos == 0)
				{
					// Jump forward to end of matching ']'
					i++; // Consume '['
					depth = 1;
					while (i < s.len && depth != 0)
					{
						switch (s[i])
						{
							case '[': depth++;
							case ']': depth--;
						}
						i++;
					}
				}
				else
				{
					// Starting loop
					jumps.push(i);
				}
			case ']':
				if (*pos != 0)
				{
					// Jump backwards to begin of matching '['
					i = jumps.last()!;
				}
				else
				{
					// Leaving loop
					jumps.pop()!;
				}
			default: continue;
		}
	}
	assert(jumps.len() == 0);
	return 0;
}

fn void test_hello_world() @test => @assert_leak()
{

	String input    = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>."
                          ">---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.";
	String expected = "Hello World!\n";

	char[32] buf;
	ByteWriter bw;
	bw.init_with_buffer(buf[..]);

	interpret(s: input, w: &bw)!!;
	assert(buf[:13] == expected[..]);
}

module bf_bench;

import bf, std::io;

fn void init() @init
{
	set_benchmark_warmup_iterations(5);
	set_benchmark_max_iterations(1_000_000);
}

fn void bench_hello_world() @benchmark
{

	const String INPUT = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>."
                             ">---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.";

	char[32] buf;
	ByteWriter bw;
	bw.init_with_buffer(buf[..]);

	bf::interpret(s: INPUT, w: &bw)!!;
}
