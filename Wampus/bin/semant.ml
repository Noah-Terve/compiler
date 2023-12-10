(* Semantic checking for the MicroC compiler *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (units : program) =
  let not_toplevel = false and not_inloop = false in
  let toplevel = true and inloop = true in
  (* let in_assign = ref false in *)

  (* Check if a certain kind of binding has void type or is a duplicate
     of another, previously checked binding *)
  let check_binds (kind : string) (to_check : bind list) = 
    let name_compare (_, n1) (_, n2) = compare n1 n2 in
    let check_it checked binding = 
      let dup_err = "duplicate " ^ kind ^ " " ^ snd binding
      in match binding with
        (* No void bindings *)
        (* (Void, _) -> raise (Failure void_err) *)
      | (_, n1) -> match checked with
                    (* No duplicate bindings *)
                      ((_, n2) :: _) when n1 = n2 -> raise (Failure dup_err)
                    | _ -> binding :: checked

    in let _ = List.fold_left check_it [] (List.sort name_compare to_check) 
       in to_check
  in 

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_general_bind map (name, ty, formals) = StringMap.add name {
      styp = ty; sfname = name; sformals = formals;
      sbody = []; slocals = []; } map
    in let temp_binds = 
      List.fold_left add_general_bind StringMap.empty [
        ("list_at",     Int, [(List (Int), "head"); (Int, "idx")]);
        ("list_insert", Int, [(List (Int), "head"); (Int, "idx"); (Int, "data")]); (* TODO: Use polymorphic types here for third arg*)
        ("list_remove", Int, [(List (Int), "head"); (Int, "idx")]);
        ("list_len",    Int, [(List (Int), "head")])
      ]
    in 
    let add_bind map (name, ty) = StringMap.add name {
      styp = Int; sfname = name; 
      sformals = [(ty, "x")];
      sbody = []; slocals = []; } map
    in List.fold_left add_bind temp_binds [ ("printi", Int);
                                                 ("printb", Bool);
                                                 ("printf", Float);
                                                 ("prints", String);
                                                 ("printc", Char)]
  in

  (* TODO: Consider making this a non-reference; this might be poor coding practices *)
  (* Collect all other function names into one symbol table *)
  let function_decls = ref built_in_decls in
  
  let add_func (fd : sfunc_decl) =
    let built_in_err = "function " ^ fd.sfname ^ " may not be defined" in
    let dup_err = "duplicate function " ^ fd.sfname in
    let dup_main_err = "there can be no user-defined function named 'main'" in
    let make_err er = raise (Failure er) in
    let n = fd.sfname in (* Name of the function *)
    match fd with (* No duplicate functions or redefinitions of built-ins *)
        _ when StringMap.mem n built_in_decls -> make_err built_in_err
      | _ when StringMap.mem n !function_decls -> make_err dup_err
      | _ when n = "main" -> make_err dup_main_err
      | _ -> function_decls := StringMap.add n fd !function_decls
  in

  (* Struct Decl map for statement use *)
  let struct_decls = ref StringMap.empty in
  (* Struct helper functions*)
  let find_struc strucname = 
    (* let _ = StringMap.iter (fun k v -> Printf.fprintf stderr "Structs in list: %s\n" k) !struct_decls in *)
    try StringMap.find strucname !struct_decls
    with Not_found -> raise (Failure ("unrecognized struct " ^ strucname))
  in
  let find_struct_id sd id =
    try List.find (fun (_, s) -> s = id) sd.ssformals 
    with Not_found -> raise (Failure ("Unrecognized struct identifier " ^ id))
  in
  let find_struc_from_typ = function
  (* fix this later TODO *)
      Struct(s) -> (s, find_struc s)
    | Templated(s) -> (s, find_struc s)
    | _ -> raise (Failure ("Should not be in here"))
  in
  let add_struc (sd: sstruct_decl)= 
    let name = sd.sname in
    if StringMap.mem name !struct_decls then
      raise (Failure ("Error: Duplicate named struct '" ^ name ^ "'"))
    else
      struct_decls := StringMap.add name sd !struct_decls
  in

  (* Collect all other function names into one symbol table *)
  (* let function_decls = List.fold_left add_func built_in_decls functions
  in *)
  
  (* Return a function from our symbol table *)
  let find_func fname = 
    try StringMap.find fname !function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ fname))
  in

  let globals : typ StringMap.t ref = ref StringMap.empty in

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
  let check_assign (lvaluet: typ) (rvaluet: typ) err =
      if lvaluet = rvaluet then lvaluet else raise (Failure err) in
    (* Return a variable from our local symbol table *)
  let rec type_of_identifier id (envs: typ StringMap.t list) = 
    (* let first_env = List.hd envs in
    let _ = StringMap.iter (fun k v -> Printf.printf "typ Key: '%s', Value: '%s'\n" k (string_of_typ v)) first_env in
    let _ = Printf.printf "key: '%s'\n" id in *)
    match envs with
      (* env :: rest -> (try let t = StringMap.find id env in let _ = Printf.printf "type: '%s'\n" (string_of_typ t) in t
                      with Not_found -> type_of_identifier id rest) *)
      env :: rest -> (try StringMap.find id env
                      with Not_found -> type_of_identifier id rest)
    | [] -> (try StringMap.find id !globals
            with Not_found -> raise (Failure ("Undeclared identifier " ^ id))) in
                          
  let bind id (ty: typ) envs = match envs with
      [] -> raise (Failure ("BUG IN COMPILER: no environments"))
    | env :: envs -> 
      (* let _ = Printf.printf "Binding %s to %s\n" id (string_of_typ ty) in *)
      StringMap.add id ty env :: envs
  in

  let bind_global id (ty : typ) =
    let env = !globals in
    globals := StringMap.add id ty env
  in

    (* let type_of_identifier s = 
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in *)

  let rec find_nested_structs ids sdecl = match ids with
      [] -> raise (Failure "Attempted to find an id that doesn't exist")
    | name :: rest ->
        let (t, _) = find_struct_id sdecl name in match t with
             Struct (sname) -> let new_sdecl = find_struc sname in
                            let (names, ty) = find_nested_structs rest new_sdecl in
                            (name :: names, ty)
          | _ -> match rest with
             [] -> (ids, t)
            | _ -> raise (Failure "Attempted to access a member of something that is not a struct")

  in

    (* Return a semantically-checked expression, i.e., with a type *)
  let rec check_expr e envs is_toplevel = match e with
      Literal  l -> (Int, SLiteral l)
    | Fliteral l -> (Float, SFliteral l)
    | BoolLit l  -> (Bool, SBoolLit l)
    | CharLit l -> (Char, SCharlit l)
    | StringLit l -> (String, SStringlit l)
    | Noexpr     -> (Int, SNoexpr)
    | Id s       -> (type_of_identifier s envs, SId s)
    (* Bind the variable in the topmost environment. *)
    (* | Assign (var, ListExplicit exprs) ->
        let lt = type_of_identifier var envs in
        let (rt, sxs) = check_expr (ListExplicit exprs) envs not_toplevel in
        (* Empty lists default to a list of integers, so we need to modify
            r_ty to be equal to ty if so *)
        let rt = (match sxs with
            SListExplicit [] -> let _ = Printf.printf ("In the empty list case") in lt
          | _ -> rt) in
        let _ = check_assign lt rt ("List type should match List Explicit: " ^ string_of_typ lt ^ " != " ^ string_of_typ rt) in
        (rt, SAssign(var, (rt, sxs))) *)
    | Assign (var, e) as ex -> 
        let lt = type_of_identifier var envs in
        let (rt, e') = check_expr e envs not_toplevel in
        let rt = (match e' with SListExplicit [] -> lt | _ -> rt) in
        let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
          string_of_typ rt ^ " in " ^ string_of_expr ex in
        let _ = check_assign lt rt err 
        in (lt, SAssign(var, (rt, e')))
    | Unop(op, e) as ex -> 
        let (t, e') = check_expr e envs not_toplevel in
        let ty = match op with
          Neg when t = Int || t = Float || t = Char -> t
        | Not when t = Bool -> Bool
        | _ -> raise (Failure ("illegal unary operator " ^ 
                                string_of_uop op ^ string_of_typ t ^
                                " in " ^ string_of_expr ex))
        in (ty, SUnop(op, (t, e')))
    | Binop(e1, op, e2) as e -> 
        let (t1, e1')  = check_expr e1 envs not_toplevel in
        let (t2, e2') = check_expr e2 envs not_toplevel in
        (* All binary operators require operands of the same type *)
        let same = t1 = t2 in
        (* Determine expression type based on operator and operand types *)
        (* Used for arithmetic *)
        let resultFloat = function
            Char -> true
          | Int -> true
          | Float -> true
          | _ -> false
        in
        let resultInt = function
            Char -> true
          |  Int -> true
          | _ -> false
        in
        let ty = match op with
          Add when same && (t1 = Char || t1 = String) -> String
        | Add | Sub | Mult | Div when same && (t1 = Int || t1 = Float || t1 = Char)   -> t1
        | Add | Sub | Mult | Div when (resultInt t1 && resultInt t2)  -> Int
        | Add | Sub | Mult | Div when (resultFloat t1 && resultFloat t2) -> Float
        (* Potential route *)
        (* | expr Assign(e1, SBinop((t1, e1'), op, (t2, e2'))) *)
        | Mod when same && (t1 = Int || t1 = Char) -> t1
        | Equal | Neq            when same               -> Bool
        | Less | Leq | Greater | Geq
                    when same && (t1 = Int || t1 = Float) -> Bool
        | And | Or when same && t1 = Bool -> Bool
        | _ -> raise (
            Failure ("illegal binary operator " ^
                      string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                      string_of_typ t2 ^ " in " ^ string_of_expr e))
        in (ty, SBinop((t1, e1'), op, (t2, e2')))
    | Call (fname, args) as call ->
        let sfd = find_func fname in
        let param_length = List.length sfd.sformals in
        if List.length args != param_length then
          raise (Failure ("expecting " ^ string_of_int param_length ^ 
                          " arguments in " ^ string_of_expr call))
        (* Compare types of arguments to expected types of functions *)
        else let check_call (args: sexpr list) (formal_t, _) e = 
          (* Ensure that templated calls work here *)
          let ((et, sx) as se) = check_expr e envs not_toplevel in
          (* Correct empty list types if necessary *)
          let et = (match sx with (SListExplicit []) -> List (formal_t) | _ -> et) in
          let err = "illegal argument found " ^ string_of_typ et ^
            " expected " ^ string_of_typ formal_t ^ " in " ^ string_of_expr e in
          let _ = check_assign formal_t et err
          in (se::args)
        in
      let args' = List.fold_left2 check_call [] sfd.sformals args
      in (sfd.styp, SCall(fname, List.rev args'))

      (* TODO: For now, we assume any list is not empty.
         Empty lists will require some sort of type inference *)
      (* | ListExplicit [] -> (raise (Failure "Zero element lists are not yet implemented!")) 
      | ListExplicit exprs ->
          let (ty, sx) = check_expr e envs is_toplevel in        

          let check_list_expr envs exprs sx =
            let (ty', sx') = check_expr e envs is_toplevel in
            if ty == ty' then (ty, sx' :: sx)
                         else (Failure "This expression's type does not match the list's type!")
        in List.fold_left check_list_exprs envs exprs [sx] *)
        
    (* TODO: Empty lists nested in something else *)
    | ListExplicit [] -> (List (Int), SListExplicit [])
    | ListExplicit exprs ->
        let sexprs = List.map(fun e -> check_expr e envs not_toplevel) exprs in
        let (t, _) = List.hd sexprs in
        let _ = List.map (fun (ty, _) -> check_assign t ty ("Types of elements in list do not match: " ^ string_of_typ t ^ " != " ^ string_of_typ ty)) sexprs in
        (List(t), SListExplicit sexprs)
    | StructAssign (names, e) -> (match names with
        [] -> raise (Failure "This isn't possible")
      | first :: rest -> 
        (* Check that the struct name is in the env *)
        let ltyp = type_of_identifier first envs in
        let (first_name, struc) = find_struc_from_typ ltyp in
      
        (* get the names of the rest of the structs, and the type that
           eventually is returned *)
        let (rest_names, lt) = find_nested_structs rest struc in

        let (rt, e') = check_expr e envs not_toplevel in
        let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
          string_of_typ rt ^ " in " ^ string_of_expr e in
        let _ = check_assign lt rt err in
        (lt, SStructAssign(first_name :: rest_names, names, (rt, e'))))

    | StructAccess (names) -> (match names with
        [] -> raise (Failure "This isn't possible")
      | first :: rest ->
        (* Check that the struct name is in the env *)
        let ltyp = type_of_identifier first envs in
        let (first_name, struc) = find_struc_from_typ ltyp in
        (* get the names of the rest of the structs, and the type that
           eventually is returned *)
        let (rest_names, lt) = find_nested_structs rest struc in

        (* Check that the struct id is in the struct *)
        (lt, SStructAccess(first_name :: rest_names, names)))


        
    | TemplatedCall _ -> raise (Failure "there should be no templated calls at semant")
    | BindAssign _  | BindDec _ -> raise (Failure "Nested BindDec and BindAssign are not permitted")
    | _  -> raise (Failure "Expr not handled yet")
  in

  let check_bool_expr e envs = 
    let (t', e') = check_expr e envs not_toplevel
    and err = "expected Boolean expression in " ^ string_of_expr e
    in if t' != Bool then raise (Failure err) else (t', e')
  in

  (* let rec check_stmt_expr: This should allow bindings. It matches against bindings, and semantically checks those.
    Everything else uses regular check_expr. Then, bindings in check_expr should raise an error 
    A for loop needs to use check_stmt_expr
  in check_stmt, expression case just uses check_stmt_expr *)
  let check_stmt_expr e envs is_toplevel = match e with 
      (* Bind the variable in the topmost environment. *)
      BindAssign (typ, id, e1) ->
        (* if !in_assign then raise (Failure "Nested assigns are not allowed")
        else *)
        (* let _ = (match typ with 
                  Struct(s) ->) *)
        (* difference is the binds *)
        (* let _ = in_assign := true in *)
        
        let envs' = 
          if is_toplevel then
            let _ = bind_global id typ in envs
          else
            bind id typ envs
        in
        (match typ with
          Struct(s) | Templated(s) -> 
            let struc_body = find_struc s in
            let struc_formals = struc_body.ssformals in
            let formals_length = List.length struc_formals in
            let struct_explicit = (match e1 with 
                StructExplicit(l) -> l
              | _ -> raise(Failure("Not Struct explicit"))) 
            in
            if List.length struct_explicit != formals_length then
              raise (Failure ("expecting " ^ string_of_int formals_length ^ 
                              " arguments in struct" ^ struc_body.sname))
            else 
            (* build sexpr list *)
            let sstruct_explicit = List.map (fun e -> let (e2) = check_expr e envs not_toplevel in e2) struct_explicit in
            (* check for equal types *)
            let _ = List.map2 (fun (lt, _) (rt, _) -> 
              let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ string_of_typ rt in
              check_assign lt rt err
              ) struc_formals sstruct_explicit in
            (envs', (Struct(s), SStructExplicit(typ, id, sstruct_explicit)))
          | _ -> 
            let (t, e1') = check_expr e1 envs' not_toplevel
            in
            let t = (match e1' with SListExplicit [] -> typ | _ -> t) in
            let err = "illegal assignment " ^ string_of_typ typ ^ " = " ^ string_of_typ t ^ " in " ^ string_of_expr e in
            let _ = check_assign typ t err in
            (* let _ = in_assign := false in *)
            (envs', (typ, SBindAssign(typ, id, (t, e1')))))
      
    | BindDec (typ, id) -> 
        (* check if the typ is struct that it is in the struct map *)
        let _ = 
          (match typ with 
              Struct(s) -> 
                (* let _ = print_endline id in  *)
                let _ = find_struc s in ()
            | _ -> () )
        in
        (match is_toplevel with 
          (* Not at top level *)
          false -> 
            let envs' = bind id typ envs in
            (* let first_env = List.hd envs' in
            let _ = StringMap.iter (fun k v -> Printf.printf "Key: %s, Value: %s\n" k (string_of_typ v)) first_env in *)
            (envs', (typ, SBindDec(typ, id)))
          (* At top level *)
        | true ->  
              let _ = bind_global id typ in 
              (* let _ = StringMap.iter (fun k v -> Printf.printf "Key: %s, Value: %s\n" k (string_of_typ v)) !globals in *)
              (envs, (typ, SBindDec(typ, id))))    
    | _ -> (envs, check_expr e envs is_toplevel)
  in

  (* Return a semantically-checked statement i.e. containing sexprs *)
  let rec check_stmt (envs: typ StringMap.t list) stmt is_toplevel is_inloop = match stmt with
      Block stmts ->
        (* A new block creates a new scoping, so we need to create a new
            environment for this block *)
        let rec check_stmt_list envs stmts = match stmts with
            [Return _ as s] -> let (_, sstmt) = check_stmt envs s not_toplevel is_inloop in [sstmt]
          | Return _ :: _ -> raise (Failure "Bad coding practice! Nothing should follow a return statement")
          | Block _ as block :: stmts ->
              let (_, sstmt) = check_stmt (StringMap.empty :: envs) block not_toplevel is_inloop and
                  sstmts = check_stmt_list envs stmts in (sstmt :: sstmts)
          | stmt :: stmts ->
              let (envs', sstmt) = check_stmt envs stmt not_toplevel is_inloop in
              let sstmts = check_stmt_list envs' stmts in (sstmt :: sstmts)
          | [] -> []
        in (envs, SBlock(check_stmt_list (StringMap.empty :: envs) stmts))
    | Expr e -> 
        let (envs', se) = check_stmt_expr e envs is_toplevel in
        (* let first_env = List.hd envs' in
        let _ = StringMap.iter (fun k v -> Printf.printf "expr Key: %s, Value: %s\n" k (string_of_typ v)) first_env in *)
        (envs', SExpr(se))
    | If(p, b1, b2) -> 
        let p' = check_bool_expr p envs in
        let (envs', b1') = check_stmt envs b1 not_toplevel is_inloop in
        let (_, b2') = check_stmt envs' b2 not_toplevel is_inloop in 
      (envs, SIf(p', b1', b2'))
    | For(e1, e2, e3, st) -> 
        let (envs', e1') = check_stmt_expr e1 envs not_toplevel in
        let e2' = check_bool_expr e2 envs' in
        let e3' = check_expr e3 envs' not_toplevel in
        let (_, st') = check_stmt envs' st not_toplevel inloop in
        (envs, SFor(e1', e2', e3', st'))
    | While(p, s) -> 
      let p' = check_bool_expr p envs in
      let (_, s') = check_stmt envs s not_toplevel inloop in
      (envs, SWhile(p', s'))
    | Return e -> let e' = check_expr e envs not_toplevel in
                  (envs, SReturn(e'))
    (* | ForEnhanced (e1, e2, st) -> *)
    | Continue -> if is_inloop = inloop then (envs, SContinue) 
                  else raise (Failure "Continue cannot be outside a loop")
    | Break -> if is_inloop = inloop then (envs, SBreak)
                else raise (Failure "Break cannot be outside a loop")

    | _ -> raise (Failure "Unhandled statement")

in

  (* Checks that each return in a list of statements is of the correct type *)
  (* TODO: Check that a returm statement is always reachable *)
  let check_return (sl : sstmt list) f =
    let ret_ty = f.typ in
    let rec check_stmt_return = function
        SReturn (t, _) when t = ret_ty -> ()
      | SReturn (t, _) -> raise (Failure ("Function " ^ f.fname ^ " has return type " ^
                                          " " ^ string_of_typ ret_ty ^ " but expected " ^
                                          string_of_typ t ^ " in return statement"))
      | SBlock sl -> List.iter check_stmt_return sl
      | _ -> ()
    in List.iter check_stmt_return sl
  in 

  let check_function func =
    (* Make sure no formals or locals are void or duplicates *)
    let formals' = check_binds "formal" func.formals in
    let env = List.fold_left (fun env (ty, name) -> StringMap.add name ty env)
      StringMap.empty formals' in
    let (_, sbody) = check_stmt [env] (Block func.body) not_toplevel not_inloop in
    let sstmt_list = match sbody with
        SBlock(sl) -> sl
      | _ -> raise (Failure "Internal error: block didn't become a block??") in
    let _ = check_return sstmt_list func in
    let sfd = 
      { 
        styp = func.typ;
        sfname = func.fname;
        sformals = formals';
        slocals  = [];
        sbody = sstmt_list ;
      }
    in let _ = add_func sfd in sfd
  in

  let check_program_unit (envs, sunits) prog_unit =
    match prog_unit with
        (* TODO: Make sure envs is updated after every check *)
        Stmt(s) -> let (envs, sstmt) = check_stmt envs s toplevel not_inloop in (envs, SStmt(sstmt) :: sunits)
      | Fdecl(f) -> let sf = check_function f in (envs, SFdecl(sf) :: sunits)
      | _ -> raise (Failure "Unimplemented units")

    (* | Fdecl(f) -> raise (Failure "Unimplemented functions")
    | Sdecl(st) -> raise (Failure "Unimplemented structs") *)
  in let envs = [StringMap.empty] 
  in let (_, sunits) = (List.fold_left check_program_unit (envs, []) units) in List.rev sunits
