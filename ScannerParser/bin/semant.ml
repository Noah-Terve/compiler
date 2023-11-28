(* Semantic checking for the MicroC compiler *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (units : program) =
  let not_toplevel = false in
  let toplevel = true in
  let in_assign = ref false in

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
    let add_bind map (name, ty) = StringMap.add name {
      styp = Int; sfname = name; 
      sformals = [(ty, "x")];
      sbody = []; sfun_t_list = []; slocals = []; } map
    in List.fold_left add_bind StringMap.empty [ ("printi", Int);
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


    (* Return a semantically-checked expression, i.e., with a type *)
  let rec check_expr e envs is_toplevel = match e with
      Literal  l -> (envs, (Int, SLiteral l))
    | Fliteral l -> (envs, (Float, SFliteral l))
    | BoolLit l  -> (envs, (Bool, SBoolLit l))
    | CharLit l -> (envs, (Char, SCharlit l))
    | StringLit l -> (envs, (String, SStringlit l))
    | Noexpr     -> (envs, (Int, SNoexpr))
    | Id s       -> (envs, (type_of_identifier s envs, SId s))
    (* Bind the variable in the topmost environment. *)
    | BindAssign (typ, id, e1) ->
        if !in_assign then raise (Failure "Nested assigns are not allowed")
        else
        (match is_toplevel with 
          (* Not at top level *)
          false -> 
              let _ = in_assign := true in
              let envs' = bind id typ envs in
              let (envs'', (t, e1')) = check_expr e1 envs' not_toplevel in
              let err = "illegal assignment " ^ string_of_typ typ ^ " = " ^ string_of_typ t ^ " in " ^ string_of_expr e in
              let _ = check_assign typ t err in
              let _ = in_assign := false in
              (envs'', (typ, SBindAssign(typ, id, (t, e1')))) 
          (* At top level *)
        | true -> 
              let _ = in_assign := true in
              let _ = bind_global id typ in 
              let (envs', (t, e1')) = check_expr e1 envs not_toplevel in
              let _ = in_assign := false in
              (envs', (typ, SBindAssign(typ, id ,(t, e1')))))
        
    | BindDec (typ, id) -> 
        (match is_toplevel with 
          (* Not at top level *)
          false -> 
            let envs' = bind id typ envs in
            (* let first_env = List.hd envs' in
            let _ = StringMap.iter (fun k v -> Printf.printf "Key: %s, Value: %s\n" k (string_of_typ v)) first_env in *)
            envs', (typ, SBindDec(typ, id))
          (* At top level *)
        | true ->  
              let _ = bind_global id typ in 
              (envs, (typ, SBindDec(typ, id))))

    | Assign(var, e) as ex -> 
        let lt = type_of_identifier var envs in
        let (envs'', (rt, e')) = check_expr e envs not_toplevel in
        let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
          string_of_typ rt ^ " in " ^ string_of_expr ex in
        let _ = check_assign lt rt err 
        in (envs'', (lt, SAssign(var, (rt, e'))))
    | Unop(op, e) as ex -> 
        let (envs', (t, e')) = check_expr e envs not_toplevel in
        let ty = match op with
          Neg when t = Int || t = Float || t = Char -> t
        | Not when t = Bool -> Bool
        | _ -> raise (Failure ("illegal unary operator " ^ 
                                string_of_uop op ^ string_of_typ t ^
                                " in " ^ string_of_expr ex))
        in (envs', (ty, SUnop(op, (t, e'))))
    | Binop(e1, op, e2) as e -> 
        let (envs', (t1, e1'))  = check_expr e1 envs not_toplevel in
        let (envs'', (t2, e2')) = check_expr e2 envs' not_toplevel in
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
        in (envs'', (ty, SBinop((t1, e1'), op, (t2, e2'))))
    | Call(fname, args) as call -> 
        let sfd = find_func fname in
        let t_len = List.length sfd.sfun_t_list in
        if t_len != 0 then
          raise (Failure ("Compiler error: templates may not exist in function calls"))
        else let param_length = List.length sfd.sformals in
        if List.length args != param_length then
          raise (Failure ("expecting " ^ string_of_int param_length ^ 
                          " arguments in " ^ string_of_expr call))
        (* Compare types of arguments to expected types of functions *)
        else let check_call (envs, (args: sexpr list)) (formal_t, _) e = 
          (* Ensure that templated calls work here *)
          let (envs', ((et, _) as se)) = check_expr e envs not_toplevel in 
          let err = "illegal argument found " ^ string_of_typ et ^
            " expected " ^ string_of_typ formal_t ^ " in " ^ string_of_expr e in
          let _ = check_assign formal_t et err
          in (envs', se::args)
        in
      let (_, args') = List.fold_left2 check_call (envs, []) sfd.sformals args
      in (envs, (sfd.styp, SCall(fname, List.rev args')))


    | TemplatedCall _ -> raise (Failure "there should be no templated calls at semant")
    | _  -> raise (Failure "Expr not handled yet")
  in

  let check_bool_expr e envs = 
    let (envs', (t', e')) = check_expr e envs not_toplevel
    and err = "expected Boolean expression in " ^ string_of_expr e
    in if t' != Bool then raise (Failure err) else (envs', (t', e'))
  in

  (* Return a semantically-checked statement i.e. containing sexprs *)
  let rec check_stmt (envs: typ StringMap.t list) stmt is_toplevel = match stmt with
      Block stmts ->
        (* A new block creates a new scoping, so we need to create a new
            environment for this block *)
        let rec check_stmt_list envs stmts = match stmts with
            [Return _ as s] -> let (_, sstmt) = check_stmt envs s not_toplevel in [sstmt]
          | Return _ :: _ -> raise (Failure "Bad coding practice! Nothing should follow a return statement")
          | Block _ as block :: stmts ->
              let (_, sstmt) = check_stmt (StringMap.empty :: envs) block not_toplevel and
                  sstmts = check_stmt_list envs stmts in (sstmt :: sstmts)
          | stmt :: stmts ->
              let (envs', sstmt) = check_stmt envs stmt not_toplevel in
              let sstmts = check_stmt_list envs' stmts in (sstmt :: sstmts)
          | [] -> []
        in (envs, SBlock(check_stmt_list (StringMap.empty :: envs) stmts))
    | Expr e -> 
        let (envs', se) = check_expr e envs is_toplevel in
        (* let first_env = List.hd envs' in
        let _ = StringMap.iter (fun k v -> Printf.printf "expr Key: %s, Value: %s\n" k (string_of_typ v)) first_env in *)
        (envs', SExpr(se))
    | If(p, b1, b2) -> 
        let (envs', p') = check_bool_expr p envs in
        let (envs'', b1') = check_stmt envs' b1 not_toplevel  in
        let (_, b2') = check_stmt envs'' b2 not_toplevel  in 
      (envs, SIf(p', b1', b2'))
    | For(e1, e2, e3, st) -> 
        let (envs', e1') = check_expr e1 envs not_toplevel in
        let (envs'', e2') = check_bool_expr e2 envs' in
        let (envs''', e3') = check_expr e3 envs'' not_toplevel in
        let (_, st') = check_stmt envs''' st not_toplevel in
        (envs, SFor(e1', e2', e3', st'))
    | While(p, s) -> 
      let (envs', p') = check_bool_expr p envs in
      let (_, s') = check_stmt envs' s not_toplevel in
      (envs, SWhile(p', s'))
    | Return e -> let (_, e') = check_expr e envs not_toplevel in
                  (envs, SReturn(e'))
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
    let (_, sbody) = check_stmt [env] (Block func.body) not_toplevel in
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
        sfun_t_list = [];
      }
    in let _ = add_func sfd in sfd
  in

  let check_program_unit (envs, sunits) prog_unit =
    match prog_unit with
        (* TODO: Make sure envs is updated after every check *)
        Stmt(s) -> let (envs, sstmt) = check_stmt envs s toplevel in (envs, SStmt(sstmt) :: sunits)
      | Fdecl(f) -> let sf = check_function f in (envs, SFdecl(sf) :: sunits)
      | _ -> raise (Failure "Unimplemented units")

    (* | Fdecl(f) -> raise (Failure "Unimplemented functions")
    | Sdecl(st) -> raise (Failure "Unimplemented structs") *)
  in let envs = [StringMap.empty] 
  in let (_, sunits) = (List.fold_left check_program_unit (envs, []) units) in List.rev sunits
