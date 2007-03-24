#ifndef _PO_H
#define _PO_H

#include <gettext-po.h>
#include "message.h"

extern void textmode_xerror (int severity,
                             po_message_t message,
                             const char *filename, size_t lineno, size_t column,                             int multiline_p, const char *message_text);
extern void textmode_xerror2 (int severity,
                              po_message_t message1,
                              const char *filename1, size_t lineno1, size_t column1,
                              int multiline_p1, const char *message_text1,
                              po_message_t message2,
                              const char *filename2, size_t lineno2, size_t column2,
                              int multiline_p2, const char *message_text2);
struct po_xerror_handler default_xerror_handler={textmode_xerror,
                                                 textmode_xerror2};

struct Po {
//    po_file_t po_file;
    message_list_ty *mlp;
};

typedef struct Po Locale__Po4a__Po;
typedef struct Po * Locale_Po4a_Po;

#endif
