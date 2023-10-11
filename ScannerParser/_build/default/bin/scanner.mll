(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
*)

(* Ocamllex scanner for Wampus *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"     { comment lexbuf }           (* Comments *)
(* Our edits *)

(* | "include" { INCLUDE } *)
| "and"    { AND }
| "or"     { OR }
(* | "type"   { TYPE } *)
(* | "char"   { CHAR } *)
| "not"    { NOT }
(* | "template" { TEMPLATE } *)
(* | "isin"   { ISIN } *)
| "in"     { IN }
| "%"      { MOD }
| "["      { LBRACK }
| "]"      { RBRACK }
| ":"      { COLON }
(* TODO *)
(* \ table sequence *)
(* Data structures: Sets, tuples, arrays *)
(* | "set" { SET }
| "&"  { INTERSECT}
| "|"  { UNION }
| "tuple" { TUPLE }
| "list" { LIST }
| "<"    { LARROW }
| ">"    { RARROW } *)

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

(* and char = parse
  '\'' { token lexbuf }
| '\\'[] as c { char lexbux}
| '\\'['0'-'9']['0'-'9']['0'-'9']''
| _ as c { LITERAL(char_of_string c)} *)

