* We'll refer to Llvm and Ast constructs with module names *)
module L = Llvm
module A = Ast
open Sast
module StringMap = Map.Make(String)
(* Code Generation from the SAST. Returns an LLVM module if successful,
throws an exception if something is wrong. *)
let translate (globals, functions) =
let get_sbind_tuple (binding : sbind) =
match binding with
| SBindDec(t, n) > (t, n)
| SBindAssign(t, n, e) > (t, n)
in
let context = L.global_context () in
(* Add types to the context so we can use them in our LLVM code *)
let i32_t = L.i32_type context
and i8_t = L.i8_type context
and i1_t = L.i1_type context
and str_t = L.pointer_type (L.i8_type context)
and void_t = L.void_type context
(* Create an LLVM module this is a "container" into which we'll
generate actual code *)
and the_module = L.create_module context "Union" in
let to_imp str = raise (Failure (str ^ " not implemented yet")) in
(* Convert Union types to LLVM types *)
let rec ltype_of_typ = function
        A.Int > i32_t
      | A.Bool > i1_t
      | A.String > str_t
      | A.Void > void_t
      | A.Set(t) > L.pointer_type (L.struct_type context (Array.of_list([
              L.pointer_type (ltype_of_typ t);
              i32_t
              ])))
      | A.Tuple(tl) > L.pointer_type (L.struct_type context (Array.of_list([
            L.pointer_type (L.struct_type context (Array.of_list(List.map
            ltype_of_typ tl)));
            i32_t
            ])))
      | A.Unknown > raise (Failure ("Cannot convert Unknown type!"))
      256
in
(* Declare each global variable; remember its value in a map *)
let global_vars =
let global_var m (binding : sbind) =
let (t, n) = get_sbind_tuple binding in
(* TODO: Account for set and tuple types *)
(* TODO: Account for bindAssign *)
if (ltype_of_typ t = str_t)
    then (
    let init = L.const_null str_t in
    StringMap.add n (L.define_global n init the_module) m
    )
      else (
      let init = L.const_int (ltype_of_typ t) 0 in
      StringMap.add n (L.define_global n init the_module) m
      ) in
