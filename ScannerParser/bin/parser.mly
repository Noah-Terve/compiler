/* Ocamlyacc parser for MicroC */

%{
open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA PLUS MINUS TIMES DIVIDE ASSIGN
%token NOT EQ NEQ LEQ GEQ AND OR TIMESEQ DIVIDEEQ INTERSECTEQ UNIONEQ MODEQ MINUSEQ PLUSEQ
%token RETURN IF ELSE FOR WHILE INT BOOL FLOAT STRING CHAR
/* edits */
%token LBRACK RBRACK LT GT LARROW RARROW IN MOD TEMPLATE UNION INTERSECT ISIN
%token LIST SET BREAK CONTINUE STRUCT DOT TAGS
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
%right UNIONEQ 
%right INTERSECTEQ
%right PLUSEQ MINUSEQ 
%right TIMESEQ DIVIDEEQ MODEQ
%left OR 
%left AND 
%left EQ NEQ
%left LT GT LEQ GEQ
%left ISIN
%left UNION
%left INTERSECT
%left PLUS MINUS 
%left TIMES DIVIDE MOD 
%right NOT

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { ([], ([], []))               }
 | decls stmt { ((fst $1 @ [$2]), (fst (snd $1), snd (snd $1))) }
 | decls fdecl { (fst $1, ((fst (snd $1) @ [$2] ), snd (snd $1))) }
 | decls sdecl { (fst $1, (fst (snd $1), (snd (snd $1) @ [$2]))) }

fdecl:
   typ ID LPAREN formals_opt RPAREN LBRACE stmt_list RBRACE
      {{ typ = $1; 
        fname = $2;
        formals = List.rev $4;
        body = List.rev $7;
        fun_t_list = []; }}
    | TEMPLATE LARROW t_list RARROW typ ID LPAREN formals_opt RPAREN LBRACE stmt_list RBRACE
    {{ typ = $5; 
        fname = $6;
        formals = List.rev $8;
        body = List.rev $11;
        fun_t_list = List.rev $3; }}
sdecl:
  STRUCT ID LBRACE struct_formal_list RBRACE SEMI
  {{ name = $2;
    sformals = List.rev $4;
    t_list = [];
  }}
  | TEMPLATE LARROW t_list RARROW STRUCT ID LBRACE struct_formal_list RBRACE SEMI
  {{
    name = $6;
    sformals = List.rev $8;
    t_list = List.rev $3;
  }}

struct_formal_list:
    typ ID SEMI                  { [($1, $2)]     }
  | struct_formal_list typ ID SEMI { ($2, $3) :: $1 }

t_list:
    ID { [$1] }
  | t_list COMMA ID { $3 :: $1 }


formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1, $2)]     }
  | formal_list COMMA typ ID { ($3, $4) :: $1 }

typ:
    INT   { Int   }
  | BOOL  { Bool  }
  | FLOAT { Float }
  | STRING { String }
//   // Edit here for additional types
  | CHAR  { Char }
  | ID { Templated ($1)}
  | group_typ { $1 }



group_typ:
    
      SET LARROW INT RARROW         { Set (Int)     }
    | SET LARROW BOOL RARROW        { Set (Bool)    }
    | SET LARROW ID RARROW          { Set (Templated($3))}
    | SET LARROW STRING RARROW      { Set (String)  }
    | SET LARROW CHAR RARROW        { Set (Char)}
    | SET LARROW group_typ RARROW        { Set ($3)      }
    | LIST LARROW INT RARROW        { List (Int)    }
    | LIST LARROW BOOL RARROW       { List (Bool)   }
    | LIST LARROW ID RARROW         { List (Templated($3)) }
    | LIST LARROW STRING RARROW      { List (String)  }
    | LIST LARROW CHAR RARROW        { List (Char)}
    | LIST LARROW group_typ RARROW  { List ($3)     }

