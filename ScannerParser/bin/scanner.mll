(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
*)

(* Ocamllex scanner for Wampus *)

{ open Parser }

let digit = ['0' - '9']
let digits = digit+

(* A character is any printable character except  *)

let simple_char = [' ' - '!' '#' - '&' '(' - '[' ']' - '~']
let escaped_char = ['\\' '"' '\'' 'n' 't' 'r' 'b']
let wampus_char = simple_char | '\\' escaped_char
(* let escaped_seq = '\\' (['"' '\'' '\\' 'n' 't' 'r' 'b'] | digit digit digit) *)

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
| ":"      { COLON }
| "list"   { LIST }
| "set"    { SET }
| "*="     { TIMESEQ }
| "struct" { STRUCT }
(* | "'" char_chars "'" as lxm { CHAR(lxm.[1]) } *)
(* | '"'      { read_string lexbuf } *)
(* TODO *)
(* \ table sequence *)
(* Data structures: Sets, tuples, arrays *)

| "&"  { INTERSECT}
| "|"  { UNION }
| "isin" { ISIN }


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
| "string" { STRING }

(* Literals *)
| "true"   { BLIT(true)  }
| "false"  { BLIT(false) }
| digits as lxm { LITERAL(int_of_string lxm) }
| digits '.'  digit* as lxm { FLIT(lxm) }
| '\"' (wampus_char* as lxm) '\"' { SLIT(lxm)}

| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }
(* Remove *)

(* and read_string buf = parse
    [^'"' '\'' '\\' '\n' '\r' '\t' '\b']+
        { read_string (buf ^ Lexing.lexeme lexbuf) lexbuf }
  | '\\' _ as escape {
      
  }
    '"' { STRING (Buffer.contents buf) }
  | '\\' '"' { Buffer.add_char buf '"'; read_string buf lexbuf }
  | '\\' '\'' { Buffer.add_char buf '\''; read_string buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
  | '\\' 'n' { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | '\\' 't' { Buffer.add_char buf '\t'; read_string buf lexbuf }
  | '\\' 'r' { Buffer.add_char buf '\r'; read_string buf lexbuf }
  | '\\' 'b' { Buffer.add_char buf '\b'; read_string buf lexbuf }
  (* Case for \ddd *)
  | '\\' ['0'-'9']['0'-'9']['0'-'9'] { Buffer.add_char buf (char_of_int (int_of_string ("0" ^ (Lexing.lexeme lexbuf)))); read_string buf lexbuf } *)


and comment = parse
  "*/" { token lexbuf }
| eof  { raise (Failure "Comment not closed") }
| _    { comment lexbuf }

(* and char = parse
  '\'' { token lexbuf }
| '\\'[] as c { char lexbux}
| '\\'['0'-'9']['0'-'9']['0'-'9']''
| _ as c { LITERAL(char_of_string c)} *)

