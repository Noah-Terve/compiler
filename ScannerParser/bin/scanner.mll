(* Ocamllex scanner for MicroC *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"     { comment lexbuf }           (* Comments *)
(* Our edits *)

| "include" { INCLUDE }
| "and"    { AND }
| "or"     { OR }
| "elseif" { ELSEIF }
| "switch" { SWITCH }
| "type"   { TYPE }
| "char"   { CHAR }
| "function" { FUNCTION }
| "not"    { NOT }
| "case"   { CASE }
| "string" { STRING }
| "template" { TEMPLATE }
| "isin"   { ISIN }
| "in"     { IN }
| "%"      { MOD }
| "["      { LBRACK }
| "]"      { RBRACK }
| ":"      { COLON }
(* TODO *)
(* \ table sequence *)
(* Data structures: Sets, tuples, arrays *)
(* Assert?, ^?, <> for initializing sets? *)

(* MicroC *)
| '('      { LPAREN }
| ')'      { RPAREN }
| '{'      { LBRACE }
| '}'      { RBRACE }
| ';'      { SEMI }
| ','      { COMMA }
| '+'      { PLUS }
| '-'      { MINUS }
| '*'      { TIMES }
| '/'      { DIVIDE }
| '='      { ASSIGN }
| "=="     { EQ }
| "!="     { NEQ }
| '<'      { LT }
| "<="     { LEQ }
| ">"      { GT }
| ">="     { GEQ }
(* change or & and *)
| "&&"     { AND }
| "||"     { OR }
| "!"      { NOT }
| "if"     { IF }
| "else"   { ELSE }
| "for"    { FOR }
| "while"  { WHILE }
| "return" { RETURN }
| "int"    { INT }
| "bool"   { BOOL }
| "float"  { FLOAT }
| "true"   { BLIT(true)  }
| "false"  { BLIT(false) }
| digits as lxm { LITERAL(int_of_string lxm) }
| digits '.'  digit* as lxm { FLIT(lxm) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }
(* Remove *)
| "void"   { VOID }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
