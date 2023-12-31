(* 
    Authors: Neil Powers, Christopher Sasanuma, Haijun Si, Noah Tervalon

    Code generation: translate takes a semantically checked AST and
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

(* Builds a malloc instruction for a given llvalue *)
let build_malloc builder llvalue = 
  let heap = L.build_malloc (L.type_of llvalue) "heap" builder in
  let _    = L.build_store llvalue heap builder in heap

let get_float_lbinop op = match op with
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

let get_int_lbinop op = match op with
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

let get_string_binop op = match op with 
    A.Equal -> L.build_icmp L.Icmp.Eq
  | A.Neq -> L.build_icmp L.Icmp.Ne
  | _ -> raise (Failure ("unimplemented binop: " ^ (A.string_of_op op)))

(* Code Generation from the SAST. Returns an LLVM module if successful,
   throws an exception if something is wrong. *)
let translate program =

  (*** Top level main function that contains top level statements ***)
  let main_function = 
    { styp = A.Int;
      sfname = "main";
      sformals = [];
      slocals = [];
      sbody = List.rev (List.fold_left (fun acc units -> match units with 
                                SStmt struc -> struc :: acc 
                                | _ -> acc) [] program);} in
  let struct_decls =
    List.fold_left (fun acc units -> 
                      match units with 
                      SSdecl struc -> StringMap.add struc.sname struc.ssformals acc
                      | _ -> acc) 
                        StringMap.empty program in

          

  (*  Creates the one context that will be used throughout the translation function *)
  let context    = L.global_context () in
  (* let main_builder = L.builder context in *)

  (* Add types to the context so we can use them in our LLVM code *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context
  and float_t    = L.double_type context
  and struct_t   = L.named_struct_type context
  and str_t      = L.pointer_type (L.i8_type context)
  and voidptr_t  = L.pointer_type (L.i8_type context) in
  let nodeptr_t  = L.pointer_type (L.named_struct_type context "Node") in
  let list_t     = L.pointer_type (L.struct_type context [| voidptr_t; nodeptr_t |]) in
  
  (* Create an LLVM module -- this is a "container" into which we'll 
    generate actual code *)
  let the_module = L.create_module context "Wampus" in
  let pointer_t = L.pointer_type in
  (* Creating a map of structs *)
  let struct_types =
    let make_empty_struct name _ = struct_t name in
    StringMap.mapi make_empty_struct struct_decls
  in 

  (* Convert MicroC types to LLVM types *)
  let ltype_of_typ = function
      A.Int   -> i32_t
    | A.Bool  -> i1_t
    | A.Float -> float_t
    | A.Char  -> i8_t
    | A.String -> str_t
    | A.Struct(s) -> (try pointer_t (StringMap.find s struct_types)
      with _ -> raise (Failure (s ^ " is not a valid struct type")))
    | A.List _ -> list_t
    | _ -> raise (Failure "types not implemented yet")
  in

  let ltype_of_ptr_typ t = match t with
      A.List _ -> pointer_t (ltype_of_typ t)
    | _        -> ltype_of_typ t
  in

  (* Makes the struct declaration body *)
  let make_struct_body name ssformals = 
    let (types, _) = List.split ssformals in
    (* let _ = print_endline "Making a struct body" in *)
    let ltypes_list = List.map ltype_of_ptr_typ types in
    (* let _ = print_endline "Finished mapping the types" in *)
    let ltypes = Array.of_list ltypes_list in
    L.struct_set_body (StringMap.find name struct_types) ltypes false
  in
  let _ = StringMap.mapi make_struct_body struct_decls in
  (* Default values *)
  let init t = match t with
      A.Float -> L.const_float (ltype_of_typ t) 0.0
    | A.Struct(name) -> L.const_pointer_null (ltype_of_typ (A.Struct name))
    | A.String -> L.const_pointer_null (ltype_of_typ t)
    (* | A.List (_) -> L.const_pointer_null (ltype_of_typ t) *)
    | A.List (_) -> L.const_null (L.pointer_type (ltype_of_typ t))
    | _ -> L.const_int (ltype_of_typ t) 0
  in
  (* Index finder *)
  let rec find_index lst sid i = match lst with
      [] -> raise(Failure "Not in list")
    | (_, n)::rest -> if (n = sid) then i else find_index rest sid (i +1)
  in
  (* Builds a struct with name n and body of values *)
  let instantiate_struct t name =
    let (types, _) = try List.split (StringMap.find name struct_decls)
      with Not_found -> raise(Failure("Struct name is not a valid struct")) in
    let arr_type = Array.of_list (List.map init types) in
    let pty = ltype_of_typ t in (* getting the pointer of the struct type *)
    let lty = L.element_type pty in (* getting the type of the struct *)
    let lstruct = L.const_named_struct lty arr_type in
    (* (str_ptr, bind n str_ptr envs) *)
    (* let str_ptr = L.build_alloca lty n builder in
    let _ = L.build_store lstruct str_ptr builder in *)
    lstruct
  in

  let rec instantiate_all_structs t name builder =
    (* instantiate the struct itself *)
    let init_struct = instantiate_struct t name in 

    let (types, _) = try List.split (StringMap.find name struct_decls)
      with Not_found -> raise(Failure("Struct name is not a valid struct")) in
    let llvaluelist = List.map (fun t1 -> (match t1 with 
    A.Struct(s) -> instantiate_all_structs t1 s builder
    | _ -> init t1))  types in
    let pty = ltype_of_typ t in (* getting the pointer of the struct type *)
    let lty = L.element_type pty in (* getting the type of the struct *)
    (* Add values again -> for nested structs *)
    let add_elem acc (value, index) = L.build_insertvalue acc value index "building_empty_struct" builder in
    let ord_val_pairs = (List.combine llvaluelist (List.init (List.length llvaluelist) (fun i -> i))) in
    let lstruct = List.fold_left add_elem init_struct ord_val_pairs in

    let str_ptr = L.build_alloca lty "empty_struct" builder in
    let _ = L.build_store lstruct str_ptr builder in
    str_ptr
  in
    (* name : struct declaration *)
    (* sname : the struct *)
    (* sid: member of struct *)
  let cdr = function
      [] -> []
    | _ :: tail -> tail
  in
  let rec find_nested_struct sids sdecls llstruct builder = match sids with
      [] -> raise (Failure "In struct access Not possible")
    | name :: [] -> 
      let sformals = StringMap.find (List.hd sdecls) struct_decls in
      let index = find_index sformals name 0 in 
      let elm_ptr = L.build_struct_gep llstruct index name builder in
      (elm_ptr)
    | sid :: sids ->
      let next_sdecls = (cdr sdecls) in
      (* environments could be an issue here *)
      let sformals = StringMap.find (List.hd sdecls) struct_decls in
      let index = find_index sformals sid 0 in
      let elm_ptr = L.build_struct_gep llstruct index sid builder in 
      let next_llstruct = (L.build_load elm_ptr sid builder) in 
      (find_nested_struct sids next_sdecls next_llstruct builder)
    in
  (******  Function to extract global variables  *****)
  (* Extract global variables from main, declaring them, in essense. This means
      that all variables declared in main will be global variables. Since they
      are being declared here, we also convert all bindassigs to assignments,
      etc. main just uses the global environment as its local environment. *)
  let parse_main_statements sstmts =
        let parse_toplevel_statement (sstmts, global_vars) sstmt = match sstmt with
            SExpr (_t, s) -> (match s with
                SBindDec (t, n) -> (sstmts, StringMap.add n (L.define_global n (init t) the_module) global_vars)
              | SBindAssign (t, n, e) ->
                (* let _ = print_endline "hello" in *)
                  let global_vars = StringMap.add n (L.define_global n (init t) the_module) global_vars in
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


  (* Gather all the functions from main_function *)
  let functions =
    List.rev (List.fold_left (fun acc units -> match units with 
                                  SFdecl func -> func :: acc
                                | _ -> acc)
                [main_function] program) in

  (*  Takes the extracted global variables from main_function and adds it to a 
      reference to make it accessable globally *)
  let global_vars : L.llvalue StringMap.t ref = ref global_vars in

  (*** Utility functions for global_vars ***)
  (* Print all the global variable names *)
  (* let _ = StringMap.iter (fun name _ -> Printf.fprintf stderr "global var: %s\n" name) !global_vars in *)


  (**********  Processing functions (both external and internal) ********)

  (* Define each function (arguments and return type) so we can 
   * define it's body and call it later *)

  let list_head_t = L.pointer_type list_t in

  let printf_t : L.lltype =  L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue =  L.declare_function "printf" printf_t the_module in

  let list_insert_t        = L.function_type list_head_t [| list_head_t; i32_t; voidptr_t |] in
  let list_insert_func     = L.declare_function "list_insert" list_insert_t the_module in

  let list_len_t           = L.function_type i32_t [| list_head_t |] in
  let list_len_func        = L.declare_function "list_length" list_len_t the_module in

  let list_remove_t       = L.function_type (L.pointer_type list_t) [| list_head_t; i32_t |] in
  let list_remove_func    = L.declare_function "list_remove" list_remove_t the_module in

  let list_replace_t     = L.function_type list_head_t [| list_head_t; i32_t; voidptr_t |] in
  let list_replace_func  = L.declare_function "list_replace" list_replace_t the_module in

  let list_at_t          = L.function_type voidptr_t [| list_head_t; i32_t |] in
  let list_at_func       = L.declare_function "list_at" list_at_t the_module in

  (* String function *)
  let string_concat_t = L.function_type str_t [| str_t; str_t |] in
  let string_concat_f = L.declare_function "string_concat" string_concat_t the_module in

  (* ; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @list_length(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  store i32 0, ptr %3, align 4
  %5 = load ptr, ptr %2, align 8
  %6 = load ptr, ptr %5, align 8
  store ptr %6, ptr %4, align 8
  br label %7

7:                                                ; preds = %13, %1
  %8 = load ptr, ptr %4, align 8
  %9 = icmp ne ptr %8, null
  br i1 %9, label %10, label %17

10:                                               ; preds = %7
  %11 = load i32, ptr %3, align 4
  %12 = add i32 %11, 1
  store i32 %12, ptr %3, align 4
  br label %13

13:                                               ; preds = %10
  %14 = load ptr, ptr %4, align 8
  %15 = getelementptr inbounds %struct.node, ptr %14, i32 0, i32 1
  %16 = load ptr, ptr %15, align 8
  store ptr %16, ptr %4, align 8
  br label %7, !llvm.loop !8

17:                                               ; preds = %7
  %18 = load i32, ptr %3, align 4
  ret i32 %18
} *)

(* unsigned int list_length(node **head) {
  unsigned int len = 0;
  
  for (node *curr = *head; curr != NULL; curr = curr->next) {
    len++;
  }

  return len;
} *)

  (* list_len implementation: 
   * partially implemented *)
  let _ =
    let list_len_func = L.define_function "list_length_new" list_len_t the_module in
    let builder = L.builder_at_end context (L.entry_block list_len_func) in
    (* formal: node **head *)
    let list_head = L.param list_len_func 0 in
    
    (* make basic blocks *)
    let loop_cond_bb = L.append_block context "loop_cond" list_len_func in
    let loop_bb = L.append_block context "loop" list_len_func in
    let exit_loop_bb = L.append_block context "exit_loop" list_len_func in
    
    (* len = 0; node *curr = *head; node *next; *)
    let len = L.build_alloca i32_t "len" builder in
    let curr = L.build_alloca list_t "curr" builder in
    let _ = L.build_store (L.const_int i32_t 0) len builder in
    let _ = L.build_store (L.build_load list_head "head" builder) curr builder in
    let _ = L.build_br loop_cond_bb builder in
    
    (* if (curr == NULL) { goto exit_loop } else { goto loop } *)
    let _ = L.position_at_end loop_cond_bb builder in
    let is_null = L.build_is_null (L.build_load curr "curr" builder) "is_null" builder in
    let _ = L.build_cond_br is_null exit_loop_bb loop_bb builder in
    
    
    let _ = L.position_at_end loop_bb builder in
    let _ = L.build_struct_gep (L.build_load curr "curr" builder) 1 "next_ptr" builder in
    (* let _ = L.build_store (L.build_load next_ptr "next" builder) curr builder in *)
    let _ = L.build_store (L.build_add (L.build_load len "len" builder) (L.const_int i32_t 1) "len" builder) len builder in
    let _ = L.build_br loop_cond_bb builder in
   
    (* return len *)
    let _ = L.position_at_end exit_loop_bb builder in
    let _ = L.build_ret (L.build_load len "len" builder) builder in
    
    (* return 0 placeholder *)
    list_len_func
  in





  (* Define each function (arguments and return type) so we can 
   * define it's body and call it later *)
  let function_decls : ((L.llvalue * sfunc_decl) StringMap.t) =
    (* let _ = Printf.fprintf stderr "generating code for function\n" in *)

    (*  *)
    let function_decl m fdecl =
        let name = fdecl.sfname in
        (* print name to stderr *)
        (* let _ = Printf.fprintf stderr "generating code for %s\n" name in *)

        (* Converts list of function's sformal params into array of sformals *)
        let formal_types = 
            Array.of_list (List.map (fun (t, _) -> ltype_of_ptr_typ t) fdecl.sformals) in 

        (* Returns the function type in lltype *)
        let ftype = L.function_type (ltype_of_ptr_typ fdecl.styp) formal_types in
        (* Adds the function definition into the StringMap  *)
        StringMap.add name (L.define_function name ftype the_module, fdecl) m in

    List.fold_left function_decl StringMap.empty functions in
  

  (****  Fill/build the body of the given function ****)
  let build_function_body fdecl =
    (* let _ = print_endline fdecl.sfname in *)
    (* let _ = Printf.fprintf stderr "generating code for function body\n" in *)
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in
    
    let int_format_str = L.build_global_stringptr "%d" "fmt" builder
    and float_format_str = L.build_global_stringptr "%g" "fmt" builder 
    and string_format_str = L.build_global_stringptr "%s" "fmt" builder 
    and char_format_str = L.build_global_stringptr "%c" "fmt" builder in

    let int_format_str_with_nl = L.build_global_stringptr "%d\n" "fmt" builder
    and float_format_str_with_nl = L.build_global_stringptr "%g\n" "fmt" builder 
    and string_format_str_with_nl = L.build_global_stringptr "%s\n" "fmt" builder 
    and char_format_str_with_nl = L.build_global_stringptr "%c\n" "fmt" builder in


    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
          (* let _ = Printf.fprintf stderr "Adding formals\n" in *)
          let add_formal m (t, n) p = 
            let () = L.set_value_name n p in
              let local = L.build_alloca (ltype_of_ptr_typ t) n builder in
                let _  = L.build_store p local builder in
                  StringMap.add n local m 
          in

          (* Allocate space for any locally declared variables and add the
           * resulting registers to our map *)
          let add_local m (t, n) =
            let local_var = L.build_alloca (ltype_of_ptr_typ t) n builder
              in StringMap.add n local_var m 
          in
          let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals (Array.to_list (L.params the_function)) in 
            
        (* This is the return value of local vars!! i.e. End of block *)
          List.fold_left add_local formals fdecl.slocals in

      
    (* Stores the local_vars from above as the environment of this function *)
    let (envs : L.llvalue StringMap.t list) = [local_vars] in

    (* Look up and return the value for a variable or formal argument. First check
      * locals, then globals *)
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
      | env :: rest -> (StringMap.add n v env) :: rest in

    (* let bind_list_vars n v (envs: L.llvalue StringMap.t list) = 
        match envs with
          [] -> raise (Failure ("Internal error: no environment to bind variable in"))
        | env :: rest -> 
            let local = L.build_alloca (L.pointer_type (ltype_of_typ t)) n builder in
            let _     = L.build_store v local builder in
            let new_env = (StringMap.add n local env) :: rest
            in envs := new_env
    in *)

    (* Construct code for an expression; return its value *)
    (* let rec getLit e envs builder = match e with
          (_, SCharlit l) -> (String.make 1 l)
        | (_, SStringlit s) -> s
        | (_, SId s) -> L.string_of_llvalue (L.build_load (lookup s envs) s builder)
        | _ -> raise (Failure "Should not be in here")
  in *)

    let rec expr builder ((t, e) : sexpr) (envs: L.llvalue StringMap.t list) = match e with
        SLiteral i -> (L.const_int i32_t i, envs)
      | SBoolLit b -> (L.const_int i1_t (if b then 1 else 0), envs)
      | SFliteral l -> (L.const_float_of_string float_t l, envs)
      | SCharlit c  -> (L.const_int i8_t (int_of_char c), envs)
      | SStringlit s -> (L.build_global_stringptr s "string" builder, envs)
      | SNoexpr -> (L.const_int i32_t 0, envs)
      | SId s -> (match t with 
        (* A.Struct(_) ->  (lookup s envs, envs) *)
        | _ ->  (L.build_load (lookup s envs) s builder, envs))
      | SBinop (e1, op, e2) ->
        let (t1, _) = e1 in
        let (t2, _) = e2 in
        let (e1', envs) = expr builder e1 envs in
        let (e2', envs) = expr builder e2 envs in
        (match (t1, op, t2) with

          (* A.List(t) -> *)
            (A.Float, _, _) | (_, _, A.Float) -> ((get_float_lbinop op) (L.build_sitofp e1' float_t "ItoF" builder) (L.build_sitofp e2' float_t "ItoF" builder) "tmp" builder, envs)
          | (A.String, A.Add, _) | (_, A.Add, A.String) -> 
            (L.build_call string_concat_f [| e1'; e2' |] "string_concat" builder, envs)
          | (A.String, _, _) | (_, _, A.String) -> ((get_string_binop op) e1' e2' "temp" builder, envs)
          (* | (A.List(t1), A.Equal, A.List(t2)) -> iterate through both lists e1' and e2' and call expr builder with a new op on each individual value*)
          (* Integer-like cases *)
          | (A.Char, _, A.Char) -> (L.const_bitcast ((get_int_lbinop op) e1' e2' "tmp" builder) i8_t, envs)
          | (_, _, _) -> (get_int_lbinop op) e1' e2' "tmp" builder, envs)
      
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

      | SCall ("_print.string", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| string_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("_print.char", [e]) -> 
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| char_format_str ; e_llvalue |] "printf" builder, envs)
      | SCall ("_print.float", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| float_format_str ; e_llvalue |] "printf" builder, envs)
      
        | SCall ("_println.int", [e]) | SCall ("_println.bool", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| int_format_str_with_nl ; e_llvalue |] "printf" builder, envs)
        
      | SCall ("_println.string", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| string_format_str_with_nl ; e_llvalue |] "printf" builder, envs)
      | SCall ("_println.char", [e]) -> 
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| char_format_str_with_nl ; e_llvalue |] "printf" builder, envs)
      | SCall ("_println.float", [e]) ->
        let (e_llvalue, envs) = expr builder e envs in
        (L.build_call printf_func [| float_format_str_with_nl ; e_llvalue |] "printf" builder, envs)

      (* | SCall ("_println.list", [e]) ->  *)

      | SCall (s, [(A.List (t1), _) as e1; e2]) when (String.starts_with ~prefix:"_list_at" s) ->
          let (e1_llvalue, _) = expr builder e1 envs in
          let (e2_llvalue, _) = expr builder e2 envs in
          let value = L.build_call list_at_func [| e1_llvalue; e2_llvalue |] "list_at" builder in
          let cast = (match t1 with
                A.List(_) -> L.build_bitcast value (L.pointer_type (L.pointer_type (ltype_of_typ t1))) "cast" builder
              | _         -> L.build_bitcast value (L.pointer_type                 (ltype_of_typ t1))  "cast" builder ) in
          (L.build_load cast "list_at" builder, envs)

      | SCall (s, [e]) when (String.starts_with ~prefix:"_list_length" s)-> 
          let (e_llvalue, _) = expr builder e envs in
          (L.build_call list_len_func [| e_llvalue |] "list_length" builder, envs)

      | SCall (s, [e1; e2; e3]) when (String.starts_with ~prefix:"_list_insert" s) ->
          let (list_head, _) = expr builder e1 envs in
          let (idx, _) = expr builder e2 envs in
          let (value, _) = expr builder e3 envs in
          let mallocd_value = L.build_bitcast (build_malloc builder value) voidptr_t "voidptr" builder in
          let _ = L.build_call list_insert_func [| list_head; idx; mallocd_value |] "" builder in
          (list_head, envs)

      | SCall (s, [e1; e2]) when (String.starts_with ~prefix:"_list_remove" s) ->
          let (list_head, _) = expr builder e1 envs in
          let (idx, _) = expr builder e2 envs in
          let _ = L.build_call list_remove_func [| list_head; idx |] "" builder in
          (list_head, envs)

      | SCall (s, [e1; e2; e3]) when (String.starts_with ~prefix:"_list_replace" s) ->
          let (list_head, _) = expr builder e1 envs in
          let (idx, _) = expr builder e2 envs in
          let (value, _) = expr builder e3 envs in
          let mallocd_value = L.build_bitcast (build_malloc builder value) voidptr_t "voidptr" builder in
          let _ = L.build_call list_replace_func [| list_head; idx; mallocd_value |] "" builder in
          (list_head, envs)

      | SCall (f, args) ->
          let (fdef, fdecl) = StringMap.find f function_decls in
          let (llargs, envs) = List.fold_left (fun (llargs, envs) (t, e) -> 
            let (e', envs) = expr builder (t, e) envs in
            (e' :: llargs, envs)) ([], envs) args in
          let result = (A.string_of_typ fdecl.styp) ^ "result" in
          (L.build_call fdef (Array.of_list (List.rev llargs)) result builder, envs)
  
      | SBindDec (t, n) -> 
          (match t with 
            A.Struct(name) -> 
              let str_ptr = instantiate_all_structs t name builder in
              let pty = ltype_of_typ t in 
              let str_ptr_ptr = L.build_alloca pty n builder in
              let _ = L.build_store str_ptr str_ptr_ptr builder in
              (str_ptr_ptr, bind n str_ptr_ptr envs)
          | A.List (_) ->
              let list_ptr = L.build_alloca (L.pointer_type (ltype_of_typ t)) n builder in
              let _        = L.build_store (init t) list_ptr builder in
              (list_ptr, bind n list_ptr envs)
          | _ -> 
              let local_var = L.build_alloca (ltype_of_typ t) n builder in
              (init t, bind n local_var envs))
      | SAssign (var_name, e) ->
          let (value_to_assign, envs) = expr builder e envs in 
          let _ = L.build_store value_to_assign (lookup var_name envs) builder in
          (value_to_assign, envs)
      | SStructAssign (sdnames, sids, e) ->
        let llstruct = L.build_load (lookup (List.hd sids) envs) (List.hd sids) builder in
        (* environments could be an issue here *)
        let (llvalue, envs) = (match e with 
        (* could also do struct access here... *)
            (A.Struct(_), SId(s1)) -> (L.build_load (lookup s1 envs) s1 builder, envs)
          | (lt, SStructExplicit(t, n, el)) -> let _ = Printf.fprintf stderr "%s" n in expr builder (lt, SNestedStructExplicit (t, n, el)) envs
          | _ -> expr builder e envs) in
        (* get the formals of sname *)
        let elm_ptr = find_nested_struct (cdr sids) sdnames llstruct builder in
        (L.build_store llvalue elm_ptr builder, envs)
      | SStructAccess (sdnames, sids) -> 
        let llstruct = L.build_load (lookup (List.hd sids) envs) (List.hd sids) builder in 
        let elm_ptr = find_nested_struct (cdr sids) sdnames llstruct builder in 
        (L.build_load elm_ptr (List.hd (List.rev sids)) builder, envs)
      | SBindAssign (t, var_name, e) ->
          let (_, envs) = expr builder (t, SBindDec (t, var_name)) envs in
          expr builder (t, SAssign (var_name, e)) envs
      | SNestedStructExplicit (t, n, el) ->
        ( match t with 
        A.Struct(name) -> 
        let init_struct = instantiate_struct t name in
        (* Build the array of values for struct *)
        let (_, names) = List.split (StringMap.find name struct_decls) in
        (* function that takes in the two lists -> if expr is another struct literal, pass in an additional variable prev_name *)
          (* let array = Array.of_list  *)
        let pty = ltype_of_typ t in (* getting the pointer of the struct type *)
        let lty = L.element_type pty in (* getting the type of the struct *)
        let str_ptr = L.build_alloca lty n builder in
        let llvaluelist = (List.map2 (fun e n -> 
            let (e1, _) = (match e with 
              (lt, SStructExplicit (t, _, el)) -> expr builder (lt, SNestedStructExplicit (t, n, el)) envs
              | (A.Struct(_), SId(s1)) -> (L.build_load (lookup s1 envs) s1 builder, envs)
              | _ -> expr builder e envs)
            in e1) el names) in
        let add_elem acc (value, index) = L.build_insertvalue acc value index "building_struct" builder in
        let ord_val_pairs = (List.combine llvaluelist (List.init (List.length llvaluelist) (fun i -> i))) in
        let lstruct = List.fold_left add_elem init_struct ord_val_pairs in
        (* Build the struct *)
        
        let _ = L.build_store lstruct str_ptr builder in
        (str_ptr, envs)
        | _ -> raise (Failure "Should only be a struct"))
      | SStructExplicit(t, n, el) ->
        ( match t with 
        A.Struct(name) -> 
        let init_struct = instantiate_struct t name in
        (* Build the array of values for struct *)
        let (_, names) = List.split (StringMap.find name struct_decls) in
        let pty = ltype_of_typ t in (* getting the pointer of the struct type *)
        let lty = L.element_type pty in (* getting the type of the struct *)
        let str_ptr = L.build_alloca lty n builder in
        (* function that takes in the two lists -> if expr is another struct literal, pass in an additional variable prev_name *)
        (* let array = Array.of_list  *)
        let llvaluelist = (List.map2 (fun e n -> 
            let (e1, _) = (match e with 
              (lt, SStructExplicit (t, _, el)) -> expr builder (lt, SNestedStructExplicit (t, n, el)) envs
              | (A.Struct(_), SId(s1)) -> (L.build_load (lookup s1 envs) s1 builder, envs)
              | _ -> expr builder e envs)
            in e1) el names) in
        let add_elem acc (value, index) = L.build_insertvalue acc value index "building_struct" builder in
        let ord_val_pairs = (List.combine llvaluelist (List.init (List.length llvaluelist) (fun i -> i))) in
        let lstruct = List.fold_left add_elem init_struct ord_val_pairs in
        (* Build the struct *)
        
        let _ = L.build_store lstruct str_ptr builder in

        (* this breaks it, needs a single pointer at the beginning REWRITE *)
        let str_ptr_ptr = L.build_alloca pty n builder in
        let _ = L.build_store str_ptr str_ptr_ptr builder in

        (* let str_ptr = instantiate_struct t n array builder in *)
        (str_ptr_ptr, bind n str_ptr_ptr envs)
        | _ -> raise (Failure "Should only be a struct"))

        (* let rec expr builder ((_, e) : sexpr) (envs: L.llvalue StringMap.t list) = match e with *)
      
      | SListExplicit l -> 
          let l = List.rev (l) in
          (* Fold through the list 'l' and recursively runs expr builder -> 
             returns tuple of list of llvals and environment *)
          let llvals = List.fold_left 
                        (fun list_accum sex ->   
                            let (llval, _) = expr builder sex envs in
                            (* Return updated list and updated envs *)
                            llval :: list_accum
                        ) [] l
          in

          (* Map through the llvals, create malloc instruction for that llval, then store
             the pointer to that memory in the list for later reference *)
          let malloced_ptrs = List.map (build_malloc builder) llvals in

          (* Creates instruction to allocate space declares a pointer to a list_t type, i.e. a Node **l;
             which is a double pointer because list_t itself is a pointer to a struct_type *)
          let list_ptr = L.build_alloca (L.pointer_type list_t) "list_ptr" builder in 
          
          (* Create a malloc instruction for a list_t. I.e. mallocs new list*)
          let head = L.build_malloc list_t "head" builder in
          
          (* Stores the value of head into the memory location list_ptr, i.e. It connects list_ptr to head *)
          (* Mini diagram: list_ptr |  head  | ----> { voidptr_t, nodeptr_t } *)
          let _ = L.build_store head list_ptr builder in
          
          (* Const null returns an empty/null pointer of a list_t, then build_store copies the null pointer
             into head  *)
          let _ = L.build_store (L.const_null list_t) head builder in
          
          (* Inserting all list element
             Pre-process:
               - Maps through the list of malloced pointer. Replaces the current 
                 element with a tuple of (index, malloced pointer to the node)

             1) Fold through the list containing pointers to the llvals 
             2) Cast the pointers to llvals as void
             3) Loads the value of list_ptr into listval variable
             4) Calls list_insert_func with (head, index of insertion, node to insert)
             *)
          let _ = List.fold_left 
            (fun _ (i, llval) -> 
              (* Cast each llval to a void * before inserting it into the list *)
              let void_cast = L.build_bitcast llval voidptr_t "voidptr" builder in
              let listval = L.build_load list_ptr "listval" builder in
              L.build_call list_insert_func [| listval; L.const_int i32_t i; void_cast |] "" builder
              )
              list_ptr
              (List.mapi (fun i llval -> (i, llval)) malloced_ptrs) in 
          (* let finalList = (L.build_load list_ptr "listlit" builder, envs) in  *)
          (L.build_load list_ptr "listlit" builder, envs)

            
             (* let list_t     = L.pointer_type (L.struct_type context [| voidptr_t; nodeptr_t |])  *)

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