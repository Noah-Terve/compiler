/* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
    Parser for Wampus
*/

%{
open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA PLUS MINUS TIMES DIVIDE ASSIGN
%token NOT EQ NEQ LEQ GEQ AND OR TIMESEQ DIVIDEEQ MODEQ MINUSEQ PLUSEQ
%token RETURN IF ELSE FOR WHILE INT BOOL FLOAT STRING CHAR
%token LBRACK RBRACK LARROW RARROW MOD TEMPLATE
%token LIST SET BREAK CONTINUE STRUCT DOT LTAGS RTAGS LAT RAT
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token <string> SLIT
%token <char> CLIT
%token EOF

%start program
%type <Ast.program> program

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN 
%right PLUSEQ MINUSEQ 
%right TIMESEQ DIVIDEEQ MODEQ
%left OR 
%left AND 
%left EQ NEQ
%left LARROW RARROW LEQ GEQ
%left PLUS MINUS 
%left TIMES DIVIDE MOD 
%right NOT

%%

program:
    decls EOF { List.rev $1 }

decls:
    /* nothing */ { []       }
  | decls p_unit  { $2 :: $1 }

p_unit:
    stmt  { Stmt($1)  }
  | fdecl { Fdecl($1) }
  | sdecl { Sdecl($1) }

fdecl:
    typ ID LPAREN formals_opt RPAREN LBRACE stmt_list RBRACE
      {{ typ = $1; fname = $2; formals = List.rev $4;
         body = List.rev $7; fun_t_list = [];}}
  | TEMPLATE LAT t_list RAT typ ID LPAREN formals_opt RPAREN LBRACE stmt_list RBRACE
      {{ typ = $5; fname = $6; formals = List.rev $8;
         body = List.rev $11; fun_t_list = List.rev $3;}}
sdecl:
    STRUCT ID LBRACE struct_formal_list RBRACE SEMI
      {{ name = $2; sformals = List.rev $4; t_list = [];}}
  | TEMPLATE LAT t_list RAT STRUCT ID LBRACE struct_formal_list RBRACE SEMI
      {{ name = $6; sformals = List.rev $8; t_list = List.rev $3;}}

struct_formal_list:
    typ ID SEMI                    { [($1, $2)]     }
  | struct_formal_list typ ID SEMI { ($2, $3) :: $1 }

t_list:
    ID              { [$1]     }
  | t_list COMMA ID { $3 :: $1 }


formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1, $2)]     }
  | formal_list COMMA typ ID { ($3, $4) :: $1 }

typ:
    ID        { Templated ($1)}
  | INT       { Int           }
  | BOOL      { Bool          }
  | CHAR      { Char          }
  | FLOAT     { Float         }
  | STRING    { String        }
  | group_typ { $1            }

group_typ:
      ID   LAT typ_list RAT   { TStruct ($1, List.rev $3) }
    | SET  LAT ID RAT         { List (Templated($3))      }
    | SET  LAT INT RAT        { List (Int)                }
    | SET  LAT BOOL RAT       { List (Bool)               }
    | SET  LAT CHAR RAT       { List (Char)               }
    | SET  LAT FLOAT RAT      { List (Float)              }
    | SET  LAT STRING RAT     { List (String)             }
    | SET  LAT group_typ RAT  { List ($3)                 }
    | LIST LAT ID RAT         { List (Templated($3))      }
    | LIST LAT INT RAT        { List (Int)                }
    | LIST LAT BOOL RAT       { List (Bool)               }
    | LIST LAT CHAR RAT       { List (Char)               }
    | LIST LAT FLOAT RAT      { List (Float)              }    
    | LIST LAT STRING RAT     { List (String)             }
    | LIST LAT group_typ RAT  { List ($3)                 }

stmt_list:
    stmt           { [$1]     }
  | stmt_list stmt { $2 :: $1 }

stmt:
    SEMI                                    { NullStatement            }
  | expr SEMI                               { Expr $1                  }
  | BREAK SEMI                              { Break                    }
  | CONTINUE SEMI                           { Continue                 }
  | RETURN expr_opt SEMI                    { Return $2                }
  | LBRACE stmt_list RBRACE                 { Block(List.rev $2)       }
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)            }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7)           }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([]))    }
  | FOR LPAREN expr_opt SEMI expr 
    SEMI expr_opt RPAREN stmt               { For($3, $5, $7, $9)      }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1     }

