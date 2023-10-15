(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or | Mod | Isin | Union | Intersect | Multeq

type uop = Neg | Not

type typ = Int | Bool | Float | Void | String | List of typ | Set of typ
 
(* | Struct of string * (typ, id) list *)



(* or optional *)


type expr =
    Literal of int
  | Fliteral of string
  | BoolLit of bool
  (* | CharLit of char *)
  | StringLit of string
  | Id of string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | BindAssign of typ * string * expr
  | BindDec of typ * string
  | ListExplicit of expr list
  | SetExplicit of expr list
  (* struct constructor of Id * typ list * string *)
  (* struct constructor of Id * typ list * string * *)
  | Noexpr


type bind = typ * string

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  (* | ForEnhanced of expr * expr * stmt *)
  | While of expr * stmt
  (* add our case, switch, elseif statements here *)
  | NullStatement
  | Continue
  | Break

and func_decl = 
    Func of typ * string * bind list * stmt list
and struct_decl =
    Struct of string * bind list * string list
and decl = 
    Stmt of stmt list
  | SDecl of struct_decl
  | FDecl of func_decl

type program = decl list

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
  (* add here *)
  | Mod -> "%"
  | Intersect -> "&"
  | Union -> "|"
  | Isin -> "Isin"
  | Multeq -> "*="

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"

  let rec string_of_typ = function
  Int -> "int"
| Bool -> "bool"
| Float -> "float"
| Void -> "void"
| String -> "string"
| List(t) -> "List <" ^ string_of_typ t ^ ">"
| Set(t) -> "Set <" ^ string_of_typ t ^ ">"
let rec string_of_expr = function
  Literal(l) -> string_of_int l
| Fliteral(l) -> l
| BoolLit(true) -> "true"
| BoolLit(false) -> "false"
| StringLit(s) -> s
| Id(s) -> s
| Binop(e1, o, e2) ->
    string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
| Unop(o, e) -> string_of_uop o ^ string_of_expr e
| Assign(v, e) -> v ^ " = " ^ string_of_expr e
| Call(f, el) ->
    f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
| BindAssign(t, id, e) -> string_of_typ t ^ " "^ id ^ " = " ^ string_of_expr e
| BindDec (t, id) -> string_of_typ t ^ " " ^ id
| ListExplicit(el) -> "[" ^ String.concat ", " (List.map string_of_expr el) ^ "]"
| SetExplicit (el) -> "{" ^ String.concat ", " (List.map string_of_expr el) ^ "}"
| Noexpr -> ""

(* let string_of_bind = function
    BindDec(t, id) -> string_of_typ t ^ " " ^ id
  | BindAssign(t, id, e) -> string_of_typ t ^ " " ^ id ^ " = " ^
  string_of_expr e *)

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
  (* | ForEnhanced (e1, e2, s) ->  "for ("^ string_of_expr e1 ^ " in " ^ string_of_expr e2 ^ ")" ^ string_of_stmt s *)
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s
  | NullStatement -> ";\n"
  | Break -> "break;\n"
  | Continue -> "continue;\n"
  (* | Break -> "break;"
  | Continue -> "continue;" *)
  (* | DeclBind(b) -> string_of_bind b ^ ";\n" *)
(* let string_of_vdecl (b) = string_of_bind b ^ ";\n" *)

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let rec string_of_fdecl = function
  Func(t, s, b_list, s_list) -> string_of_typ t ^ " " ^
  s ^ "(" ^ String.concat ", " (List.map snd b_list) ^
  ")\n{\n" ^ String.concat "" (List.map string_of_stmt s_list) ^
  "}\n"
  
let rec string_of_sdecl = function
  Struct (s, f_list, _) -> "struct " ^ s ^ " {" ^ String.concat  ";" (List.map snd f_list) ^"}\n" 

let rec string_of_decl = function
    Stmt(slist) -> String.concat "" (List.map string_of_stmt slist)
  | SDecl(s) ->  string_of_sdecl s
  | FDecl (f) -> string_of_fdecl f

let string_of_program (decl_list) =
   String.concat "" (List.map string_of_decl decl_list) ^ "\n"

  (* String.concat "" (List.map string_of_sdecl sdecls ) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs) *)
