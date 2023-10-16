/* Ocamlyacc parser for MicroC */

%{
open Ast
%}

/* - [ ]  tuple
   - [ ]  list
   - [ ]  set
    set <int> chris = <1, 2, 3, 4>
    set <int> chris;
  - [ ]  struct
    struct will be a list containing tuples

    
  - [ ]  template
    template will be the same but with types

  - [ ]  issue */
      // two different meanings <>, <=, >=



%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA PLUS MINUS TIMES DIVIDE ASSIGN
%token NOT EQ NEQ LT LEQ GT GEQ AND OR TIMESEQ DIVIDEEQ ANDEQ OREQ MODEQ MINUSEQ PLUSEQ
%token RETURN IF ELSE FOR WHILE INT BOOL FLOAT STRING
/* edits */
%token LBRACK RBRACK LARROW RARROW IN MOD COLON TEMPLATE UNION INTERSECT ISIN
%token LIST SET BREAK CONTINUE STRUCT DOT
%token <char> CHAR
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token <string> SLIT
%token EOF

%start program
%type <Ast.program> program

%nonassoc NOELSE NOBRACKET
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left ISIN
%left UNION
%left INTERSECT
%left PLUS MINUS PLUSEQ MINUSEQ
%left TIMES DIVIDE MOD TIMESEQ DIVIDEEQ ANDEQ
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
//   | CHAR  { Char }
  | ID { Templated ($1)}
  | group_typ { $1 }



group_typ:
    
      SET LARROW INT RARROW         { Set (Int)     }
    | SET LARROW BOOL RARROW        { Set (Bool)    }
    | SET LARROW ID RARROW          { Set (Templated($3))}
  // | SET LARROW STRING RARROW      { Set (String)  }
    | SET LARROW group_typ RARROW        { Set ($3)      }
    | LIST LARROW INT RARROW        { List (Int)    }
    | LIST LARROW BOOL RARROW       { List (Bool)   }
    | LIST LARROW ID RARROW         { List (Templated($3)) }
    //  | LIST LBRACK STRING RBRACK     { List (String) }
    | LIST LARROW group_typ RARROW  { List ($3)     }






stmt_list:
  stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI                               { Expr $1               }
  | RETURN expr_opt SEMI                    { Return $2             }
  | LBRACE stmt_list RBRACE                 { Block(List.rev $2)    }
  /* elseif can be represented as a case list, also all of these would need {}? */
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7)        }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
                                            { For($3, $5, $7, $9)   }
  | FOR LPAREN expr IN expr RPAREN stmt     { ForEnhanced ($3, $5, $7)}
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)         }
  | BREAK SEMI                              { Break }
  | CONTINUE SEMI                           { Continue }
  /* Wampus statements */

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1)            }
  | FLIT	           { Fliteral($1)           }
  | BLIT             { BoolLit($1)            }
  | SLIT             { StringLit($1)          }
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
  // adding more expression operators
  | expr MOD    expr { Binop ($1, Mod, $3)}
  // this is more complicated than I thought
  // | ID PLUS ASSIGN expr { Assign( $1, Binop ($1, Add, $3))}
  | expr DIVIDEEQ expr { Binop ($1, Diveq, $3)}
  | expr TIMESEQ expr { Binop ($1, Multeq, $3) }
  | expr ANDEQ expr { Binop ($1, Andeq, $3)}
  | expr OREQ expr { Binop ($1, Oreq, $3)}
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
  | templated_expr                          { $1 }
  // Building a list & set
  | list_expr               { $1 }
  | set_expr                { $1 }
  | MINUS expr %prec NOT { Unop(Neg, $2)      }
  | NOT expr         { Unop(Not, $2)          }
  | ID ASSIGN expr   { Assign($1, $3)         }
  | ID LPAREN args_opt RPAREN { Call($1, $3)  }
  // | LPAREN expr_list RPAREN   { $2            }
  | LPAREN expr RPAREN        { $2            }

templated_expr:
    ID LARROW typ_list RARROW ID                     { BindTemplatedDec ($1, $3, $5) }
  // | ID LARROW typ_list RARROW ID ASSIGN expr         { BindTemplatedAssign ($1, $3, $5, $7)}
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


list_list:
    expr          { [$1] }
  | list_list COMMA expr { $3 :: $1}

list_expr:
  LBRACK list_list RBRACK      { ListExplicit(List.rev $2) }


set_list: 
    expr { [$1] }
  | set_list COMMA expr { $3 :: $1 }

set_expr:
  LBRACE set_list RBRACE { SetExplicit(List.rev $2 )}