open Ast

let add_std_lib units = 
  (* make the print function for basic types, this  *)
  let print = {typ = Int; fname = "print"; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in
  Fdecl(print) :: units