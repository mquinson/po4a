#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//#include "ppport.h"

//#include "const-c.inc"

#include "Po.h"

Locale_Po4a_Po Po_new(char *class)
{
    struct Po *ret;
    printf("Locale::Po4a::Po::new()\n");

    ret = (struct Po *)safemalloc(sizeof(struct Po));
//    ret->po_file = NULL;
    ret->mlp = NULL;

    return ret;
}

void Po_DESTROY(Locale_Po4a_Po self)
{
    printf("Locale::Po4a::Po::DESTROY\n");
//    if (NULL != self->po_file)
//        po_file_free(self->po_file);
    if (NULL != self->mlp)
        message_list_free(self->mlp, 0);
    safefree(self);
}

void Po_read(Locale_Po4a_Po self, char *filename)
{
    printf("Locale::Po4a::Po::read(%s)\n", filename);
//    self->po_file = po_file_read(filename, &default_xerror_handler);
    po_file_t po_file = po_file_read(filename, &default_xerror_handler);
    self->mlp = message_list_alloc (true);
#if 0
    FILE * fp = fopen(filename, "r");
    extract_po(fp,
               filename, /* real file name */
               filename, /* logical file name */
               NULL,     /* not applicable for PO files */
               self->mdlp);
    if (fp != stdin)
        fclose (fp);
#endif
    if (po_file == NULL)
        croak("Can't open the PO file %s", filename);
    else
    {
        po_message_iterator_t iterator = po_message_iterator (po_file, NULL);
        for (;;)
        {
            po_message_t message = po_next_message (iterator);
            if (message == NULL)
                break;
            else
                message_list_append (self->mlp, (message_ty *)message);
        }
        po_message_iterator_free (iterator);
    }
// No free, otherwise, the messages are freed.
//    po_file_free (po_file);
}

int debug(char *key, int klen)
{
    int ret = 0;

    HV* debug = get_hv("debug", FALSE);
    if (NULL != debug)
    {
        SV **svp = hv_fetch(debug, key, klen, FALSE);
        if (NULL != svp)
        {
            SV *sv = *svp;
            if (0 != SvIV(sv))
                ret = 1;
        }
    }

    return ret;
}

#define KEY(x) x, sizeof(x)-1

char *Po_escape_text(char *text)
{
    char *pc = text;
    unsigned int len = 0;
//    int need_escape = 0;
    char *ret;
    char *pc_ret;
    int debug_escape = debug(KEY("escape"));
    if (debug_escape)
        fprintf(stderr, "\nescape [%s]====", text);
    while (*pc != '\0')
    {
        switch (*pc)
        {
            case '\\':
            case '\"':
            case '\n':
            case '\t':
                len += 2;
//                need_escape = 1;
                break;
            default:
                len++;
        }
        pc++;
    }
//    if (0 == need_escape)
//        return text;

    Newx(ret, len+1, char);
    pc_ret = ret;
    pc = text;
    while (*pc != '\0')
    {
        switch (*pc)
        {
            case '\\':
                *pc_ret++ = '\\';
                *pc_ret++ = '\\';
                break;
            case '"':
                *pc_ret++ = '\\';
                *pc_ret++ = '"';
                break;
            case '\n':
                *pc_ret++ = '\\';
                *pc_ret++ = 'n';
                break;
            case '\t':
                *pc_ret++ = '\\';
                *pc_ret++ = 't';
                break;
            default:
                *pc_ret++ = *pc;
        }
        pc++;
    }
    *pc_ret = '\0';
    if (debug_escape)
        fprintf(stderr, ">%s<\n", ret);
    return ret;
}

char *Po_unescape_text(char *text)
{
    char *ret;
    char *pc = text;
    char *pc_ret;
    int debug_escape = debug(KEY("escape"));
    if (debug_escape)
        fprintf(stderr, "\nunescape [%s]====", text);
    Newx(ret, strlen(text)+1, char);
    pc_ret = ret;
    while (*pc != '\0')
    {
        if (*pc != '\\')
            *pc_ret++ = *pc++;
        else if (*pc == '\n')
            continue;
        else switch (pc[1])
        {
            case '\0':
                *pc_ret++ = *++pc;
                break;
            case 'n':
                *pc_ret++ = '\n';
                pc += 2;
                break;
            case 't':
                *pc_ret++ = '\t';
                pc += 2;
                break;
            case '"':
                *pc_ret++ = '"';
                pc += 2;
                break;
            case '\\':
                *pc_ret++ = '\\';
                pc += 2;
                break;
            default:
                printf("unescape sequence ?: '%c'\n", pc[1]);
        }
    }
    *pc_ret = '\0';

    if (debug_escape)
        fprintf(stderr, ">%s<\n", ret);
    return ret;
}

