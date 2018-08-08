chapter \<open>Generated by Lem from \<open>semantics/semanticPrimitives.lem\<close>.\<close>

theory "SemanticPrimitives" 

imports
  Main
  "LEM.Lem_pervasives"
  "LEM.Lem_list_extra"
  "LEM.Lem_string"
  "Lib"
  "Namespace"
  "Ast"
  "Ffi"
  "FpSem"
  "LEM.Lem_string_extra"

begin 

(*open import Pervasives*)
(*open import Lib*)
(*import List_extra*)
(*import String*)
(*import String_extra*)
(*open import Ast*)
(*open import Namespace*)
(*open import Ffi*)
(*open import FpSem*)

(* The type that a constructor builds is either a named datatype or an exception.
 * For exceptions, we also keep the module that the exception was declared in. *)
datatype tid_or_exn =
    TypeId " (modN, typeN) id0 "
  | TypeExn " (modN, conN) id0 "

(*val type_defs_to_new_tdecs : list modN -> type_def -> set tid_or_exn*)
definition type_defs_to_new_tdecs  :: "(string)list \<Rightarrow>((tvarN)list*string*(conN*(t)list)list)list \<Rightarrow>(tid_or_exn)set "  where 
     " type_defs_to_new_tdecs mn tdefs = (
  List.set (List.map ( \<lambda>x .  
  (case  x of (tvs,tn,ctors) => TypeId (mk_id mn tn) )) tdefs))"


datatype_record 'v sem_env =
  
 v ::" (modN, varN, 'v) namespace "
   
 c ::" (modN, conN, (nat * tid_or_exn)) namespace "
   


(* Value forms *)
datatype v =
    Litv " lit "
  (* Constructor application. *)
  | Conv "  (conN * tid_or_exn)option " " v list "
  (* Function closures
     The environment is used for the free variables in the function *)
  | Closure " v sem_env " " varN " " exp "
  (* Function closure for recursive functions
   * See Closure and Letrec above
   * The last variable name indicates which function from the mutually
   * recursive bundle this closure value represents *)
  | Recclosure " v sem_env " " (varN * varN * exp) list " " varN "
  | Loc " nat "
  | Vectorv " v list "

type_synonym env_ctor =" (modN, conN, (nat * tid_or_exn)) namespace "
type_synonym env_val =" (modN, varN, v) namespace "

definition Bindv  :: " v "  where 
     " Bindv = ( Conv (Some((''Bind''),TypeExn(Short(''Bind'')))) [])"


(* The result of evaluation *)
datatype abort =
    Rtype_error
  | Rtimeout_error

datatype 'a error_result =
    Rraise " 'a " (* Should only be a value of type exn *)
  | Rabort " abort "

datatype( 'a, 'b) result =
    Rval " 'a "
  | Rerr " 'b error_result "

(* Stores *)
datatype 'a store_v =
  (* A ref cell *)
    Refv " 'a "
  (* A byte array *)
  | W8array " 8 word list "
  (* An array of values *)
  | Varray " 'a list "

(*val store_v_same_type : forall 'a. store_v 'a -> store_v 'a -> bool*)
definition store_v_same_type  :: " 'a store_v \<Rightarrow> 'a store_v \<Rightarrow> bool "  where 
     " store_v_same_type v1 v2 = (
  (case  (v1,v2) of
    (Refv _, Refv _) => True
  | (W8array _,W8array _) => True
  | (Varray _,Varray _) => True
  | _ => False
  ))"


(* The nth item in the list is the value at location n *)
type_synonym 'a store =" ( 'a store_v) list "

(*val empty_store : forall 'a. store 'a*)
definition empty_store  :: "('a store_v)list "  where 
     " empty_store = ( [])"


(*val store_lookup : forall 'a. nat -> store 'a -> maybe (store_v 'a)*)
definition store_lookup  :: " nat \<Rightarrow>('a store_v)list \<Rightarrow>('a store_v)option "  where 
     " store_lookup l st = (
  if l < List.length st then
    Some (List.nth st l)
  else
    None )"


(*val store_alloc : forall 'a. store_v 'a -> store 'a -> store 'a * nat*)
definition store_alloc  :: " 'a store_v \<Rightarrow>('a store_v)list \<Rightarrow>('a store_v)list*nat "  where 
     " store_alloc v2 st = (
  ((st @ [v2]), List.length st))"


(*val store_assign : forall 'a. nat -> store_v 'a -> store 'a -> maybe (store 'a)*)
definition store_assign  :: " nat \<Rightarrow> 'a store_v \<Rightarrow>('a store_v)list \<Rightarrow>(('a store_v)list)option "  where 
     " store_assign n v2 st = (
  if (n < List.length st) \<and>
     store_v_same_type (List.nth st n) v2
  then
    Some (List.list_update st n v2)
  else
    None )"


datatype_record 'ffi state =
  
 clock ::" nat "
   
 refs  ::" v store "
   
 ffi ::" 'ffi ffi_state "
   
 defined_types ::" tid_or_exn set "
   
 defined_mods ::" ( modN list) set "
   


