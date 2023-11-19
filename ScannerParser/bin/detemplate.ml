open Ast
module StringMap = Map.Make(String)

let detemplate (units) = 
  (* functions and structs that are instatiated *)
  let resolved_functions = StringMap.empty in
  let resolved_structs = StringMap.empty in
  (* functions and structs that are templated *)
  let known_templates_funcs = StringMap.empty in
  let known_templated_structs = StringMap.empty in
  
  let get_return_type t = (match t with
      Templated (templ) -> 
      | _ -> t
    )
  (* Given a function declaration and a list of types, replace type variables
     in the declaration with the corresponding type *)
  let rec resolveFunctionTyvars (Fdecl(typ fname formals body fun_t_list) as fdecl) ty_list = 
    match fun_t_list with
        [] -> fdecl
      | _  ->
        let fun_t_list_len = List.length fun_t_list in
        let ty_list_len = List.length ty_list in
        if fun_t_list_len = ty_list_len then
          (* Create a new formals list *)
          let new_fname = "_" ^ fname ^ "." ^ (String.)oncat "." (List.map string_of_typ ty_lis)
          let new_formals = List.map2 (fun (typ, name) ty -> (ty, name)) formals ty_list in
          (* Create a new return type if needed *)
          let new_type = get_return_type 
          (* Create a new body *)
          let new_body = List.map resolveTemplates body
  in 
  (* let rec addNewBindings 
  in *)

  
  let rec resolveTemplates uni_t acc = (match uni_t with 
      Fdecl(typ fname formals body fun_t_list) as fdecl -> match fun_t_list with
          [] -> let _ = StringMap.add fname fdecl resolved_functions in fdecl :: acc
                
          (* Replace all type variables in the function definition with a specified
             type variable.  *)
          | template_list -> StringMap.add fname fdecl known_templated_funcs in acc       
        
        
    | Stmt  (stmt)    -> match stmt with
        (* Get the templated calls *)
        TemplatedCall (s, t_list, e_list) -> 
          (*  Look for it in known_templates_funcs *)
          
          (* to_template is the Function struct *)
          let to_template = try Stringmap.find s known_templates_funcs
              with Not_found -> raise (Failure ("Undeclared Function " ^ s)) in
          
          if List.length t_list = List.length to_template.fun_t_list then
          resolveFunctionTyvars to_template t_list
            
          else raise (Failure "Template Parameters do not match with Function Declaration")
          
          
        (*  Recursive version here if there is another instatiation here *)
      | Stmt (nestedStmt) -> resolveTemplates nestedStmt
          
      | _ -> 
        
        (* Get the templated data structures *)
    | Sdecl (s)   ->   )

    in
  
  
  (* given a prog_unit, remove the structs and functions that are templated, as we have resolved all templates at this point *)
  let removeTemplates elem acc = match elem with
      Fdecl(func) ->  match func.fun_t_list with
                      (* if an empty list its not a tempalted function, if non empty, remove it *)
                      [] -> Fdecl(func) :: acc
                      _ -> acc

    | Sdecl(struc) -> match struc.t_list with
                      (* if an empty list its not a tempalted struct, if non empty, remove it *)
                      [] -> Sdecl(struc) :: acc
                      _ -> acc
                      
    | Stmt(stmt) -> Stmt(stmt) :: acc
     
  
  List.fold_left resolveTemplates [] units in
  
  (* List.rev (List.fold_left removeTemplates [] fin) *)



(* 

Template <T>
T foo (T x) {return x;}

@l int @r foo (5);

-----------------------
after mapping resolvetemplates
(fin)

Template <T>
T foo (T x) {return x;}

int _foo.int (int x) {return x;}

_foo.int (5);

------------------------
after remove templates

int _foo.int (int x) {return x;}

_foo.int (5);
*)