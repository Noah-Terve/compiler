open Ast
module StringMap = Map.Make(String)

let detemplate units = 
  (* functions and structs that are instatiated *)
  let resolved_functions = ref StringMap.empty in
  let resolved_structs = ref StringMap.empty in
  (* functions and structs that are templated *)
  let known_templated_funcs = ref StringMap.empty in
  let known_templated_structs = ref StringMap.empty in
  
  let rec typ_to_new_name = function
      Int -> "int"
    | Bool -> "bool"
    | Float -> "float"
    | String -> "string"
    | Char -> "char"
    | List(t) -> "list_" ^ typ_to_new_name t
    | Set(t) -> "set_" ^ typ_to_new_name t
    | Templated(t) -> t
    | Struct(t) -> t
  in

  let get_new_name name t_list = 
    "_" ^ name ^ "." ^ (String.concat "." (List.map typ_to_new_name t_list))
  in 

  (* given a name, a list of types, and the program, 
     create a new version of the function with all statements having new types
     for the resolved templates and a new function name. Also checks that
     the list of types is the same length as the expected list for the template.
     Append the new version of the function to the front of the program and
     return the updated program *)

  let rec potentially_templated_to_typ typ names_to_types = match typ with
      Templated(n) -> (try StringMap.find n names_to_types
                      with Not_found -> 
                        try let _ = StringMap.find n !resolved_structs in
                            Struct(n)
                        with Not_found ->
                          let msg = "Attempted to turn the template or struct: " ^ n ^ ", into a type, but didn't find it as a current tempalted type or struct" in 
                          raise (Failure msg))
    | List (t) -> List (potentially_templated_to_typ t names_to_types)
    | Set (t) -> Set (potentially_templated_to_typ t names_to_types)
    | _ ->  typ
  in
  
  let rec resolve_templated_function name types prog = 
    let new_fname = get_new_name name types in
    let templated_func = try StringMap.find name !known_templated_funcs
                         with Not_found -> let msg = "Function: " ^ name ^ " was not declared but attempted to be called" in 
                                           raise (Failure msg) in
    let pairs = try List.combine templated_func.fun_t_list types
                with Invalid_argument _ -> raise (Failure "Number of template parameters do not match with function declaration") in
    let new_names_to_types = List.fold_left (fun map (n, t) -> (StringMap.add n t map)) StringMap.empty pairs in
    let new_typ = (potentially_templated_to_typ templated_func.typ new_names_to_types) in
    let new_formals = List.map (fun (typ, name) -> (potentially_templated_to_typ typ new_names_to_types, name)) templated_func.formals in
    let (new_body, p1) = resolve_stmts templated_func.body prog new_names_to_types in
    let new_func = {typ = new_typ; fname = new_fname; formals = new_formals; body = new_body; fun_t_list = []} in
    let _ = resolved_functions := (StringMap.add new_func.fname new_func !resolved_functions) in
    Fdecl(new_func) :: p1
    
    (* check that the length of the list of tempaltes they gave is the right length
       
       we might want to generate a map of names to types (done)
       
       with the tempalted func dec in hand, we need to generate all the new info
       typ = typ iff typ is not tempalted, if it is, replace it
       fname = new name
       formals = go through formals and replace types
       body = go through body and replace types
       fun_t_list = []

       add to the list of resolved functions
     *)
  and

  resolve_templated_struct name types prog =
    let new_sname = get_new_name name types in
    let templated_struct = try StringMap.find name !known_templated_structs
                           with Not_found -> let msg = "Struct: " ^ name ^ " was not declared but attempted to be instanciated" in 
                                             raise (Failure msg) in
    let pairs = try List.combine templated_struct.t_list types
                with Invalid_argument _ -> raise (Failure "Number of template parameters do not match with function declaration") in
    let new_names_to_types = List.fold_left (fun map (n, t) -> (StringMap.add n t map)) StringMap.empty pairs in
    let new_formals = List.map (fun (typ, name) -> (potentially_templated_to_typ typ new_names_to_types, name)) templated_struct.sformals in
    let new_struct = {name = new_sname; sformals = new_formals; t_list = []} in
    let _ = resolved_structs := (StringMap.add new_struct.name new_struct !resolved_structs) in
    Sdecl(new_struct) :: prog

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

      (let new_ts = List.map (fun typ -> potentially_templated_to_typ typ names_to_types) ts in
       let new_fname = get_new_name name new_ts in
                  (* case where the function has already been resolved to this set of types *)
      try let _ = StringMap.find new_fname !resolved_functions in 
          let (exprs, p0) = resolve_exprs es prog names_to_types in 
          (Call(new_fname, exprs), p0)
              
              (* case where the function hasnt been resolved yet *)
      with Not_found -> let p0 = resolve_templated_function name new_ts prog in
                        let (exprs, p1) = resolve_exprs es p0 names_to_types in 
                        (Call(new_fname, exprs), p1))

    | BindAssign (t, name, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                 let ty = potentially_templated_to_typ t names_to_types in 
                                 (BindAssign(ty, name, exp1), p0)
    | BindDec (t, name) -> let ty = potentially_templated_to_typ t names_to_types in
                           (BindDec(ty, name), prog)
    | StructAssign (name, field, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                       (StructAssign(name, field, exp1), p0)
    | BindTemplatedDec (s_id, ts, name) ->
      (let new_ts = List.map (fun typ -> potentially_templated_to_typ typ names_to_types) ts in
       let new_sname = get_new_name s_id new_ts in
                  (* case where the struct has already been resolved to this set of types *)
      try let _ = StringMap.find new_sname !resolved_structs in
          (BindDec(Struct(new_sname), name), prog)

                  (* cause where the struct hasn't been resolved yet *)
      with Not_found -> let p0 = resolve_templated_struct s_id new_ts prog in
                        (BindDec(Struct(new_sname), name), p0))      
    | BindTemplatedAssign (s_id, ts, name, e) ->

      (let new_ts = List.map (fun typ -> potentially_templated_to_typ typ names_to_types) ts in
       let new_sname = get_new_name s_id new_ts in
                  (* case where the struct has already been resolved to this set of types *)
      try let _ = StringMap.find new_sname !resolved_structs in
          let (exp1, p0) = resolve_expr e prog names_to_types in
          (BindAssign(Struct(new_sname), name, exp1), p0)

                  (* cause where the struct hasn't been resolved yet *)
      with Not_found -> let p0 = resolve_templated_struct s_id new_ts prog in
                        let (exp1, p1) = resolve_expr e p0 names_to_types in
                        (BindAssign(Struct(new_sname), name, exp1), p1))

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
      Block (stmts) -> let (sts, p0) = resolve_stmts stmts prog names_to_types in
                       (Block(sts), p0)
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
  
  let resolveTemplates prog prog_unit = match prog_unit with 
      Fdecl (func) -> (match func.fun_t_list with
           [] -> let (new_body, p0) = resolve_stmts func.body prog StringMap.empty in
                 let new_func = {typ = func.typ; fname = func.fname; formals = func.formals; body = new_body; fun_t_list = func.fun_t_list} in
                 let _ = resolved_functions := (StringMap.add func.fname new_func !resolved_functions) in Fdecl(func) :: p0
          | _ -> let _ = known_templated_funcs := (StringMap.add func.fname func !known_templated_funcs) in prog)
        
    | Sdecl (struc) -> (match struc.t_list with
           [] -> let _ = resolved_structs := (StringMap.add struc.name struc !resolved_structs) in (Sdecl(struc)) :: prog
          | _ -> let _ = known_templated_structs := (StringMap.add struc.name struc !known_templated_structs) in prog)
        
    | Stmt (stmt) -> let (st, p0) = resolve_stmt stmt prog StringMap.empty in (Stmt st) :: p0
  
  in
  
  List.rev (List.fold_left resolveTemplates [] units)
