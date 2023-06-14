#ifndef __PROG_H__
#define __PROG_H__

#include "object.h"

#define MAX_PROG_SIZE 65536

class Program: public Object
{
protected:
	int size;
	char data[MAX_PROG_SIZE];
	
	void ResetData() { size=0; }
	void WriteByte(int n) { data[size++]=n; }
	void WriteWord(int n) { WriteByte((n>>8)&0xff); WriteByte(n&0xff); }
	void WriteDWord(int n) { WriteWord((n>>16)&0xffff); WriteWord(n&0xffff); }
	int ReadByte(int ofs) { return data[ofs]; }
	int ReadWord(int ofs) { return ((data[ofs]&0xff)<<8)|(data[ofs+1]&0xff); }
	int ReadDWord(int ofs) { return ((data[ofs]&0xff)<<24)|((data[ofs+1]&0xff)<<16)|((data[ofs+2]&0xff)<<8)|(data[ofs+3]&0xff); }
public:
	Program(char *fn): Object(fn) {}
	virtual ~Program() {}
};

class PlusShellProgram: public Program
{
	int calc;
	void WriteData();
	void GetOffsets(int &bssTableOfs,int &exportTableOfs,int &stubCodeOfs,int &stubLen);
public:
	PlusShellProgram(char *fn,int _calc);
	~PlusShellProgram();
	//virtual int Read();
	virtual int Write();
};


void inline AddWord(char *dest,int n)
{
	int v=((dest[0]&0xff)<<8)|(dest[1]&0xff);
	v+=n;
	dest[0]=(v>>8)&0xff;
	dest[1]=v&0xff;
}

void inline AddDWord(char *dest,int n)
{
	int v=((dest[0]&0xff)<<24)|((dest[1]&0xff)<<16)|((dest[2]&0xff)<<8)|
		(dest[3]&0xff);
	v+=n;
	dest[0]=(v>>24)&0xff;
	dest[1]=(v>>16)&0xff;
	dest[2]=(v>>8)&0xff;
	dest[3]=v&0xff;
}

#endif