(* Other primitives *)
(* Check that a constructor is properly applied *)
(*val do_con_check : env_ctor -> maybe (id modN conN) -> nat -> bool*)
fun do_con_check  :: "((string),(string),(nat*tid_or_exn))namespace \<Rightarrow>(((string),(string))id0)option \<Rightarrow> nat \<Rightarrow> bool "  where 
     " do_con_check cenv None l = ( True )"
|" do_con_check cenv (Some n) l = (
        (case  nsLookup cenv n of
            None => False
          | Some (l',ns) => l = l'
        ))"


(*val build_conv : env_ctor -> maybe (id modN conN) -> list v -> maybe v*)
fun build_conv  :: "((string),(string),(nat*tid_or_exn))namespace \<Rightarrow>(((string),(string))id0)option \<Rightarrow>(v)list \<Rightarrow>(v)option "  where 
     " build_conv envC None vs = (
        Some (Conv None vs))"
|" build_conv envC (Some id1) vs = (
        (case  nsLookup envC id1 of
            None => None
          | Some (len,t1) => Some (Conv (Some (id_to_n id1, t1)) vs)
        ))"


(*val lit_same_type : lit -> lit -> bool*)
definition lit_same_type  :: " lit \<Rightarrow> lit \<Rightarrow> bool "  where 
     " lit_same_type l1 l2 = (
  (case  (l1,l2) of
      (IntLit _, IntLit _) => True
    | (Char _, Char _) => True
    | (StrLit _, StrLit _) => True
    | (Word8 _, Word8 _) => True
    | (Word64 _, Word64 _) => True
    | _ => False
  ))"


datatype 'a match_result =
    No_match
  | Match_type_error
  | Match " 'a "

(*val same_tid : tid_or_exn -> tid_or_exn -> bool*)
fun  same_tid  :: " tid_or_exn \<Rightarrow> tid_or_exn \<Rightarrow> bool "  where 
     " same_tid (TypeId tn1) (TypeId tn2) = ( tn1 = tn2 )"
|" same_tid (TypeExn _) (TypeExn _) = ( True )"
|" same_tid _ _ = ( False )"


(*val same_ctor : conN * tid_or_exn -> conN * tid_or_exn -> bool*)
fun  same_ctor  :: " string*tid_or_exn \<Rightarrow> string*tid_or_exn \<Rightarrow> bool "  where 
     " same_ctor (cn1, TypeExn mn1) (cn2, TypeExn mn2) = ( (cn1 = cn2) \<and> (mn1 = mn2))"
|" same_ctor (cn1, _) (cn2, _) = ( cn1 = cn2 )"


(*val ctor_same_type : maybe (conN * tid_or_exn) -> maybe (conN * tid_or_exn) -> bool*)
definition ctor_same_type  :: "(string*tid_or_exn)option \<Rightarrow>(string*tid_or_exn)option \<Rightarrow> bool "  where 
     " ctor_same_type c1 c2 = (
  (case  (c1,c2) of
      (None, None) => True
    | (Some (_,t1), Some (_,t2)) => same_tid t1 t2
    | _ => False
  ))"


(* A big-step pattern matcher.  If the value matches the pattern, return an
 * environment with the pattern variables bound to the corresponding sub-terms
 * of the value; this environment extends the environment given as an argument.
 * No_match is returned when there is no match, but any constructors
 * encountered in determining the match failure are applied to the correct
 * number of arguments, and constructors in corresponding positions in the
 * pattern and value come from the same type.  Match_type_error is returned
 * when one of these conditions is violated *)
(*val pmatch : env_ctor -> store v -> pat -> v -> alist varN v -> match_result (alist varN v)*)
function (sequential,domintros) 
pmatch_list  :: "((string),(string),(nat*tid_or_exn))namespace \<Rightarrow>((v)store_v)list \<Rightarrow>(pat)list \<Rightarrow>(v)list \<Rightarrow>(string*v)list \<Rightarrow>((string*v)list)match_result "  
                   and
pmatch  :: "((string),(string),(nat*tid_or_exn))namespace \<Rightarrow>((v)store_v)list \<Rightarrow> pat \<Rightarrow> v \<Rightarrow>(string*v)list \<Rightarrow>((string*v)list)match_result "  where 
     "
pmatch envC s Pany v' env = ( Match env )"
|"
pmatch envC s (Pvar x) v' env = ( Match ((x,v')# env))"
|"
pmatch envC s (Plit l) (Litv l') env = (
  if l = l' then
    Match env
  else if lit_same_type l l' then
    No_match
  else
    Match_type_error )"
|"
pmatch envC s (Pcon (Some n) ps) (Conv (Some (n', t')) vs) env = (
  (case  nsLookup envC n of
      Some (l, t1) =>
        if same_tid t1 t' \<and> (List.length ps = l) then
          if same_ctor (id_to_n n, t1) (n',t') then
            (if List.length vs = l then pmatch_list envC s ps vs env else Match_type_error)
          else
            No_match
        else
          Match_type_error
    | _ => Match_type_error
  ))"
|"
pmatch envC s (Pcon None ps) (Conv None vs) env = (
  if List.length ps = List.length vs then
    pmatch_list envC s ps vs env
  else
    Match_type_error )"
|"
pmatch envC s (Pref p) (Loc lnum) env = (
  (case  store_lookup lnum s of
      Some (Refv v2) => pmatch envC s p v2 env
    | Some _ => Match_type_error
    | None => Match_type_error
  ))"
