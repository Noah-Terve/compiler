open Ast
module StringMap = Map.Make(String)

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
  | TStruct(s, ts) -> get_new_name s ts
  | Unknown_contents -> "Empty"
and
  
get_new_name name t_list = 
  "_" ^ name ^ "." ^ (String.concat "." (List.map typ_to_new_name t_list))


let new_function_name_for_overloading name t_list =
  name ^ "," ^ (String.concat "." (List.map typ_to_new_name t_list))

let detemplate units = 
  (* functions and structs that are instatiated *)
  let resolved_functions = ref StringMap.empty in
  let resolved_structs = ref StringMap.empty in
  (* functions and structs that are templated *)
  let known_templated_funcs = ref StringMap.empty in
  let known_templated_structs = ref StringMap.empty in

  (* given a name, a list of types, and the program, 
     create a new version of the function with all statements having new types
     for the resolved templates and a new function name. Also checks that
     the list of types is the same length as the expected list for the template.
     Append the new version of the function to the front of the program and
     return the updated program *)

  let rec potentially_templated_to_typ typ names_to_types prog = match typ with
      Templated(n) -> (try let ty = StringMap.find n names_to_types in
                            (ty, prog)
                      with Not_found -> 
                        (* case where the name is the name of a struct that isn't templated *)
                        try let _ = StringMap.find n !resolved_structs in
                              (Struct(n), prog)
                        with Not_found ->
                          let msg = "Attempted to turn the template or struct: " ^ n ^ ", into a type, but didn't find it as a current tempalted type or struct" in 
                          raise (Failure msg))
    | List (t) -> let (ty, p0) = potentially_templated_to_typ t names_to_types prog in
                    (List (ty), p0)
    | Set (t) -> let (ty, p0) = potentially_templated_to_typ t names_to_types prog in
                    (Set (ty), p0)
    | TStruct (s, ts) -> let (new_ts, p0) = potentially_templated_typs_to_typ ts names_to_types prog in
                         let new_sname = get_new_name s new_ts in
                         (* case where the struct has already been resolved *)
                         (try let _ = StringMap.find new_sname !resolved_structs in
                            (Struct(new_sname), p0)
                          with Not_found -> let p1 = resolve_templated_struct s new_ts p0 in
                                              (Struct(new_sname), p1))
    | _ -> (typ, prog)
  and

  potentially_templated_typs_to_typ ts names_to_types prog = match ts with
      [] -> ([], prog)
    | t :: types -> let (ty, p0) = potentially_templated_to_typ t names_to_types prog in
                    let (tys, p1) = potentially_templated_typs_to_typ types names_to_types p0 in
                    (ty :: tys, p1)
  and

  potentially_templated_binds_to_binds bs names_to_types prog = match bs with
      [] -> ([], prog)
    | (t, name) :: binds -> let (ty, p0) = potentially_templated_to_typ t names_to_types prog in
                            let (rest_bs, p1) = potentially_templated_binds_to_binds binds names_to_types p0 in
                            ((ty, name) :: rest_bs, p1)
  
  and
  
  resolve_templated_function name types prog = 
    let new_fname = get_new_name name types in
    let templated_func = try StringMap.find name !known_templated_funcs
                         with Not_found -> let msg = "Function: " ^ name ^ " was not declared but attempted to be called" in 
                                           raise (Failure msg) in
    let pairs = try List.combine templated_func.fun_t_list types
                with Invalid_argument _ -> raise (Failure "Number of template parameters do not match with function declaration") in
    let new_names_to_types = List.fold_left (fun map (n, t) -> (StringMap.add n t map)) StringMap.empty pairs in
    let (new_typ, p0) = potentially_templated_to_typ templated_func.typ new_names_to_types prog in
    let (new_formals, p1) = potentially_templated_binds_to_binds templated_func.formals new_names_to_types p0 in
    let (new_body, p2) = resolve_stmts templated_func.body p1 new_names_to_types in
    let new_func = {typ = new_typ; fname = new_fname; formals = new_formals; body = new_body; fun_t_list = []} in
    let _ = resolved_functions := (StringMap.add new_func.fname new_func !resolved_functions) in
    Fdecl(new_func) :: p2
    
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
    let (new_formals, p0) = potentially_templated_binds_to_binds templated_struct.sformals new_names_to_types prog in
    let new_struct = {name = new_sname; sformals = new_formals; t_list = []} in
    let _ = resolved_structs := (StringMap.add new_struct.name new_struct !resolved_structs) in
    Sdecl(new_struct) :: p0
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

      (let (new_ts, p0) = potentially_templated_typs_to_typ ts names_to_types prog in
       let new_fname = get_new_name name new_ts in
                  (* case where the function has already been resolved to this set of types *)
      try let _ = StringMap.find new_fname !resolved_functions in 
          let (exprs, p1) = resolve_exprs es p0 names_to_types in 
          (Call(new_fname, exprs), p1)
              
              (* case where the function hasnt been resolved yet *)
      with Not_found -> let p1 = resolve_templated_function name new_ts p0 in
                        let (exprs, p2) = resolve_exprs es p1 names_to_types in 
                        (Call(new_fname, exprs), p2))

    | BindAssign (t, name, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                 let (ty, p1) = potentially_templated_to_typ t names_to_types p0 in 
                                 (BindAssign(ty, name, exp1), p1)
    | BindDec (t, name) -> let (ty, p0) = potentially_templated_to_typ t names_to_types prog in
                           (BindDec(ty, name), p0)
    | StructAssign (names, e) -> let (exp1, p0) = resolve_expr e prog names_to_types in
                                       (StructAssign(names, exp1), p0)

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
                 (* if the function exists already that is against our rules *)
           [] -> (let new_name = new_function_name_for_overloading func.fname (List.map (fun (t, _) -> t) func.formals) in 
                  try let _ = StringMap.find new_name !resolved_functions in raise (Failure "Functions can't have the same name and the same input types in the same order")
                      with Not_found ->
                        let (new_typ, p') = potentially_templated_to_typ func.typ StringMap.empty prog in
                        let (new_body, p0) = resolve_stmts func.body p' StringMap.empty in
                        let (new_formals, p1) = potentially_templated_binds_to_binds func.formals StringMap.empty p0 in
                        let new_func = {typ = new_typ; fname = new_name; formals = new_formals; body = new_body; fun_t_list = []} in
                        let _ = resolved_functions := (StringMap.add new_name new_func !resolved_functions) in Fdecl(new_func) :: p1)
          | _ ->  try let _ = StringMap.find func.fname !known_templated_funcs in raise (Failure "Templated functions can't be overloaded")
                      with Not_found -> 
                        let _ = known_templated_funcs := (StringMap.add func.fname func !known_templated_funcs) in prog)
        
    | Sdecl (struc) -> (match struc.t_list with
            [] -> ( try let _ = StringMap.find struc.name !resolved_structs in raise (Failure "You can't overload structs")
                    with Not_found ->
                      let (new_formals, p0) = potentially_templated_binds_to_binds struc.sformals StringMap.empty prog in
                      let new_struct = {name = struc.name; t_list = []; sformals = new_formals} in
                      let _ = resolved_structs := (StringMap.add struc.name new_struct !resolved_structs) in (Sdecl(new_struct)) :: p0 )
          | _ -> let _ = known_templated_structs := (StringMap.add struc.name struc !known_templated_structs) in prog)
        
    | Stmt (stmt) -> let (st, p0) = resolve_stmt stmt prog StringMap.empty in (Stmt st) :: p0
  
  in
  
  List.rev (List.fold_left resolveTemplates [] units)
