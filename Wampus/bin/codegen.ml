(* Code generation: translate takes a semantically checked AST and
produces LLVM IR

LLVM tutorial: Make sure to read the OCaml version of the tutorial

http://llvm.org/docs/tutorial/index.html

Detailed documentation on the OCaml LLVM library:

http://llvm.moe/
http://llxvm.moe/ocaml/

*)

(* We'll refer to Llvm and Ast constructs with module names *)
module L = Llvm
module A = Ast
open Sast

module StringMap = Map.Make(String)

(* Code Generation from the SAST. Returns an LLVM module if successful,
   throws an exception if something is wrong. *)
let translate program =
  let main_function = 
    { styp = A.Int;
      sfname = "main";
      sformals = []; (* TODO: Remove formals from funcitons; use environment instead *)
      slocals = []; (* TODO: Remove locals from functions; use environment instead*)
      sbody = List.rev (List.fold_left (fun acc units -> match units with 
                                SStmt struc -> struc :: acc 
                                | _ -> acc) [] program);} in

  let context    = L.global_context () in
  (* Add types to the context so we can use them in our LLVM code *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context
  and float_t    = L.double_type context
  (* Types for representation of lists  *)
  and voidptr_t  = L.pointer_type (L.i8_type context) 
  and nodeptr_t  = L.pointer_type (L.named_struct_type context "Node")  
  let list_t     = L.pointer_type (L.struct_type context [| voidptr_t; nodeptr_t |]) in 


  
  (* Create an LLVM module -- this is a "container" into which we'll 
    generate actual code *)
  and the_module = L.create_module context "Wampus" 
  and pointer_t = L.pointer_type in

  (* Convert MicroC types to LLVM types *)
  let ltype_of_typ = function
      A.Int   -> i32_t
    | A.Bool  -> i1_t
    | A.Float -> float_t
    | A.Char  -> i8_t
    | A.String -> pointer_t i8_t
    | A.ListExplicit _ -> list_t
    | _ -> raise (Failure "types not implemented yet")
  in

  (* Extract global variables from main, declaring them, in essense. This means
      that all variables declared in main will be global variables. Since they
      are being declared here, we also convert all bindassigs to assignments,
      etc. main just uses the global environment as its local environment. *)
  let parse_main_statements sstmts =
    let parse_toplevel_statement (sstmts, global_vars) sstmt = match sstmt with
        SExpr (_t, s) -> (match s with
            SBindDec (t, n) -> (sstmts, StringMap.add n (L.define_global n (L.const_int (ltype_of_typ t) 0) the_module) global_vars)
          | SBindAssign (t, n, e) ->
              let global_vars = StringMap.add n (L.define_global n (L.const_int (ltype_of_typ t) 0) the_module) global_vars in
              let e = (t, SAssign (n, e)) in
              ((SExpr e) :: sstmts, global_vars)
          | _ -> (sstmt :: sstmts, global_vars))
      | _ -> (sstmt :: sstmts, global_vars)
    in
    let global_vars = StringMap.empty in
    let (sstmts, global_vars) = List.fold_left parse_toplevel_statement ([], global_vars) sstmts in
    (List.rev sstmts, global_vars)
  in

  (* Update mains sbody and get the global vars *)
  let (main_function_stmts, global_vars) = parse_main_statements main_function.sbody in
  let main_function = { main_function with sbody = main_function_stmts } in

  (* Gather all the functions *)
  let functions =
    List.rev (List.fold_left (fun acc units -> match units with 
                                  SFdecl func -> func :: acc
                                | _ -> acc)
                [main_function] program) in

  (* let global_vars : L.llvalue StringMap.t ref = ref StringMap.empty in *)
  let global_vars : L.llvalue StringMap.t ref = ref global_vars in

  (* Print all the global variable names *)
  (* let _ = StringMap.iter (fun name _ -> Printf.fprintf stderr "global var: %s\n" name) !global_vars in *)

  (* Define each function (arguments and return type) so we can 
   * define it's body and call it later *)

  let printf_t : L.lltype = 
      L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue = 
     L.declare_function "printf" printf_t the_module in

  (* let printbig_t = L.function_type i32_t [| i32_t |] in
  let printbig_func = L.declare_function "printbig" printbig_t the_module in *)

  (* Define each function (arguments and return type) so we can 
   * define it's body and call it later *)
  let function_decls : ((L.llvalue * sfunc_decl) StringMap.t) =
    (* let _ = Printf.fprintf stderr "generating code for function\n" in *)
    let function_decl m fdecl =
      let name = fdecl.sfname in
      (* print name to stderr *)
      (* let _ = Printf.fprintf stderr "generating code for %s\n" name in *)
      let formal_types = 
        Array.of_list (List.map (fun (t, _) -> ltype_of_typ t) fdecl.sformals)
      in let ftype = L.function_type (ltype_of_typ fdecl.styp) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    (* let _ = Printf.fprintf stderr "generating code for function body\n" in *)
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in
    
    let int_format_str = L.build_global_stringptr "%d" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g" "fmt" builder 
    and string_format_str = L.build_global_stringptr "%s" "fmt" builder 
    and char_format_str = L.build_global_stringptr "%c" "fmt" builder in

    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
          (* let _ = Printf.fprintf stderr "Adding formals\n" in *)
          let add_formal m (t, n) p = 
            let () = L.set_value_name n p in
              let local = L.build_alloca (ltype_of_typ t) n builder in
                let _  = L.build_store p local builder in
                  StringMap.add n local m 
          in

          (* Allocate space for any locally declared variables and add the
          * resulting registers to our map *)
          let add_local m (t, n) =
            let local_var = L.build_alloca (ltype_of_typ t) n builder
              in StringMap.add n local_var m 
          in
          let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals (Array.to_list (L.params the_function)) in 
            
          (* let _ = Printf.fprintf stderr "checking if added after formals: %b s \n" (StringMap.is_empty (formals)) in *)
            (* let _ = StringMap.iter (fun k v -> Printf.fprintf stderr "Adding key: %s\n" k) formals in  *)

          List.fold_left add_local formals fdecl.slocals in
  (* let _ = Printf.fprintf stderr "**** checking if added after formals: %b s \n" (StringMap.is_empty (List.hd envs)) in *) 
    let (envs : L.llvalue StringMap.t list) = [local_vars] in
    (* Return the value for a variable or formal argument. First check
     * locals, then globals *)
    (* let lookup n = try StringMap.find n local_vars
                   with Not_found -> StringMap.find n global_vars
    in *)
    let rec lookup n (envs: L.llvalue StringMap.t list) = 
      match envs with
        [] -> (try StringMap.find n !global_vars
             with Not_found -> raise (Failure ("Internal error: Semant should have rejected variable " ^ n ^ " in function " ^ fdecl.sfname)))
      | env :: rest -> try StringMap.find n env
                       with Not_found -> lookup n rest
    in
    (* Adds the mapping n : value into the current environment *)
    let bind n v (envs: L.llvalue StringMap.t list) = 
      match envs with
        [] -> raise (Failure ("Internal error: no environment to bind variable in"))
      | env :: rest -> (StringMap.add n v env) :: rest
    in

    (* Construct code for an expression; return its value *)
    let rec getLit = function
          (_, SCharlit l) -> (String.make 1 l)
        | (_, SStringlit s) -> s
        | (t, sx) -> getLit (t, sx) in
    let rec expr builder ((_, e) : sexpr) (envs: L.llvalue StringMap.t list) = match e with
        SLiteral i -> (L.const_int i32_t i, envs)
      | SBoolLit b -> (L.const_int i1_t (if b then 1 else 0), envs)
      | SFliteral l -> (L.const_float_of_string float_t l, envs)
      | SCharlit c  -> (L.const_int i8_t (int_of_char c), envs)
      | SStringlit s -> (L.build_global_stringptr s "string" builder, envs)
      | SNoexpr -> (L.const_int i32_t 0, envs)
      | SId s -> (L.build_load (lookup s envs) s builder, envs)
      | SBinop (e1, op, e2) ->
        let (t1, expr1) = e1 in
        let (t2, expr2) = e2 in
        let (e1', envs) = expr builder e1 envs in
        let (e2', envs) = expr builder e2 envs in
        
        if (t1 = A.Float || t2 = A.Float) then ((match op with 
            A.Add     -> L.build_fadd
          | A.Sub     -> L.build_fsub
          | A.Mult    -> L.build_fmul
          | A.Div     -> L.build_fdiv 
          | A.Equal   -> L.build_fcmp L.Fcmp.Oeq
          | A.Neq     -> L.build_fcmp L.Fcmp.One
          | A.Less    -> L.build_fcmp L.Fcmp.Olt
          | A.Leq     -> L.build_fcmp L.Fcmp.Ole
          | A.Greater -> L.build_fcmp L.Fcmp.Ogt
          | A.Geq     -> L.build_fcmp L.Fcmp.Oge
          | A.And | A.Or ->
              raise (Failure "Internal error: semant should have rejected and/or on float")
          | _ -> raise (Failure ("unimplemented float binop: " ^ (A.string_of_op op)))
          ) (L.build_sitofp e1' float_t "ItoF" builder) (L.build_sitofp e2' float_t "ItoF" builder) "tmp" builder, envs)
        else if (op = A.Add && (t1 = A.String || t1 = A.Char)) then 
          let s1 = getLit (t1, expr1) in
          let s2 = getLit (t1, expr2) in
          let s = s1 ^ s2 in
          (L.build_global_stringptr s "string" builder, envs)
        else (match op with
            A.Add     -> L.build_add
          | A.Sub     -> L.build_sub
          | A.Mult    -> L.build_mul
          | A.Div     -> L.build_sdiv
          | A.Mod     -> L.build_srem
          | A.And     -> L.build_and
          | A.Or      -> L.build_or
          | A.Equal   -> L.build_icmp L.Icmp.Eq
          | A.Neq     -> L.build_icmp L.Icmp.Ne
          | A.Less    -> L.build_icmp L.Icmp.Slt
          | A.Leq     -> L.build_icmp L.Icmp.Sle
          | A.Greater -> L.build_icmp L.Icmp.Sgt
          | A.Geq     -> L.build_icmp L.Icmp.Sge
          | _ -> raise (Failure ("unimplemented binop: " ^ (A.string_of_op op)))
        ) e1' e2' "tmp" builder, envs
      | SUnop(op, e) ->
          let (t, _) = e in
          let (e', envs) = expr builder e envs in
          (match op with
            A.Neg when t = A.Float -> (L.build_fneg e' "tmp" builder, envs)
          | A.Neg                  -> (L.build_neg e' "tmp" builder, envs)
          | A.Not                  -> (L.build_not e' "tmp" builder, envs)
          )
      | SCall ("_print.int", [e]) | SCall ("_print.bool", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| int_format_str ; e_llvalue |] "printf" builder, envs)
        
    (* | SCall ("printbig", [e]) ->
      L.build_call printbig_func [| (expr builder e) |] "printbig" builder *)
      | SCall ("_print.string", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| string_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("_print.char", [e]) -> 
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| char_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("_print.float", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| float_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall (f, args) ->
          let (fdef, fdecl) = StringMap.find f function_decls in
          let (llargs, envs) = List.fold_left (fun (llargs, envs) (t, e) -> 
            let (e', envs) = expr builder (t, e) envs in
            (e' :: llargs, envs)) ([], envs) args in
          let result = (A.string_of_typ fdecl.styp) ^ "result" in

          (* (L.build_call fdef (Array.of_list llargs) result builder, envs) *)
          (L.build_call fdef (Array.of_list (List.rev llargs)) result builder, envs)
      (* | SBindDec (t, n) -> (L.const_int (ltype_of_typ t) 0, bind n (L.const_int (ltype_of_typ t) 0) envs) *)
      | SBindDec (t, n) ->
          (* let _ = Printf.fprintf stderr "generating code for binding %s\n" n in *)
          let local_var = L.build_alloca (ltype_of_typ t) n builder in
          (L.const_int (ltype_of_typ t) 0, bind n local_var envs)
          
      | SAssign (var_name, e) ->
          let (value_to_assign, envs) = expr builder e envs in
          let _ = L.build_store value_to_assign (lookup var_name envs) builder in
          (value_to_assign, envs)
      | SBindAssign (t, var_name, e) ->
          let (_, envs) = expr builder (t, SBindDec (t, var_name)) envs in
          expr builder (t, SAssign (var_name, e)) envs

          (* let rec expr builder ((_, e) : sexpr) (envs: L.llvalue StringMap.t list) = match e with *)
      | SListExplicit l -> 
          let (llvals, envs) = List.fold_left 
                  (fun (list_accum, envs') sex =   
                      let (llval, envs'') = expr builder sex envs'

                  ([], envs)



      | _ -> raise (Failure ("expr in codegen not implemented yet (ignore type): " ^ (string_of_sexpr (A.Int, e))))
    in
    
    (* Each basic block in a program ends with a "terminator" instruction i.e.
    one that ends the basic block. By definition, these instructions must
    indicate which basic block comes next -- they typically yield "void" value
    and produce control flow, not values *)
    (* Invoke "instr builder" if the current block doesn't already
       have a terminator (e.g., a branch). *)
    let add_terminal builder instr =
                           (* The current block where we're inserting instr *)
      match L.block_terminator (L.insertion_block builder) with
        Some _ -> ()
      | None -> ignore (instr builder) in
  
    (* Build the code for the given statement; return the builder for
       the statement's successor (i.e., the next instruction will be built
       after the one generated by this call) *)
    (* Imperative nature of statement processing entails imperative OCaml *)
    let rec stmt builder s (envs: L.llvalue StringMap.t list) loop_list = match s with
        SExpr e -> let (_, envs) = expr builder e envs in (builder, envs)

      (* | SBlock sl -> List.fold_left stmt builder sl *)
      (* A block should create a new temporary environment for its statements *)
      (* The created environment is discarded at the end *)
      | SBlock sl ->
          let envs' = StringMap.empty :: envs in
          let (builder, _) = List.fold_left (fun (builder, envs) s -> stmt builder s envs loop_list) 
                                (builder, envs') sl in
          (builder, envs)
      (* | SBlock sl ->
          let rec stmt_list builder cur_vars' sl = match sl with
              []  -> (cur_vars', builder)
            | [s] -> let (builder, cur_vars') = stmt builder cur_vars' s in
                        (cur_vars', builder)
            | s :: the_rest -> let (cur_vars', builder) = stmt builder cur_vars' s in
                stmt_list builder cur_vars' the_rest
          in
          stmt_list builder cur_vars sl *)

          (* Generate code for this expression, return resulting builder *)
      | SReturn e -> let _ = 
          let (e_llvalue, _envs) = expr builder e envs in
          L.build_ret e_llvalue builder in (builder, envs)

        
    
      (* The order that we create and add the basic blocks for an If statement
      doesnt 'really' matter (seemingly). What hooks them up in the right order
      are the build_br functions used at the end of the then and else blocks (if
      they don't already have a terminator) and the build_cond_br function at
      the end, which adds jump instructions to the "then" and "else" basic blocks *)
      | SIf (predicate, then_stmt, else_stmt) ->
        let (bool_val, envs) = expr builder predicate envs in
          (* Add "merge" basic block to our function's list of blocks *)
        let merge_bb = L.append_block context "merge" the_function in
          (* Partial function used to generate branch to merge block *) 
        let branch_instr = L.build_br merge_bb in

          (* Same for "then" basic block *)
        let then_bb = L.append_block context "then" the_function in
          (* Position builder in "then" block and build the statement *)
        let (then_builder, envs) = stmt (L.builder_at_end context then_bb) then_stmt envs loop_list in
          (* Add a branch to the "then" block (to the merge block) 
            if a terminator doesn't already exist for the "then" block *)
        let () = add_terminal then_builder branch_instr in

          (* Identical to stuff we did for "then" *)
        let else_bb = L.append_block context "else" the_function in
        let (else_builder, envs) = stmt (L.builder_at_end context else_bb) else_stmt envs loop_list in
        let () = add_terminal else_builder branch_instr in

          (* Generate initial branch instruction perform the selection of "then"
          or "else". Note we're using the builder we had access to at the start
          of this alternative. *)
        let _ = L.build_cond_br bool_val then_bb else_bb builder in
          (* Move to the merge block for further instruction building *)
        (L.builder_at_end context merge_bb, envs)

      | SWhile (predicate, body) ->
        (* First create basic block for condition instructions -- this will
        serve as destination in the case of a loop *)
        let pred_bb = L.append_block context "while" the_function in
        (* In current block, branch to predicate to execute the condition *)
        let _ = L.build_br pred_bb builder in
        let merge_bb = L.append_block context "merge" the_function in
        (* Create the body's block, generate the code for it, and add a branch
        back to the predicate block (we always jump back at the end of a while
        loop's body, unless we returned or something) *)
        let body_bb = L.append_block context "while_body" the_function in
        let (while_builder, envs) = stmt (L.builder_at_end context body_bb) body envs ((pred_bb, merge_bb) :: loop_list) in
        let () = add_terminal while_builder (L.build_br pred_bb) in

        (* Generate the predicate code in the predicate block *)
        let pred_builder = L.builder_at_end context pred_bb in
        let (bool_val, envs) = expr pred_builder predicate envs in

        (* Hook everything up *)
        let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
        (L.builder_at_end context merge_bb, envs)

      (* Implement for loops as while loops! *)
      | SFor (e1, e2, e3, body) -> stmt builder 
      ( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] ) envs loop_list
      | SContinue -> let () = add_terminal builder (L.build_br (fst (List.hd loop_list))) in (builder, envs)
      | SBreak -> let () = add_terminal builder (L.build_br (snd (List.hd loop_list))) in (builder, envs)
      | a -> raise (Failure ("stmt not implemented yet: " ^ (string_of_sstmt a)))
    in

    (* Build the code for each statement in the function *)
    (* let builder = stmt builder (SBlock fdecl.sbody) in *)
    (* Note: envs is returned because we need to consider variable assignment *)
    let (builder, _envs) = stmt builder (SBlock fdecl.sbody) envs [] in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.styp with
        A.Float -> L.build_ret (L.const_float float_t 0.0)
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module