stmt_list:
    stmt { [$1] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI                               { Expr $1               }
  | RETURN expr_opt SEMI                    { Return $2             }
  | LBRACE stmt_list RBRACE                 { Block(List.rev $2)    }
  /* elseif can be represented as a case list, also all of these would need {}? */
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7)        }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
                                            { For($3, $5, $7, $9)   }
  /* Wampus statements */
  | FOR LPAREN expr IN expr RPAREN stmt     { ForEnhanced ($3, $5, $7)}
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)         }
  | BREAK SEMI                              { Break }
  | CONTINUE SEMI                           { Continue }
  | SEMI                                    { NullStatement }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1)            }
  | FLIT	           { Fliteral($1)           }
  | BLIT             { BoolLit($1)            }
  | SLIT             { StringLit($1)          }
  | CLIT             { CharLit($1)            }
  | ID               { Id($1)                 }
  | expr PLUS   expr { Binop($1, Add,   $3)   }
  | expr MINUS  expr { Binop($1, Sub,   $3)   }
  | expr TIMES  expr { Binop($1, Mult,  $3)   }
  | expr DIVIDE expr { Binop($1, Div,   $3)   }
  | expr EQ     expr { Binop($1, Equal, $3)   }
  | expr NEQ    expr { Binop($1, Neq,   $3)   }
  | expr LT     expr { Binop($1, Less,  $3)   }
  | expr LEQ    expr { Binop($1, Leq,   $3)   }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3)   }
  | expr AND    expr { Binop($1, And,   $3)   }
  | expr OR     expr { Binop($1, Or,    $3)   }
  | expr MOD    expr { Binop ($1, Mod, $3)}
  | expr DIVIDEEQ expr { Binop ($1, Diveq, $3)}
  | expr TIMESEQ expr { Binop ($1, Multeq, $3) }
  | expr INTERSECTEQ expr { Binop ($1, Intersecteq, $3)}
  | expr UNIONEQ expr { Binop ($1, Unioneq, $3)}
  | expr MODEQ expr { Binop ($1, Modeq, $3)}
  | expr MINUSEQ expr { Binop ($1, Minuseq, $3)}
  | expr PLUSEQ expr {Binop ($1, Pluseq, $3)}
  | expr INTERSECT expr {Binop ($1, Intersect, $3) }
  | expr UNION expr     {Binop ($1, Union, $3) }
  | expr ISIN expr      {Binop ($1, Isin, $3 ) }
  | typ ID ASSIGN expr                 { BindAssign ($1, $2, $4) }
  | typ ID                             { BindDec($1, $2) }  
  // Struct dot assign and templating struct
  | ID DOT ID ASSIGN expr              { BindDot ($1, $3, $5) }
  | LPAREN expr RPAREN                 { $2            }
  | templated_expr                     { $1            }
  // Building a list & set
  | LBRACK list_opt RBRACK      { ListExplicit(List.rev $2)       }
  | LBRACE set_opt RBRACE       { SetExplicit(List.rev $2 )       }
  | TAGS struct_list TAGS        { StructExplicit(List.rev $2)     }
  | MINUS expr %prec NOT         { Unop(Neg, $2)      }
  | NOT expr                     { Unop(Not, $2)          }
  | ID ASSIGN expr               { Assign($1, $3)         }
  | ID LPAREN args_opt RPAREN    { Call($1, $3)  }

templated_expr:
    ID LARROW typ_list RARROW ID                     { BindTemplatedDec ($1, $3, $5) }
  | ID LARROW typ_list RARROW ID ASSIGN expr         { BindTemplatedAssign ($1, $3, $5, $7)}
  | ID LARROW typ_list RARROW LPAREN args_opt RPAREN { TemplatedCall ($1, List.rev $3, $6) } 

typ_list:
    typ { [$1] }
  | typ_list COMMA typ { $3 :: $1}
args_opt:
    /* nothing */ { [] }
  | args_list  { List.rev $1 }

args_list:
    expr                    { [$1] }
  | args_list COMMA expr { $3 :: $1 }

list_opt:
  /* Nothing */ {[]}
  | list_list   { $1 }

list_list:
    expr          { [$1] }
  | list_list COMMA expr { $3 :: $1}

set_opt:
  /* Nothing */ {[]}
  | set_list   { $1 }

set_list: 
    expr { [$1] }
  | set_list COMMA expr { $3 :: $1 }

struct_list:
    expr                        { [$1] }
  | struct_list COMMA expr      { $3 :: $1 }


