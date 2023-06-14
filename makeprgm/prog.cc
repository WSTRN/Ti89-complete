#include <stdio.h>
#include "prog.h"
#include "progstub.h" // Contains kernel-based loader code

// Values of linker-defined variables in PlusShell
int PlusShellSpecialVal[]={0x4c00,0,10,12,14};

PlusShellProgram::PlusShellProgram(char *fn,int _calc): Program(fn)
{
   char buffer[100];
   removeExt(fn, buffer);
	calc=_calc;
	// Override old file name
	/*if (filename) delete[] filename;
	filename=new char[strlen(buffer)+5];
	*/
	sprintf(filename,"%s.%sz",buffer,(calc==89)?"89":"9x");
}

PlusShellProgram::~PlusShellProgram()
{
}

/*
int PlusShellProgram::Read()
{
	// Read the file into memory
	FILE *fp=fopen(filename,"rb");
	fseek(fp,0x56,SEEK_SET);
	size=fgetc(fp)<<8;
	size|=fgetc(fp);
	size-=1; // Leave out ASM token at end
	fread(data,size,1,fp);
	fclose(fp);
	if ((data[4]=='P')&&(data[5]=='S')&&(data[6]=='v'))
	{
		// Pre PlusShell v1.0 program
		int pos; // Variable to keep track of position in data
		output89=(data[8]&0x80)?1:0;
		output92Plus=(data[8]&0x40)?0:1;
		if (data[9]=='P') // Program
		{
			// Read offset of comment
			commentOfs=ReadWord(0xa);
			exportCount=0; // v0.99 programs could not have exports
			pos=0xc; // Relocation info starts at offset 0xc
		}
		else // Library
		{
			// Read export table
			exportCount=ReadWord(0xe);
			pos=0x10; // Export table starts at offset 0x10
			for (int i=0;i<exportCount;i++)
			{
				exportOfs[i]=ReadWord(pos);
				pos+=2; // Advance position to next entry
			}
		}
		// Read ROM relocation table
		int count=ReadWord(pos); pos+=2;
		for (int i=0;i<count;i++)
		{
			int ofs=ReadWord(pos); pos+=2;
			int func=ReadWord(pos); pos+=2;
			ROM.ref[ROM.count].type=LibRefDWord;
			ROM.ref[ROM.count].func=func;
			ROM.ref[ROM.count++].ofs=ofs;
		}
		if (data[7]!='0') // No RAM relocation table before v0.99tr1
		{
			// Read RAM relocation table
			count=ReadWord(pos); pos+=2;
			for (int i=0;i<count;i++)
			{
				int ofs=ReadWord(pos); pos+=2;
				int func=ReadWord(pos); pos+=2;
				if (func<3) // Only 0-2 are stored in RAM table now
				{
					RAM.ref[RAM.count].type=(func&0x8000)?LibRefWord:LibRefDWord;
					RAM.ref[RAM.count].func=func&0x7fff;
					RAM.ref[RAM.count++].ofs=ofs;
				}
				else // Func #3 and above now have ROM equivilents
				{
					int funcOfs; // Offset from ROM address
					if (func==3) { func=0x2f; funcOfs=0x11a; }
					else if (func==4) { func=0x2a3; funcOfs=0x15a+0x1c; }
					else if (func==5) { func=0x2a3; funcOfs=0x15a+0x1e; }
					else
					{
						printf("Error: Unknown v0.99 RAM address number $%X\n",func);
						return 1;
					}
					// Zero out reference in code before adding
					data[ofs]=0; data[ofs+1]=0;
					data[ofs+2]=0; data[ofs+3]=0;
					// Update offset in the code
					AddDWord(&data[ofs],funcOfs);
					// Add reference to ROM reference table
					ROM.ref[ROM.count].type=LibRefDWord;
					ROM.ref[ROM.count].func=func;
					ROM.ref[ROM.count++].ofs=ofs;
				}
			}
		}
		// Read library relocation table
		count=ReadWord(pos); pos+=2;
		for (int i=0;i<count;i++)
		{
			// Read library name
			for (int j=0;j<8;j++)
				lib[libCount].name[j]=data[pos++];
			lib[libCount].name[8]=0; // Terminating null
			lib[libCount].count=0; // Reset number of library references
			// Read library references
			int refCount=ReadWord(pos); pos+=2;
			for (int j=0;j<refCount;j++)
			{
				int ofs=ReadWord(pos); pos+=2;
				int func=ReadWord(pos); pos+=2;
				if (!strcmp(lib[libCount].name,"gray4lib"))
				{
					// Functions in old version of gray4lib were in a
					// different order
					if (func==0) func=1;
					else if (func==1) func=0;
				}
				// Add reference to library reference table
				lib[libCount].ref[lib[libCount].count].type=LibRefDWord;
				lib[libCount].ref[lib[libCount].count].func=func;
				lib[libCount].ref[lib[libCount].count++].ofs=ofs;
			}
			libCount++;
		}
		// Pre v0.9 programs did not have a BSS relocation table.  In
		// these versions, the stub code start where the BSS table would
		// start otherwise.  Check to see if the stub code follows, and if
		// not, read the BSS table.
		if (((data[pos]!=0x48)||(data[pos+1]!=(char)0xe7)||(data[pos+2]!=0x7f)||
			(data[pos+3]!=(char)0xfe)||(data[pos+4]!=0x28)||(data[pos+5]!=0x7c)||
			(data[pos+6]!=0)||(data[pos+7]!=0)||(data[pos+8]!=0)||
			(data[pos+9]!=0))&&
			((data[pos]!=0x48)||(data[pos+1]!=0x7a)||(data[pos+4]!=0x28)||
			(data[pos+5]!=0x78)||(data[pos+6]!=0)||(data[pos+7]!=(char)0xc8)||
			(data[pos+8]!=(char)0xd9)||(data[pos+9]!=(char)0xfc)))
		{
			// Allocate memory for BSS relocations
			reloc[1].ofs=new int[MAX_RELOCS];
			// Read BSS relocation table			
			bssSize=ReadWord(pos); pos+=2;
			count=ReadWord(pos); pos+=2;
			for (int i=0;i<count;i++)
			{
				int codeOfs=ReadWord(pos); pos+=2;
				int bssOfs=ReadWord(pos); pos+=2;
				// Zero out reference in code before adding
				data[codeOfs]=0; data[codeOfs+1]=0;
				data[codeOfs+2]=0; data[codeOfs+3]=0;
				// Add BSS offset in code
				AddDWord(&data[codeOfs],bssOfs);
				// Add relocation to BSS table
				reloc[1].ofs[reloc[1].count++]=codeOfs;
			}
		}
		// Find 'LIBRARY NOT FOUND' so that the end of the stub can be located
		for (;;pos++)
		{
			if (!strcmp(&data[pos],"LIBRARY NOT FOUND:  "))
				break;
			if (pos>size)
			{
				printf("Error: Program has invalid format\n");
				return 1;
			}
		}
		// Find BRA to _main instruction which marks start of actual code
		for (;;pos+=2)
		{
			if ((data[pos]==0x60)&&(data[pos+1]==0))
				break;
			if (pos>size)
			{
				printf("Error: Program has invalid format\n");
				return 1;
			}
		}
		codeSize=size-pos; // Calculate size of code
		code=new char[codeSize]; // Allocate memory for code
		memcpy(code,&data[pos],codeSize); // Copy code into correct mem area
		int stubLen=pos; // Save stub length
		// Allocate memory for relocations
		reloc[0].ofs=new int[MAX_RELOCS];
		// Read relocation table
		pos=size;
		while (1)
		{
			pos-=2; int ofs=ReadWord(pos);
			if (ofs==0) break;
			pos-=2; int dest=ReadWord(pos);
			// There is always one relocation table entry which is in
			// the stub code and points to offset 0 of the program.  This
			// entry will not be needed and is discarded.
			if (dest==0) continue;
			// Subract stub size from offsets
			ofs-=stubLen; dest-=stubLen;
			// Zero out reference in code before adding
			code[ofs]=0; code[ofs+1]=0;
			code[ofs+2]=0; code[ofs+3]=0;
			// Add destination offset in actual code
			AddDWord(&code[ofs],dest);
			reloc[0].ofs[reloc[0].count++]=ofs;
		}
		// Recalculate code size to exclude old relocation table
		codeSize=pos-stubLen;
		// Subtract stub length from library relocations
		for (int i=0;i<libCount;i++)
		{
			for (int j=0;j<lib[i].count;j++)
				lib[i].ref[j].ofs-=stubLen;
		}
		// Subtract stub length from ROM relocations
		for (int i=0;i<ROM.count;i++)
			ROM.ref[i].ofs-=stubLen;
		// Subtract stub length from RAM relocations
		for (int i=0;i<RAM.count;i++)
			RAM.ref[i].ofs-=stubLen;
		// Subtract stub length from BSS relocations
		for (int i=0;i<reloc[1].count;i++)
			reloc[1].ofs[i]-=stubLen;
		// Subtract stub length from exports
		for (int i=0;i<exportCount;i++)
			exportOfs[i]-=stubLen;
		// Subtract stub length from comment offsets
		if (commentOfs!=OfsNotDefined) commentOfs-=stubLen;
		// Set main offset to the BRA instruction (jumps to correct _main)
		if (data[9]=='P') mainOfs=0;
	}
	else if ((data[4]=='6')&&(data[5]=='8')&&(data[6]=='k'))
	{
		// PlusShell v1.0 or later program
		printf("Error: Program is already compiled for the new version\n");
		return 1;
	}
	else
	{
		// Non PlusShell program
		printf("Error: Program is not a PlusShell program and does not need conversion\n");
		return 1;
	}
	return 0;
}
*/

