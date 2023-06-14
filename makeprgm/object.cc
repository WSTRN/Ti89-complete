#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "object.h"

// Names of variables defined by linker

int   SymCmp(const void *e1, const void *e2)
{
 return (((SymRef *)e1)->ofs - ((SymRef *)e2)->ofs);
}

int   AStrnCmp(const char *s1, const char *s2, int n)
{
   while (n--)
    if (tolower(*(s1++)) != tolower(*(s2++)))
       return 1;
   return 0;
}

Object::Object(char *name)
{
	// Initialize information variables
   removeExt(name, filename);
   output89=0; output92=0; output92Plus=0; outputV200=0; outputTitanium=0;
   restoreScreen = 1; callExit = 0; readOnly = 0;
	mainOfs=OfsNotDefined; commentOfs=OfsNotDefined; exitOfs=OfsNotDefined;
	extraRAMOfs=OfsNotDefined; stubType=StubNormal;
	code=NULL; codeSize=0;
	bssSize=0;
	reloc[RelocCode].count=0; reloc[RelocCode].ofs=NULL;
	reloc[RelocBSS].count=0; reloc[RelocBSS].ofs=NULL;
	exportCount=0;
	ROM.count=0; RAM.count=0; libCount=0; special.count=0;
	version = 0;
   Debug = 0;
   DSymCount = 0, SymCount = 0;
   Offset = 0;
}

Object::~Object()
{
}

