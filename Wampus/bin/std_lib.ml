open Ast

let add_std_lib units = 
  (* make the print and println function for basic types, this  *)
  let print = {fname = "print"; typ = Int; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in
  let println = {fname = "println"; typ = Int; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in

  (* print for 1st level lists *)
  let printlist = {fname = "printlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("print", [String], [StringLit("[")])); Expr(BindAssign(Bool, "started", BoolLit(false))); Expr(BindDec(Templated("T"), "elem")); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("l")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([Expr(Assign("elem", TemplatedCall("list_at", [Templated("T")], [Id("l"); Id("i")]))); If(Unop(Not, Id("started")), Block([Expr(TemplatedCall("print", [Templated("T")], [Id("elem")])); Expr(Assign("started", BoolLit(true)))]), Block([Expr(TemplatedCall("print", [String], [StringLit(", ")])); Expr(TemplatedCall("print", [Templated("T")], [Id("elem")]))]))])); Expr(TemplatedCall("print", [String], [StringLit("]")])); Return(Literal(0))]} in
  let printlnlist = {fname = "printlnlist"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(TemplatedCall("printlist", [Templated("T")], [Id("l")])); Expr(TemplatedCall("println", [String], [StringLit("")])); Return(Literal(0))]} in

  (* lists *)
  let list_insert = {fname = "list_insert"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos"); (Templated("T"), "data")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in
  let list_remove = {fname = "list_remove"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in
  let list_at = {fname = "list_at"; typ = Templated("T"); formals = [(List(Templated("T")), "l"); (Int, "pos")]; fun_t_list = ["T"]; body = [Expr(BindDec(Templated("T"), "x")); Return(Id("x"))]} in
  let list_length = {fname = "list_length"; typ = Int; formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Return(Literal(0))]} in
  let list_replace = {fname = "list_replace"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l"); (Int, "pos"); (Templated("T"), "data")]; fun_t_list = ["T"]; body = [Return(Id("l"))]} in

  let list_contains = {fname = "list_contains"; typ = Bool; formals = [(List(Templated("T")), "l"); (Templated("T"), "elem")]; fun_t_list = ["T"]; body = [For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("l")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([If(Binop(TemplatedCall("list_at", [Templated("T")], [Id("l"); Id("i")]), Equal, Id("elem")), Block([Return(BoolLit(true))]), Block([]))])); Return(BoolLit(false))]} in
  let list_copy = {fname = "list_copy"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(BindDec(List(Templated("T")), "new_list")); For(BindAssign(Int, "i", TemplatedCall("list_length", [Templated("T")], [Id("l")])), Binop(Id("i"), Geq, Literal(0)), Assign("i", Binop(Id("i"), Sub, Literal(1))), Block([Expr(TemplatedCall("list_insert", [Templated("T")], [Id("new_list"); Literal(0); TemplatedCall("list_at", [Templated("T")], [Id("l"); Id("i")])]))])); Return(Id("new_list"))]} in
  let isin = {fname = "isin"; typ = Bool; formals = [(List(Templated("T")), "s"); (Templated("T"), "elem")]; fun_t_list = ["T"]; body = [Return(TemplatedCall("list_contains", [Templated("T")], [Id("s"); Id("elem")]))]} in
  let set_of_list = {fname = "set_of_list"; typ = List(Templated("T")); formals = [(List(Templated("T")), "l")]; fun_t_list = ["T"]; body = [Expr(BindDec(List(Templated("T")), "s")); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("l")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([Expr(BindAssign(Templated("T"), "elem", TemplatedCall("list_at", [Templated("T")], [Id("l"); Id("i")]))); If(Unop(Not, TemplatedCall("isin", [Templated("T")], [Id("s"); Id("elem")])), Block([Expr(TemplatedCall("list_insert", [Templated("T")], [Id("s"); Literal(0); Id("elem")]))]), Block([]))])); Return(Id("s"))]} in
  let list_of_set = {fname = "list_of_set"; typ = List(Templated("T")); formals = [(List(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Return(TemplatedCall("set_of_list", [Templated("T")], [Id("s")]))]} in
  let set_add = {fname = "set_add"; typ = List(Templated("T")); formals = [(List(Templated("T")), "s"); (Templated("T"), "elem")]; fun_t_list = ["T"]; body = [Return(TemplatedCall("list_insert", [Templated("T")], [Id("s"); Literal(0); Id("elem")]))]} in
  let set_remove = {fname = "set_remove"; typ = List(Templated("T")); formals = [(List(Templated("T")), "s"); (Templated("T"), "elem")]; fun_t_list = ["T"]; body = [For(BindAssign(Int, "i", TemplatedCall("list_length", [Templated("T")], [Id("s")])), Binop(Id("i"), Geq, Literal(0)), Assign("i", Binop(Id("i"), Sub, Literal(1))), Block([If(Binop(TemplatedCall("list_at", [Templated("T")], [Id("s"); Id("i")]), Equal, Id("elem")), Block([Expr(TemplatedCall("list_remove", [Templated("T")], [Id("s"); Id("i")]))]), Block([]))])); Return(Id("s"))]} in
  let union = {fname = "union"; typ = List(Templated("T")); formals = [(List(Templated("T")), "s1"); (List(Templated("T")), "s2")]; fun_t_list = ["T"]; body = [Expr(BindDec(List(Templated("T")), "new_set")); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("s1")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([Expr(TemplatedCall("list_insert", [Templated("T")], [Id("new_set"); Literal(0); TemplatedCall("list_at", [Templated("T")], [Id("s1"); Id("i")])]))])); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("s2")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([Expr(TemplatedCall("list_insert", [Templated("T")], [Id("new_set"); Literal(0); TemplatedCall("list_at", [Templated("T")], [Id("s2"); Id("i")])]))])); Return(Id("new_set"))]} in
  let set_intersection = {fname = "set_intersection"; typ = List(Templated("T")); formals = [(List(Templated("T")), "s1"); (List(Templated("T")), "s2")]; fun_t_list = ["T"]; body = [Expr(BindDec(List(Templated("T")), "new_set")); For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("s1")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([If(TemplatedCall("list_contains", [Templated("T")], [Id("s2"); TemplatedCall("list_at", [Templated("T")], [Id("s1"); Id("i")])]), Block([Expr(TemplatedCall("list_insert", [Templated("T")], [Id("new_set"); Literal(0); TemplatedCall("list_at", [Templated("T")], [Id("s1"); Id("i")])]))]), Block([]))])); Return(Id("new_set"))]} in
  let set_size = {fname = "set_size"; typ = Int; formals = [(List(Templated("T")), "s")]; fun_t_list = ["T"]; body = [Return(TemplatedCall("list_length", [Templated("T")], [TemplatedCall("set_of_list", [Templated("T")], [Id("s")])]))]} in
  let set_superset = {fname = "set_superset"; typ = Bool; formals = [(List(Templated("T")), "s1"); (List(Templated("T")), "s2")]; fun_t_list = ["T"]; body = [For(BindAssign(Int, "i", Literal(0)), Binop(Id("i"), Less, TemplatedCall("list_length", [Templated("T")], [Id("s2")])), Assign("i", Binop(Id("i"), Add, Literal(1))), Block([If(Unop(Not, TemplatedCall("list_contains", [Templated("T")], [Id("s1"); TemplatedCall("list_at", [Templated("T")], [Id("s2"); Id("i")])])), Block([Return(BoolLit(false))]), Block([]))])); Return(BoolLit(true))]} in
  let set_subset = {fname = "set_subset"; typ = Bool; formals = [(List(Templated("T")), "s1"); (List(Templated("T")), "s2")]; fun_t_list = ["T"]; body = [Return(TemplatedCall("set_superset", [Templated("T")], [Id("s2"); Id("s1")]))]} in
  let set_equals = {fname = "set_equals"; typ = Bool; formals = [(List(Templated("T")), "s1"); (List(Templated("T")), "s2")]; fun_t_list = ["T"]; body = [If(TemplatedCall("set_superset", [Templated("T")], [Id("s1"); Id("s2")]), Block([If(Binop(TemplatedCall("set_size", [Templated("T")], [Id("s1")]), Equal, TemplatedCall("set_size", [Templated("T")], [Id("s2")])), Block([Return(BoolLit(true))]), Block([]))]), Block([])); Return(BoolLit(false))]} in

  Fdecl(print) :: Fdecl(println) :: 
  Fdecl(list_insert) :: Fdecl(list_remove) ::
  Fdecl(list_at) :: Fdecl(list_length) :: Fdecl(list_replace) ::  
  Fdecl(printlist) :: Fdecl(printlnlist) :: Fdecl(list_contains) :: 
  Fdecl(list_copy) :: Fdecl(isin) :: Fdecl(set_of_list) :: 
  Fdecl(list_of_set) :: Fdecl(set_add) :: Fdecl(set_remove) :: 
  Fdecl(union) :: Fdecl(set_intersection) :: Fdecl(set_size) ::
  Fdecl(set_superset) :: Fdecl(set_subset) :: Fdecl(set_equals) ::
  units