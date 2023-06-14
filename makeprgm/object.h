#ifndef __OBJECT_H__
#define __OBJECT_H__

// These are the hunk IDs from the A68K source
#define HunkUnit 999
#define HunkName 1000
#define HunkCode 1001
#define HunkData 1002
#define HunkBSS  1003
#define HunkR32  1004
#define HunkR16  1005
#define HunkR8   1006
#define HunkExt  1007
#define HunkSym  1008
#define HunkDbg  1009
#define HunkEnd  1010

// Relocation section IDs
#define RelocCode 0
#define RelocBSS 1

// Symbol entry type IDs
#define TypeEnd 0
#define TypeExport 1
#define TypeImport32 0x81
#define TypeImport16 0x83
#define TypeImport8 0x84
#define TypeImport16Alt 0x8a
#define TypeEqu 0x02

// Stub types
#define StubNone 0
#define StubNormal 1
#define StubStandalone 2
#define StubLibrary 3
#define StubFargoConvert 4
#define StubMedium 5
#define StubInstall 6

// Library/RAM/ROM reference types
#define LibRefDWord 0
#define LibRefWord 0x8000
#define LibRefExtra 0x4000

#define OfsNotDefined -1

#define MAX_EXPORTS 2048
#define MAX_LIBS 32
#define MAX_LIB_REF 2048
#define MAX_RELOCS 16384
#define MAX_SYMBOL 32768

struct RelocInfo
{
	int count;
	int *ofs;
};

struct LibRef
{
	int type;
	int func;
	int ofs;
};

struct LibRefInfo
{
	char name[9];
	int count;
	unsigned int version;
	LibRef ref[MAX_LIB_REF];
};

struct SymRef
{
  char name[129];
  int  ofs;
};

class Object
{
protected:
   char filename[20];
	int codeSize,bssSize;
	char *code;
	RelocInfo reloc[2];
	int mainOfs,commentOfs,exitOfs,extraRAMOfs;
	int stubType;
	int exportCount,exportOfs[MAX_EXPORTS];
	LibRefInfo ROM,RAM,lib[MAX_LIBS],special;
	int libCount;	
	int AddLib(char *name);
	unsigned int	version;
   int restoreScreen, callExit, readOnly;
   SymRef DSymbol[MAX_SYMBOL];
   int DSymCount;
   int Debug;
   int Offset;
   SymRef Symbol[MAX_SYMBOL];
   int SymCount;
public:
	int output89,output92,output92Plus,outputV200,outputTitanium;
	Object(char *name);
	virtual ~Object();
	virtual int Read(char *fn); // Read information from file
	virtual int Write();        // Write object file with correct format
	void CopyInfo(Object *obj); // Copy information from another object
};

int inline ReadDWord(FILE *fp)
{
	int v=fgetc(fp)<<24;
	v|=fgetc(fp)<<16;
	v|=fgetc(fp)<<8;
	v|=fgetc(fp);
	return v;
}

void  inline removeExt(const char *source, char *dest)
{
  int i = 0;
  while (source[i]!=0 & source[i]!='.')
      dest[i++] = source[i];
  dest[i] = 0;
}

#endif