|"
pmatch envC s (Ptannot p t1) v2 env = (
  pmatch envC s p v2 env )"
|"
pmatch envC _ _ _ env = ( Match_type_error )"
|"
pmatch_list envC s [] [] env = ( Match env )"
|"
pmatch_list envC s (p # ps) (v2 # vs) env = (
  (case  pmatch envC s p v2 env of
      No_match => No_match
    | Match_type_error => Match_type_error
    | Match env' => pmatch_list envC s ps vs env'
  ))"
|"
pmatch_list envC s _ _ env = ( Match_type_error )" 
by pat_completeness auto


(* Bind each function of a mutually recursive set of functions to its closure *)
(*val build_rec_env : list (varN * varN * exp) -> sem_env v -> env_val -> env_val*)
definition build_rec_env  :: "(varN*varN*exp)list \<Rightarrow>(v)sem_env \<Rightarrow>((string),(string),(v))namespace \<Rightarrow>((string),(string),(v))namespace "  where 
     " build_rec_env funs cl_env add_to_env = (
  List.foldr ( \<lambda>x .  
  (case  x of
      (f,x,e) => \<lambda> env' .  nsBind f (Recclosure cl_env funs f) env'
  )) funs add_to_env )"


(* Lookup in the list of mutually recursive functions *)
(*val find_recfun : forall 'a 'b. varN -> list (varN * 'a * 'b) -> maybe ('a * 'b)*)
fun  find_recfun  :: " string \<Rightarrow>(string*'a*'b)list \<Rightarrow>('a*'b)option "  where 
     " find_recfun n ([]) = ( None )"
|" find_recfun n ((f,x,e) # funs) = (
        if f = n then
          Some (x,e)
        else
          find_recfun n funs )"


datatype eq_result =
    Eq_val " bool "
  | Eq_type_error

(*val do_eq : v -> v -> eq_result*)
function (sequential,domintros) 
do_eq_list  :: "(v)list \<Rightarrow>(v)list \<Rightarrow> eq_result "  
                   and
do_eq  :: " v \<Rightarrow> v \<Rightarrow> eq_result "  where 
     "
do_eq (Litv l1) (Litv l2) = (
  if lit_same_type l1 l2 then Eq_val (l1 = l2)
  else Eq_type_error )"
|"
do_eq (Loc l1) (Loc l2) = ( Eq_val (l1 = l2))"
|"
do_eq (Conv cn1 vs1) (Conv cn2 vs2) = (
  if (cn1 = cn2) \<and> (List.length vs1 = List.length vs2) then
    do_eq_list vs1 vs2
  else if ctor_same_type cn1 cn2 then
    Eq_val False
  else
    Eq_type_error )"
|"
do_eq (Vectorv vs1) (Vectorv vs2) = (
  if List.length vs1 = List.length vs2 then
    do_eq_list vs1 vs2
  else
    Eq_val False )"
|"
do_eq (Closure _ _ _) (Closure _ _ _) = ( Eq_val True )"
|"
do_eq (Closure _ _ _) (Recclosure _ _ _) = ( Eq_val True )"
|"
do_eq (Recclosure _ _ _) (Closure _ _ _) = ( Eq_val True )"
|"
do_eq (Recclosure _ _ _) (Recclosure _ _ _) = ( Eq_val True )"
|"
do_eq _ _ = ( Eq_type_error )"
|"
do_eq_list [] [] = ( Eq_val True )"
|"
do_eq_list (v1 # vs1) (v2 # vs2) = (
  (case  do_eq v1 v2 of
      Eq_type_error => Eq_type_error
    | Eq_val r =>
        if \<not> r then
          Eq_val False
        else
          do_eq_list vs1 vs2
  ))"
|"
do_eq_list _ _ = ( Eq_val False )" 
by pat_completeness auto


(*val prim_exn : conN -> v*)
definition prim_exn  :: " string \<Rightarrow> v "  where 
     " prim_exn cn = ( Conv (Some (cn, TypeExn (Short cn))) [])"


(* Do an application *)
(*val do_opapp : list v -> maybe (sem_env v * exp)*)
fun do_opapp  :: "(v)list \<Rightarrow>((v)sem_env*exp)option "  where 
     " do_opapp ([Closure env n e, v2]) = (
      Some (( env (| v := (nsBind n v2(v   env)) |)), e))"
|" do_opapp ([Recclosure env funs n, v2]) = (
      if allDistinct (List.map ( \<lambda>x .  
  (case  x of (f,x,e) => f )) funs) then
        (case  find_recfun n funs of
            Some (n,e) => Some (( env (| v := (nsBind n v2 (build_rec_env funs env(v   env))) |)), e)
          | None => None
        )
      else
        None )"
|" do_opapp _ = ( None )"


(* If a value represents a list, get that list. Otherwise return Nothing *)
(*val v_to_list : v -> maybe (list v)*)
function (sequential,domintros)  v_to_list  :: " v \<Rightarrow>((v)list)option "  where 
     " v_to_list (Conv (Some (cn, TypeId (Short tn))) []) = (
  if (cn = (''nil'')) \<and> (tn = (''list'')) then
    Some []
  else
    None )"
