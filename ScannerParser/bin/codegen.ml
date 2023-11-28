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
                                | _ -> acc) [] program);
      sfun_t_list = []} in (* TODO: templates are resolved BEFORE semant + codegen, so this is useless *)

  let context    = L.global_context () in
  (* Add types to the context so we can use them in our LLVM code *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context
  and float_t    = L.double_type context
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
    | _ -> raise (Failure "types not implemented yet")
  in

  (* Extract global variables from main, declaring them, in essense. This means
      that all variables declared in main will be global variables. Since they
      are being declared here, we also convert all bindassigs to assignments,
      etc. main just uses the global environment as its local environment. *)
  let parse_main_statements sstmts =
    let parse_statement (sstmts, global_vars) sstmt = match sstmt with
        SExpr (t, s) -> (match s with
            SBindDec (t, n) -> (sstmts, StringMap.add n (L.define_global n (L.const_int (ltype_of_typ t) 0) the_module) global_vars)
          | SBindAssign (t, n, e) ->
              let global_vars = StringMap.add n (L.define_global n (L.const_int (ltype_of_typ t) 0) the_module) global_vars in
              let e = (t, SAssign (n, e)) in
              ((SExpr e) :: sstmts, global_vars)
          | _ -> (sstmt :: sstmts, global_vars))
      | _ -> (sstmt :: sstmts, global_vars)
    in
    let global_vars = StringMap.empty in
    let (sstmts, global_vars) = List.fold_left parse_statement ([], global_vars) sstmts in
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

  (* Declare each global variable; remember its value in a map *)
  (* let global_vars : L.llvalue StringMap.t =
    let global_var m (t, n) = 
      let init = match t with
          A.Float -> L.const_float (ltype_of_typ t) 0.0
        | _ -> L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in *)
  (* How variable scoping works:
     In Wampus, any function will have access to its local variables (which
    includes variables declared in the function and any formal parameters), and
    all global variables, which are those accessible from the global scope.
    
    To manage scope, we create two separate environments: one for globals and
    one for locals. Each environment is a list of maps, where each map is a 
    mapping from variable names to their corresponding LLVM values (llvalues).
    The first map in the list is the innermost scope, and the last map is the
    outermost scope (which typically contains function parameters). When we
    look up a variable, we first look in the local environment, and if it's not
    there, we look in the global environment. Within an environment, we look up
    variables in the innermost scope first, and then work our way outwards.
    
    New scopes are created when we enter a new block (e.g. an if's body), and
    are discarded when we leave the block. This means that we can shadow
    variables in inner scopes, and that we can't access variables from outer
    scopes once we leave them. This is the behavior we want.

    The reason we use a list of maps instead of a single map is because we want
    to be able to shadow variables in inner scopes. If we used a single map,
    then we would have to remove the variable from the map when we leave the
    scope, which would be a pain. Instead, we just discard the map when we
    leave the scope, and the variable is no longer accessible.

    Because Wampus doesn't have a true "main" function, it is a little tricky
    to handle global variables, especially since LLVM requires a main function.
    Instead, all statements in the global scope are treated as if
    they were in the main function. If treated as a normal function, this would
    mean that all global variables would be local variables, and would not be
    accessible from other functions. To get around this, we make `main` a
    special function that uses the global environment as its local environment.
    *)
  (* ref *)
  (* let global_vars : L.llvalue StringMap.t ref = ref StringMap.empty in *)
  let global_vars : L.llvalue StringMap.t ref = ref global_vars in

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
  let function_decls : (L.llvalue * sfunc_decl) StringMap.t =
    let function_decl m fdecl =
      let name = fdecl.sfname
      and formal_types = 
        Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.sformals)
      in let ftype = L.function_type (ltype_of_typ fdecl.styp) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let envs : L.llvalue StringMap.t list = [StringMap.empty] in
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in
    
    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g\n" "fmt" builder 
    and string_format_str = L.build_global_stringptr "%s\n" "fmt" builder 
    and char_format_str = L.build_global_stringptr "%c\n" "fmt" builder in

    let local_vars =
      let add_formal m (t, n) p =
        let () = L.set_value_name n p in
        let local = L.build_alloca (ltype_of_typ t) n builder in
        let _ = L.build_store p local builder in
        StringMap.add n local m
      in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals 
          (Array.to_list (L.params the_function)) in
      formals
    in

    let add_local (t, n) builder cur_vars =
      let local_var = L.build_alloca (ltype_of_typ t) n builder in
      StringMap.add n local_var cur_vars
    in

    let lookup n cur_vars =
      try StringMap.find n cur_vars
        with Not_found -> try StringMap.find n !global_vars
          with Not_found -> raise (Failure ("Internal error: Semant should have rejected variable " ^ n ^ " in function " ^ fdecl.sfname))
    in


    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    (* THIS LINE NEEDS TO BE UNCOMMENTED TO ADD BACK IN LOCAL VARS
       NOT NEEDED NOW, REMOVING TO REMOVE UNUSED VAR WARNING
       let local_vars = *)
    let _ =
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
        in StringMap.add n local_var m in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.slocals in

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

    let bind n v (envs: L.llvalue StringMap.t list) = 
      match envs with
        [] -> raise (Failure ("Internal error: no environment to bind variable in"))
      | env :: rest -> (StringMap.add n v env) :: rest
    in

    (* Construct code for an expression; return its value *)
    let convert_to_float (t, e) = (if t = A.Int || t = A.Char then L.build_sitofp e float_t "ItoF" builder else e) in

    let rec expr builder ((_, e) : sexpr) (envs: L.llvalue StringMap.t list) = match e with
        SLiteral i -> (L.const_int i32_t i, envs)
      | SBoolLit b -> (L.const_int i1_t (if b then 1 else 0), envs)
      | SFliteral l -> (L.const_float_of_string float_t l, envs)
      | SCharlit c  -> (L.const_int i8_t (int_of_char c), envs)
      | SStringlit s -> (L.build_global_stringptr s "string" builder, envs)
      | SNoexpr -> (L.const_int i32_t 0, envs)
      | SId s -> (L.build_load (lookup s envs) s builder, envs)
      | SBinop (e1, op, e2) ->
        let (t1, _) = e1 in
        let (t2, _) = e2 in
        let (e1', envs) = expr builder e1 envs in
        let (e2', envs) = expr builder e2 envs in
        
        if (t1 = A.Float || t2 = A.Float) then (match op with 
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
          (* | A.Pluseq  -> expr builder SAssign(e, ) *)
          | A.And | A.Or ->
              raise (Failure "Internal error: semant should have rejected and/or on float")
          | _ -> raise (Failure "not implemented yet")
          ) e1' e2' "tmp" builder, envs
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
          | _ -> raise (Failure "not implemeneted yet")
        ) e1' e2' "tmp" builder, envs
      | SUnop(op, e) ->
          let (t, _) = e in
          let (e', envs) = expr builder e envs in
          (match op with
            A.Neg when t = A.Float -> (L.build_fneg e' "tmp" builder, envs)
          | A.Neg                  -> (L.build_neg e' "tmp" builder, envs)
          | A.Not                  -> (L.build_not e' "tmp" builder, envs)
          )
      | SCall ("printi", [e]) | SCall ("printb", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| int_format_str ; e_llvalue |] "printf" builder, envs)
        
    (* | SCall ("printbig", [e]) ->
      L.build_call printbig_func [| (expr builder e) |] "printbig" builder *)
      | SCall ("prints", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| string_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("printc", [e]) -> 
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| char_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("printf", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| float_format_str ; e_llvalue |] "printf" builder, envs)
      (* | SCall (f, args) ->
         let (fdef, fdecl) = StringMap.find f function_decls in
   let llargs = List.rev (List.map (expr builder) (List.rev args)) in
   let result = (match fdecl.styp with 
                        A.Void -> ""
                      | _ -> f ^ "_result") in
         L.build_call fdef (Array.of_list llargs) result builder *)
      | SBindDec (t, n) -> (L.const_int (ltype_of_typ t) 0, bind n (L.const_int (ltype_of_typ t) 0) envs)
      | SAssign (var_name, e) ->
          let (value_to_assign, envs) = expr builder e envs in
          let _ = L.build_store value_to_assign (lookup var_name envs) builder in
          (value_to_assign, envs)
      | SBindAssign (t, var_name, e) ->
          let (_, envs) = expr builder (t, SBindDec (t, var_name)) envs in
          expr builder (t, SAssign (var_name, e)) envs
      | _ -> raise (Failure "Codegen: expr not implemented yet")
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
    let rec stmt builder s (envs: L.llvalue StringMap.t list) = match s with
        SExpr e -> let (_, envs) = expr builder e envs in (builder, envs)

      (* | SBlock sl -> List.fold_left stmt builder sl *)
      (* A block should create a new temporary environment for its statements *)
      (* The created environment is discarded at the end *)
      | SBlock sl ->
          let envs' = StringMap.empty :: envs in
          let (builder, _) = List.fold_left (fun (builder, envs) s -> stmt builder s envs) 
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
          let (e_llvalue, envs) = expr builder e envs in
          L.build_ret e_llvalue builder in (builder, envs)

        
    (*
      (* The order that we create and add the basic blocks for an If statement
      doesnt 'really' matter (seemingly). What hooks them up in the right order
      are the build_br functions used at the end of the then and else blocks (if
      they don't already have a terminator) and the build_cond_br function at
      the end, which adds jump instructions to the "then" and "else" basic blocks *)
      | SIf (predicate, then_stmt, else_stmt) ->
         let bool_val = expr builder predicate in
         (* Add "merge" basic block to our function's list of blocks *)
   let merge_bb = L.append_block context "merge" the_function in
         (* Partial function used to generate branch to merge block *) 
         let branch_instr = L.build_br merge_bb in

         (* Same for "then" basic block *)
   let then_bb = L.append_block context "then" the_function in
         (* Position builder in "then" block and build the statement *)
         let then_builder = stmt (L.builder_at_end context then_bb) then_stmt in
         (* Add a branch to the "then" block (to the merge block) 
           if a terminator doesn't already exist for the "then" block *)
   let () = add_terminal then_builder branch_instr in

         (* Identical to stuff we did for "then" *)
   let else_bb = L.append_block context "else" the_function in
         let else_builder = stmt (L.builder_at_end context else_bb) else_stmt in
   let () = add_terminal else_builder branch_instr in

         (* Generate initial branch instruction perform the selection of "then"
         or "else". Note we're using the builder we had access to at the start
         of this alternative. *)
   let _ = L.build_cond_br bool_val then_bb else_bb builder in
         (* Move to the merge block for further instruction building *)
   L.builder_at_end context merge_bb

      | SWhile (predicate, body) ->
          (* First create basic block for condition instructions -- this will
          serve as destination in the case of a loop *)
    let pred_bb = L.append_block context "while" the_function in
          (* In current block, branch to predicate to execute the condition *)
    let _ = L.build_br pred_bb builder in

          (* Create the body's block, generate the code for it, and add a branch
          back to the predicate block (we always jump back at the end of a while
          loop's body, unless we returned or something) *)
    let body_bb = L.append_block context "while_body" the_function in
          let while_builder = stmt (L.builder_at_end context body_bb) body in
    let () = add_terminal while_builder (L.build_br pred_bb) in

          (* Generate the predicate code in the predicate block *)
    let pred_builder = L.builder_at_end context pred_bb in
    let bool_val = expr pred_builder predicate in

          (* Hook everything up *)
    let merge_bb = L.append_block context "merge" the_function in
    let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
    L.builder_at_end context merge_bb

      (* Implement for loops as while loops! *)
      | SFor (e1, e2, e3, body) -> stmt builder
      ( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] ) *)
      | a -> raise (Failure ("stmt not implemented yet: " ^ (string_of_sstmt a)))
    in

    (* Build the code for each statement in the function *)
    (* let builder = stmt builder (SBlock fdecl.sbody) in *)
    (* Note: envs is returned because we need to consider variable assignment *)
    let (builder, envs) = stmt builder (SBlock fdecl.sbody) envs in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.styp with
        A.Float -> L.build_ret (L.const_float float_t 0.0)
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module