void PlusShellProgram::WriteData()
{
	FILE *out=fopen(filename,"wb");
	int i,csum;
	// Write signature
	if (calc==89)
		{
		fprintf(out,"**TI89**");
      printf("TARGET TI-89    SIZE: %d\n", size+3);
		}
   else
      {
		fprintf(out,"**TI92P*");
      printf("TARGET TI-92+   SIZE: %d\n", size+3);
		}
   fputc(1,out); fputc(0,out); // Unknown
	// Output folder name
	fprintf(out,"main");
	fputc(0,out); fputc(0x8b,out); fputc(0x76,out); fputc(0xa,out);
	// File comment (doesn't seem to work if not filled with zero bytes)
	for (i=0;i<40;i++)
		fputc(0,out);
	fputc(1,out); fputc(0,out); fputc(0x52,out); fputc(0,out); // Unknown
	fputc(0,out); fputc(0,out); // Unknown
	// Output program name
	for (i=0;i<8;i++)
	{
		if (filename[i]=='.') break;
		fputc(filename[i],out);
	}
	for (;i<8;i++)
		fputc(0,out);
	// Output program type
	fputc(0x21,out); fputc(0,out); fputc(0,out); fputc(0,out);
	// Output file length
	fputc((size+0x5b)&0xff,out);
	fputc((size+0x5b)>>8,out);
	fputc(0,out); fputc(0,out);
	fputc(0xa5,out); fputc(0x5a,out); fputc(0,out); fputc(0,out); // Unknown
	fputc(0,out); fputc(0,out); // Unknown
	// Output program length
	fputc((size+1)>>8,out);
	fputc((size+1)&0xff,out);
	// Add program length to checksum
	csum=(size+1)&0xff;
	csum+=((size+1)>>8)&0xff;
	// Output program data
	for (i=0;i<size;i++)
	{
		fputc(data[i],out);
		csum+=data[i]&0xff;
	}
	fputc(0xf3,out); // Assembly program token
	csum+=0xf3;
	// Output checksum
	fputc(csum&0xff,out);
	fputc((csum>>8)&0xff,out);
	fclose(out);
}

