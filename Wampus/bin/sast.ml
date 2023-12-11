(* Semantically-checked Abstract Syntax Tree and functions for printing it *)

open Ast

type sexpr = typ * sx
and sx =

    SLiteral of int
  | SFliteral of string
  | SBoolLit of bool
  | SCharlit of char
  | SStringlit of string
  | SId of string
  | SBinop of sexpr * op * sexpr
  | SUnop of uop * sexpr
  | SAssign of string * sexpr
  | SCall of string * sexpr list
  | SBindAssign of typ * string * sexpr
  | SBindDec of typ * string
  | SStructAssign of string list * string list * sexpr
  | SStructAccess of string list * string list
  | SListExplicit of sexpr list
  | SSetExplicit of sexpr list
  | SStructExplicit of typ * string * sexpr list
  | SNoexpr

type sstmt =
    SBlock of sstmt list
  | SExpr of sexpr
  | SReturn of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SFor of sexpr * sexpr * sexpr * sstmt
  | SForEnhanced of sexpr * sexpr * sstmt
  | SWhile of sexpr * sstmt
  | SContinue
  | SBreak
  | SNullStatement

type sfunc_decl = {
  styp : typ;
  sfname : string;
  sformals : bind list;
  slocals : bind list;
  sbody : sstmt list;
}

type sstruct_decl = {
  sname : string;
  ssformals : bind list;
}

type sunit_program = 
    SStmt of sstmt
  | SFdecl of sfunc_decl
  | SSdecl of sstruct_decl

type sprogram = sunit_program list

(* Pretty-printing functions *)
let rec string_of_sexpr (t, e) =
  "(" ^ string_of_typ t ^ " : " ^ (match e with
    SLiteral(l) -> string_of_int l
  | SFliteral(l) -> l
  | SBoolLit(true) -> "true"
  | SBoolLit(false) -> "false"
  | SCharlit (c) -> string_of_int (int_of_char c)
  | SStringlit (s) -> s
  | SId(s) -> s
  | SBinop(e1, o, e2) ->
      string_of_sexpr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_sexpr e2
  | SUnop(o, e) -> string_of_uop o ^ string_of_sexpr e
  | SAssign(v, e) -> v ^ " = " ^ string_of_sexpr e
  | SCall(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_sexpr el) ^ ")"
  | SBindAssign (_, id, e) -> id ^ " = " ^ string_of_sexpr e
  | SBindDec (_, id) -> id
  | SStructAssign (_, ids, e) -> String.concat "." ids ^ " = " ^ string_of_sexpr e
  | SStructAccess (_, sids) -> String.concat "." sids
  | SListExplicit el -> "[" ^ String.concat ", " (List.map string_of_sexpr el) ^ "]"
  | SSetExplicit el -> "{" ^ String.concat ", " (List.map string_of_sexpr el) ^ "}"
  | SStructExplicit (_, n, el)-> n ^ "#l" ^ String.concat ", " (List.map string_of_sexpr el) ^ "#r"
  | SNoexpr -> ""
    ) ^ ")"

let rec string_of_sstmt = function
    SBlock(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_sstmt stmts) ^ "}\n"
  | SExpr(expr) -> string_of_sexpr expr ^ ";\n";
  | SReturn(expr) -> "return " ^ string_of_sexpr expr ^ ";\n";
  | SIf(e, s, SBlock([])) ->
      "if (" ^ string_of_sexpr e ^ ")\n" ^ string_of_sstmt s
  | SIf(e, s1, s2) ->  "if (" ^ string_of_sexpr e ^ ")\n" ^
      string_of_sstmt s1 ^ "else\n" ^ string_of_sstmt s2
  | SFor(e1, e2, e3, s) ->
      "for (" ^ string_of_sexpr e1  ^ " ; " ^ string_of_sexpr e2 ^ " ; " ^
      string_of_sexpr e3  ^ ") " ^ string_of_sstmt s
  | SForEnhanced (e1, e2, s) -> "for (" ^ string_of_sexpr e1  ^ " in " ^ string_of_sexpr e2 ^
      ") " ^ string_of_sstmt s
  | SWhile(e, s) -> "while (" ^ string_of_sexpr e ^ ") " ^ string_of_sstmt s
  | SContinue -> "continue"
  | SBreak -> "break"
  | SNullStatement -> ""

let string_of_sfdecl fdecl =
  string_of_typ fdecl.styp ^ " " ^
  fdecl.sfname ^ "(" ^ String.concat ", " (List.map snd fdecl.sformals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_sstmt fdecl.sbody) ^
  "}\n"
let string_of_ssdecl sdecl = 
  "struct " ^ sdecl.sname ^ " { \n" ^ String.concat ";\n " (List.map (fun (t, s) -> string_of_typ t ^ " " ^ s) sdecl.ssformals) ^ ";\n};\n"
let string_of_sunit = function
   SStmt(stmt) -> string_of_sstmt stmt
  | SFdecl(fdecl) -> string_of_sfdecl fdecl
  | SSdecl (sdecl) -> string_of_ssdecl sdecl

let rec string_of_sprogram = function 
  [] -> ""
  | e :: rest -> (string_of_sunit e) ^ (string_of_sprogram rest)
