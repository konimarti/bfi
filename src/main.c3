module bfi;
import bf, std::io;

fn int main(String[] args) => @pool()
{
	if (args.len != 2)
	{
		io::printfn("Usage: bfi <file>");
		return 1;
	}
	char[] code = file::load_temp(args[1]) ?? args[1][..];

	Bf interpreter;
	interpreter.init();
	return interpreter.interpret((String)code[..])!!;
}

