(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
*)

(* Ocamllex scanner for Wampus *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+

(* A character is any printable character except  *)

let simple_char = [' ' - '!' '#' - '&' '(' - '[' ']' - '~']
let escaped_char = ['\\' '"' '\'' 'n' 't' 'r' 'b' '0'-'9']
let wampus_char = simple_char | '\\' escaped_char

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"     { comment lexbuf }           (* Comments *)
(* Our edits *)

| "and"    { AND }
| "or"     { OR }
(* | "char"   { CHAR } *)
| "not"    { NOT }
| "template" { TEMPLATE }
| "break"  { BREAK }
| "continue" { CONTINUE }
| "in"     { IN }
| "%"      { MOD }
| "["      { LBRACK }
| "]"      { RBRACK }
| "<"      { LARROW }
| ">"      { RARROW }
| "."      { DOT }
| "list"   { LIST }
| "set"    { SET }
| "*="     { TIMESEQ }
| "/="     { DIVIDEEQ }
| "&="     { INTERSECTEQ }
| "|="     { UNIONEQ }
| "%="     { MODEQ }
| "-="     { MINUSEQ }
| "+="     { PLUSEQ }
| "struct" { STRUCT }
| "&"  { INTERSECT}
| "|"  { UNION }
| "isin" { ISIN }
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
| "<="     { LEQ }
| ">="     { GEQ }
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
| "string" { STRING }
| "#l"      { LTAGS }
| "#r"      { RTAGS }
| "@l"      { LAT }
| "@r"      { RAT }

(* Literals *)
| "true"   { BLIT(true)  }
| "false"  { BLIT(false) }
| digits as lxm { LITERAL(int_of_string lxm) }
| digits '.'  digit* as lxm { FLIT(lxm) }
| '\"' (wampus_char* as s) '\"' { SLIT(Scanf.unescaped s) }
| "'" (wampus_char as c) "'" { CLIT((Scanf.unescaped c).[0])}

| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| eof  { raise (Failure "Comment not closed") }
| _    { comment lexbuf }
