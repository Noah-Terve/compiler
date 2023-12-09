open Ast

let add_std_lib units = 
  (* make the print and println function for basic types, this  *)
  let print = {fname = "print"; typ = Int; formals = [(Templated("T"), "x")]; body = [Return(Literal(0))]; fun_t_list = ["T"]} in
  (* make the print functions for sets and lists *)
  (* let printset = 
    {typ = Int; fname = "print"; formals = [(Set(Templated("T")), "x")]; 
    body = [
    TemplatedCall("print", [String], [TemplatedCall("to_str", [String], [])]);
    Return(Literal(0))
    ]; 
    
    fun_t_list = ["T"]} in *)
  
  
    Fdecl(print) :: units