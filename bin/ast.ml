(* 
 * Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
 * AST for Wampus, and functions for printing it. *)


type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or | Mod | Isin | Union | Intersect 

type uop = Neg | Not

type typ = Int | Bool | Float | String | Char |
           List of typ | Set of typ | Templated of string | Struct of string |
           TStruct of string * typ list | (* this is resolving a templated struct as a type *)
           Unknown_contents (* this is the type we will associate the empty list with temporarily in semantic checking *)

type expr =
    Literal of int
  | Fliteral of string
  | BoolLit of bool
  | CharLit of char
  | StringLit of string
  | Id of string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | TemplatedCall of string * typ list * expr list
  | BindAssign of typ * string * expr
  | BindDec of typ * string
  | StructAccess of string list
  | StructAssign of string list * expr
  | ListExplicit of expr list
  | SetExplicit of expr list
  | StructExplicit of expr list
  | Noexpr

type bind = typ * string

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  | ForEnhanced of expr * expr * stmt
  | While of expr * stmt
  | Continue
  | Break
  | NullStatement

type func_decl = {
    typ : typ;
    fname : string;
    formals : bind list;
    body : stmt list;
    fun_t_list : string list;
  }

type struct_decl = {
  name : string;
  sformals : bind list;
  t_list : string list;
}

type prog_unit = 
    Stmt of stmt
  | Fdecl of func_decl
  | Sdecl of struct_decl

type program = prog_unit list
(* type program = stmt list * (func_decl list * struct_decl list) *)

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"
  | Mod -> "%"
  | Intersect -> "&"
  | Union -> "|"
  | Isin -> "Isin"

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"

  let rec string_of_typ = function
  Int -> "int"
| Bool -> "bool"
| Float -> "float"
| String -> "string"
| Char -> "char"
| List(t) -> "list @l " ^ string_of_typ t ^ " @r"
| Set(t) -> "set @l " ^ string_of_typ t ^ " @r"
| Templated(t) -> "tmpl -> " ^ t 
| Struct(t) -> "stru -> " ^ t
| TStruct(s, ts) -> s ^ " @l " ^ String.concat ", "(List.map string_of_typ ts) ^ " @r"
| Unknown_contents -> "'a"

let rec string_of_expr = function
  Literal(l) -> string_of_int l
| Fliteral(l) -> l
| BoolLit(true) -> "true"
| BoolLit(false) -> "false"
| StringLit(s) -> "\"" ^ String.escaped s ^ "\""
| CharLit(c) -> "'" ^ Char.escaped c ^ "'"
| Id(s) -> s
| Binop(e1, o, e2) ->
    string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
| Unop(o, e) -> string_of_uop o ^ string_of_expr e
| Assign(v, e) -> v ^ " = " ^ string_of_expr e
| Call(f, el) -> f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
| TemplatedCall(f, tl, el) ->
    f ^ " @l " ^ String.concat ", "(List.map string_of_typ tl) ^ " @r (" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
| BindAssign(t, id, e) -> string_of_typ t ^ " "^ id ^ " = " ^ string_of_expr e
| BindDec (t, id) -> string_of_typ t ^ " " ^ id
| StructAssign (ids, e) -> String.concat "." ids ^ " = " ^ string_of_expr e
| StructAccess (ids) -> String.concat "." ids
| ListExplicit(el) -> "[" ^ String.concat ", " (List.map string_of_expr el) ^ "]"
| SetExplicit (el) -> "{" ^ String.concat ", " (List.map string_of_expr el) ^ "}"
| StructExplicit (el) -> "#l " ^ String.concat ", " (List.map string_of_expr el) ^ " #r"
| Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s ^ "\n"
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ " else\n" ^ string_of_stmt s2 ^ "\n"
  | For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | ForEnhanced (e1, e2, s) -> "for (" ^ string_of_expr e1 ^ " in " ^ 
      string_of_expr e2 ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s
  | Break -> "break;\n"
  | Continue -> "continue;\n"
  | NullStatement -> ";\n"

