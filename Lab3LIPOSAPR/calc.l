%{
/*
This file is part of Reverse Notation Calc.

    Reverse Notation Calc is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

*/

#include "mystack.h"
int int_value;

typedef enum {
    LexNumber=1001,
    LexPlus,
    LexMinus,
    LexDiv,
    LexMult,
    LexDiapStart,
    LexDiapEnd,
    LexDiapDelim,
    LexDiapMultPre,
    LexDiapMultPost,
    LexNumberInDiap,
    LexComma,
    LexEnd,
    LexUnknown,
} LexType;

my_stack stack;

int diap_opened;
int delim_parsed;
int comma_parsed;
int num_count;
int end_file;

void clean_stack_and_flags();
void clean_flags();

%}

%s SKIPERROR

digit     [0-9]
number    {digit}+
delimiter \.\.\.

%%

{number}	{
		  int_value=atoi(yytext);
		  fprintf(stderr, "found %d\n", int_value);
		  return LexNumber; }
{delimiter} {
          fprintf(stderr, "...\n");  
          return LexDiapDelim; }
\[           {
          fprintf(stderr, "[\n");  
          return LexDiapStart;}
,           {
          fprintf(stderr, ",\n");  
          return LexComma;}
\]           {
          fprintf(stderr, "]\n");  
          return LexDiapEnd;}
\*nd        {
          fprintf(stderr, "diap * pre\n");  
          return LexDiapMultPre;}
\*dn        {
          fprintf(stderr, "diap * post\n");  
          return LexDiapMultPost;}
\?d         {
          fprintf(stderr, "is number in diap\n");  
          return LexNumberInDiap;}
\+		{
		  fprintf(stderr, "plus\n");
		  return LexPlus; }
\-		{
		  fprintf(stderr, "minus\n");
		  return LexMinus; }
\/		{
		  fprintf(stderr, "div\n");
		  return LexDiv; }
\*		{
		  fprintf(stderr, "mult\n");
		  return LexMult; }
^[ \t]*\n	{
		  fprintf(stderr, "empty line\n");
		}
\n		{
		  fprintf(stderr, "CR\n");
		  return LexEnd; }
[ \t]		{ }
.		{ return LexUnknown; }

<SKIPERROR>[^\n]* {}
%%

