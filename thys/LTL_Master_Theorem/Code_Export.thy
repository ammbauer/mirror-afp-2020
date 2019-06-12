(*
    Author:   Benedikt Seidl
    License:  BSD
*)

section \<open>Code export to Standard ML\<close>

theory Code_Export
imports
  "LTL_to_DRA/DRA_Implementation"
  LTL.Code_Equations
  "HOL-Library.Code_Target_Numeral"
begin

subsection \<open>LTL to DRA\<close>

export_code ltlc_to_draei checking


declare ltl_to_dra.af_letter\<^sub>F_lifted_semantics [code]
declare ltl_to_dra.af_letter\<^sub>G_lifted_semantics [code]
declare ltl_to_dra.af_letter\<^sub>\<nu>_lifted_semantics [code]

definition atoms_ltlc_list_literals :: "String.literal ltlc \<Rightarrow> String.literal list"
where
  "atoms_ltlc_list_literals = atoms_ltlc_list"

definition ltlc_to_draei_literals :: "String.literal ltlc \<Rightarrow> (String.literal set, nat) draei"
where
  "ltlc_to_draei_literals = ltlc_to_draei"

definition sort_transitions :: "(nat \<times> String.literal set \<times> nat) list \<Rightarrow> (nat \<times> String.literal set \<times> nat) list"
where
  "sort_transitions = sort_key fst"

export_code True_ltlc Iff_ltlc ltlc_to_draei_literals
  alphabetei initialei transei acceptingei
  integer_of_nat atoms_ltlc_list_literals sort_transitions set
  in SML module_name LTL file_prefix LTL_to_DRA



subsection \<open>LTL to NBA\<close>

(* TODO *)



subsection \<open>LTL to LDBA\<close>

(* TODO *)



end