let template = function
    [] -> ""
    | types -> "template @l " ^ String.concat ", " (List.map (fun s -> s) types) ^ " @r\n"

let string_of_fdecl fdecl =
  (template fdecl.fun_t_list) ^
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map (fun (t, s) -> string_of_typ t ^ " " ^ s) fdecl.formals) ^
  ")\n{\n" ^ String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_sdecl sdecl = 
  (template sdecl.t_list) ^ "struct " ^ sdecl.name ^ " { " ^ String.concat "; " (List.map (fun (t, s) -> string_of_typ t ^ " " ^ s) sdecl.sformals) ^ ";};\n"


let string_of_unit = function
    Stmt(stmt) -> string_of_stmt stmt
  | Fdecl(fdecl) -> string_of_fdecl fdecl
  | Sdecl(sdecl) -> string_of_sdecl sdecl

let rec string_of_program = function
    [] -> ""
  | e :: rest -> (string_of_unit e) ^ (string_of_program rest)
  
let info_of_strings = function
    [] -> "[]"
  | types -> "[\"" ^ String.concat "\"; \"" (List.map (fun s -> s) types) ^ "\"]"
  
  let info_of_op = function
    Add -> "Add"
  | Sub -> "Sub"
  | Mult -> "Mult"
  | Div -> "Div"
  | Equal -> "Equal"
  | Neq -> "Neq"
  | Less -> "Less"
  | Leq -> "Leq"
  | Greater -> "Greater"
  | Geq -> "Geq"
  | And -> "And"
  | Or -> "Or"
  | Mod -> "Mod"
  | Intersect -> "Intersect"
  | Union -> "Union"
  | Isin -> "Isin"

  let info_of_uop = function
    Neg -> "Neg"
  | Not -> "Not"

let rec info_of_typ = function
    Int -> "Int"
  | Bool -> "Bool"
  | Float -> "Float"
  | String -> "String"
  | Char -> "Char"
  | List(t) -> "List(" ^ info_of_typ t ^ ")"
  | Set(t) -> "Set(" ^ info_of_typ t ^ ")"
  | Templated(t) -> "Templated(\"" ^ t ^ "\")" 
  | Struct(t) -> "Struct(\"" ^ t ^ "\")"
  | TStruct(s, ts) -> "TStruct(\"" ^ s ^ "\", [" ^ String.concat "; "(List.map info_of_typ ts) ^ "])"
  | Unknown_contents -> "Unknown_contents"

let info_of_typs = function
    [] -> "[]"
  | typs -> "[" ^ String.concat "; " (List.map info_of_typ typs) ^ "]"

let rec info_of_expr = function
    Literal(l) -> "Literal(" ^ string_of_int l ^ ")"
  | Fliteral(l) -> "Fliteral(" ^ l ^ ")"
  | BoolLit(true) -> "BoolLit(true)"
  | BoolLit(false) -> "BoolLit(false)"
  | StringLit(s) -> "StringLit(\"" ^ String.escaped s ^ "\")"
  | CharLit(c) -> "CharLit('" ^ Char.escaped c ^ "')"
  | Id(s) -> "Id(\"" ^ s ^ "\")"
  | Binop(e1, o, e2) -> "Binop(" ^ info_of_expr e1 ^ ", " ^ info_of_op o ^ ", " ^ info_of_expr e2 ^ ")"
  | Unop(o, e) -> "Unop(" ^ info_of_uop o ^ ", " ^ info_of_expr e ^ ")"
  | Assign(v, e) -> "Assign(\"" ^ v ^ "\", " ^ info_of_expr e ^ ")"
  | Call(f, el) -> "Call(\"" ^ f ^ "\", " ^ info_of_exprs el ^ ")"
  | TemplatedCall(f, tl, el) -> "TemplatedCall(\"" ^ f ^ "\", " ^ info_of_typs tl ^ ", " ^ info_of_exprs el ^ ")"
  | BindAssign(t, id, e) -> "BindAssign(" ^ info_of_typ t ^ ", \"" ^ id ^ "\", " ^ info_of_expr e ^ ")"
  | BindDec (t, id) -> "BindDec(" ^ info_of_typ t ^ ", \"" ^ id ^ "\")"
  | StructAssign (ids, e) -> "StructAccess(" ^ info_of_strings ids ^ ", " ^ info_of_expr e ^ ")"
  | StructAccess (ids) -> "StructAccess(" ^info_of_strings ids ^ ")"
  | ListExplicit(el) -> "ListExplicit(" ^ info_of_exprs el ^ ")"
  | SetExplicit (el) -> "SetExplicit(" ^ info_of_exprs el ^ ")"
  | StructExplicit (el) -> "StructExplicit(" ^ info_of_exprs el ^ ")"
  | Noexpr -> "Noexpr"

