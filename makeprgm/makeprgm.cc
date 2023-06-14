#include <stdio.h>
#include "object.h"
#include "prog.h"


int main(int argc,char *argv[])
{

  printf("MAKEPRGM by Rusty Wagner\n Modified by PpHd Version P16+\n");

  if (argc<2)
	{
		printf("Usage: MAKEPRGM NameOfObjectFile\n");
		return 1;
	}
	// Open the object file
	Object *obj=new Object(argv[1]);
	// Read the object file information into memory
	if (obj->Read(argv[1])) return 1;
	if ((!obj->output89)&&(!obj->output92)&&(!obj->output92Plus)
	   &&(!obj->outputV200)&&(!obj->outputTitanium))
		obj->output92Plus=1;
	// Create the output file(s)
	if (obj->output89||obj->outputTitanium) // Output TI-89 file?
	{
      // Create a new program file object
		PlusShellProgram *prog=new PlusShellProgram(argv[1],89);
		// Copy the information from the object file
		prog->CopyInfo(obj);
		// Write the program
		if (prog->Write()) return 1;
		delete prog;
	}
	if (obj->output92Plus||obj->outputV200) // Output TI-92+ file?
	{
		// Create a new program file object
		PlusShellProgram *prog=new PlusShellProgram(argv[1],92);
		// Copy the information from the object file
		prog->CopyInfo(obj);
		// Write the program
		if (prog->Write()) return 1;
		delete prog;
	}
	delete obj;
	return 0;
}
