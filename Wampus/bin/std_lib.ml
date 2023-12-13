open Ast

let add_std_lib units = 
  (* make the print and println function for basic types, this  *)
  let print = {fname = "print"; typ = Int; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in
  let println = {fname = "println"; typ = Int; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in
  (* let set_to_str = {fname = "set_to_str"; typ = String; formals = [(Set(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Expr(BindAssign(String, "result", StringLit("{"))); Expr(BindAssign(Bool, "started", BoolLit(false))); ForEnhanced(Id("elem"), Id("s"), Block([If(Unop(Not, Id("started")), Block([Expr(Assign("result", Binop(Id("result"), Add, TemplatedCall("to_str", [Templated("T")], [Id("elem")])))); Expr(Assign("started", BoolLit(true)))]), Expr(Assign("result", Binop(Id("result"), Add, Binop(StringLit(", "), Add, TemplatedCall("to_str", [Templated("T")], [Id("elem")]))))))])); Return(Binop(Id("result"), Add, StringLit("}")))]} in *)
  (* let list_to_str = {fname = "list_to_str"; typ = String; formals = [(List(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Expr(BindAssign(String, "result", StringLit("["))); Expr(BindAssign(Bool, "started", BoolLit(false))); ForEnhanced(Id("elem"), Id("s"), Block([If(Unop(Not, Id("started")), Block([Expr(Assign("result", Binop(Id("result"), Add, TemplatedCall("to_str", [Templated("T")], [Id("elem")])))); Expr(Assign("started", BoolLit(true)))]), Expr(Assign("result", Binop(Id("result"), Add, Binop(StringLit(", "), Add, TemplatedCall("to_str", [Templated("T")], [Id("elem")]))))))])); Return(Binop(Id("result"), Add, StringLit("]")))]} in *)
  (* let printset = {fname = "printset"; typ = Int; formals = [(Set(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("print", [String], [TemplatedCall("set_to_str", [Templated("T")], [Id("s")])])); Return(Literal(0))]} in *)
  (* let printlist = {fname = "printlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("print", [String], [TemplatedCall("list_to_str", [Templated("T")], [Id("l")])])); Return(Literal(0))]} in *)
  (* let printlnset = {fname = "printlnset"; typ = Int; formals = [(Set(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("println", [String], [TemplatedCall("set_to_str", [Templated("T")], [Id("s")])])); Return(Literal(0))]} in *)
  (* let printlnlist = {fname = "printlnlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("println", [String], [TemplatedCall("list_to_str", [Templated("T")], [Id("l")])])); Return(Literal(0))]} in *)
  
  let list_insert = {fname = "list_insert"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos"); (Templated("T"), "data")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in
  let list_remove = {fname = "list_remove"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in
  let list_at = {fname = "list_at"; typ = Templated("T"); formals = [(List(Templated("T")), "l"); (Int, "pos")]; fun_t_list = ["T"]; body = [Expr(BindDec(Templated("T"), "x")); Return(Id("x"))]} in
  let list_length = {fname = "list_length"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Return(Literal(0))]} in
  let list_replace = {fname = "list_replace"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos"); (Templated("T"), "data")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in

  let printlist = {fname = "printlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("print", [String], [StringLit("[")])); Expr(BindAssign(Bool, "started", BoolLit(false))); Expr(BindDec(Templated("T"), "elem")); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("l")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([Expr(Assign("elem", TemplatedCall("list_at", [Templated("T")], [Id("l"); Id("i")]))); If(Unop(Not, Id("started")), Block([Expr(TemplatedCall("print", [Templated("T")], [Id("elem")])); Expr(Assign("started", BoolLit(true)))]), Block([Expr(TemplatedCall("print", [String], [StringLit(", ")])); Expr(TemplatedCall("print", [Templated("T")], [Id("elem")]))]))])); Expr(TemplatedCall("print", [String], [StringLit("]")])); Return(Literal(0))]} in
  let printlnlist = {fname = "printlnlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("printlist", [Templated("T")], [Id("l")])); Expr(TemplatedCall("println", [String], [StringLit("")])); Return(Literal(0))]} in

  Fdecl(print) :: Fdecl(println) :: 
  (* Fdecl(set_to_str) :: Fdecl(list_to_str) :: *)
  (* Fdecl(printset) :: Fdecl(printlist) :: Fdecl(printlnset) :: Fdecl(printlnlist) :: *)

  Fdecl(list_insert) :: Fdecl(list_remove) ::
  Fdecl(list_at) :: Fdecl(list_length) :: Fdecl(list_replace) ::  
  Fdecl(printlist) :: 
  Fdecl(printlnlist) ::
  units