and info_of_exprs = function 
    [] -> "[]"
  | exprs -> "[" ^ String.concat "; " (List.map info_of_expr exprs) ^ "]"

let rec info_of_stmt = function
    Block(stmts) ->
      "Block(" ^ info_of_stmts stmts ^ ")"
  | Expr(expr) -> "Expr(" ^ info_of_expr expr ^ ")"
  | Return(expr) -> "Return(" ^ info_of_expr expr ^ ")"
  | If(e, s, Block([])) -> "If(" ^ info_of_expr e ^ ", " ^ info_of_stmt s ^ ", Block([]))"
  | If(e, s1, s2) ->  "If(" ^ info_of_expr e ^ ", " ^
      info_of_stmt s1 ^ ", " ^ info_of_stmt s2 ^ ")"
  | For(e1, e2, e3, s) ->
      "For(" ^ info_of_expr e1  ^ ", " ^ info_of_expr e2 ^ ", " ^
      info_of_expr e3  ^ ", " ^ info_of_stmt s ^ ")"
  | ForEnhanced (e1, e2, s) -> "ForEnhanced(" ^ info_of_expr e1 ^ ", " ^ 
      info_of_expr e2 ^ ", " ^ info_of_stmt s ^ ")"
  | While(e, s) -> "While(" ^ info_of_expr e ^ ", " ^ info_of_stmt s ^ ")"
  | Break -> "Break"
  | Continue -> "Continue"
  | NullStatement -> "NullStatement"

and info_of_stmts = function
    [] -> "[]"
  | stmts -> "[" ^ String.concat "; " (List.map info_of_stmt stmts) ^ "]"


let info_of_binds = function
    [] -> "[]"
  | types -> "[(" ^ String.concat "); (" (List.map (fun (t, s) -> info_of_typ t ^ ", \"" ^ s ^ "\"") types) ^ ")]"

let info_of_fdecl fdecl =
  "{fname = \"" ^ fdecl.fname ^ "\"; typ = " ^ info_of_typ fdecl.typ ^ "; formals = " ^ info_of_binds fdecl.formals ^ "; fun_t_list = " ^ info_of_strings fdecl.fun_t_list ^ "; body = " ^ info_of_stmts fdecl.body ^ "}\n"

let info_of_sdecl sdecl = 
  "{name = \"" ^ sdecl.name ^ "\"; t_list = " ^ info_of_strings sdecl.t_list ^ "; sformals = " ^ info_of_binds sdecl.sformals ^ "}\n"

let info_of_unit = function
  Stmt(stmt) -> info_of_stmt stmt ^ "\n"
| Fdecl(fdecl) -> info_of_fdecl fdecl
| Sdecl(sdecl) -> info_of_sdecl sdecl

let rec info_of_program = function
    [] -> ""
  | e :: rest -> (info_of_unit e) ^ (info_of_program rest)
