(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon
*)

(* Toplevel driver for Wampus *)

type action = Ast | Std | DeTemp | Sast | LLVM_IR | Compile |
              AstInfo | StdInfo | DeTempInfo 

let () =
  let action = ref Compile in
  let set_action a () = action := a in
  let speclist = [
    ("-a", Arg.Unit (set_action Ast), "Print the AST");
    ("-std", Arg.Unit (set_action Std), "Print the AST with the standard library");
    ("-d", Arg.Unit (set_action DeTemp), "Print the detemplated AST");
    ("-ai", Arg.Unit (set_action AstInfo), "Print the AST with detailed info");
    ("-stdi", Arg.Unit (set_action StdInfo), "Print the AST with the standard library with detailed info");
    ("-di", Arg.Unit (set_action DeTempInfo), "Print the detemplated AST with detailed info");
    ("-s", Arg.Unit (set_action Sast), "Print the SAST");
    ("-l", Arg.Unit (set_action LLVM_IR), "Print the generated LLVM IR");
    ("-c", Arg.Unit (set_action Compile),
      "Check and print the generated LLVM IR (default)");
  ] in
  let usage_msg = "usage: ./_build/default/bin/toplevel.exe [flag] [file.mc]" in
  let channel = ref stdin in
  Arg.parse speclist (fun filename -> channel := open_in filename) usage_msg;

  let lexbuf = Lexing.from_channel !channel in
  let ast = Parser.program Scanner.token lexbuf in
  let ast_std = Std_lib.add_std_lib ast in
  let detemp = Detemplate.detemplate ast_std in
  match !action with
    Ast -> print_string (Ast.string_of_program ast)
  | Std -> print_string (Ast.string_of_program ast_std)
  | DeTemp -> print_string (Ast.string_of_program detemp)
  | AstInfo -> print_string (Ast.info_of_program ast)
  | StdInfo -> print_string (Ast.info_of_program ast_std)
  | DeTempInfo -> print_string (Ast.info_of_program detemp)
  | _ -> let sast = Semant.check detemp in
    match !action with
      Sast    -> print_string (Sast.string_of_sprogram sast)
    | LLVM_IR -> print_string (Llvm.string_of_llmodule (Codegen.translate sast))
    | Compile -> let m = Codegen.translate sast in
                 Llvm_analysis.assert_valid_module m;
                 print_string (Llvm.string_of_llmodule m)
    | _ -> ()