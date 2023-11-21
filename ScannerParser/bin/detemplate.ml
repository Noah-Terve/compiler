open Ast
module StringMap = Map.Make(String)

let detemplate (units) = 
  (* functions and structs that are instatiated *)
  let resolved_functions = ref StringMap.empty in
  let resolved_structs = ref StringMap.empty in
  (* functions and structs that are templated *)
  let known_templated_funcs = ref StringMap.empty in
  let known_templated_structs = ref StringMap.empty in
  
  let get_new_function_name name t_list = 
    "_" ^ name ^ "." ^ (String.concat "." (List.map string_of_typ t_list))
  in 
  (* let get_return_type t = (match t with
      Templated (templ) -> 
      | _ -> t
    ) *)

  (* Given a function declaration and a list of types, replace type variables
     in the declaration with the corresponding type *)
  (* let resolveFunctionTyvars {typ = t; fname = name; formals = form; body = b; fun_t_list = t_list} ty_list = 
    match t_list with
        [] -> Fdecl (typ = t; fname = name; formals = form; body = b; fun_t_list = t_list)
      | _  ->
        let fun_t_list_len = List.length t_list in
        let ty_list_len = List.length ty_list in
        if fun_t_list_len = ty_list_len then
          (* Create a new formals list *)
          let new_fname = "_" ^ fname ^ "." ^ (String.concat "." (List.map string_of_typ ty_list)) in
          let new_formals = List.map2 (fun (typ, name) ty -> (ty, name)) formals ty_list in
          (* Create a new return type if needed *)
          let new_type = get_return_type in
          (* Create a new body *)
          let new_body = List.map resolveTemplates body in 
          raise (Failure "Not finished implementing")
        else raise (Failure "Template Parameters do not match with Function Declaration")
  in  *)

  (* given a name, a list of types, and the program, 
     create a new version of the function with all statements having new types
     for the resolved templates and a new function name. Also checks that
     the list of types is the same length as the expected list for the template.
     Append the new version of the function to the front of the program and
     return the updated program *)

  let potentially_templated_to_typ typ names_to_types = match typ with
      Templated(n) -> try StringMap.find n names_to_types
                      with Not_found -> let msg = "Attempted to turn the template: " ^ n ^ ", into a type, but didn't find it as a current tempalted type" in 
                                            raise (Failure msg)
    | _ -> typ
  in
  
  let rec resolve_templated_function name types prog names_to_types = 
    let new_fname = get_new_function_name name types in
    let templated_func = try StringMap.find name !known_templated_funcs
                         with Not_found -> let msg = "Function: " ^ name ^ " not declared but attempted to be called" in 
                                           raise (Failure msg)
    in let pairs = try List.combine templated_func.fun_t_list types
      with Invalid_argument _ -> raise (Failure "Number of template parameters do not match with function declaration")
    in let new_names_to_types = List.fold_left (fun map (n, t) -> (StringMap.add n t map)) names_to_types pairs
    in let new_typ = potentially_templated_to_typ templated_func.typ
    in let new_formals = List.map (fun (typ, name) -> (potentially_templated_to_typ typ new_names_to_types, name)) templated_func.formals 
    in let (new_body, p1) = resolve_stmts templated_func.body prog new_names_to_types
    in Fdecl({typ = new_typ; fname = new_fname; formals = new_formals; body = new_body; fun_t_list = []}) :: p1
    
    (* check that the length of the list of tempaltes they gave is the right length
       
       we might want to generate a map of names to types (done)
       
       with the tempalted func dec in hand, we need to generate all the new info
       typ = typ iff typ is not tempalted, if it is, replace it
       fname = new name
       formals = go through formals and replace types
       body = go through body and replace types
       fun_t_list = []
     *)
  and

  (* given a list of expressions and a program (list of prog_units)
     resolve each expression and return the list of expressions and the
     new program after resolving all expressions *)
  resolve_exprs exp_list prog names_to_types = match exp_list with
      [] -> ([], prog)
    | e :: es -> let (exp1, p0) = resolve_expr e prog names_to_types in
                 let (exps, p1) = resolve_exprs es p0 names_to_types in
                 (exp1 :: exps, p1)
  and

  (* return the expr which has templates removed *)
  resolve_expr exp prog names_to_types = match exp with
      Binop (e1, op, e2) -> let (exp1, p0) = resolve_expr e1 prog names_to_types in
                            let (exp2, p1) = resolve_expr e2 p0 names_to_types in
                            (Binop(exp1, op, exp2), p1)
    | Unop (op, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                      (Unop(op, exp1), p0)
    | Assign (name, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                          (Assign(name, exp1), p0)
    | Call (name, es) -> let (exps, p0) = resolve_exprs es prog names_to_types in 
                         (Call(name, exps), p0)
    | TemplatedCall (name, ts, es) -> 

      let new_fname = get_new_function_name name ts in
      let _ = try StringMap.find new_fname !resolved_functions 
              
              (* case where the function hasnt been resolved yet *)
              with Not_found -> let p0 = resolve_templated_function name ts prog names_to_types in
                                let (exprs, p1) = resolve_exprs es p0 names_to_types in 
                                (Call(new_fname, exprs), p1)
      
      (* case where the function has been resolved *)
      in let (exprs, p0) = resolve_exprs es prog names_to_types in 
         (Call(new_fname, exprs), p0)

    | BindAssign (t, name, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                 let ty = potentially_templated_to_typ t names_to_types in 
                                 (BindAssign(ty, name, exp1), p0)
    | BindDec (t, name) -> let ty = potentially_templated_to_typ t names_to_types in
                           (BindDec(ty, name), prog)
    | StructAssign (name, field, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                       (StructAssign(name, field, exp1), p0)
    | BindTemplatedDec (typ, ts, name) -> raise (Failure "not implemented yet")
    | BindTemplatedAssign (typ, ts, name, e) -> raise (Failure "not implemented yet")
    | ListExplicit (es) -> let (exps, p0) = resolve_exprs es prog names_to_types in
                           (ListExplicit(exps), p0)
    | SetExplicit (es) -> let (exps, p0) = resolve_exprs es prog names_to_types in
                          (SetExplicit(exps), p0)
    | StructExplicit (es) -> let (exps, p0) = resolve_exprs es prog names_to_types in
                             (StructExplicit(exps), p0)
    | _ -> (exp, prog)
  and 

  resolve_stmts stmt_list prog names_to_types = match stmt_list with
      [] -> ([], prog)
    | stmt :: stmts -> let (st, p0) = resolve_stmt stmt prog names_to_types in
                       let (sts, p1) = resolve_stmts stmts p0 names_to_types in
                       (st :: sts, p1)
  and

  (* return the statement with no tempaltes within it *)
  resolve_stmt stmt prog names_to_types = match stmt with
      Block (stmts) -> raise (Failure "blocks not implmented yet") (* Block (List.map resolve_stmt stmts) *)
    | Expr (e) -> let (exp, p) = resolve_expr e prog names_to_types in (Expr(exp), p)
    | Return (e) -> let (exp, p) = resolve_expr e prog names_to_types in (Return(exp), p)
    | If (e1, stmt1, stmt2) -> let (exp1, p0) = resolve_expr e1 prog names_to_types in
                               let (st1, p1) = resolve_stmt stmt1 p0 names_to_types in
                               let (st2, p2) = resolve_stmt stmt2 p1 names_to_types in
                               (If(exp1, st1, st2), p2)

    | For (e1, e2, e3, stmt1) -> let (exp1, p0) = resolve_expr e1 prog names_to_types in
                                let (exp2, p1) = resolve_expr e2 p0 names_to_types in
                                let (exp3, p2) = resolve_expr e3 p1 names_to_types in
                                let (st1, p3) = resolve_stmt stmt1 p2 names_to_types in
                                (For(exp1, exp2, exp3, st1), p3)

    | ForEnhanced (e1, e2, stmt1) -> let (exp1, p0) = resolve_expr e1 prog names_to_types in
                                    let (exp2, p1) = resolve_expr e2 p0 names_to_types in
                                    let (st1, p2) = resolve_stmt stmt1 p1 names_to_types in
                                    (ForEnhanced(exp1, exp2, st1), p2)

    | While (e1, stmt1) -> let (exp1, p0) = resolve_expr e1 prog names_to_types in
                           let (st1, p1) = resolve_stmt stmt1 p0 names_to_types in
                           (While(exp1, st1), p1)
    | _ -> (stmt, prog)
  in
  
  let rec resolveTemplates acc prog_unit = match prog_unit with 
      Fdecl (func) -> (match func.fun_t_list with
      (* TODO this needs to be updated to go through the function's statements *)
           [] -> let _ = resolved_functions := (StringMap.add func.fname (Fdecl(func)) !resolved_functions) in Fdecl(func) :: acc
          | _ -> let _ = known_templated_funcs := (StringMap.add func.fname (Fdecl(func)) !known_templated_funcs) in acc)
        
    | Sdecl (struc) -> (match struc.t_list with
           [] -> let _ = resolved_structs := (StringMap.add struc.name (Sdecl(struc)) !resolved_structs) in (Sdecl(struc)) :: acc
          | _ -> let _ = known_templated_structs := (StringMap.add struc.name (Sdecl(struc)) !known_templated_structs) in acc)
        
    | Stmt (stmt) -> let (st, prog) = resolve_stmt stmt acc StringMap.empty in (Stmt st) :: prog
  
  in
  
  List.rev (List.fold_left resolveTemplates [] units)