int Object::Read(char *fn)
{
   char buffer[100], file[100];
   removeExt(fn, buffer);
	sprintf(file,"%s.o",buffer);
   FILE *fp=fopen(file,"rb");
   if (fp == NULL)
      {
       printf("Cannot open Object file: %s\n",file);
       return 1;
      }

   // Process each hunk in the object file
	while (1)
	{
		if (feof(fp)) break;
		int hunk=ReadDWord(fp);
      //printf("Hunk code: %X\n", hunk);
		if (hunk==HunkCode)
		{
			int size=ReadDWord(fp); // Size is in DWORDs
			// Allocate space for the code
			code=new char[size<<2];
			codeSize=size<<2;
         //printf(">Code Size = 0x%X\n", codeSize);
			// Read the code into memory
			fread(code,size,4,fp);
		}
		else if (hunk==HunkBSS)
			bssSize=ReadDWord(fp)<<2;
			//printf(">BSS Size = 0x%X\n", bssSize);
		else if (hunk==HunkR32)
		{
			// Read each section's relocations
			while (1)
			{
				int count=ReadDWord(fp);
				if (!count) break;
				int section=ReadDWord(fp);
				if ((section==RelocCode)||(section==RelocBSS))
				{
					// Check to see if the section has already been defined
					if (reloc[section].ofs)
					{
						printf("Error: Duplicate or split relocation information\n");
						return 1;
					}
					reloc[section].count=count;
					reloc[section].ofs=new int[count];
					// Read in the relocation info
					for (int i=0;i<count;i++)
						reloc[section].ofs[i]=0x7FFFFFFFUL & ReadDWord(fp);
				}
				else
				{
					// Unknown section number, so skip relocations
					for (int i=0;i<count;i++)
						ReadDWord(fp);
				}
			}
		}
		else if (hunk==HunkR16)
		{
			printf("Error: 16-bit relocations are unsupported\n");
			return 1;
		}
		else if (hunk==HunkR8)
		{
			printf("Error: 8-bit relocations are unsupported\n");
			return 1;
		}
		else if (hunk==HunkExt) // Exports or external references
		{
			// Read each entry
			while (1)
			{
				int size=ReadDWord(fp);
				// High byte of size contains type byte
				int type=(size>>24)&0xff;
				size&=0xffffff;
				if (type==TypeEnd)
					break;
				// Read name of symbol
				char sym[(size<<2)+1];
				int i;
				for (i=0;i<(size<<2);i++)
					sym[i]=fgetc(fp);
				sym[i]=0;
            //printf("Exported symbol : %s\n", sym);
				if (type==TypeExport)
				{
					// Get offset of exported function
					unsigned long ofs=0x7FFFFFFFUL & ReadDWord(fp);
					// Check for special export names
					if (!strcmp(sym,"_ti89"))
						output89=1;
					else if (!strcmp(sym,"_ti92"))
						output92=1;
					else if (!strcmp(sym,"_ti92plus"))
						output92Plus=1;
					else if (!strcmp(sym,"_v200"))
						outputV200=1;
               else if (!strcmp(sym,"_ti89ti") || !strcmp(sym,"_titanium"))
                  outputTitanium=1;
               else if (!strcmp(sym,"_nosavescreen"))
                  restoreScreen = 0;
               else if (!strcmp(sym,"_main"))
						mainOfs=ofs;
					else if (!strcmp(sym,"_comment"))
						commentOfs=ofs;
					else if (!strcmp(sym,"_EXIT"))
                  exitOfs=ofs, callExit = 1;
					else if (!strcmp(sym,"_exit"))
						exitOfs=ofs;
               else if (!strcmp(sym,"_readonly"))
                  readOnly = 1;
               else if (!strcmp(sym,"_debug"))
                  Debug = 1, printf("Debug\n");
					else if (!strcmp(sym,"_extraram"))
						extraRAMOfs=ofs;
					else if (!strcmp(sym,"_nostub"))
						stubType=StubNone;
					else if (!strcmp(sym,"_mistub"))
						stubType=StubMedium;
               else if (!strcmp(sym,"_install_preos"))
                  stubType=StubInstall;
					else if (!strcmp(sym,"_library"))
						stubType=StubLibrary;
               else if (!AStrnCmp(sym,"_version",8))
                  {
                  version = 1000;
                  sscanf(&sym[strlen(sym)-2],"%x",&version);
						if (version > 255 )
                     {
                     printf("Error: The version of the program couldn't be > 255 : %u\n", version);
                     return 1;
                     }
                  //printf("Program Version: $%X\n", version);
                  }
					else if (strlen(sym)>10 && !AStrnCmp(sym+strlen(sym)-10,"@version",8))
							{
                     int num=1000; // Initialize in case sscanf fails
						   sscanf(&sym[strlen(sym)-2],"%x",&num);
							if (num > 255)
                        {
                        printf("Error: The symbol '%s' couldn't be > 255 : %u\n", sym, num);
                        return 1;
                        }
                     sym[strlen(sym)-10]=0;
							lib[AddLib(sym)].version = num;
                     //printf("LIB %s version $%X \n", sym, num);
                     }
              else if (!AStrnCmp(filename, sym, strlen(filename))
                       && sym[strlen(sym)-5]=='@')
					{
						// Check to make sure number is correct
						int num=-1; // Initialize in case sscanf fails
						sscanf(&sym[strlen(sym)-4],"%x",&num);
						if (num!=exportCount)
						{
							printf("Error: Exported function xdef out of order or invalid: %s\n"
                            "Expected exported function number : %u\n"
							       "You can't define the exported functions in a random order !\n"
							       "And do not define functions\n", sym, exportCount);
							return 1;
						}
						// Add label to export table
						exportOfs[exportCount++]=ofs;
					}
               else
                   printf("WARNING: Useless Export '%s'\n", sym);
				}
				else if (type==TypeImport32)
				{
					// Read number of references
					int count=ReadDWord(fp);
					if (!strncmp(sym,"_ROM_CALL_",10))
					{
						// Add references to ROM reference table
						int func=-1; // Initialize in case sscanf fails
						sscanf(&sym[10],"%x",&func);
						if (func==-1)
						{
							printf("Error: cannot read rom call value '%s'\n",sym);
							return 1;
						}
						for (i=0;i<count;i++)
						{
							ROM.ref[ROM.count].type=LibRefDWord;
							ROM.ref[ROM.count].func=func;
							ROM.ref[ROM.count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
						}
					}
					else if (!strncmp(sym,"_RAM_CALL_",10))
					{
						// Add references to RAM reference table
						int func=-1; // Initialize in case sscanf fails
						sscanf(&sym[10],"%x",&func);
						for (i=0;i<count;i++)
						{
							RAM.ref[RAM.count].type=LibRefDWord;
							RAM.ref[RAM.count].func=func;
							RAM.ref[RAM.count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
						}
					}
					else if (!strncmp(sym,"_extraramaddr@",14))
					{
						// Add references to RAM reference table, setting
						// the extra flag
						int func=-1; // Initialize in case sscanf fails
						sscanf(&sym[14],"%x",&func);
						for (i=0;i<count;i++)
						{
							RAM.ref[RAM.count].type=LibRefDWord|LibRefExtra;
							RAM.ref[RAM.count].func=func;
							RAM.ref[RAM.count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
						}
					}
					else if (strlen(sym)>=5 && sym[strlen(sym)-5]=='@') // Library reference
					{
							// Add library reference to table
							int func=-1; // Initialize in case sscanf fails
							sscanf(&sym[strlen(sym)-4],"%x",&func);
							if (func==-1)
							{
								printf("Error: Undefined symbol '%s'\n",sym);
								return 1;
							}						
							sym[strlen(sym)-5]=0; // Strip number from name
							int libNum=AddLib(sym);
							for (i=0;i<count;i++)
							{
								lib[libNum].ref[lib[libNum].count].type=LibRefDWord;
								lib[libNum].ref[lib[libNum].count].func=func;
								lib[libNum].ref[lib[libNum].count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
							}
					}
               else // Unknow Imported labels
               {
                 printf("ERROR: Undefined symbol '%s'\n", sym);
                 return 1;
                 //strncpy(Symbol[SymCount].name, sym, 128);
                 //Symbol[SymCount].ofs =ReadDWord(fp);
                 //SymCount++;
               }
				}

				else if ((type==TypeImport16)||(type==TypeImport16Alt))
				{
					// Read number of references
					int count=ReadDWord(fp);
					if (!strncmp(sym,"_ROM_CALL_",10))
					{
						printf("Error: Rom calls '%s' cannot be used as 16-bit\n",sym);
						return 1;
					}
					else if (!strncmp(sym,"_RAM_CALL_",10))
					{
						// Add references to RAM reference table
						int func=-1; // Initialize in case sscanf fails
						sscanf(&sym[10],"%x",&func);
                  if (func == -1)
                     {
                      printf("Symbol %s is not a valid RAM_CALL\n",sym);
                      return -1;
                     }
						for (i=0;i<count;i++)
						{
							RAM.ref[RAM.count].type=LibRefWord;
							RAM.ref[RAM.count].func=func;
							RAM.ref[RAM.count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
						}
					}
					else if (!strncmp(sym,"_extraramaddr@",14))
					{
						// Add references to RAM reference table, setting
						// the extra flag
						int func=-1; // Initialize in case sscanf fails
						sscanf(&sym[14],"%x",&func);
                  if (func == -1)
                     {
                      printf("Symbol %s is not a valid EXTRA_RAM_CALL\n",sym);
                      return -1;
                     }
						for (i=0;i<count;i++)
						{
							RAM.ref[RAM.count].type=LibRefWord|LibRefExtra;
							RAM.ref[RAM.count].func=func;
							RAM.ref[RAM.count++].ofs=0x7FFFFFFFUL & ReadDWord(fp);
						}
					}
					else if (strlen(sym)>=5 && sym[strlen(sym)-5] == '@')// Library or linker-defined reference
					{
							printf("Error: Library call '%s' cannot be used as 16-bit\n",sym);
							return 1;
					}
               else
                   {
                     printf("Sorry, cannot import symbol %s as 16-bits.\n",sym);
                     return 1;
                   }
				}
				else if (type==TypeImport8)
				{
					printf("Error: 8-bit imports are unsupported for symbol '%s'\n", sym);
					return 1;
				}
				/*else if (type == TypeEqu)
				{
					unsigned int val = ReadDWord(fp);
					if (!strcmp(sym,"_version"))
						{
						version = val;
                  if (val > 255)
                     {
                     printf("Error: The version of the program couldn't be > 255 : %u\n", val);
                     return 1;
                     }
                  }
					else if (strlen(sym)>8 && !strcmp(sym+strlen(sym)-8,"@version"))
							{
                     if (val > 255)
                        {
                        printf("Error: The symbol '%s' couldn't be > 255 : %u\n", sym, val);
                        return 1;
                        }
                     sym[strlen(sym)-8]=0;
							lib[AddLib(sym)].version = val; // Problem : we can add a library without any importation !
                     }
               else
						printf("Warning: '%s' is an useless exported EQU\n", sym);
				}*/
				else 
				{
					printf("Error: Unknown symbol '%s' type number $%2.2X\n",sym,type);
					return 1;
				}
			}
		}
		else if (hunk==HunkEnd) // End of code or BSS section
		{
			// Do nothing
		}
		else if (hunk==HunkSym)
		 {
       int size;
       int i;
       while ((size = ReadDWord(fp)) != 0)
             {
              // Read name of symbol
				  for (i=0;i<(size<<2);i++)
				   	DSymbol[DSymCount].name[i]=fgetc(fp);
				  DSymbol[DSymCount].name[i]=0;
              DSymbol[DSymCount].ofs = ReadDWord(fp);
              //printf("Symbol %s Offset %X\n", DSymbol[DSymCount].name, DSymbol[DSymCount].ofs);
              DSymCount++;
             }
       qsort(DSymbol, DSymCount, sizeof(SymRef), SymCmp);
       }
      else if (!feof(fp))
		{
			int size=ReadDWord(fp); // Size is in DWORDs
			// Unused hunk, so skip it
         //printf("Unused hunk section : %X\n", hunk);
			fseek(fp,size<<2,SEEK_CUR);
		}
	}

   // Fix the unused libs bugs...
   for(int i = 0 ; i < libCount ;)
           {
           if (lib[i].count == 0)
              {
              for(int j = i ; j < libCount; j++)
                      lib[j] = lib[j+1];
              libCount--;
              }
           else i++;
           }

   printf("RELOC CODE:%d RELOC BSS:%d ROM CALLS:%d RAM CALLS:%d LIBRARIES:%d SYMBOLS:%d\n",
                 reloc[0].count, reloc[1].count, ROM.count, RAM.count, libCount, DSymCount);
   // Sort the symbols
	return 0;
}


int Object::Write()
{
  return 0;
}

void Object::CopyInfo(Object *obj)
{
	output89=obj->output89; output92=obj->output92;
	output92Plus=obj->output92Plus; outputV200=obj->outputV200;
   outputTitanium = obj->outputTitanium;
   readOnly = obj->readOnly; restoreScreen = obj->restoreScreen;
   callExit = obj->callExit;
   codeSize=obj->codeSize; bssSize=obj->bssSize;
	code=new char[codeSize]; memcpy(code,obj->code,codeSize);
	memcpy(&reloc[0],&obj->reloc[0],sizeof(RelocInfo));
	memcpy(&reloc[1],&obj->reloc[1],sizeof(RelocInfo));
	mainOfs=obj->mainOfs; commentOfs=obj->commentOfs;
	exitOfs=obj->exitOfs; extraRAMOfs=obj->extraRAMOfs;
	stubType=obj->stubType;
	exportCount=obj->exportCount;
	memcpy(exportOfs,obj->exportOfs,sizeof(int)*MAX_EXPORTS);
	memcpy(&ROM,&obj->ROM,sizeof(LibRefInfo));
	memcpy(&RAM,&obj->RAM,sizeof(LibRefInfo));
	memcpy(lib,obj->lib,sizeof(LibRefInfo)*MAX_LIBS);
	memcpy(&special,&obj->special,sizeof(LibRefInfo));
	libCount=obj->libCount;
	version = obj->version;
   DSymCount = obj->DSymCount;
   memcpy(DSymbol, obj->DSymbol, sizeof(SymRef)*MAX_SYMBOL);
   Debug = obj->Debug;
   SymCount = obj->SymCount;
   memcpy(Symbol, obj->Symbol, sizeof(SymRef)*MAX_SYMBOL);
}

int Object::AddLib(char *name)
{
	int found=-1;

	// Search library table for name
	for (int i=0;i<libCount;i++)
	{
		if (!strcmp(name,lib[i].name))
		{
			found=i;
			break;
		}
	}
	if (found==-1)
	{
		// Add a new library
		strcpy(lib[libCount].name,name);
		lib[libCount].version = 0;
		lib[libCount++].count = 0;
		return libCount-1;
	}
	else
		return found;
}
