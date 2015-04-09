/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

#define DEBUH(x) std::cout << (x) << std::endl
#define STR_TOO_LONG (!((string_buf + MAX_STR_CONST - 1) > string_buf_ptr))

unsigned comment_depth = 0;
unsigned string_len = 0;
int string_has_null = 0;
int string_too_long = 0;
%}

/*
 * Define names for regular expressions here.
 */

/* Integers, Identifiers, and Special Notation */

DIGIT				[0-9]
INTEGER			{DIGIT}+

ALNUM				[A-Za-z0-9_]
LOWER				[a-z]
UPPER				[A-Z]
OBJECTID		{LOWER}{ALNUM}*
TYPEID			{UPPER}{ALNUM}*

/* Strings  */

NEWLINE					\n
WHITECHAR				[ \f\r\t\v]
STRING					\"[^\"\0]*\"
UNTERM_STRING		\"[^\"]*
STRING_TERM			\"


/* Keywords */
CLASS				(?i:class)
ELSE				(?i:else)
FI					(?i:fi)
IF					(?i:if)
IN					(?i:in)
INHERITS		(?i:inherits)
LET					(?i:let)
LOOP				(?i:loop)
POOL				(?i:pool)
THEN				(?i:then)
WHILE				(?i:while)
CASE				(?i:case)
ESAC				(?i:esac)
OF					(?i:of)
NEW					(?i:new)
ISVOID			(?i:isvoid)
NOT					(?i:not)
BOOL_TRUE		(t(?i:rue))
BOOL_FALSE	(f(?i:alse))

/* Operators */
LE					<= 
DARROW			=>
ASSIGN			<-

BRAKETS_AND_SO		[\{\}\(\)\;\:\.\,\=\+\-\<\~\*\/\@]


ONE_LINE_COMMENT	(--).*
OPEN_COMMENT			(\(\*)
CLOSE_COMMENT			(\*\))

%x comment
%x string
%%

 /*
  *  Nested comments
  */

{ONE_LINE_COMMENT}				{ }
{CLOSE_COMMENT}						{
														cool_yylval.error_msg = strdup("Unmatched *)");
														return(ERROR);
													}
{OPEN_COMMENT}						{ BEGIN(comment); ++comment_depth; }
<comment><<EOF>>					{
														cool_yylval.error_msg = strdup("EOF in comment");
														comment_depth = 0;
														BEGIN(INITIAL);
														return(ERROR);
													}
<comment>{OPEN_COMMENT} 	{ ++comment_depth; }
<comment>{CLOSE_COMMENT}	{ if (--comment_depth == 0) BEGIN(INITIAL); }
<comment>{NEWLINE}				{ curr_lineno++; }
<comment>.								{ }

{STRING_TERM}							{
														string_has_null = 0;
														string_too_long = 0;
														BEGIN(string);
														string_buf_ptr = string_buf;
													}
<string>{STRING_TERM}			{
														BEGIN(INITIAL);
														if (string_has_null != 0)
														{
															cool_yylval.error_msg = strdup("String contains null character");
	                            	return(ERROR);
														}
														else if (string_too_long != 0)
														{
															cool_yylval.error_msg = strdup("String constant too long");
                              	return(ERROR);
														}
														*string_buf_ptr = '\0';
										        cool_yylval.symbol = stringtable.add_string(string_buf);
							  			      return (STR_CONST);
													}
<string><<EOF>>						{
														cool_yylval.error_msg = strdup("EOF in string constant");
                            BEGIN(INITIAL);
                            return(ERROR);
													}
<string>\\{NEWLINE}				{
														curr_lineno++;
														if (STR_TOO_LONG) string_too_long = 1;
														else *string_buf_ptr++ = yytext[1];
													}
<string>{NEWLINE}					{
														curr_lineno++;
								    				BEGIN(INITIAL);
														cool_yylval.error_msg = strdup("Unterminated string constant");
														return(ERROR);
													}
<string>\\\"							{
														if (STR_TOO_LONG) string_too_long = 1;
														else *string_buf_ptr++ = yytext[1];
													}
<string>\\[ntvbf]					{
														if (STR_TOO_LONG) string_too_long = 1;
														else
															switch(yytext[1])
															{
																case 'n': *string_buf_ptr = '\n'; break;
																//case 'r': *string_buf_ptr = '\r'; break;
																case 't': *string_buf_ptr = '\t'; break;
																case 'v': *string_buf_ptr = '\v'; break;
																case 'b': *string_buf_ptr = '\b'; break;
																case 'f': *string_buf_ptr = '\f'; break;
															}
                              ++string_buf_ptr;
													}
<string>\\\0							{
														string_has_null = 1;
													}
<string>\\.								{
														if (STR_TOO_LONG) string_too_long = 1;
														else *string_buf_ptr++ = yytext[1];
													}
<string>.									{
														if (STR_TOO_LONG) string_too_long = 1;
														else
														{
															*string_buf_ptr++ = yytext[0];
															if (yytext[0] == '\0')
																string_has_null = 1;
														}
													}

{INTEGER}						{
											cool_yylval.symbol = inttable.add_string(yytext);
											return (INT_CONST);
										}
{DARROW}						{ return (DARROW); }
{ASSIGN}						{ return (ASSIGN); }
{LE}								{ return (LE); }

 /* Keywords */
{CLASS}							{ return (CLASS); }
{ELSE}							{ return (ELSE); }
{FI}								{ return (FI); }
{IF}								{ return (IF); }
{IN}								{ return (IN); }
{INHERITS}					{ return (INHERITS); }
{LET}								{ return (LET); }
{LOOP}							{ return (LOOP); }
{POOL}							{ return (POOL); }
{THEN}							{ return (THEN); }
{WHILE}							{ return (WHILE); }
{CASE}							{ return (CASE); }
{ESAC}							{ return (ESAC); }
{OF}								{ return (OF); }
{NEW}								{ return (NEW); }
{ISVOID}						{ return (ISVOID); }
{NOT}								{ return (NOT); }

{BOOL_TRUE}					{ 
											cool_yylval.boolean = true;
											return (BOOL_CONST);
										}
{BOOL_FALSE}				{ 
											cool_yylval.boolean = false;
											return (BOOL_CONST);
										}

{BRAKETS_AND_SO}		{ return (yytext[0]); }

{OBJECTID}					{
											cool_yylval.symbol = idtable.add_string(yytext);
                      	return (OBJECTID);
										}
{TYPEID}						{
											cool_yylval.symbol = idtable.add_string(yytext);
                      	return (TYPEID);
										}
{NEWLINE}      			{ curr_lineno++; }
{WHITECHAR}+				{ }

.										{
											cool_yylval.error_msg = strdup(yytext);
											return(ERROR);
										}
