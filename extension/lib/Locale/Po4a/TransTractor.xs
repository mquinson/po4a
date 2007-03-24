#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//#include "ppport.h"

//#include "const-c.inc"

char *TransTractor_write(SV* self, char *filename)
{
    FILE *out = NULL;

    if (NULL == filename)
        croak("Can't write to a file without filename");

    if (0 == strcmp(filename, "-"))
    {
        out = stdout;
    }
    else
    {
        int count;
        I32 i = 0;
        dSP;
        ENTER;

        out = fopen(filename, "w");
        if (NULL == out)
        {
            perror("fopen");
            croak("Can't create %s.\n", filename);
        }

        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;
        count = call_method("docheader", G_ARRAY);

        SPAGAIN;

        for (i=0; i< count; i++)
        {
            fputs(POPp, out);
        }

        HV *hv = SvRV(self);
//        if (hv_exists(hv, "TT", 2))
//        {
            SV **psv = hv_fetch(hv, "TT", 2,0);
            if (NULL != psv)
            {
                SV *sv = *psv;
//                if (hv_exists(SvRV(sv), "doc_out", 7))
//                {
                    psv = hv_fetch(SvRV(sv), "doc_out", 7, 0);
                    sv = *psv;
                    AV *av = SvRV(sv);
                    for (i = 0; i < av_len(av); i++)
                    {
                        fputs(SvRV(*av_fetch(av, i, 0)), out);
                    }
//                }
//                else
//                {
//                    croak("No doc_out.\n");
//                }
            }
//        }
//        else
//        {
//            croak("No TT.\n");
//        }

fclose(out);
        PUTBACK;
        LEAVE;
    }
}

MODULE = Locale::Po4a::TransTractor	PACKAGE = Locale::Po4a::TransTractor	PREFIX = TransTractor_

void TransTractor_write(self, filename)
	SV *		self
	char *		filename

