(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
*)

(* AST for Wampus *)


type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or | Mod | Isin | Union | Intersect 

type uop = Neg | Not

type typ = Int | Bool | Float | String | Char
         | List of typ | Set of typ | Templated of string | Struct of string

type expr =
    Literal of int
  | Fliteral of string
  | BoolLit of bool
  | CharLit of char
  | StringLit of string
  | Id of string
  | StructMem of string * string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | TemplatedCall of string * typ list * expr list
  | BindAssign of typ * string * expr
  | BindDec of typ * string
  | StructAssign of string * string * expr
  | BindTemplatedDec of string * typ list * string
  | BindTemplatedAssign of string * typ list * string * expr
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
  (* | Multeq -> "*="
  | Diveq -> "/="
  | Pluseq -> "+="
  | Minuseq -> "-="
  | Intersecteq -> "&="
  | Unioneq -> "|="
  | Modeq -> "%=" *)

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
| Templated(t) -> t
| Struct(t) -> t

let rec string_of_expr = function
  Literal(l) -> string_of_int l
| Fliteral(l) -> l
| BoolLit(true) -> "true"
| BoolLit(false) -> "false"
| StringLit(s) -> "\"" ^ String.escaped s ^ "\""
| CharLit(c) -> "'" ^ Char.escaped c ^ "'"
| Id(s) -> s
| StructMem(s1, s2) -> s1 ^ "." ^ s2
| Binop(e1, o, e2) ->
    string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
| Unop(o, e) -> string_of_uop o ^ string_of_expr e
| Assign(v, e) -> v ^ " = " ^ string_of_expr e
| Call(f, el) ->
    f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
| TemplatedCall(f, tl, el) ->
    f ^ "@l " ^ String.concat ", "(List.map string_of_typ tl) ^ " @r  (" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
| BindAssign(t, id, e) -> string_of_typ t ^ " "^ id ^ " = " ^ string_of_expr e
| BindDec (t, id) -> string_of_typ t ^ " " ^ id
| StructAssign (struct_id, id1, e) -> struct_id ^ "."^ id1 ^ " = " ^ string_of_expr e
| BindTemplatedDec (struct_id, t_list, id) ->  struct_id ^ " @l " ^ String.concat ", " (List.map string_of_typ t_list) ^ " @r " ^ id
| BindTemplatedAssign (struct_id, t_list, id, e) -> struct_id ^ " @l " ^ String.concat ", " (List.map string_of_typ t_list) ^ " @r " ^ id ^ " = " ^ string_of_expr e
| ListExplicit(el) -> "[" ^ String.concat ", " (List.map string_of_expr el) ^ "]"
| SetExplicit (el) -> "{" ^ String.concat ", " (List.map string_of_expr el) ^ "}"
| StructExplicit (el) -> "#l " ^ String.concat ", " (List.map string_of_expr el) ^ " #r"
| Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
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
  
(* let string_of_program (stmts, (funcs, structs)) =
  String.concat "" (List.map string_of_stmt stmts)  ^
  String.concat "\n" (List.map string_of_fdecl funcs) ^
  String.concat "\n" (List.map string_of_sdecl structs) *)