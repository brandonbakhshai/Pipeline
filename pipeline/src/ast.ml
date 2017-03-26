type op = Add | Sub | Mult | Div | Mod | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or

type uop = Neg | Not 

type typ = Int | Float | Bool | Char | Void | MyString | StructType of string 

type bind = typ * string

type expr =
    Literal of int
  | FloatLiteral of float
  | BoolLit of bool
  | MyStringLit of string
  (*add struct*)
  (*add list *)
  | CharLit of char
  | Id of string
  | Binop of expr * op * expr
  | Dotop of expr * string
  | Castop of typ * expr
  | Unop of uop * expr
  (*| SAssign of typ * string * expr *) 
  | Assign of string * expr
  | Call of string * expr list
  | Noexpr

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  (* else *)
  | For of expr * expr * expr * stmt
  | While of expr * stmt
  | SAssign of typ * string * expr
  | Print of expr (* print 5 *)
  


type pipe_decl = {
    
    locals : bind list;
    body : stmt list;
}

type func_decl = {
    typ : typ;
    fname : string;
    formals : bind list;
    locals : bind list;
    body : stmt list;
  }



type struct_decl = {
    sname: string;
    sformals: bind list;

}

type program = bind list * func_decl list * struct_decl list

(*
type program = {
                    funcs : stmt list;
                    main  : stmt list;
               }
*)

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"

let string_of_unop = function
    Neg -> "-"
  | Not -> "!"

let rec string_of_typ = function
    Int -> "int"
  | Float -> "float"
  | Bool -> "bool"
  | Void -> "void"
  | MyString -> "string"
  | StructType(s) -> "struct" ^ s

let rec string_of_expr = function
    Literal(l) -> string_of_int l
  | FloatLiteral(l) -> string_of_float l
  | BoolLit(true) -> "1"
  | BoolLit(false) -> "0"
  | MyStringLit(s) -> s
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_unop o ^ string_of_expr e
  | Dotop(e1, e2) -> string_of_expr e1 ^ ". " ^ e2
 (* | Castop(t, e) -> "(" ^ string_of_typ t ^ ")" ^ string_of_expr e *)
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s
  | SAssign(t, v, e) -> 
          string_of_typ t ^ " " ^ v ^ " = " ^ string_of_expr e ^ ";"

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_sdecl sdecl = sdecl.sname

let string_of_program (vars, funcs, structs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs) ^ "\n" ^
  String.concat "\n" (List.map string_of_sdecl structs)