void PlusShellProgram::GetOffsets(int &bssTableOfs,int &exportTableOfs,int &stubCodeOfs,int &stubLen)
{
	stubLen=0x1a; // 0x1a is the start of the lib relocation table, the first
				  // dynamically sized section of the program header
	// Library import table
   //printf("Libs: %X\n", stubLen);
	stubLen+=2;            // Number of libs used
	stubLen+=libCount*10;  // Library names
	// Library relocation info
	for (int i=0;i<libCount;i++)
	{
		stubLen+=2; // Number of functions used in lib - 1
		int func=-1;
		// Examine library functions used
		for (int j=0;j<lib[i].count;j++)
		{
			if (func!=lib[i].ref[j].func)
			{
				if (func!=-1) stubLen+=2; // Terminate old list if needed
				func=lib[i].ref[j].func;
				stubLen+=2; // Function number
			}
			stubLen+=2; // Relocation offset
		}
		stubLen+=2;    // End the list from the last function
	}
	//printf("ROMS: %X\n", stubLen);
	// ROM reference table
	stubLen+=2;      // Number of ROM references
	// Output ROM relocation info
	int func=-1;
	if (ROM.count) // Table exists only if there are ROM references
		{
		stubLen+=2; // Number of ROM functions used - 1
	   // Examine ROM functions used
	   for (int j=0;j<ROM.count;j++)
	   {
		 if (func!=ROM.ref[j].func)
		 {
			if (func!=-1) stubLen+=2; // Terminate old list if needed
			func=ROM.ref[j].func;
			stubLen+=2; // Function number
		  }
       stubLen+=2; // Relocation offset
   	}
      stubLen+=2; // End the list from the last function
      }

   //printf("RAMS: %X\n", stubLen);
   // RAM reference table
	stubLen+=2; // Number of RAM references
	// Output RAM relocation info
	func=-1;
	if (RAM.count) // Table exists only if there are RAM references
		{
		stubLen+=2; // Number of RAM functions used - 1
	   // Examine RAM functions used
	   for (int j=0;j<RAM.count;j++)
	   {
		 if (func!=(RAM.ref[j].func|RAM.ref[j].type))
		    {
			 if (func!=-1) stubLen+=2; // Terminate old list if needed
			 func=RAM.ref[j].func|RAM.ref[j].type;
			 stubLen+=2;             // Function number
		    }
       stubLen+=2; // Relocation offset
	    }
      stubLen+=2; // End the list from the last function
      }
   // Code relocation table
   //printf("Code: %X\n", stubLen);
	stubLen+=2+(reloc[0].count*2); // Relocations and terminating marker
	// BSS relocation table
	//printf("BSS: %X\n", stubLen);
   bssTableOfs=stubLen;
	stubLen+=6+(reloc[1].count*2); // Size, relocations and terminating marker
	// Export table
	//printf("EXPORTS: %X\n", stubLen);
   exportTableOfs=stubLen;
	stubLen+=4+(exportCount*2); // Count, offsets, and terminating marker
	stubCodeOfs=stubLen;

   if (stubType == StubMedium)
      stubLen+=progMiStubLen;
   else if (stubType == StubInstall)
      stubLen+=progInstallStubLen;
	else if (stubType!=StubLibrary)
		stubLen+=progStubLen; // Stub loader code

   printf(">Stub size = 0x%X BssOfs = 0x%X ExportOfs = 0x%X StubCodeOFs = 0x%X\n",
                 stubLen, bssTableOfs, exportTableOfs, stubCodeOfs);
}

