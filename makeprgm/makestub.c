#include <stdio.h>

unsigned long ReadDWord(FILE *fp)
{
        unsigned long val;
        val=fgetc(fp)<<24;
        val|=fgetc(fp)<<16;
        val|=fgetc(fp)<<8;
        val|=fgetc(fp);
        return val;
}

void main()
{
        FILE *fp,*out;
        int len,i,l;

        fp=fopen("progstub.o","rb");
        out=fopen("progstub.h","w");
        fseek(fp,0x18,SEEK_SET);
        len=ReadDWord(fp)<<2;
        fprintf(out,"int progStubLen=%d;\n",len);
        fprintf(out,"unsigned char progStub[]={\n    ");
        for (i=0,l=0;i<len;i++)
        {
                fprintf(out,"0x%2.2X",fgetc(fp));
                if ((i+1)<len) fprintf(out,",");
                l++; if (l>12) { fprintf(out,"\n    "); l=0; }
        }
        fprintf(out,"};\n");
        fclose(fp);
        fclose(out);
}