int process_command(int token)
{
    fprintf(stderr, "token: %d\n", token);

    switch (token) {
    case LexDiapStart: {
        // Diap must not be opened
        if (diap_opened == 1 || delim_parsed == 1 || comma_parsed == 1 || num_count > 0) {
            return -1;
        }
        diap_opened = 1;
        num_count = 0;
        
        break;}
        
    case LexNumber: {
        if (diap_opened == 1) {
            // First number in diap;
            // Second number in diap,
            // he must be after delimiter
            // or after comma;
            // Third number in diap,
            // he must be after parsed comma and parsed delimiter.
            // Numbers count in diap must be maximum 3.
            if ((num_count == 0)
                || (num_count == 1 && delim_parsed == 1)
                || (num_count == 1 && comma_parsed == 1)
                || (num_count == 2 && comma_parsed == 1 && delim_parsed == 1)
            ) {
                my_stack_push(&stack, int_value);
                if (my_stack_is_full(&stack)) {
                    return -1;
                }
                num_count++;
            } else {
                return -1;
            }
            if (num_count > 3) {
                return -1;
            }
        } else {
            my_stack_push(&stack, int_value);
            if (my_stack_is_full(&stack)) {
                return -1;
            }
        }
        break; }
        
    case LexComma: {
        // Comma must not be parsed twice in diap
        // and diap must be opened
        if (comma_parsed == 1 || delim_parsed == 1 || diap_opened == 0) {
            return -1;
        }
        
        comma_parsed = 1;
        break; }
        
    case LexDiapDelim: {
        // Delimiter must not be parsed twice in diap
        // and diap must be opened
        if (delim_parsed == 1 || diap_opened == 0) {
            return -1;
        }
        if (num_count == 1) {
            delim_parsed = 1;
            // Default diap step is 1
            my_stack_push(&stack, 1);
        }
        else if ((num_count == 2 && comma_parsed == 1)) {
            delim_parsed = 1;
        } else {
            return -1;
        }
        break;}
        
    case LexDiapEnd: {
        // Diap must be opened
        if (diap_opened == 0) {
            return -1;
        }
        if ((num_count == 2 && delim_parsed == 1)
            || (num_count == 3 && delim_parsed == 1 && comma_parsed == 1)
        ) {
            clean_flags();
        } else {
            return -1;
        }
        break;}
        
    case LexDiapMultPost: {
        if (diap_opened == 1 
            || comma_parsed == 1 
            || delim_parsed == 1
            || my_stack_count < 4 
            || my_stack_is_full(&stack)
        ) {
            return -1;
        }
        
        int mult = my_stack_pull(&stack);
        int end = my_stack_pull(&stack);
        int step = my_stack_pull(&stack);
        int start = my_stack_pull(&stack);
        
        // Mult must not equal to 0       
        if (mult != 0) {
            start *= mult;
            end *= mult;
        }
        
        my_stack_push(&stack, end);
        my_stack_push(&stack, step);
        my_stack_push(&stack, start);
        
        break; }
        
    case LexDiapMultPre: {
        if (diap_opened == 1 
            || comma_parsed == 1 
            || delim_parsed == 1
            || my_stack_count < 4 
            || my_stack_is_full(&stack)
        ) {
            return -1;
        }
        
        int end = my_stack_pull(&stack);
        int step = my_stack_pull(&stack);
        int start = my_stack_pull(&stack);
        int mult = my_stack_pull(&stack);
        
        // Mult must not equal to 0
        if (mult != 0) {
            start *= mult;
            end *= mult;
        }
        
        my_stack_push(&stack, end);
        my_stack_push(&stack, step);
        my_stack_push(&stack, start);
    
        break; }
        
    case LexNumberInDiap: {
        if (diap_opened == 1 
            || comma_parsed == 1 
            || delim_parsed == 1
            || my_stack_count < 4 
            || my_stack_is_full(&stack)
        ) {
            return -1;
        }
        
        int number = my_stack_pull(&stack);
        int stop = my_stack_get_deep(&stack, 1);
        int step = my_stack_get_deep(&stack, 2);
        int start = my_stack_get_deep(&stack, 3);
        
        int state = 0;
        
        if (start == stop && step == 0 && number == start) {
            state = 1;
        } else if (start != stop && step == 0) {
            state = 0;
        }
        
        for (int i = start; i < stop; i += step) {
            if (i == number) {
                state = 1;
                break;
            } else {
                continue;
            }
        }
        
        my_stack_push(&stack, state);
        
        break; }
        
    case LexPlus: {
        // Diap must be opened
        if (diap_opened == 1) {
            return -1;
        }
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, a+b);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexMinus: {
        // Diap must be opened
        if (diap_opened == 1) {
            return -1;
        }
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, b-a);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexDiv: {
        // Diap must be opened
        if (diap_opened == 1) {
            return -1;
        }
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, b/a);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexMult: {
        // Diap must be opened
        if (diap_opened == 1) {
            return -1;
        }
        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int a=my_stack_pull(&stack);

        if (my_stack_is_empty(&stack)) {
            return -1;
        }
        int b=my_stack_pull(&stack);

        my_stack_push(&stack, b*a);
        if (my_stack_is_full(&stack)) {
            return -1;
        }
        break;}
    case LexEnd:
    case 0:
        return 0;
    case LexUnknown:
        return -1;

    }
    return 1;
}

int calc_line()
{
    int token = yylex();
    if (token == 0) {
        return 1;
    }

    while (1) {
        int cmd_res = process_command(token);
        if (cmd_res == 0) {
            break;
        }
        else if (cmd_res == -1) {
            clean_stack_and_flags();
            fprintf(stderr, "Syntax error\n");
            return 0;
        }
        token = yylex();
    }

    if (my_stack_is_empty(&stack)) {
        fprintf(stderr, "Stack is empty but required value\n");
        return 0;
    }
    
    if (my_stack_count(&stack) == 4) {
        int result = my_stack_pull(&stack);
        fprintf(yyout, "%d ", result);
    }
        
    if (my_stack_count(&stack) == 3) {
        fprintf(yyout, "range(");
        for (int i = 0; i < 3; i++) {
            int result = my_stack_pull(&stack);
            fprintf(yyout, "%d", result);
            
            if (i != 2) {
                fprintf(yyout, ", ");
            }
        }
        fprintf(yyout, ") ");
    } else {
        for (int i = 0; i < my_stack_count(&stack); i++) {
            int result = my_stack_pull(&stack);
            fprintf(yyout, "%d ", result);
        }
    }
    
    clean_stack_and_flags();

    return 1;
}

void calc()
{
    while (!end_file) {
        fprintf(stderr, "parse line\n");
        if (calc_line() == 0) {
            printf("FAIL\n");
            BEGIN(SKIPERROR);
            yylex();
            BEGIN(INITIAL);
        }
        else {
            printf("OK\n");
        }
        fprintf(stderr, "line parsed\n");
    }
}

void clean_flags()
{
    diap_opened = 0;
    comma_parsed = 0;
    delim_parsed = 0;
    num_count = 0;
}

void clean_stack_and_flags()
{
    clean_flags();
    my_stack_clean(&stack);
}

int main(void)
{
    my_stack_init(&stack, 100);
    end_file = 0;
    clean_stack_and_flags();
    
    calc();

    my_stack_done(&stack);
    return 0;
}

int yywrap(void)
{
    end_file = 1;
    return 1;
}