|" v_to_list (Conv (Some (cn,TypeId (Short tn))) [v1,v2]) = (
  if (cn = (''::''))  \<and> (tn = (''list'')) then
    (case  v_to_list v2 of
        Some vs => Some (v1 # vs)
      | None => None
    )
  else
    None )"
|" v_to_list _ = ( None )" 
by pat_completeness auto


(*val v_to_char_list : v -> maybe (list char)*)
function (sequential,domintros)  v_to_char_list  :: " v \<Rightarrow>((char)list)option "  where 
     " v_to_char_list (Conv (Some (cn, TypeId (Short tn))) []) = (
  if (cn = (''nil'')) \<and> (tn = (''list'')) then
    Some []
  else
    None )"
|" v_to_char_list (Conv (Some (cn,TypeId (Short tn))) [Litv (Char c2),v2]) = (
  if (cn = (''::''))  \<and> (tn = (''list'')) then
    (case  v_to_char_list v2 of
        Some cs => Some (c2 # cs)
      | None => None
    )
  else
    None )"
|" v_to_char_list _ = ( None )" 
by pat_completeness auto


(*val vs_to_string : list v -> maybe string*)
function (sequential,domintros)  vs_to_string  :: "(v)list \<Rightarrow>(string)option "  where 
     " vs_to_string [] = ( Some (''''))"
|" vs_to_string (Litv(StrLit s1)# vs) = (
  (case  vs_to_string vs of
    Some s2 => Some (s1 @ s2)
  | _ => None
  ))"
|" vs_to_string _ = ( None )" 
by pat_completeness auto


(*val copy_array : forall 'a. list 'a * integer -> integer -> maybe (list 'a * integer) -> maybe (list 'a)*)
fun copy_array  :: " 'a list*int \<Rightarrow> int \<Rightarrow>('a list*int)option \<Rightarrow>('a list)option "  where 
     " copy_array (src,srcoff) len d = (
  if (srcoff <( 0 :: int)) \<or> ((len <( 0 :: int)) \<or> (List.length src < nat (abs ( (srcoff + len))))) then None else
    (let copied = (List.take (nat (abs ( len))) (List.drop (nat (abs ( srcoff))) src)) in
    (case  d of
      Some (dst,dstoff) =>
        if (dstoff <( 0 :: int)) \<or> (List.length dst < nat (abs ( (dstoff + len)))) then None else
          Some ((List.take (nat (abs ( dstoff))) dst @
                copied) @
                List.drop (nat (abs ( (dstoff + len)))) dst)
    | None => Some copied
    )))"


(*val ws_to_chars : list word8 -> list char*)
definition ws_to_chars  :: "(8 word)list \<Rightarrow>(char)list "  where 
     " ws_to_chars ws = ( List.map (\<lambda> w .  (%n. char_of (n::nat))(unat w)) ws )"


(*val chars_to_ws : list char -> list word8*)
definition chars_to_ws  :: "(char)list \<Rightarrow>(8 word)list "  where 
     " chars_to_ws cs = ( List.map (\<lambda> c2 .  word_of_int(int(of_char c2))) cs )"


(*val opn_lookup : opn -> integer -> integer -> integer*)
fun opn_lookup  :: " opn \<Rightarrow> int \<Rightarrow> int \<Rightarrow> int "  where 
     " opn_lookup Plus = ( (+))"
|" opn_lookup Minus = ( (-))"
|" opn_lookup Times = ( ( * ))"
|" opn_lookup Divide = ( (div))"
|" opn_lookup Modulo = ( (mod))"


(*val opb_lookup : opb -> integer -> integer -> bool*)
fun opb_lookup  :: " opb \<Rightarrow> int \<Rightarrow> int \<Rightarrow> bool "  where 
     " opb_lookup Lt = ( (<))"
|" opb_lookup Gt = ( (>))"
|" opb_lookup Leq = ( (\<le>))"
|" opb_lookup Geq = ( (\<ge>))"


(*val opw8_lookup : opw -> word8 -> word8 -> word8*)
fun opw8_lookup  :: " opw \<Rightarrow> 8 word \<Rightarrow> 8 word \<Rightarrow> 8 word "  where 
     " opw8_lookup Andw = ( Bits.bitAND )"
|" opw8_lookup Orw = ( Bits.bitOR )"
|" opw8_lookup Xor = ( Bits.bitXOR )"
|" opw8_lookup Add = ( Groups.plus )"
|" opw8_lookup Sub = ( Groups.minus )"


(*val opw64_lookup : opw -> word64 -> word64 -> word64*)
fun opw64_lookup  :: " opw \<Rightarrow> 64 word \<Rightarrow> 64 word \<Rightarrow> 64 word "  where 
     " opw64_lookup Andw = ( Bits.bitAND )"
|" opw64_lookup Orw = ( Bits.bitOR )"
|" opw64_lookup Xor = ( Bits.bitXOR )"
|" opw64_lookup Add = ( Groups.plus )"
|" opw64_lookup Sub = ( Groups.minus )"


(*val shift8_lookup : shift -> word8 -> nat -> word8*)
fun shift8_lookup  :: " shift \<Rightarrow> 8 word \<Rightarrow> nat \<Rightarrow> 8 word "  where 
     " shift8_lookup Lsl = ( shiftl )"