int PlusShellProgram::Write()
{
	ResetData();

	// Fill in linker-defined references with their values
	for (int i=0;i<special.count;i++)
	{
		if (special.ref[i].type&LibRefWord)
			AddWord(&code[special.ref[i].ofs],PlusShellSpecialVal[special.ref[i].func]);
		else // Dword reference
			AddDWord(&code[special.ref[i].ofs],PlusShellSpecialVal[special.ref[i].func]);
	}

	if (stubType != StubNone)
	{
		// Get size of stub and offset of tables
		int bssTableOfs,exportTableOfs,stubCodeOfs,stubLen;
		GetOffsets(bssTableOfs,exportTableOfs,stubCodeOfs,stubLen);	
		if (stubType==StubLibrary)
		{
			// Libraries cannot be executed, so first instruction is rts
			WriteWord(0x4e75);
			WriteWord(0x4e75);
			// Write signature dword
			WriteByte('6'); WriteByte('8'); WriteByte('k'); WriteByte('L');
		}
		else // File is a program
		{	
			// Branch to stub loader code
			WriteDWord(0x61000000+(stubCodeOfs-2));
			// Write signature dword
			WriteByte('6'); WriteByte('8'); WriteByte('k'); WriteByte('P');
		}

		// Extra Flags
      WriteByte(0);
      // Relocation count - always zero at first
		WriteByte(0);

		// Offsets to _main, _comment, and _exit
		if (commentOfs==OfsNotDefined)
			WriteWord(0); // No _comment
		else
			WriteWord(commentOfs+stubLen);
		if (mainOfs==OfsNotDefined)
			WriteWord(0); // No _main
		else
			WriteWord(mainOfs+stubLen);
		if (exitOfs==OfsNotDefined)
			WriteWord(0); // No _exit
		else
			WriteWord(exitOfs+stubLen);
		// Version Number
      WriteByte(version);
		// Compatibility flags
		WriteByte((output92Plus?1:0)
               |(output89?2:0)
               |(restoreScreen?0:4)
               |(readOnly?8:0)
               |(output92?16:0)
               |(outputV200?32:0)
               |(outputTitanium?64:0) );
		// BSS handle - used by kernel when program is run
		WriteWord(0);
		// Offset to BSS, export, and extra RAM tables
		if (bssSize)
			WriteWord(bssTableOfs);
		else // No BSS section
			WriteWord(0);
		WriteWord(exportTableOfs);
		if (extraRAMOfs==OfsNotDefined)
			WriteWord(0); // No extra RAM table
		else
			WriteWord(extraRAMOfs+stubLen);
      //printf("2LIBS: %X\n", size);
      // Library import table
		WriteWord(libCount); // Number of libs used
		// Output names of all libraries
		for (int i=0;i<libCount;i++)
		{
			int j;
			for (j=0;j<8;j++)
			{
				if (!lib[i].name[j]) break;
				WriteByte(lib[i].name[j]);
			}
			for (;j<9;j++)
				WriteByte(0);
         WriteByte(lib[i].version);
		}
		// Output library relocation info
		for (int i=0;i<libCount;i++)
		{
			int count=0;
			int func=-1;
			// Count the number of library functions used
			for (int j=0;j<lib[i].count;j++)
			{
				if (func!=lib[i].ref[j].func)
				{
					count++;
					func=lib[i].ref[j].func;
				}
			}
			// Add stub size to lib relocation offsets
			for (int j=0;j<lib[i].count;j++)
				lib[i].ref[j].ofs+=stubLen;
			WriteWord(count-1);           // Number of functions used in lib - 1
			// Output table
			func=-1;
			for (int j=0;j<lib[i].count;j++)
			{
				if (func!=lib[i].ref[j].func)
				{
					if (func!=-1) WriteWord(0); // Terminate old list if needed
					func=lib[i].ref[j].func;
					WriteWord(func);				
				}
				WriteWord(lib[i].ref[j].ofs);
			}
			// End the list from the last function
			WriteWord(0);
		}

		// ROM reference table
      //printf("2ROMS: %X\n", size);
      WriteWord(ROM.count);
		if (ROM.count) // Table only exists if there are ROM references
		{
			// Output ROM relocation info
			int count=0;
			int func=-1;
			// Count the number of ROM functions used
			for (int j=0;j<ROM.count;j++)
			{
				if (func!=ROM.ref[j].func)
				{
					count++;
					func=ROM.ref[j].func;
				}
			}
			// Add stub size to ROM relocation offsets
			for (int j=0;j<ROM.count;j++)
				ROM.ref[j].ofs+=stubLen;
			WriteWord(count-1); // Number of ROM functions used - 1
			// Output table
			func=-1;
			for (int j=0;j<ROM.count;j++)
			{
				if (func!=ROM.ref[j].func)
				{
					if (func!=-1) WriteWord(0); // Terminate old list if needed
					func=ROM.ref[j].func;
					WriteWord(func);				
				}
				WriteWord(ROM.ref[j].ofs);
			}
			// End the list from the last function
			WriteWord(0);
		}

		// RAM reference table
		//printf("2RAMS: %X\n", size);
      WriteWord(RAM.count);
		if (RAM.count) // Table only exists if there are RAM references
		{
			// Output RAM relocation info
			int count=0;
			int func=-1;
			// Count the number of RAM functions used
			for (int j=0;j<RAM.count;j++)
			{
				if (func!=(RAM.ref[j].func|RAM.ref[j].type))
				{
					count++;
					// Function number and type are combined into one value
					// to save space
					func=RAM.ref[j].func|RAM.ref[j].type;
				}
			}
			// Add stub size to RAM relocation offsets
			for (int j=0;j<RAM.count;j++)
				RAM.ref[j].ofs+=stubLen;
			WriteWord(count-1); // Number of RAM functions used - 1
			// Output table
			func=-1;
			for (int j=0;j<RAM.count;j++)
			{
				if (func!=(RAM.ref[j].func|RAM.ref[j].type))
				{
					if (func!=-1) WriteWord(0); // Terminate old list if needed
					func=RAM.ref[j].func|RAM.ref[j].type;
					WriteWord(func);				
				}
				WriteWord(RAM.ref[j].ofs);
			}
			// End the list from the last function
			WriteWord(0);
		}
      //printf("2CODES: %X\n", size);
		// Code relocation table
		for (int i=0;i<reloc[0].count;i++)
		{
			// Update destination offset in code section
			AddDWord(&code[reloc[0].ofs[i]],stubLen);
			// Write relocation offset
			WriteWord(reloc[0].ofs[i]+stubLen);
		}
		WriteWord(0); // End relocation table

		// BSS relocation table
      //printf("2BSS: %X\n", size);
      WriteDWord(bssSize);
		for (int i=0;i<reloc[1].count;i++)
			WriteWord(reloc[1].ofs[i]+stubLen);
		WriteWord(0); // End relocation table

		// Export table
      //printf("2EXPORTS: %X\n", size);
		WriteWord(exportCount);
		for (int i=0;i<exportCount;i++)
			WriteWord(exportOfs[i]+stubLen);
		WriteWord(0); // End export table

		// Output stub code
		if (stubType!=StubLibrary)
		{
         if (stubType == StubMedium)
            {
             for (int i=0;i<progMiStubLen;i++)
				    WriteByte(progMiStub[i]);
            }
         else if (stubType == StubInstall)
            {
             for (int i=0;i<progInstallStubLen;i++)
				    WriteByte(progInstallStub[i]);
            }
         else
			   for (int i=0;i<progStubLen;i++)
				    WriteByte(progStub[i]);
		}

		// Output code
		for (int i=0;i<codeSize;i++)
			WriteByte(code[i]);

      // Debug infos
      if (Debug)
         {
         WriteByte(0);
         WriteWord(0xFFFF);   // Symbol Table End
         for(int i = 0 ; i < DSymCount ; i++)
             {
              for(int j = 0 ; DSymbol[i].name[j] != 0 ; j++)
                 WriteByte(DSymbol[i].name[j]);
              WriteByte(0); // String ends
              WriteWord(DSymbol[i].ofs + stubLen);
             }
         }

		WriteWord(0); // Termination marker for TI's relocation method
	}
	else // No stub
	{
		// Output code
		for (int i=0;i<codeSize;i++)
			WriteByte(code[i]);
		WriteWord(0); // Termination marker for TI's relocation method
		// Code relocation table
		for (int i=0;i<reloc[0].count;i++)
		{
			WriteWord(ReadDWord(reloc[0].ofs[i]));
			WriteWord(reloc[0].ofs[i]);
		}
	}
	WriteData();
	return 0;
}


