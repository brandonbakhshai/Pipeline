(* Semantic checker for Pipeline *)

open Ast

module StringMap = Map.Make(String)

let check (globals, functions) = 
    let report_duplicate exceptf list =
        let rec helper = function
            n1::n2::_ when n1 = n2 -> raise (Failure (exceptf n1))
            | _ :: t -> helper t
            | [] -> ()
        in helper (List.sort compare list)
    in
    (* Not sure if this is desirable in our language *)
    let check_not_void exceptf = function
        (Void, n) -> raise (Failure (exceptf n))
        | _ -> ()
    in
    let check_assign lvaluet rvaluet err =
        if lvaluet == rvaluet then lvaluet else raise err
    in
    (* Checking globals *)
    List.iter (check_not_void (fun n -> "illegal void global " ^ n)) globals;
    report_duplicate (fun n -> "duplicate global " ^ n) (List.map snd globals);
    (* Checking Functions *)
    if List.mem "print" (List.map (fun fd -> fd.fname) functions) (*not sure this is necessary*)
    then raise (Failure ("function print may not be defined")) else ();

    report_duplicate (fun n -> "duplicate function " ^ n)
    (List.map (fun fd -> fd.fname) functions);

    let built_in_decls = StringMap.singleton "print" (*think this is incorrect*)
        { typ = Void; fname = "print"; formals = [(MyString, "str")]; 
          locals = []; body = [] }
    in
    let function_decls = List.fold_left 
        (fun m fd -> StringMap.add fd.fname fd m) built_in_decls functions
    in

    let func_decl s = try StringMap.find s function_decls
        with Not_found -> raise (Failure ("unrecognized function " ^ s))
    in

    let _ = func_decl "main"
    in 
    
    let check_function func = 
        (*List.iter (check_not_void (fun n -> "illegal void formal " ^ n ^
          " in " ^ func.fname)) func.formals; *)
        report_duplicate (fun n -> "duplicate formal "^ n ^" in " ^ func.fname)
          (List.map snd func.formals);
        List.iter (check_not_void (fun n -> "illegal void local " ^ n ^
            " in " ^ func.fname)) func.locals;
        report_duplicate (fun n -> "duplicate local " ^ n ^ " in " ^ func.fname)
          (List.map snd func.locals);

    let symbols = List.fold_left (fun m (t, n) ->  StringMap.add n t m)
    StringMap.empty (globals @ func.formals @ func.locals )
    in
    let type_of_identifier s =
        try StringMap.find s symbols
        with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in
    let rec expr = function
        Literal _ -> Int
        | FloatLiteral _ -> Float
        | MyStringLit _ -> MyString
        | Binop(e1, op, e2) as e-> let t1 = expr e1 and t2 = expr e2 in
        (match op with
            Add | Sub | Mult | Div when t1 = Int && t2 = Int -> Int
            | Equal | Neq when t1 = t2 -> Bool
            | Less | Leq | Greater | Geq when (t1 = Int || t1 = Float) &&
                                              (t2 = Int || t2 = Float) -> Bool
            | And | Or when t1 = Bool && t2 = Bool -> Bool
            (* Need to add other expressions here *)
            | _ -> raise (Failure ("illegal binary operator " )) (*^
                   string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                   string_of_typ t2 ^ " in " ^ string_of_expr e)*)
        )
            | Unop(op, e) as ex -> let t = expr e in
            (match op with
              Neg when t = Int -> Int
            | Neg when t = Float -> Float
            | Not when t = Bool -> Bool
(*            | Ref when t = Bool -> PointerType (*Bool | Int | MyString | Float | Void | StructType*)
            | Deref when t = (PointerType || Voidstar) -> typ *)
            | _ -> raise (Failure ("illegal unary operator"))
            (*  ^ string_of_uop op ^ string_of_type ^ " in "  ^ string_of_expr ex)*)
            )
            | Noexpr -> Void
            | Assign(var, e) as ex -> let lt = type_of_identifier var
                                   and rt = expr e in
              check_assign lt rt (Failure ("illegal assignment "))(* ^
                                            string_of_typ lt ^ 
                                            " = "  ^ string_of_typ rt
                                            ^ " in " ^
                                            string_of expr ex)*)
            | Call(fname, actuals) as call -> let fd = func_decl fname in
              if List.length actuals != List.length fd.formals then
                  raise (Failure ("expecting " ^ string_of_int
                    (List.length fd.formals))) (* ^ " arguments in " ^
                     string_of_expr call)*)
              else
                  List.iter2 (fun (ft, _) e -> let et = expr e in
                    ignore (check_assign ft et
                      (Failure ("illegal actual argument found ")))) (* 
                      ^ string_of_typ et ^ " expected "
                      ^ string_of_typ ft ^ " in " string_of_expr e)))*)
                    fd.formals actuals;
                  fd.typ
        in

        let check_bool_expr e = 
            if expr e != Bool then raise 
            (Failure ("expected Boolean Boolean expre in "))(* ^ string_of_expr r)*)
            else ()
        in

        let rec stmt = function
        Block sl -> 
            let rec check_block = function
                  [Return _ as s] -> stmt s
                | Return _ :: _ -> raise (Failure "nothing may follow a return") (*not very sure about this one *)
                | Block sl :: ss -> check_block ss
                | s :: ss -> stmt s ; check_block ss
                | [] -> ()
            in check_block sl
                | Expr e -> ignore (expr e)
                | Return e -> let t = expr e in if t = func.typ then () else
                    raise (Failure ("incorrect return type")) 
                    (*"return gives " ^ string_of_typ t ^
                                    " expected " ^ string_of_typ func.typ
                                    ^ " in " ^ string_of_expr e)*)
                
                | If(p, b1, b2) -> check_bool_expr p; stmt b1; stmt b2
                | For(e1, e2, e3, st) -> ignore (expr e1); check_bool_expr e2;
                                         ignore (expr e3); stmt st
                | While(p, s) -> check_bool_expr p; stmt s
        in
        stmt (Block func.body)
    in
    List.iter check_function functions