|" shift8_lookup Lsr = ( shiftr )"
|" shift8_lookup Asr = ( sshiftr )"
|" shift8_lookup Ror = ( (% a b. word_rotr b a) )"


(*val shift64_lookup : shift -> word64 -> nat -> word64*)
fun shift64_lookup  :: " shift \<Rightarrow> 64 word \<Rightarrow> nat \<Rightarrow> 64 word "  where 
     " shift64_lookup Lsl = ( shiftl )"
|" shift64_lookup Lsr = ( shiftr )"
|" shift64_lookup Asr = ( sshiftr )"
|" shift64_lookup Ror = ( (% a b. word_rotr b a) )"


(*val Boolv : bool -> v*)
definition Boolv  :: " bool \<Rightarrow> v "  where 
     " Boolv b = ( if b
  then Conv (Some ((''true''), TypeId (Short (''bool'')))) []
  else Conv (Some ((''false''), TypeId (Short (''bool'')))) [])"


datatype exp_or_val =
    Exp " exp "
  | Val " v "

type_synonym( 'ffi, 'v) store_ffi =" 'v store * 'ffi ffi_state "

(*val do_app : forall 'ffi. store_ffi 'ffi v -> op -> list v -> maybe (store_ffi 'ffi v * result v v)*)
fun do_app  :: "((v)store_v)list*'ffi ffi_state \<Rightarrow> op0 \<Rightarrow>(v)list \<Rightarrow>((((v)store_v)list*'ffi ffi_state)*((v),(v))result)option "  where 
     " do_app ((s:: v store),(t1:: 'ffi ffi_state)) op1 vs = (
  (case  (op1, vs) of
      (Opn op1, [Litv (IntLit n1), Litv (IntLit n2)]) =>
        if ((op1 = Divide) \<or> (op1 = Modulo)) \<and> (n2 =( 0 :: int)) then
          Some ((s,t1), Rerr (Rraise (prim_exn (''Div''))))
        else
          Some ((s,t1), Rval (Litv (IntLit (opn_lookup op1 n1 n2))))
    | (Opb op1, [Litv (IntLit n1), Litv (IntLit n2)]) =>
        Some ((s,t1), Rval (Boolv (opb_lookup op1 n1 n2)))
    | (Opw W8 op1, [Litv (Word8 w1), Litv (Word8 w2)]) =>
        Some ((s,t1), Rval (Litv (Word8 (opw8_lookup op1 w1 w2))))
    | (Opw W64 op1, [Litv (Word64 w1), Litv (Word64 w2)]) =>
        Some ((s,t1), Rval (Litv (Word64 (opw64_lookup op1 w1 w2))))
    | (FP_bop bop, [Litv (Word64 w1), Litv (Word64 w2)]) =>
        Some ((s,t1),Rval (Litv (Word64 (fp_bop bop w1 w2))))
    | (FP_uop uop, [Litv (Word64 w)]) =>
        Some ((s,t1),Rval (Litv (Word64 (fp_uop uop w))))
    | (FP_cmp cmp, [Litv (Word64 w1), Litv (Word64 w2)]) =>
        Some ((s,t1),Rval (Boolv (fp_cmp cmp w1 w2)))
    | (Shift W8 op1 n, [Litv (Word8 w)]) =>
        Some ((s,t1), Rval (Litv (Word8 (shift8_lookup op1 w n))))
    | (Shift W64 op1 n, [Litv (Word64 w)]) =>
        Some ((s,t1), Rval (Litv (Word64 (shift64_lookup op1 w n))))
    | (Equality, [v1, v2]) =>
        (case  do_eq v1 v2 of
            Eq_type_error => None
          | Eq_val b => Some ((s,t1), Rval (Boolv b))
        )
    | (Opassign, [Loc lnum, v2]) =>
        (case  store_assign lnum (Refv v2) s of
            Some s' => Some ((s',t1), Rval (Conv None []))
          | None => None
        )
    | (Opref, [v2]) =>
        (let (s',n) = (store_alloc (Refv v2) s) in
          Some ((s',t1), Rval (Loc n)))
    | (Opderef, [Loc n]) =>
        (case  store_lookup n s of
            Some (Refv v2) => Some ((s,t1),Rval v2)
          | _ => None
        )
    | (Aw8alloc, [Litv (IntLit n), Litv (Word8 w)]) =>
        if n <( 0 :: int) then
          Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
        else
          (let (s',lnum) =
            (store_alloc (W8array (List.replicate (nat (abs ( n))) w)) s)
          in
            Some ((s',t1), Rval (Loc lnum)))
    | (Aw8sub, [Loc lnum, Litv (IntLit i)]) =>
        (case  store_lookup lnum s of
            Some (W8array ws) =>
              if i <( 0 :: int) then
                Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
              else
                (let n = (nat (abs ( i))) in
                  if n \<ge> List.length ws then
                    Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
                  else
                    Some ((s,t1), Rval (Litv (Word8 (List.nth ws n)))))
          | _ => None
        )
    | (Aw8length, [Loc n]) =>
        (case  store_lookup n s of
            Some (W8array ws) =>
              Some ((s,t1),Rval (Litv(IntLit(int(List.length ws)))))
          | _ => None
         )
    | (Aw8update, [Loc lnum, Litv(IntLit i), Litv(Word8 w)]) =>
        (case  store_lookup lnum s of
          Some (W8array ws) =>
            if i <( 0 :: int) then
              Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
            else
              (let n = (nat (abs ( i))) in
                if n \<ge> List.length ws then
                  Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
                else
                  (case  store_assign lnum (W8array (List.list_update ws n w)) s of
                      None => None
                    | Some s' => Some ((s',t1), Rval (Conv None []))
                  ))
        | _ => None
      )
    | (WordFromInt W8, [Litv(IntLit i)]) =>
        Some ((s,t1), Rval (Litv (Word8 (word_of_int i))))
    | (WordFromInt W64, [Litv(IntLit i)]) =>
        Some ((s,t1), Rval (Litv (Word64 (word_of_int i))))
    | (WordToInt W8, [Litv (Word8 w)]) =>
        Some ((s,t1), Rval (Litv (IntLit (int(unat w)))))
    | (WordToInt W64, [Litv (Word64 w)]) =>
        Some ((s,t1), Rval (Litv (IntLit (int(unat w)))))
    | (CopyStrStr, [Litv(StrLit str),Litv(IntLit off),Litv(IntLit len)]) =>
        Some ((s,t1),
        (case  copy_array ( str,off) len None of
          None => Rerr (Rraise (prim_exn (''Subscript'')))
        | Some cs => Rval (Litv(StrLit((cs))))
        ))
    | (CopyStrAw8, [Litv(StrLit str),Litv(IntLit off),Litv(IntLit len),
                    Loc dst,Litv(IntLit dstoff)]) =>
        (case  store_lookup dst s of
          Some (W8array ws) =>
            (case  copy_array ( str,off) len (Some(ws_to_chars ws,dstoff)) of
              None => Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
            | Some cs =>
              (case  store_assign dst (W8array (chars_to_ws cs)) s of
                Some s' =>  Some ((s',t1), Rval (Conv None []))
              | _ => None
              )
            )
        | _ => None
        )
    | (CopyAw8Str, [Loc src,Litv(IntLit off),Litv(IntLit len)]) =>
      (case  store_lookup src s of
        Some (W8array ws) =>
        Some ((s,t1),
          (case  copy_array (ws,off) len None of
            None => Rerr (Rraise (prim_exn (''Subscript'')))
          | Some ws => Rval (Litv(StrLit((ws_to_chars ws))))
          ))
      | _ => None
      )
    | (CopyAw8Aw8, [Loc src,Litv(IntLit off),Litv(IntLit len),
                    Loc dst,Litv(IntLit dstoff)]) =>
      (case  (store_lookup src s, store_lookup dst s) of
        (Some (W8array ws), Some (W8array ds)) =>
          (case  copy_array (ws,off) len (Some(ds,dstoff)) of
            None => Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
          | Some ws =>
              (case  store_assign dst (W8array ws) s of
                Some s' => Some ((s',t1), Rval (Conv None []))
              | _ => None
              )
          )
      | _ => None
      )
    | (Ord, [Litv (Char c2)]) =>
          Some ((s,t1), Rval (Litv(IntLit(int(of_char c2)))))
    | (Chr, [Litv (IntLit i)]) =>
        Some ((s,t1),
          (if (i <( 0 :: int)) \<or> (i >( 255 :: int)) then
            Rerr (Rraise (prim_exn (''Chr'')))
          else
            Rval (Litv(Char((%n. char_of (n::nat))(nat (abs ( i))))))))
    | (Chopb op1, [Litv (Char c1), Litv (Char c2)]) =>
        Some ((s,t1), Rval (Boolv (opb_lookup op1 (int(of_char c1)) (int(of_char c2)))))
    | (Implode, [v2]) =>
          (case  v_to_char_list v2 of
            Some ls =>
              Some ((s,t1), Rval (Litv (StrLit ( ls))))
          | None => None
          )
    | (Strsub, [Litv (StrLit str), Litv (IntLit i)]) =>
        if i <( 0 :: int) then
          Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
        else
          (let n = (nat (abs ( i))) in
            if n \<ge> List.length str then
              Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
            else
              Some ((s,t1), Rval (Litv (Char (List.nth ( str) n)))))
    | (Strlen, [Litv (StrLit str)]) =>
        Some ((s,t1), Rval (Litv(IntLit(int(List.length str)))))
    | (Strcat, [v2]) =>
        (case  v_to_list v2 of
          Some vs =>
            (case  vs_to_string vs of
              Some str =>
                Some ((s,t1), Rval (Litv(StrLit str)))
            | _ => None
            )
        | _ => None
        )
    | (VfromList, [v2]) =>
          (case  v_to_list v2 of
              Some vs =>
                Some ((s,t1), Rval (Vectorv vs))
            | None => None
          )
    | (Vsub, [Vectorv vs, Litv (IntLit i)]) =>
        if i <( 0 :: int) then
          Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
        else
          (let n = (nat (abs ( i))) in
            if n \<ge> List.length vs then
              Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
            else
              Some ((s,t1), Rval (List.nth vs n)))
    | (Vlength, [Vectorv vs]) =>
        Some ((s,t1), Rval (Litv (IntLit (int (List.length vs)))))
    | (Aalloc, [Litv (IntLit n), v2]) =>
        if n <( 0 :: int) then
          Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
        else
          (let (s',lnum) =
            (store_alloc (Varray (List.replicate (nat (abs ( n))) v2)) s)
          in
            Some ((s',t1), Rval (Loc lnum)))
    | (AallocEmpty, [Conv None []]) =>
        (let (s',lnum) = (store_alloc (Varray []) s) in
          Some ((s',t1), Rval (Loc lnum)))
    | (Asub, [Loc lnum, Litv (IntLit i)]) =>
        (case  store_lookup lnum s of
            Some (Varray vs) =>
              if i <( 0 :: int) then
                Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
              else
                (let n = (nat (abs ( i))) in
                  if n \<ge> List.length vs then
                    Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
                  else
                    Some ((s,t1), Rval (List.nth vs n)))
          | _ => None
        )
    | (Alength, [Loc n]) =>
        (case  store_lookup n s of
            Some (Varray ws) =>
              Some ((s,t1),Rval (Litv(IntLit(int(List.length ws)))))
          | _ => None
         )
    | (Aupdate, [Loc lnum, Litv (IntLit i), v2]) =>
        (case  store_lookup lnum s of
          Some (Varray vs) =>
            if i <( 0 :: int) then
              Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
            else
              (let n = (nat (abs ( i))) in
                if n \<ge> List.length vs then
                  Some ((s,t1), Rerr (Rraise (prim_exn (''Subscript''))))
                else
                  (case  store_assign lnum (Varray (List.list_update vs n v2)) s of
                      None => None
                    | Some s' => Some ((s',t1), Rval (Conv None []))
                  ))
        | _ => None
      )
    | (ConfigGC, [Litv (IntLit i), Litv (IntLit j)]) =>
        Some ((s,t1), Rval (Conv None []))
    | (FFI n, [Litv(StrLit conf), Loc lnum]) =>
        (case  store_lookup lnum s of
          Some (W8array ws) =>
            (case  call_FFI t1 n (List.map (\<lambda> c2 .  of_nat(of_char c2)) ( conf)) ws of
              (t', ws') =>
               (case  store_assign lnum (W8array ws') s of
                 Some s' => Some ((s', t'), Rval (Conv None []))
               | None => None
               )
            )
        | _ => None
        )
    | _ => None
  ))"


(* Do a logical operation *)
(*val do_log : lop -> v -> exp -> maybe exp_or_val*)
fun do_log  :: " lop \<Rightarrow> v \<Rightarrow> exp \<Rightarrow>(exp_or_val)option "  where 
     " do_log And v2 e = ( 
  (case  v2 of
      Litv _ => None
    | Conv m l2 => (case  m of
                       None => None
                     | Some p => (case  p of
                                     (s1,t1) =>
                                 if(s1 = (''true'')) then
                                   ((case  t1 of
                                        TypeId i => (case  i of
                                                        Short s2 =>
                                                    if(s2 = (''bool'')) then
                                                      ((case  l2 of
                                                           [] => Some (Exp e)
                                                         | _ => None
                                                       )) else None
                                                      | Long _ _ => None
                                                    )
                                      | TypeExn _ => None
                                    )) else
                                   (
                                   if(s1 = (''false'')) then
                                     ((case  t1 of
                                          TypeId i2 => (case  i2 of
                                                           Short s4 =>
                                                       if(s4 = (''bool'')) then
                                                         ((case  l2 of
                                                              [] => Some
                                                                    (Val v2)
                                                            | _ => None
                                                          )) else None
                                                         | Long _ _ => 
                                                       None
                                                       )
                                        | TypeExn _ => None
                                      )) else None)
                                 )
                   )
    | Closure _ _ _ => None
    | Recclosure _ _ _ => None
    | Loc _ => None
    | Vectorv _ => None
  ) )"
|" do_log Or v2 e = ( 
  (case  v2 of
      Litv _ => None
    | Conv m0 l6 => (case  m0 of
                        None => None
                      | Some p0 => (case  p0 of
                                       (s8,t0) =>
                                   if(s8 = (''false'')) then
                                     ((case  t0 of
                                          TypeId i5 => (case  i5 of
                                                           Short s9 =>
                                                       if(s9 = (''bool'')) then
                                                         ((case  l6 of
                                                              [] => Some
                                                                    (Exp e)
                                                            | _ => None
                                                          )) else None
                                                         | Long _ _ => 
                                                       None
                                                       )
                                        | TypeExn _ => None
                                      )) else
                                     (
                                     if(s8 = (''true'')) then
                                       ((case  t0 of
                                            TypeId i8 => (case  i8 of
                                                             Short s11 =>
                                                         if(s11 = (''bool'')) then
                                                           ((case  l6 of
                                                                [] => 
                                                            Some (Val v2)
                                                              | _ => 
                                                            None
                                                            )) else None
                                                           | Long _ _ => 
                                                         None
                                                         )
                                          | TypeExn _ => None
                                        )) else None)
                                   )
                    )
    | Closure _ _ _ => None
    | Recclosure _ _ _ => None
    | Loc _ => None
    | Vectorv _ => None
  ) )"


(* Do an if-then-else *)
(*val do_if : v -> exp -> exp -> maybe exp*)
definition do_if  :: " v \<Rightarrow> exp \<Rightarrow> exp \<Rightarrow>(exp)option "  where 
     " do_if v2 e1 e2 = (
  if v2 = (Boolv True) then
    Some e1
  else if v2 = (Boolv False) then
    Some e2
  else
    None )"


(* Semantic helpers for definitions *)

(* Build a constructor environment for the type definition tds *)
(*val build_tdefs : list modN -> list (list tvarN * typeN * list (conN * list t)) -> env_ctor*)
definition build_tdefs  :: "(string)list \<Rightarrow>((tvarN)list*string*(string*(t)list)list)list \<Rightarrow>((string),(string),(nat*tid_or_exn))namespace "  where 
     " build_tdefs mn tds = (
  alist_to_ns
    (List.rev
      (List.concat
        (List.map
          ( \<lambda>x .  
  (case  x of
      (tvs, tn, condefs) =>
  List.map
    ( \<lambda>x .  (case  x of
                        (conN, ts) =>
                    (conN, (List.length ts, TypeId (mk_id mn tn)))
                    )) condefs
  ))
          tds))))"


(* Checks that no constructor is defined twice in a type *)
(*val check_dup_ctors : list (list tvarN * typeN * list (conN * list t)) -> bool*)
definition check_dup_ctors  :: "((tvarN)list*string*(string*(t)list)list)list \<Rightarrow> bool "  where 
     " check_dup_ctors tds = (
  Lem_list.allDistinct ((let x2 = 
  ([]) in  List.foldr
   (\<lambda>x .  (case  x of
                      (tvs, tn, condefs) => \<lambda> x2 .  List.foldr
                                                              (\<lambda>x .  
                                                               (case  x of
                                                                   (n, ts) => 
                                                               \<lambda> x2 . 
                                                                 if True then
                                                                   n # x2
                                                                 else 
                                                                 x2
                                                               )) condefs 
                                                            x2
                  )) tds x2)))"


(*val combine_dec_result : forall 'a. sem_env v -> result (sem_env v) 'a -> result (sem_env v) 'a*)
fun combine_dec_result  :: "(v)sem_env \<Rightarrow>(((v)sem_env),'a)result \<Rightarrow>(((v)sem_env),'a)result "  where 
     " combine_dec_result env (Rerr e) = ( Rerr e )"
|" combine_dec_result env (Rval env') = ( Rval (| v = (nsAppend(v   env')(v   env)), c = (nsAppend(c   env')(c   env)) |) )"


(*val extend_dec_env : sem_env v -> sem_env v -> sem_env v*)
definition extend_dec_env  :: "(v)sem_env \<Rightarrow>(v)sem_env \<Rightarrow>(v)sem_env "  where 
     " extend_dec_env new_env env = (
  (| v = (nsAppend(v   new_env)(v   env)), c = (nsAppend(c   new_env)(c   env))  |) )"


(*val decs_to_types : list dec -> list typeN*)
definition decs_to_types  :: "(dec)list \<Rightarrow>(string)list "  where 
     " decs_to_types ds = (
  List.concat (List.map (\<lambda> d . 
        (case  d of
            Dtype locs tds => List.map ( \<lambda>x .  
  (case  x of (tvs,tn,ctors) => tn )) tds
          | _ => [] ))
     ds))"


(*val no_dup_types : list dec -> bool*)
definition no_dup_types  :: "(dec)list \<Rightarrow> bool "  where 
     " no_dup_types ds = (
  Lem_list.allDistinct (decs_to_types ds))"


(*val prog_to_mods : list top -> list (list modN)*)
definition prog_to_mods  :: "(top0)list \<Rightarrow>((string)list)list "  where 
     " prog_to_mods tops = (
  List.concat (List.map (\<lambda> top1 . 
        (case  top1 of
            Tmod mn _ _ => [[mn]]
          | _ => [] ))
     tops))"


