(* Semantic checking for the MicroC compiler *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check units =

  (* Check if a certain kind of binding has void type or is a duplicate
     of another, previously checked binding *)
  (* let check_binds (kind : string) (to_check : bind list) = 
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
  in  *)

  (**** Checking Global Variables ****)

  (* let globals' = check_binds "global" globals in *)

  (**** Checking Functions ****)


  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_bind map (name, ty) = StringMap.add name {
      typ = Int; fname = name; 
      formals = [(ty, "x")];
      body = []; fun_t_list = []; } map
    in List.fold_left add_bind StringMap.empty [ ("print", Int);
                                                 ("printb", Bool);
                                                 ("printf", Float)]
  (* let built_in_decls = 
    let add_bind map(name, return_typ) = StringMap.add name {
      typ = return_typ; fname = name; 
      formals = [("T", "x")];
      body = []; fun_t_list = ["T"]; } map
    in List.fold_left add_bind StringMap.empty [ ("print", Int);
                                                 ("println", Int);
                                                 ("to_str", String); *)
                                                 (* ("printb", Bool); *)
                                                 (* ("printf", Float); *)
                                                 (* ("printbig", Int) *)
  in

  (* Add function name to symbol table *)
  (* let add_func map fd = 
    let built_in_err = "function " ^ fd.fname ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.fname
    and make_err er = raise (Failure er)
    and n = fd.fname (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
         _ when StringMap.mem n built_in_decls -> make_err built_in_err
       | _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n fd map 
  in *)

  (* Collect all other function names into one symbol table *)
  (* let function_decls = List.fold_left add_func built_in_decls functions
  in *)
  
  (* Return a function from our symbol table *)
  let find_func s = 
    try StringMap.find s built_in_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  (* let _ = find_func "main" in Ensure "main" is defined *)

  (* let check_function func =
    (* Make sure no formals or locals are void or duplicates *)
    let formals' = check_binds "formal" func.formals in
    let locals' = check_binds "local" func.locals in *)

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign (lvaluet: typ) (rvaluet: typ) err =
       if lvaluet = rvaluet then lvaluet else raise (Failure err) in
    (* Return a variable from our local symbol table *)
    let rec type_of_identifier id (envs: typ StringMap.t list) = match envs with
        [] -> raise (Failure ("Undeclared identifier " ^ id))
      | env :: envs -> try StringMap.find id env
                          with Not_found -> type_of_identifier id envs in
    let bind id (ty: typ) env = match env with
        [] -> raise (Failure ("BUG IN COMPILER: no environments"))
      | env :: envs -> StringMap.add id ty env :: envs
    in 

    (* let type_of_identifier s = 
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in *)


    (* Return a semantically-checked expression, i.e., with a type *)
    let rec check_expr e envs = match e with
        Literal  l -> (envs, (Int, SLiteral l))
      | Fliteral l -> (envs, (Float, SFliteral l))
      | BoolLit l  -> (envs, (Bool, SBoolLit l))
      | CharLit l -> (envs, (Char, SCharlit l))
      | StringLit l -> (envs, (String, SStringlit l))
      | Noexpr     -> (envs, (Int, SNoexpr))
      | Id s       -> (envs, (type_of_identifier s envs, SId s))
      (* Bind the variable in the topmost environment. *)
      | BindAssign (typ, id, e1) ->
          let envs' = bind id typ envs in
          let (envs'', (t, e1')) = check_expr e1 envs' in
          let err = "illegal assignment " ^ string_of_typ typ ^ " = " ^
            string_of_typ t ^ " in " ^ string_of_expr e in
          let _ = check_assign typ t err
          in (envs'', (typ, SBindAssign(typ, id, (t, e1'))))
      | BindDec (typ, id) -> 
          let envs' = bind id typ envs
          in (envs', (typ, SBindDec(typ, id)))
      | Assign(var, e) as ex -> 
          let lt = type_of_identifier var envs in
          let (envs'', (rt, e')) = check_expr e envs in
          let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
            string_of_typ rt ^ " in " ^ string_of_expr ex in
          let _ = check_assign lt rt err 
          in (envs'', (lt, SAssign(var, (rt, e'))))
      | Unop(op, e) as ex -> 
          let (envs', (t, e')) = check_expr e envs in
          let ty = match op with
            Neg when t = Int || t = Float -> t
          | Not when t = Bool -> Bool
          | _ -> raise (Failure ("illegal unary operator " ^ 
                                 string_of_uop op ^ string_of_typ t ^
                                 " in " ^ string_of_expr ex))
          in (envs', (ty, SUnop(op, (t, e'))))
      | Binop(e1, op, e2) as e -> 
          let (envs', (t1, e1'))  = check_expr e1 envs in
          let (envs'', (t2, e2')) = check_expr e2 envs' in
          (* All binary operators require operands of the same type *)
          let same = t1 = t2 in
          (* Determine expression type based on operator and operand types *)
          let ty = match op with
            Add | Sub | Mult | Div when same && (t1 = Int || t1 = Float)   -> t1
          | Add | Sub | Mult | Div when (t1 = Int && t2 = Float) || (t1 = Float && t2 = Int) -> Float
          (* Potential route *)
          (* | expr Assign(e1, SBinop((t1, e1'), op, (t2, e2'))) *)
          | Mod when same && t1 = Int -> t1
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
          let fd = find_func fname in
          let t_len = List.length fd.fun_t_list in
          if t_len != 0 then
            raise (Failure ("Compiler error: templates may not exist in function calls"))
          else let param_length = List.length fd.formals in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          (* Compare types of arguments to expected types of functions *)
          else let check_call (envs, (args: sexpr list)) (formal_t, _) e = 
            (* Ensure that templated calls work here *)
            let (envs', ((et, _) as se)) = check_expr e envs in 
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ formal_t ^ " in " ^ string_of_expr e in
            let _ = check_assign formal_t et err
            in (envs', se::args)
          in
        let (envs', args') = List.fold_left2 check_call (envs, []) fd.formals args
        in (envs', (fd.typ, SCall(fname, List.rev args')))


        (* | TemplatedCall (fname, t_list, args) as call ->
          let fd = find_func fname in
          let template_length = List.length fd.fun_t_list in
          if List.length t_list != template_length then
            raise (Failure ("expecting " ^ string_of_int template_length ^ 
                            " templates in " ^ string_of_expr call))
          else let param_length = List.length fd.formals in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          (* Creating a template string : type  map *)
          else let t_ = List.fold_left2 (fun ft t map -> StringMap.add ft t map) StringMap.empty fd.fun_t_list t_list in
          (* args has to check the string map additionally *)
          let check_args (ft, _ ) a s = 
            let (et, e') = expr e in
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
          in  *)
          (* build a t list *)

      | _  -> raise (Failure "Expr not handled yet")
    in

    (* let check_bool_expr e = 
      let (t', e') = expr e
      and err = "expected Boolean expression in " ^ string_of_expr e
      in if t' != Bool then raise (Failure err) else (t', e') 
    in *)

    (* Return a semantically-checked statement i.e. containing sexprs *)
    let rec check_stmt (envs: typ StringMap.t list) stmt = match stmt with
        Block stmts ->
          (* A new block creates a new scoping, so we need to create a new
             environment for this block *)
          let rec check_stmt_list envs stmts = match stmts with
              [Return _ as s] -> let (_, sstmt) = check_stmt envs s in [sstmt]
            | Return _ :: _ -> raise (Failure "Bad coding practice! Nothing should follow a return statement")
            | Block _ as block :: stmts ->
                let (_, sstmt) = check_stmt (StringMap.empty :: envs) block and
                    sstmts = check_stmt_list envs stmts in (sstmt :: sstmts)
            | stmt :: stmts ->
                let (envs', sstmt) = check_stmt envs stmt in
                let sstmts = check_stmt_list envs' stmts in (sstmt :: sstmts)
            | [] -> []
          in (envs, SBlock(check_stmt_list (StringMap.empty :: envs) stmts))
      | Expr e -> 
          let (envs', se) = check_expr e envs in
          (envs', SExpr(se))
      (* | If(p, b1, b2) -> SIf(check_bool_expr p, check_stmt b1, check_stmt b2)
      | For(e1, e2, e3, st) ->
          SFor(expr e1, check_bool_expr e2, expr e3, check_stmt st)
      | While(p, s) -> SWhile(check_bool_expr p, check_stmt s)
      | Return e -> let (t, e') = expr e in
        if t = func.typ then SReturn (t, e') 
        else raise (
          Failure ("return gives " ^ string_of_typ t ^ " expected " ^
                   string_of_typ func.typ ^ " in " ^ string_of_expr e)) *)
      | _ -> raise (Failure "Unhandled statement")


    (* in (* body of check_function *)
    { styp = func.typ;
      sfname = func.fname;
      sformals = formals';
      slocals  = locals';
      sbody = match check_stmt (Block func.body) with
        SBlock(sl) -> sl
      | _ -> let err = "internal error: block didn't become a block?"
      in raise (Failure err)
    } *)
    in
    let check_program_unit prog_unit =
      let env = StringMap.empty in
      let envs = [env] in
      match prog_unit with
          Stmt(s) -> let (_, sstmt) = check_stmt envs s in SStmt(sstmt)
        | _ -> raise (Failure "Unimplemented units")

    (* | Fdecl(f) -> raise (Failure "Unimplemented functions")
    | Sdecl(st) -> raise (Failure "Unimplemented structs") *)
  in (List.map check_program_unit units)
