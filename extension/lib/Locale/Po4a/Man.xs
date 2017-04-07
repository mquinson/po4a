#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//#include "ppport.h"

//#include "const-c.inc"


static char *current_font = NULL;
static char *previous_font = NULL;
static char *regular_font = NULL;
void set_font(char *font)
{
//    fprintf(stderr, "   set_font(%s)\n", font);
    char *saved_previous;
    if (current_font == NULL)
        current_font = strdup("R");
    if (previous_font == NULL)
        previous_font = strdup("R");
    saved_previous = previous_font;
    previous_font = strdup(current_font);

    if (font[0] == '\0')
    {
        free(current_font);
        current_font = strdup("R");
    }
    else if (0 == strcmp(font, "P") ||
             0 == strcmp(font, "[]") ||
             0 == strcmp(font, "[P]"))
    {
        free(current_font);
        current_font = strdup(saved_previous);
    }
    else if (strlen(font) == 1)
    {
        free(current_font);
        current_font = strdup(font);
    }
    else if (strlen(font) == 2)
    {
        free(current_font);
        current_font = malloc(4);
        current_font[0] = '(';
        current_font[1] = font[0];
        current_font[2] = font[1];
        current_font[3] = '\0';
    }
    else
    {
        fprintf(stderr, "not implemented");
    }
//        fprintf(stderr, "my set_font => r:'%s', p:'%s', c:'%s'\n", regular_font, previous_font, current_font);
    free(saved_previous);
//    fprintf(stderr, "   end set_font()\n");
}
void set_regular(char *font)
{
//    fprintf(stderr, "   set_regular(%s)\n", font);
    set_font(font);
    free(regular_font);
    regular_font = strdup(current_font);
//    fprintf(stderr, "   end set_regular()\n");
}

char *do_fonts(char *string, char *ref)
{
//    fprintf(stderr, "do_fonts(%s)\n", string);
    char *tmp;
    char *pc = string;
    char *pc_tmp;
    char previous[10];
    char current[10];
    char new[10];
    char last[10];
    if (current_font == NULL)
        current_font = strdup("R");
    if (previous_font == NULL)
        previous_font = strdup("R");
    if (regular_font == NULL)
        regular_font = strdup("R");
    last[0] = '\0';
    Newx(tmp, strlen(string)*2, char);
    pc_tmp = tmp;
    strcpy(previous, previous_font);
    strcpy(current, current_font);
    if (strcmp(regular_font, current_font) != 0)
        strcpy(new, current_font);
    else
        new[0] = '\0';

    while (*pc != '\0')
    {
        if (pc[0] == 'E' && pc[1] == '<' && pc[2] == '.')
        {
            if (new[0] != '\0')
            {
                char *pc_new = new;
                while (*pc_new != '\0')
                    *pc_tmp++ = *pc_new++;
                *pc_tmp++ = '<';
                new[0] = '\0';
            }

            pc_tmp[0] = pc[0];
            pc_tmp[1] = pc[1];
            pc_tmp[2] = pc[2];
            pc_tmp+=3;
            pc+=3;

            int count = 0;
            while (*pc !='>' || count != 0)
            {
                if (*pc == '<')
                    count++;
                if (*pc == '>')
                    count--;
                *pc_tmp++ = *pc++;
            }
        }
        else if (pc[0] == '\\' && pc[1] == 'f')
        {
            /* We found a font modifier */
            char f[10];
            pc += 2;

            /* Extract the font */
            if (*pc == '[')
            {
                char *pc_f = f;
                pc++;
                while(*pc != ']' && (pc_f - f < 10))
                    *pc_f++ = *pc++;
                if (*pc != ']')
                    die("font too long: '%s%s'\n", f, pc);
                pc++;
                *pc_f = '\0';
            }
            else if (*pc == '(')
            {
                pc++;
                f[0] = *pc++;
                f[1] = *pc++;
                f[2] = '\0';
            }
            else
            {
                f[0] = *pc++;
                f[1] = '\0';
            }
//            fprintf(stderr, "found font: '%s'\n", f);

            /* Canonize the font */
            if (f[1] == '\0')
            {
                if (f[0] == '\0' || f[0] == 'P')
                {
                    strcpy(f,previous);
                }
                else if (f[0] == '1')
                    f[0] = 'R';
                else if (f[0] == '2')
                    f[0] = 'I';
                else if (f[0] == '3')
                    f[0] = 'B';
                else if (f[0] == '3')
                {
                    f[0] = 'B';
                    f[1] = 'I';
                    f[2] = '\0';
                }
            }

//            fprintf(stderr, "found font: '%s'\n", f);
            /*
            if ((pc[0] == 'P' && pc++) ||
                (pc[0] == '[' && pc[1] == ']' && (pc = pc + 2)) ||
                (pc[0] == '[' && pc[1] == 'P' && pc[2] == ']' && (pc = pc +3)))
            {
                if (0 == strcmp(previous, regular_font))
                {
                    strcpy(previous, current);
                    new[0] = '>';
                    new[1] = '\0';
                    strcpy(current, regular_font);
                }
                else
                {
                    strcpy(new, previous);
                    strcpy(previous, current);
                    strcpy(current, new);
                }
            }
            else */

            if (0 == strcmp(f, regular_font))
            {
//                printf("     regular\n");
                strcpy(previous, current);
//                if (0 != strcmp(current, regular_font))
//                {
                    new[0] = '>';
                    new[1] = '\0';
                    strcpy(current, regular_font);
//                }
            }
            else// if (pc[1] pc[0] == 'B' || pc[0] == 'I' || pc[0] == 'R')
            {
                strcpy(previous, current);
                strcpy(current, f);
                strcpy(new, current);
            }/*
            else
            {
                fprintf(stderr, "unrecognized font: '%s'\n", pc);
            }*/
        }
        else
        {
//            printf("%p %p\n", pc_tmp, pc);
            if (new[0] != '\0')
            {
                char *pc_new = new;
                if (strcmp(new, last) != 0 && last[0] != '\0')
                    *pc_tmp++ = '>';
                if (new[0] != '>')
                {
                    if (strcmp(new, last) != 0)
                    {
                    while (*pc_new != '\0')
                        *pc_tmp++ = *pc_new++;
                    *pc_tmp++ = '<';
                    strcpy(last, new);
                    }
                }
                else
                    last[0] = '\0';
                new[0] = '\0';
            }

            *pc_tmp++ = *pc++;
        }
    }
    if (last[0] != '\0')
    {
        if (pc_tmp[-1] == '\n')
        {
            if (pc_tmp[-2] == '<')
            {
                if (pc_tmp[-3] == 'B' || pc_tmp[-3] == 'I' || pc_tmp[-3] == 'R')
                {
                    pc_tmp -=3;
                }
                else if (pc_tmp[-3] == 'W' && pc_tmp[-4] == 'C')
                {
                    pc_tmp -=4;
                }
                else
                {
                    pc_tmp[-1] = '>';
                }
            }
            else
            {
                pc_tmp[-1] = '>';
            }
            *pc_tmp++ = '\n';
        }
        else
            *pc_tmp++ = '>';
    }
    *pc_tmp = '\0';
    strcpy(previous_font, previous);
    strcpy(current_font, current);
//    fprintf(stderr, "end do_fonts: '%s'\n", tmp);
    return tmp;
}

MODULE = Locale::Po4a::Man		PACKAGE = Locale::Po4a::Man

char *
do_fonts(string, ref)
	char *		string
	char *		ref

void set_regular(font)
	char *		font

void set_font(font)
	char *		font