char *Po_unquote_text(char *text)
{
    char *ret;
    char *pc = text;
    char *pc_ret;
    int debug_quote = debug(KEY("quote"));
    if (debug_quote)
        fprintf(stderr, "\nunquote [%s]====\n", text);
    Newx(ret, strlen(text)+1, char);
    pc_ret = ret;
    if (pc[0] == '"' && pc[1] == '"' && pc[2] == '\n')
	pc += 3;
    if (pc[0] == '"')
	pc++;
    while (*pc != '\0')
    {
	if (pc[0] == '"' && pc[1] == '\0')
	    pc++;
	else if (pc[0] == '"' && pc[1] == '\n' && pc[2] == '"')
	    pc += 3;
	else if (pc[0] == '\\' && pc[1] == 'n' && pc[2] == '\n')
	{
	    *pc_ret++ = '\\';
	    *pc_ret++ = 'n';
	    pc += 3;
	}
	else
	{
	    *pc_ret++ = *pc++;
	}
    }
    *pc_ret = '\0';

    if (debug_quote)
        fprintf(stderr, ">%s<\n", ret);
    return ret;
}

char *Po_canonize(char *text)
{
    char *ret;
    char *pc = text;
    char *pc_ret;
    int len = strlen(text)+1;
    int debug_canonize = debug(KEY("canonize"));
    if (debug_canonize)
        fprintf(stderr, "\ncanonize [%s]====\n", text);
while(*pc != '\0')
{
    if (*pc == '.' || *pc == '(')
        len++;
    pc++;
}
pc = text;
Newx(ret, len, char);
pc_ret = ret;
    while (*pc == ' ')
        pc++;
/*
    if (*pc == '\t')
    {
        *pc_ret++ = ' ';
        *pc_ret++ = ' ';
        while (*pc == ' ' || *pc == '\t')
            pc++;
    }
*/
    while (*pc != '\0')
    {
        if (pc_ret != ret)
        {
            /* already one char in ret */
            if (pc[0] == '\n')
            {
                if (pc_ret[-1] == ')' || pc_ret[-1] == '.')
                {
                    *pc_ret++ = ' ';
                    *pc_ret++ = ' ';
                }
                else if (pc_ret[-1] != ' ' || pc_ret[-2] == ')' || pc_ret[-2] == '.')
                {
                    *pc_ret++ = ' ';
                }
                pc++;
            }
            else if (pc[0] == ' '/* || pc[0] == '\t'*/)
            {
                if (pc_ret[-1] == ' ')
                {
                    if (pc_ret >= ret+2 && (pc_ret[-2] == ')' || pc_ret[-2] == '.'))
                    {
                        *pc_ret++ = ' ';
                    }
                }
                else
                {
                    *pc_ret++ = ' ';
                }
                pc++;
            }
            else
                *pc_ret++ = *pc++;
        }
        else
            *pc_ret++ = *pc++;
    }

    do
    {
        *pc_ret-- = '\0';
    }
    while (*pc_ret == ' ');

    if (debug_canonize)
        fprintf(stderr, ">%s<\n", ret);
    return ret;
}