expr:
  // Basic Literals
    LITERAL          { Literal($1)   }
  | FLIT	           { Fliteral($1)  }
  | BLIT             { BoolLit($1)   }
  | SLIT             { StringLit($1) }
  | CLIT             { CharLit($1)   }
  | ID               { Id($1)        }

  // Binary Operators
  | expr EQ     expr { Binop($1, Equal, $3)   }
  | expr OR     expr { Binop($1, Or,    $3)   }
  | expr AND    expr { Binop($1, And,   $3)   }
  | expr MOD    expr { Binop($1, Mod,   $3)   }
  | expr GEQ    expr { Binop($1, Geq,   $3)   }
  | expr NEQ    expr { Binop($1, Neq,   $3)   }
  | expr LEQ    expr { Binop($1, Leq,   $3)   }
  | expr PLUS   expr { Binop($1, Add,   $3)   }
  | expr MINUS  expr { Binop($1, Sub,   $3)   }
  | expr TIMES  expr { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr { Binop($1, Div,   $3)   }
  | expr LARROW expr { Binop($1, Less,  $3)   }
  | expr RARROW expr { Binop($1, Greater, $3) }

  // Assignment Operators
  | ID ASSIGN expr      { Assign($1, $3)                           }
  | ID MODEQ expr       { Assign($1, Binop (Id($1), Mod,       $3))}
  | ID PLUSEQ expr      { Assign($1, Binop (Id($1), Add,       $3))}
  | ID MINUSEQ expr     { Assign($1, Binop (Id($1), Sub,       $3))}
  | ID TIMESEQ expr     { Assign($1, Binop (Id($1), Mult,      $3))}
  | ID DIVIDEEQ expr    { Assign($1, Binop (Id($1), Div,       $3))}

  // Variable Declarations
  | typ ID             { BindDec    ($1, $2)    }
  | typ ID ASSIGN expr { BindAssign ($1, $2, $4)}
  
  // Expression Ordering
  | LPAREN expr RPAREN { $2 }
  
  // Building a list & set
  | LBRACE set_opt RBRACE   { ListExplicit   (List.rev $2)}
  | LBRACK list_opt RBRACK  { ListExplicit  (List.rev $2)}
  | LTAGS struct_list RTAGS { StructExplicit(List.rev $2)}

  // Unary Operators
  | NOT expr             { Unop(Not, $2)}
  | MINUS expr %prec NOT { Unop(Neg, $2)}

  // Function call
  | ID LPAREN args_opt RPAREN { Call($1, $3)}

  // templated expressions and templated function calls
  | struct_expr    { $1 }
  | ID LAT typ_list RAT LPAREN args_opt RPAREN { TemplatedCall       ($1, List.rev $3, $6)     } 

struct_expr:
    // for structs you must have at least one level of access and then 
    // you can continue going to deeper levels after that
    ID struct_opts                  { StructAccess ($1 :: List.rev $2)     }
  | ID struct_opts ASSIGN expr      { StructAssign ($1 :: List.rev $2, $4) }
  | ID struct_opts MODEQ expr       { StructAssign ($1 :: List.rev $2, Binop (StructAccess($1 :: List.rev $2), Mod,       $4))}
  | ID struct_opts PLUSEQ expr      { StructAssign ($1 :: List.rev $2, Binop (StructAccess($1 :: List.rev $2), Add,       $4))}
  | ID struct_opts MINUSEQ expr     { StructAssign ($1 :: List.rev $2, Binop (StructAccess($1 :: List.rev $2), Sub,       $4))}
  | ID struct_opts TIMESEQ expr     { StructAssign ($1 :: List.rev $2, Binop (StructAccess($1 :: List.rev $2), Mult,      $4))}
  | ID struct_opts DIVIDEEQ expr    { StructAssign ($1 :: List.rev $2, Binop (StructAccess($1 :: List.rev $2), Div,       $4))}

struct_opts:
    DOT ID             { [$2]     }
  | struct_opts DOT ID { $3 :: $1 }

typ_list:
    typ                { [$1]     }
  | typ_list COMMA typ { $3 :: $1 }

args_opt:
    /* nothing */ { []          }
  | args_list     { List.rev $1 }

args_list:
    expr                 { [$1]     }
  | args_list COMMA expr { $3 :: $1 }

list_opt:
    /* Nothing */ { [] }
  | list_list     { $1 }

list_list:
    expr                 { [$1]     }
  | list_list COMMA expr { $3 :: $1 }

set_opt:
    /* Nothing */ { [] }
  | set_list      { $1 }

set_list: 
    expr                { [$1]     }
  | set_list COMMA expr { $3 :: $1 }

struct_list:
    expr                   { [$1]     }
  | struct_list COMMA expr { $3 :: $1 }