List.fold_left global_var StringMap.empty globals in
(* Declare built in c functions *)
let printf_t = L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
let printf_func = L.declare_function "printf" printf_t the_module in
let strcomp_t = L.var_arg_function_type i32_t [| str_t; str_t |] in
let strcomp_func = L.declare_function "strcomp" strcomp_t the_module in
let rando_t = L.var_arg_function_type i32_t [| i32_t; i32_t; i32_t |] in
let rando_func = L.declare_function "rando" rando_t the_module in
(* Define each function (arguments and return type) so we can
* define it's body and call it later *)
let function_decls =
let function_decl m fdecl =
let name = fdecl.sfname
and formal_types =
Array.of_list (List.map (fun (t,_) > ltype_of_typ t) (List.map
get_sbind_tuple fdecl.sformals))
in let ftype = L.function_type (ltype_of_typ fdecl.styp) formal_types in
StringMap.add name (L.define_function name ftype the_module, fdecl) m in
List.fold_left function_decl StringMap.empty functions in
(* Fill in the body of the given function *)
let build_function_body fdecl =
let (the_function, _) = StringMap.find fdecl.sfname function_decls in
let builder = L.builder_at_end context (L.entry_block the_function) in
let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder
257
and string_format_str = L.build_global_stringptr "%s\n" "fmt" builder in
(* Construct the function's "locals": formal arguments and locally
declared variables. Allocate each on the stack, initialize their
value, if appropriate, and remember their values in the "locals" map *)
let local_vars =
let add_formal m (t, n) p =
let () = L.set_value_name n p in
let local = L.build_alloca (ltype_of_typ t) n builder in
let _ = L.build_store p local builder in
StringMap.add n local m
in
(* Allocate space for any locally declared variables and add the
* resulting registers to our map *)
(*
List.fold_left add_local formals (List.map get_sbind_tuple fdecl.slocals)
*)
let formals = List.fold_left2 add_formal StringMap.empty (List.map
get_sbind_tuple fdecl.sformals)
(Array.to_list (L.params the_function))
in
formals
in
let add_local (t, n) cur_builder cur_vars =
let local_var = L.build_alloca (ltype_of_typ t) n cur_builder in
StringMap.add n local_var cur_vars
in
(* Return the value for a variable or formal argument. First check
* locals, then globals *)
let lookup n cur_vars = try StringMap.find n cur_vars
with Not_found > try StringMap.find n global_vars
with Not_found > raise (Failure
("Variable " ^
n ^ " not found in var
map!"))
in
(* Each basic block in a program ends with a "terminator" instruction i.e.
one that ends the basic block. By definition, these instructions must
indicate which basic block comes next they typically yield "void" value
and produce control flow, not values *)
258
(* Invoke "f builder" if the current block doesn't already
have a terminator (e.g., a branch). *)
let add_terminal builder f =
(* The current block where we're inserting instr *)
match L.block_terminator (L.insertion_block builder) with
Some _ > ()
| None > ignore (f builder) in
(* mapping function to make a list of expr builder *)
(* remember to reverse list afterwords! *)
let rec expr_list input output builder' cur_vars' = match input with
[] > (builder', cur_vars', output)
| [e] > let (builder', cur_vars', e') = expr builder' cur_vars' e in
(builder', cur_vars', e' :: output)
| e :: the_rest > let (builder', cur_vars', e') = expr builder'
cur_vars' e in
expr_list (the_rest) (e' :: output) builder' cur_vars'
and
(* Construct code for an expression; return its value *)
expr builder cur_vars (t, e) = match e with
SLiteral i > (builder, cur_vars, L.const_int i32_t i)
| SBoolLit b > (builder, cur_vars, L.const_int i1_t (if b then 1 else
0))
| SStringLit s > (builder, cur_vars, L.build_global_stringptr s "str"
builder)
| SNoexpr > (builder, cur_vars, L.const_int i32_t 0)
| SId s > (builder, cur_vars, L.build_load (lookup s cur_vars) s
builder)
| SBinop (e1, op, e2) >
let (builder, cur_vars, e1') = expr builder cur_vars e1 in
let (builder, cur_vars, e2') = expr builder cur_vars e2 in
let op' = (match op with
| A.Add > L.build_add
| A.Sub > L.build_sub
| A.Mult > L.build_mul
| A.Div > L.build_sdiv
| A.Mod > L.build_srem
| A.And > L.build_and
| A.Or > L.build_or
| A.Equal > L.build_icmp L.Icmp.Eq
| A.Neq > L.build_icmp L.Icmp.Ne
| A.Less > L.build_icmp L.Icmp.Slt
| A.Leq > L.build_icmp L.Icmp.Sle
| A.Greater > L.build_icmp L.Icmp.Sgt
| A.Geq > L.build_icmp L.Icmp.Sge
| _ > to_imp ("Binary operator " ^ A.string_of_op op)
) in
259
(builder, cur_vars, op' e1' e2' "tmp" builder)
| SUnop(op, e) >
let (builder, cur_vars, e') = expr builder cur_vars e in
let op' = (match op with
A.Neg > L.build_neg
| A.Not > L.build_not) in
(builder, cur_vars, op' e' "tmp" builder)
| SAssign (s, e) > let (builder, cur_vars, e') = expr builder cur_vars
e in
let _ = L.build_store e' (lookup s cur_vars)
builder in (builder, cur_vars, e')
| SCall ("print", [e]) > (
let (builder, cur_vars, e') = (expr builder cur_vars e) in
match e with
| (A.String, _) >
(builder, cur_vars, L.build_call printf_func [|
string_format_str ; e' |]
"printf" builder)
| (A.Int, _) >
(builder, cur_vars, L.build_call printf_func [| int_format_str ;
e' |]
"printf" builder)
| (A.Bool, _) >
(builder, cur_vars, L.build_call printf_func [| int_format_str ;
e' |]
"printf" builder)
| _ > raise(Failure("Invalid print() arguments"))
)
| SCall ("len", [e]) >
let (builder, cur_vars, struct_ptr) = expr builder cur_vars e in
let res = L.build_load (L.build_struct_gep struct_ptr 1 "len()"
builder) "length" builder in
(builder, cur_vars, res)
| SCall ("add", [set; element]) >
let (builder, cur_vars, old_struct_ptr) = expr builder cur_vars set
in
let (builder, cur_vars, element_ll) = expr builder cur_vars element
in
(* Populate array with old set's elements using a for loop *)
(* For loop init block *)
(* int ix = 0 *)
let init_bb = L.append_block context "add()_init" the_function in
let init_builder = L.builder_at_end context init_bb in
(* Calculate new set's length *)
let old_length = L.build_load
260
(L.build_struct_gep old_struct_ptr 1 "add()" init_builder )
"old_length" init_builder in
let new_length = L.build_add old_length
(L.const_int i32_t 1) "add()" init_builder in
(* Get array holding old set's elements *)
let old_arr = L.build_load
(L.build_struct_gep old_struct_ptr 0 "add()" init_builder )
"old_set" init_builder in
(* Create array to hold new set's elements *)
let element_ltype = match t with
A.Set typ > ltype_of_typ typ
| _ > raise(Failure("Invalid set typ"))
in
let typ = L.pointer_type element_ltype in
let new_arr = L.build_array_malloc typ new_length "add()"
init_builder in
let new_arr = L.build_pointercast new_arr typ "add()" init_builder
in
(* Add 1 to old_length since array starts at 1 *)
let len = (L.build_add old_length (L.const_int i32_t 1) "temp"
init_builder) in
(* Initialize indexer ix *)
let ix = L.build_alloca i32_t "ix" init_builder in
(* The set element for some reason starts at 1 *)
let _ = L.build_store (L.const_int i32_t 1) ix init_builder in
(* First branch from builder to init *)
let _ = L.build_br init_bb builder in
(* Predicate block *)
(* Check if ix < len *)
let pred_bb = L.append_block context "add()_for_loop" the_function
in
let pred_builder = L.builder_at_end context pred_bb in
(* Then branch from init to pred *)
let _ = L.build_br pred_bb init_builder in
(* For loop body block *)
let body_bb = L.append_block context "add()_for_loop_body"
the_function in
let body_builder = L.builder_at_end context body_bb in
let ix_val = L.build_load ix "ix_val" body_builder in
(* Set new_arr[| ix |] = old_arr[| ix |] *)
let curr_el = L.build_load (L.build_gep old_arr [| ix_val |]
"curr_el_ptr" body_builder) "add()_curr_el" body_builder in
261
ignore(L.build_store curr_el (L.build_gep new_arr [| ix_val |]
"curr_el_ptr" body_builder) body_builder);
(* After for loop body is done ix++ and branch to pred_bb *)
let ix_inc = L.build_add ix_val (L.const_int i32_t 1) "ix_inc"
body_builder in
let _ = L.build_store ix_inc ix body_builder in
let () = add_terminal body_builder (L.build_br pred_bb) in
(* Check bool then cond_branch *)
let ix_val = L.build_load ix "ix_val" pred_builder in
let bool_val = L.build_icmp L.Icmp.Slt ix_val len "bool_val"
pred_builder in
let merge_bb = L.append_block context "add()_for_loop_merge"
the_function in
let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
let merge_builder = L.builder_at_end context merge_bb in
(* End of for loop *)
(* Add new element to the array *)
ignore(L.build_store element_ll (L.build_gep new_arr [| new_length
|]
"set" merge_builder) merge_builder);
(* Create struct with the following form to represent new set:
[<pointer to array holding set's elements>; <size of set>] *)
    let set_struct = (L.struct_type context (Array.of_list([
        L.pointer_type element_ltype;
        i32_t
    ]))) in
    let set_struct_ptr = L.build_malloc set_struct "add()" merge_builder
    in
    (* Populate struct *)
    ignore(L.build_store new_arr (L.build_struct_gep
    set_struct_ptr 0 "add()" merge_builder) merge_builder);
    ignore(L.build_store new_length
    (L.build_struct_gep set_struct_ptr 1 "add()" merge_builder)
    merge_builder);
    (L.builder_at_end context merge_bb, cur_vars, set_struct_ptr)
    | SCall ("range", [x; y; step]) >
    let extract_args e = match e with
    (A.Int, SLiteral(i)) > i
    | (A.Int, SUnop(A.Neg, (A.Int, SLiteral(i)))) > i
    | _ > raise(Failure("Invalid range() arguments"))
    in
      262
      let (x', y', step') = match List.map extract_args [x; y; step] with
      [first; second; third] > (first, second, third)
      | _ > raise(Failure("Invalid range() arguments"))
      in
      let rec get_range_list i j =
      if i == j then []
      else (A.Int, SLiteral(i)) :: get_range_list (i + step') j
      in
      if (x' > y' && step' > 0) || (x' < y' && step' < 0)
      then expr builder cur_vars (A.Tuple([]), STupleLit([]))
      else
      let get_typ_list element = match element with i > A.Int in
      let range_list = get_range_list x' y' in
      expr builder cur_vars (A.Tuple(List.map get_typ_list range_list),
STupleLit(range_list))
| SCall ("strcomp", [e1; e2]) >
let (builder, cur_vars, e1') = (expr builder cur_vars e1)
and (builder', cur_vars', e2') = (expr builder cur_vars e2)
in
(builder', cur_vars', L.build_call strcomp_func [| e1'; e2' |]
"strcomp" builder')
| SCall ("rando", [e1; e2; e3]) >
  let (builder, cur_vars, e1') = (expr builder cur_vars e1)
  and (builder', cur_vars', e2') = (expr builder cur_vars e2)
  and (builder'', cur_vars'', e3') = (expr builder cur_vars e3)
  in
(builder'', cur_vars'', L.build_call rando_func [| e1'; e2'; e3'
|] "rando" builder')
| SCall (f, act) >
let (fdef, fdecl) = StringMap.find f function_decls in
let (builder, cur_vars, actuals) = expr_list (List.rev act) []
builder cur_vars in
let result = (match fdecl.styp with
A.Void > ""
| _ > f ^ "_result") in
(builder, cur_vars, L.build_call fdef (Array.of_list actuals) result
builder)
| SSetExplicit(el) >
(* Create array to hold the set's elements *)
let element_ltype = match t with
A.Set typ > ltype_of_typ typ
| _ > raise(Failure("Invalid set typ"))
in
let size = L.const_int i32_t ((List.length el) + 1) in
let typ = L.pointer_type element_ltype in
let arr = L.build_array_malloc typ size "set" builder in
let arr = L.build_pointercast arr typ "set" builder in
(* Populate array with the set's elements *)
263
let (builder, cur_vars, values) = expr_list el [] builder cur_vars
in
let values = List.rev values in
let buildf i v = (
let arr_ptr = L.build_gep arr [| (L.const_int i32_t (i + 1)) |]
"set" builder in
ignore(L.build_store v arr_ptr builder);
) in List.iteri buildf values;
(* Create struct with the following form to represent the set:
[<pointer to array holding set's elements>; <size of set>] *)
let set_struct = (L.struct_type context (Array.of_list([
L.pointer_type element_ltype;
i32_t
]))) in
let set_struct_ptr = L.build_malloc set_struct "set" builder in
(* Populate struct *)
ignore(L.build_store arr (L.build_struct_gep
set_struct_ptr 0 "set" builder) builder);
ignore(L.build_store (L.const_int i32_t (List.length el))
(L.build_struct_gep set_struct_ptr 1 "set" builder) builder);
(builder, cur_vars, set_struct_ptr)
| SSetShortened(e1, e2) >
let (i1, i2) = match (e1, e2) with
((A.Int, SLiteral(i1)), (A.Int, SLiteral(i2))) > (i1, i2)
| _ > raise(Failure("Something went wrong in semant." ^
string_of_sexpr(e1)))
in
let rec rangeList i j =
if i == j then []
else (Ast.Int, SLiteral(i)) :: rangeList (i+1) j
in
let err = "Set shortened constructor arguments have non overlapping
intervals: " ^ string_of_sexpr e1 ^ " is less than " ^ string_of_sexpr e2 ^
"."
in
if i1 > i2 then
raise (Failure (err))
else
let el = rangeList i1 i2 in
expr builder cur_vars (Set A.Int, SSetExplicit(el))
| SSetConditional(t, id1, id2, e1, e2) as ex >
let empty_set_e = (A.Set(Int), SSetEmpty(Set(Int))) in
(* declare temp empty set *)
let pred_stmt = SDeclBind(SBindAssign(A.Set(Int), "emptyTempSet",
empty_set_e)) in
let (new_vars, builder) = stmt builder cur_vars pred_stmt in
264
let new_vars = add_local (t, id1) builder new_vars in
let i_range = match e1 with
(_, SSetShortened(e1, e2)) > (e1, e2)
| _ > raise(Failure("Something went wrong in semant." ^
string_of_sexpr((Set A.Int, ex))))
in
let (i1, i2) = match i_range with
((A.Int, SLiteral(i1)), (A.Int, SLiteral(i2))) > (i1, i2)
| _ > raise(Failure("Something went wrong in semant." ^
string_of_sexpr((Set A.Int, ex))))
in
let rec rangeList i j =
if i = j then []
else i :: rangeList (i+1) j
in
let el = rangeList i1 i2 in
let var_e = (A.Set(Int), SId("emptyTempSet")) in
let add_call i = (A.Set(Int), SCall("add", [var_e; (A.Int,
SLiteral(i))])) in
let repeat_stmt i = SExpr((A.Set(Int),
SAssign("emptyTempSet", add_call i))) in
(* Use SIF to check e2 boolean for each possible value of id1 *)
let rec check_condition il prev_builder' = match il with
[] > prev_builder'
| [i] >
let _ = L.build_store (L.const_int i32_t i) (lookup id1 new_vars)
prev_builder' in
let (_, b') = stmt prev_builder' new_vars (
SIf(e2, repeat_stmt i, SBlock([]))
) in
b'
| i :: the_rest >
let _ = L.build_store (L.const_int i32_t i) (lookup id1 new_vars)
prev_builder' in
let (_, b') = stmt prev_builder' new_vars (
SIf(e2, repeat_stmt i, SBlock([]))
) in
check_condition the_rest b'
in
let last_b = check_condition el builder
in
265
let (last_b, new_vars, final_set) = expr last_b new_vars var_e in
(last_b, cur_vars, final_set)
| STupleLit(el) >
(* Create struct to hold the tuple's elements *)
let element_ltypes =
let typ_list = match t with
A.Tuple typ_list > typ_list
| _ > raise(Failure("Invalid tuple typ list"))
in List.map ltype_of_typ typ_list
in
let el_struct = L.struct_type context
(Array.of_list(element_ltypes)) in
let el_struct_ptr = L.build_malloc el_struct "tuple" builder in
(* Populate struct with the tuple's elements *)
let set_element i e =
let (builder, cur_vars ,e') = expr builder cur_vars e in
ignore(L.build_store e'
(L.build_struct_gep el_struct_ptr i "tuple" builder) builder);
in List.iteri set_element el;
(* Create struct with the following form to represent the tuple:
[<pointer to struct holding tuple's elements>; <size of tuple>]
*)
let tuple_struct = (L.struct_type context (Array.of_list([
L.pointer_type (L.struct_type context
(Array.of_list(element_ltypes)));
i32_t
]))) in
let tuple_struct_ptr = L.build_malloc tuple_struct "tuple" builder
in
(* Populate struct *)
ignore(L.build_store el_struct_ptr (L.build_struct_gep
tuple_struct_ptr 0 "tuple" builder) builder);
ignore(L.build_store (L.const_int i32_t (List.length el))
(L.build_struct_gep tuple_struct_ptr 1 "tuple" builder) builder);
(builder, cur_vars, tuple_struct_ptr)
| STupleIndex(s, e, tl) >
(* TODO: pass tuple's typ list to STupleIndex() *)
let (builder, cur_vars, tuple_struct_ptr) = expr builder cur_vars
(A.Tuple(tl), SId(s))
and index =
let extract_index e = match e with
(A.Int, SLiteral(i)) > i
(* | (A.Int, SUnop(A.Neg, (A.Int, SLiteral(i)))) > i *)
| _ > raise(Failure("Invalid tuple index"))
in extract_index e
in
(* Get pointer to struct holding tuple's elements *)
266
let el_struct_ptr = L.build_load (L.build_struct_gep
tuple_struct_ptr 0 "tuple_index" builder) "elements" builder in
(* Get field <index> of the struct *)
(builder, cur_vars, L.build_load (L.build_struct_gep el_struct_ptr
index "tuple_index" builder) "element" builder)
| SSetEmpty(t') > expr builder cur_vars (t, SSetExplicit([]))
| STupleEmpty(tl') > expr builder cur_vars (t, STupleLit([]))
| SSetEmptyEx(sexpr') > expr builder cur_vars (t, SSetExplicit([]))
| STupleEmptyEx(sexpr') > expr builder cur_vars (t, STupleLit([]))
and
(* Build the code for the given statement; return the builder for
the statement's successor (i.e., the next instruction will be built
after the one generated by this call) *)
(* Imperative nature of statement processing entails imperative OCaml *)
stmt builder cur_vars = function
SBlock sl >
let rec stmt_list builder cur_vars' sl = match sl with
[] > (cur_vars', builder)
| [s] > let (cur_vars', builder) = stmt builder cur_vars' s in
(cur_vars', builder)
| s :: the_rest > let (cur_vars', builder) = stmt builder
cur_vars' s in
stmt_list builder cur_vars' the_rest
in
stmt_list builder cur_vars sl
(* Generate code for this expression, return resulting builder *)
| SExpr e > let (builder, cur_vars, _) = expr builder cur_vars e in
(cur_vars, builder)
| SReturn e > let (builder, cur_vars, e') = (expr builder cur_vars e)
in
let _ = match fdecl.styp with
(* Special "return nothing" instr *)
A.Void > L.build_ret_void builder
(* Build return statement *)
| _ > L.build_ret e' builder
in (cur_vars, builder)
(* The order that we create and add the basic blocks for an If statement
doesnt 'really' matter (seemingly). What hooks them up in the right
order
are the build_br functions used at the end of the then and else blocks
(if
they don't already have a terminator) and the build_cond_br function at
the end, which adds jump instructions to the "then" and "else" basic
blocks *)
| SIf (predicate, then_stmt, else_stmt) >
let (builder, cur_vars, bool_val) = expr builder cur_vars predicate
in
267
(* Add "merge" basic block to our function's list of blocks *)
let merge_bb = L.append_block context "merge" the_function in
(* Partial function used to generate branch to merge block *)
let branch_instr = L.build_br merge_bb in
(* Same for "then" basic block *)
let then_bb = L.append_block context "then" the_function in
(* Position builder in "then" block and build the statement *)
let (then_vars, then_builder) = stmt (L.builder_at_end context
then_bb) cur_vars then_stmt in
(* Add a branch to the "then" block (to the merge block)
if a terminator doesn't already exist for the "then" block *)
let () = add_terminal then_builder branch_instr in
(* Identical to stuff we did for "then" *)
let else_bb = L.append_block context "else" the_function in
let (else_vars, else_builder) = stmt (L.builder_at_end context
else_bb) cur_vars else_stmt in
let () = add_terminal else_builder branch_instr in
(* Generate initial branch instruction perform the selection of
"then"
or "else". Note we're using the builder we had access to at the start
of this alternative. *)
let _ = L.build_cond_br bool_val then_bb else_bb builder in
(* Move to the merge block for further instruction building *)
(cur_vars, L.builder_at_end context merge_bb)
| SWhile (predicate, body) >
(* First create basic block for condition instructions this will
serve as destination in the case of a loop *)
let pred_bb = L.append_block context "while" the_function in
(* In current block, branch to predicate to execute the condition *)
let _ = L.build_br pred_bb builder in
(* Create the body's block, generate the code for it, and add a
branch
back to the predicate block (we always jump back at the end of a
while
loop's body, unless we returned or something) *)
let body_bb = L.append_block context "while_body" the_function in
let (while_vars, while_builder) = stmt (L.builder_at_end context
body_bb) cur_vars body in
let () = add_terminal while_builder (L.build_br pred_bb) in
(* Generate the predicate code in the predicate block *)
268
let pred_builder = L.builder_at_end context pred_bb in
let (builder, cur_vars, bool_val) = expr pred_builder cur_vars
predicate in
(* Hook everything up *)
let merge_bb = L.append_block context "merge" the_function in
let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
(cur_vars, L.builder_at_end context merge_bb)
(* Implement for loops as while loops! *)
| SFor (e1, e2, e3, body) > stmt builder cur_vars
( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] )
| SForEach (t, id, e, body) >
(* foreach init block *)
(* int ix = 0 *)
let init_bb = L.append_block context "foreach_init" the_function in
let init_builder = L.builder_at_end context init_bb in
(* init set ptr and len *)
let (_, _, struct_ptr) = expr init_builder cur_vars e in
let len = L.build_load (L.build_struct_gep struct_ptr 1 "len"
init_builder) "len" init_builder in
(* add 1 to length since array starts at 1 *)
let len = (L.build_add len (L.const_int i32_t 1) "temp"
init_builder) in
let arr = L.build_load (L.build_struct_gep struct_ptr 0 "set"
init_builder) "arr" init_builder in
(* initialize indexer ix *)
let ix = L.build_alloca i32_t "ix" init_builder in
(* The set element for some reason starts at 1 *)
let _ = L.build_store (L.const_int i32_t 1) ix init_builder in
(* first branch from builder to init *)
let _ = L.build_br init_bb builder in
(* Predicate block *)
(* add local var (t, id) and check if ix < len *)
let pred_bb = L.append_block context "foreach" the_function in
let pred_builder = L.builder_at_end context pred_bb in
(* add (t, id) to currrent var_map *)
let for_each_vars = add_local (t, id) pred_builder cur_vars in
(* then branch from init to pred *)
let _ = L.build_br pred_bb init_builder in
(* foreach_body block *)
269
let body_bb = L.append_block context "foreach_body" the_function in
let body_builder = L.builder_at_end context body_bb in
let ix_val = L.build_load ix "ix_val" body_builder in
let curr_el = L.build_load (L.build_gep arr [| ix_val |]
"curr_el_ptr" body_builder) id body_builder in
let _ = L.build_store curr_el (lookup id for_each_vars)
body_builder in
let (foreach_vars, body_builder) = stmt body_builder for_each_vars
body in
(* after for each body is done ix++ and branch to pred_bb *)
let ix_inc = L.build_add ix_val (L.const_int i32_t 1) "ix_inc"
body_builder in
let _ = L.build_store ix_inc ix body_builder in
let () = add_terminal body_builder (L.build_br pred_bb) in
(* check bool then cond_branch *)
let ix_val = L.build_load ix "ix_val" pred_builder in
let bool_val = L.build_icmp L.Icmp.Slt ix_val len "bool_val"
pred_builder in
let merge_bb = L.append_block context "foreach_merge" the_function
in
let _ = L.build_cond_br bool_val body_bb merge_bb pred_builder in
(cur_vars, L.builder_at_end context merge_bb)
| SDeclBind(b) > (match b with
| SBindDec(t, n) > let new_vars = add_local (t, n) builder cur_vars
in
(new_vars, builder)
| SBindAssign(t, n, se) > let new_vars = add_local (t, n) builder
cur_vars in
let (builder, new_vars, e') = expr builder new_vars se in
let _ = L.build_store e' (lookup n new_vars) builder in
(new_vars, builder)
)
in
(* Build the code for each statement in the function *)
let (_, builder) = stmt builder local_vars (SBlock fdecl.sbody) in
(* Add a return if the last block falls off the end *)
add_terminal builder (match fdecl.styp with
A.Void > L.build_ret_void
270
| t > L.build_ret (L.const_int (ltype_of_typ t) 0))
in
List.iter build_function_body functions;
the_module