/*
char *quote_text(char *text)
{
    char *ret;
    int debug_escape = debug(KEY("escape"));
    if (debug_escape)
        fprintf(stderr, "\nquote [%s]====", text);

    if (debug_escape)
        fprintf(stderr, ">%s<\n", ret);
    return ret;
}
*/
char *Po_get_charset(SV* self)
{
    char *ret;
    char *header;
    STRLEN headerlen;
    SV* self_sv;
    SV** psv;
    SV* string;
    STRLEN header_len;
    if(!SvOK(self) || !SvROK(self)) goto error;
    self_sv = SvRV(self);
    if(SvTYPE(self_sv) != SVt_PVHV) goto error;
    psv = hv_fetch((HV *)self_sv, "header", 6, 0);
    if(psv == NULL) goto error;
    string = *psv;
//fprintf(stderr, "get_charset3 %p %s\n", string, SvPV_nolen(string));
    if(!SvPOK(string)) goto error;
//fprintf(stderr, "get_charset4\n");
    header = SvPV(string, headerlen);
    char *charset = strstr(header, "charset=");
    if (NULL == charset)
    {
        fprintf(stderr, "no charset found\n");
        ret = strdup("");
    }
    else
    {
        charset += 8; /* remove "charset=" */
        char *pc = charset;
        while (   pc < header + headerlen
               && *pc != ' '
               && *pc != '\t'
               && *pc != '\n'
               && *pc != '\\')
        {
            pc++;
        }
        Newx(ret, pc - charset+1, char);
        memcpy(ret, charset, pc - charset);
        ret[pc - charset] = '\0';
    }


    return ret;
error:
    croak("can't extract charset.");
}

/*
self new(this, options)
char *timezone()
initialize(self,options)
read(self, filename)
write(self, filename)
write_if_needed(self, filename)
move_po_if_needed(new_po, old_po, backup)
gettextize(this, class)
filter(self, filter)
to_utf8(self)
gettext(self, text, options)
stats_get(self)
stats_clear(self)
push(self, entry)
push_raw(self, entry)
int count_enties(self)
int count_entries_doc(self)
char *msgid(self, num)
char *msgid_doc(self, num)
set_charset(self, charset)
char *quote_text(string)
char *wrap(text)
char *format_comment(comment, c)
*/
MODULE = Locale::Po4a::Po		PACKAGE = Locale::Po4a::Po		PREFIX = Po_

char *
Po_escape_text(text)
	char *		text

char *
Po_unescape_text(text)
	char *		text

char *
Po_get_charset(self)
	SV *		self

char *
Po_unquote_text(text)
	char *		text

char *
Po_canonize(text)
	char *		text

Locale_Po4a_Po
Po_new(class)
	char *		class

void
Po_DESTROY(self)
	Locale_Po4a_Po	self

void
Po_read(self, filename)
	Locale_Po4a_Po	self
	char *		filename

void
Po_push(self, ...)
	Locale_Po4a_Po	self
CODE:
    char *msgid     = NULL;
    char *msgstr    = NULL;
    char *reference = NULL;
    char *comment   = NULL;
    char *automatic = NULL;
    char *flags     = NULL;
    char *type      = NULL;
    int i = items;

    printf("Locale::Po4a::Po::push()\n");

    if ((items % 2) == 0)
        croak("Usage: Locale::Po4a::Po::push(self, k => v, ...)\n");

    for (i=1; i<items; i+=2)
    {
        char *key = SvPV_nolen(ST(i));
        if (strEQ(key, "msgid"))
            msgid     = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "msgstr"))
            msgstr    = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "reference"))
            reference = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "comment"))
            comment   = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "automatic"))
            automatic = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "flags"))
            flags     = SvPV_nolen(ST(i+1));
        else if (strEQ(key, "type"))
            type      = SvPV_nolen(ST(i+1));
        else
            croak("Unknown key found in Locale::Po4a::Po::push: %s\n",
                  SvPV_nolen(ST(i)));
    }
    /* message_list_search, message_list_append, message_alloc */

    message_ty *mp1 = message_list_search(self->mlp, NULL, msgid);
    printf("push search: %p\n", mp1);
    lex_pos_ty pos = { "file", 0 /*line*/};
    message_ty *mp2 = message_alloc(NULL, /* msgctxt */
                                   msgid,
                                   NULL, /* No plural */
                                   msgstr,
                                   strlen (msgstr) + 1,
                                   &pos);

    if (NULL == mp1)
    {
        message_list_append(self->mlp, mp2);
    }
    else
    {
        if (!strEQ(msgstr, mp1->msgstr))
            printf("duplicate: msgid: \"%s\", msgstr: \"%s\"/\"%s\"\n",
                   msgid, msgstr, mp1->msgstr);
    }

