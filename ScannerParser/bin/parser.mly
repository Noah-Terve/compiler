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
%token NOT EQ NEQ LT LEQ GT GEQ AND OR
%token RETURN IF ELSE FOR WHILE INT BOOL FLOAT VOID
/* edits */
%token LBRACK RBRACK LARROW RARROW IN MOD COLON TEMPLATE UNION INTERSECT ISIN
%token LIST SET TIMESEQ
// %token TYPE  CASE STRUCT ISIN SET LIST STRING TUPLE
// float, char, and string?
%token <char> CHAR
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token <string> STRING
%token EOF

%start program
%type <Ast.program> program

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
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
   /* nothing */ { ([], [])               }
 | decls vdecl { (($2 :: fst $1), snd $1) }
 | decls fdecl { (fst $1, ($2 :: snd $1)) }

fdecl:
   typ ID LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
     { { typ = $1;
	 fname = $2;
	 formals = List.rev $4;
	 locals = List.rev $7;
	 body = List.rev $8 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { $1 }

formal_list:
    typ ID                   { [($1, $2)]     }
  | formal_list COMMA typ ID { ($3, $4) :: $1 }

// struct_list:
//   struct                      {List.rev $1}

// struct:
//     typ ID                   { [($1,$2)]     }
//   | struct SEMI typ ID       { ($3,$4) :: $1 }
  // need a way to assign member varib
  // assignment
  // | struct DOT ID ASSIGN expr { }

// typ_list:
//     typ { [$1] }
//   | typ_list COMMA typ { $3 :: $1}

typ:
    INT   { Int   }
  | BOOL  { Bool  }
  | FLOAT { Float }
  | VOID  { Void  }
  // | STRING { String }
//   // Edit here for additional types
//   | CHAR  { Char }
  | group_typ { $1 }



group_typ:
    
      SET LARROW INT RARROW         { Set (Int)     }
    | SET LARROW BOOL RARROW        { Set (Bool)    }
  // | SET LARROW STRING RARROW      { Set (String)  }
    | SET LARROW group_typ RARROW        { Set ($3)      }
    | LIST LARROW INT RARROW        { List (Int)    }
    | LIST LARROW BOOL RARROW       { List (Bool)   }
    //  | LIST LBRACK STRING RBRACK     { List (String) }
    | LIST LARROW group_typ RARROW  { List ($3)     }

// group_typ_list:
//     INT           { [Int]     }
//   | BOOL          { [Bool]    }
//   | STRING        { [String]  }
//   | group_typ     { [$1]      }
//   | group_typ_list COMMA INT        { Int :: $1 }
//   | group_typ_list COMMA BOOL       { Bool :: $1 }
//   | group_typ_list COMMA STRING     { String :: $1 }
//   /* group type list containing a type of groups*/
//   | group_typ_list COMMA group_typ  { $3 :: $1 }



vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
    typ ID SEMI { ($1, $2) }
  // | typ ID ASSIGN expr SEMI { BindAssign($1, $2, $4) }

stmt_list:
    /* nothing */  { [] }
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
  | FOR LPAREN expr IN expr RPAREN stmt     {}
  | WHILE LPAREN expr RPAREN stmt           { While($3, $5)         }
  /* Wampus statements */
  // | vdecl { DeclBind($1) }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1)            }
  | FLIT	           { Fliteral($1)           }
  | BLIT             { BoolLit($1)            }
  | STRING           { StringLit($1)          }
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
  | expr TIMESEQ expr { Binop ($1, Multeq, $3) }
  | expr INTERSECT expr {Binop ($1, Intersect, $3) }
  | expr UNION expr     {Binop ($1, Union, $3) }
  | expr ISIN expr      {Binop ($1, Isin, $3 ) }
  // Building a list & set
  | list_expr               { $1 }
  | set_expr                { $1 }
// do we need to do x binary operators
  | MINUS expr %prec NOT { Unop(Neg, $2)      }
  | NOT expr         { Unop(Not, $2)          }
  | ID ASSIGN expr   { Assign($1, $3)         }
  // | typ ID ASSIGN expr    { }
  //  type assign ?
  | ID LPAREN args_opt RPAREN { Call($1, $3)  }
  | LPAREN expr RPAREN { $2                   }

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