(*val no_dup_mods : list top -> set (list modN) -> bool*)
definition no_dup_mods  :: "(top0)list \<Rightarrow>((modN)list)set \<Rightarrow> bool "  where 
     " no_dup_mods tops defined_mods2 = (
  Lem_list.allDistinct (prog_to_mods tops) \<and>
  (% M N. M \<inter> N = {}) (List.set (prog_to_mods tops)) defined_mods2 )"


(*val prog_to_top_types : list top -> list typeN*)
definition prog_to_top_types  :: "(top0)list \<Rightarrow>(string)list "  where 
     " prog_to_top_types tops = (
  List.concat (List.map (\<lambda> top1 . 
        (case  top1 of
            Tdec d => decs_to_types [d]
          | _ => [] ))
     tops))"


(*val no_dup_top_types : list top -> set tid_or_exn -> bool*)
definition no_dup_top_types  :: "(top0)list \<Rightarrow>(tid_or_exn)set \<Rightarrow> bool "  where 
     " no_dup_top_types tops defined_types2 = (
  Lem_list.allDistinct (prog_to_top_types tops) \<and>
  (% M N. M \<inter> N = {}) (List.set (List.map (\<lambda> tn .  TypeId (Short tn)) (prog_to_top_types tops))) defined_types2 )"

end
