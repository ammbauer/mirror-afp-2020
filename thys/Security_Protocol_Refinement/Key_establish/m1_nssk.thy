(*******************************************************************************

  Project: Development of Security Protocols by Refinement

  Module:  Key_establish/m1_nssk.thy (Isabelle/HOL 2016-1)
  ID:      $Id: m1_nssk.thy 133856 2017-03-20 18:05:54Z csprenge $
  Author:  Christoph Sprenger, ETH Zurich <sprenger@inf.ethz.ch>
  
  Key distribution protocols
  First refinement: abstract server-based key transport protocol with 
  initiator and responder roles.

  Copyright (c) 2009-2016 Christoph Sprenger
  Licence: LGPL

*******************************************************************************)

section {* Abstract Needham-Schroeder Shared Key (L1) *}

theory m1_nssk imports m1_keydist_iirn 
begin

text {* We add augment the basic abstract key distribution model such that 
the server reads and stores the initiator's nonce. We show three refinements, 
namley that this model refines
\begin{enumerate}
\item the basic key distribution model @{text "m1a"}, and
\item the injective agreement model @{text "a0i"}, instantiated such that 
the initiator agrees with the server on the session key and its nonce.
\item the non-injective agreement model @{text "a0n"}, instantiated such that 
the responder agrees with the server on the session key.
\end{enumerate}
*}

consts
  nb :: "nat"       -- {* responder nonce constant *}
  END :: "atom"     -- {* run end marker for responder *}


(******************************************************************************)
subsection {* State *}
(******************************************************************************)

text {* We extend the basic key distribution by adding nonces. The frames, 
the state, and the observations remain the same as in the previous model, but 
we will use the @{typ "nat list"}'s to store nonces. *}

record m1_state = m1r_state + 
  leak :: "(key \<times> fresh_t \<times> fresh_t) set"   -- {* keys leaked plus session context *}

type_synonym m1_obs = "m1_state"

type_synonym 'x m1_pred = "'x m1_state_scheme set"
type_synonym 'x m1_trans = "('x m1_state_scheme \<times> 'x m1_state_scheme) set"


(******************************************************************************)
subsection {* Events *}
(******************************************************************************)

definition     -- {* by @{term "A"}, refines @{term "m1a_step1"} *}
  m1_step1 :: "[rid_t, agent, agent, nonce] \<Rightarrow> 'x m1r_trans"
where
  "m1_step1 Ra A B Na \<equiv> m1a_step1 Ra A B Na"

definition    -- {* by @{term "B"}, refines @{text "m1a_step2"} *}
  m1_step2 :: "[rid_t, agent, agent] \<Rightarrow> 'x m1r_trans"
where
  "m1_step2 Rb A B \<equiv> m1a_step2 Rb A B"

definition    -- {* by @{term "Server"}, refines @{term m1a_step3} *}
  m1_step3 :: "[rid_t, agent, agent, nonce, key] \<Rightarrow> 'x m1r_trans"
where
  "m1_step3 Rs A B Na Kab \<equiv> m1a_step3 Rs A B Kab Na []"

definition     -- {* by @{text "A"}, refines @{term m1a_step4} *}
  m1_step4 :: "[rid_t, agent, agent, nonce, key] \<Rightarrow> 'x m1_trans"
where
  "m1_step4 Ra A B Na Kab \<equiv> {(s, s').
     (* guards: *)
     runs s Ra = Some (Init, [A, B], []) \<and>
     Na = Ra$na \<and>                                              (* fix parameter *)
     (Kab \<notin> Domain (leak s) \<longrightarrow> (Kab, A) \<in> azC (runs s)) \<and>     (* authorization guard *)

     (* new guard for agreement with server on (Kab, B, Na), *)
     (* injectiveness by including Na *)
     (A \<notin> bad \<longrightarrow> (\<exists>Rs. Kab = sesK (Rs$sk) \<and>
        runs s Rs = Some (Serv, [A, B], [aNon Na]))) \<and>

     (* actions: *)
     s' = s\<lparr> runs := (runs s)(Ra \<mapsto> (Init, [A, B], [aKey Kab])) \<rparr>
  }"

definition     -- {* by @{term "B"}, refines @{term m1a_step5} *}
  m1_step5 :: "[rid_t, agent, agent, nonce, key] \<Rightarrow> 'x m1_trans"
where
  "m1_step5 Rb A B Nb Kab \<equiv> {(s, s'). 
     (* new guards: *)
     Nb = Rb$nb \<and>                                              (* generate Nb *)

     (* prev guards: *)
     runs s Rb = Some (Resp, [A, B], []) \<and> 
     (Kab \<notin> Domain (leak s) \<longrightarrow> (Kab, B) \<in> azC (runs s)) \<and>    (* authorization guard *)

     (* guard for showing agreement with server on (Kab, A), *)
     (* this agreement is non-injective *)
     (B \<notin> bad \<longrightarrow> (\<exists>Rs Na. Kab = sesK (Rs$sk) \<and>
        runs s Rs = Some (Serv, [A, B], [aNon Na]))) \<and>

     (* actions: *)
     s' = s\<lparr> runs := (runs s)(Rb \<mapsto> (Resp, [A, B], [aKey Kab])) \<rparr>
  }"

definition     -- {* by @{term "A"}, refines @{term skip} *}
  m1_step6 :: "[rid_t, agent, agent, nonce, nonce, key] \<Rightarrow> 'x m1_trans"
where
  "m1_step6 Ra A B Na Nb Kab \<equiv> {(s, s'). 
    runs s Ra = Some (Init, [A, B], [aKey Kab]) \<and>      (* key recv'd before *)
    Na = Ra$na \<and>

    (* guard for showing agreement with B on Kab and Nb *)
    (A \<notin> bad \<longrightarrow> B \<notin> bad \<longrightarrow> 
    (\<forall>Nb'. (Kab, Na, Nb') \<notin> leak s) \<longrightarrow>    (* NEW: weaker condition *)
       (\<exists>Rb nl. Nb = Rb$nb \<and> runs s Rb = Some (Resp, [A, B], aKey Kab # nl))) \<and> 

    (* actions: *)
    s' = s\<lparr>
      runs := (runs s)(Ra \<mapsto> (Init, [A, B], [aKey Kab, aNon Nb])) 
    \<rparr>
  }"

definition     -- {* by @{term "B"}, refines @{term skip} *}
  m1_step7 :: "[rid_t, agent, agent, nonce, key] \<Rightarrow> 'x m1_trans"
where
  "m1_step7 Rb A B Nb Kab \<equiv> {(s, s').
    runs s Rb = Some (Resp, [A, B], [aKey Kab]) \<and>      (* key recv'd before *)
    Nb = Rb$nb \<and>

    (* guard for showing agreement with A on Kab and Nb *)
    (A \<notin> bad \<longrightarrow> B \<notin> bad \<longrightarrow> Kab \<notin> Domain (leak s) \<longrightarrow> 
(*    (\<forall>Na'. (Kab, Na', Nb) \<notin> leak s) \<longrightarrow>     (too strong, does not work) *)
      (\<exists>Ra. runs s Ra = Some (Init, [A, B], [aKey Kab, aNon Nb]))) \<and> 
     
    (* actions: (redundant) update local state marks successful termination *)
    s' = s\<lparr>
      runs := (runs s)(Rb \<mapsto> (Resp, [A, B], [aKey Kab, END]))
    \<rparr>
  }"

definition     -- {* by attacker, refines @{term s0g_leak} *}
  m1_leak :: "[rid_t, rid_t, rid_t, agent, agent] \<Rightarrow> 'x m1_trans"
where
  "m1_leak Rs Ra Rb A B \<equiv> {(s, s1).           
    (* guards: *) 
    runs s Rs = Some (Serv, [A, B], [aNon (Ra$na)]) \<and>
    runs s Ra = Some (Init, [A, B], [aKey (sesK (Rs$sk)), aNon (Rb$nb)]) \<and>  
    runs s Rb = Some (Resp, [A, B], [aKey (sesK (Rs$sk)), END]) \<and>  

    (* actions: *)
    s1 = s\<lparr> leak := insert (sesK (Rs$sk), Ra$na, Rb$nb) (leak s) \<rparr>
  }"


(******************************************************************************)
subsection {* Specification *}
(******************************************************************************)

abbreviation
  m1_init :: "m1_state set"
where
  "m1_init \<equiv> { \<lparr>
     runs = empty,
     leak = corrKey \<times> {undefined} \<times> {undefined}      (* initial leakage *) 
  \<rparr> }" 

definition 
  m1_trans :: "'x m1_trans" where
  "m1_trans \<equiv> (\<Union>A B Ra Rb Rs Na Nb Kab.
     m1_step1 Ra A B Na \<union>
     m1_step2 Rb A B \<union>
     m1_step3 Rs A B Na Kab \<union>
     m1_step4 Ra A B Na Kab \<union>
     m1_step5 Rb A B Nb Kab \<union>
     m1_step6 Ra A B Na Nb Kab \<union>
     m1_step7 Rb A B Nb Kab \<union>
     m1_leak Rs Ra Rb A B \<union>
     Id
  )"

definition 
  m1 :: "(m1_state, m1_obs) spec" where
  "m1 \<equiv> \<lparr>
    init = m1_init,
    trans = m1_trans,
    obs = id
  \<rparr>" 

lemmas m1_loc_defs = 
  m1_def m1_trans_def
  m1_step1_def m1_step2_def m1_step3_def m1_step4_def m1_step5_def 
  m1_step6_def m1_step7_def m1_leak_def

lemmas m1_defs = m1_loc_defs m1a_defs 

lemma m1_obs_id [simp]: "obs m1 = id"
by (simp add: m1_def)


(******************************************************************************)
subsection {* Invariants *}
(******************************************************************************)

subsubsection {* inv0: Finite domain *}
(*inv**************************************************************************)

text {* There are only finitely many runs. This is needed to establish the 
responder/initiator agreements. This is already defined in the previous model,
we just need to show that it still holds in the current model. *}

abbreviation
  m1_inv0_fin :: "'x m1_pred" where
  "m1_inv0_fin \<equiv> m1a_inv0_fin"

lemmas m1_inv0_finI = m1a_inv0_finI
lemmas m1_inv0_finE = m1a_inv0_finE
lemmas m1_inv0_finD = m1a_inv0_finD


text {* Invariance proofs. *}

lemma PO_m1_inv0_fin_init [iff]:
  "init m1 \<subseteq> m1_inv0_fin"
by (auto simp add: m1_defs intro!: m1_inv0_finI)

lemma PO_m1_inv0_fin_trans [iff]:
  "{m1_inv0_fin} trans m1 {> m1_inv0_fin}"
by (auto simp add: PO_hoare_defs m1_defs intro!: m1_inv0_finI)

lemma PO_m1_inv0_fin [iff]: "reach m1 \<subseteq> m1_inv0_fin"
by (rule inv_rule_incr, auto del: subsetI)

declare PO_m1_inv0_fin [THEN subsetD, intro]


(******************************************************************************)
subsection {* Refinement of @{text "m1a"} *}
(******************************************************************************)

subsubsection {* Simulation relation *}
(******************************************************************************)

text {* med1a1: The mediator function maps a concrete observation (i.e., run) 
to an abstract one. *}


text {* Instantiate parameters regarding list of freshness identifiers stored
at server. *}

overloading is_len' \<equiv> "is_len" rs_len' \<equiv> "rs_len" begin
definition is_len_def [simp]: "is_len' \<equiv> 0::nat"
definition rs_len_def [simp]: "rs_len' \<equiv> 0::nat"
end

fun 
  rm1a1 :: "role_t \<Rightarrow> atom list \<Rightarrow> atom list"
where
  "rm1a1 Init = take (Suc is_len)"       (* take Kab *)
| "rm1a1 Resp = take (Suc rs_len)"       (* take Kab *)
| "rm1a1 Serv = id"                      (* take all *)

abbreviation 
  runs1a1 :: "runs_t \<Rightarrow> runs_t" where
  "runs1a1 \<equiv> map_runs rm1a1" 

lemmas runs1a1_def = map_runs_def

lemma knC_runs1a1 [simp]:
  "knC (runs1a1 runz) = knC runz"
apply (auto simp add: map_runs_def elim!: knC.cases)
apply (rename_tac b, case_tac b, auto)
apply (rename_tac b, case_tac b, auto)
apply (rule knC_init, auto simp add: runs1a1_def)
apply (rule knC_resp, auto simp add: runs1a1_def)
apply (rule_tac knC_serv, auto simp add: runs1a1_def)
done


text {* R1a1: The simulation relation is defined in terms of the mediator
function. *}

definition
  med1a1 :: "m1_obs \<Rightarrow> m1a_obs" where
  "med1a1 s \<equiv> \<lparr> runs = runs1a1 (runs s), m1x_state.leak = Domain (leak s) \<rparr>"
   
definition
  R1a1 :: "(m1a_state \<times> m1_state) set" where
  "R1a1 \<equiv> {(s, t). s = med1a1 t}"

lemmas R1a1_defs = R1a1_def med1a1_def 


subsubsection {* Refinement proof *}
(******************************************************************************)

lemma PO_m1_step1_refines_m1a_step1:
  "{R1a1} 
     (m1a_step1 Ra A B Na), (m1_step1 Ra A B Na) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs)

lemma PO_m1_step2_refines_m1a_step2:
  "{R1a1} 
     (m1a_step2 Rb A B), (m1_step2 Rb A B) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs)

lemma PO_m1_step3_refines_m1a_step3:
  "{R1a1} 
     (m1a_step3 Rs A B Kab Na []), (m1_step3 Rs A B Na Kab)
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs)

lemma PO_m1_step4_refines_m1a_step4:
  "{R1a1} 
     (m1a_step4 Ra A B Na Kab []), (m1_step4 Ra A B Na Kab) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs runs1a1_def)

lemma PO_m1_step5_refines_m1a_step5:
  "{R1a1} 
     (m1a_step5 Rb A B Kab []), (m1_step5 Rb A B Nb Kab) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs runs1a1_def)

lemma PO_m1_step6_refines_m1a_skip:
  "{R1a1} 
     Id, (m1_step6 Ra A B Na Nb Kab) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs runs1a1_def)

lemma PO_m1_step7_refines_m1a_skip:
  "{R1a1} 
     Id, (m1_step7 Rb A B Nb Kab) 
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs runs1a1_def)

lemma PO_m1_leak_refines_m1a_leak:
  "{R1a1} 
     (m1a_leak Rs), (m1_leak Rs Ra Rb A B)
   {> R1a1}"
by (auto simp add: PO_rhoare_defs R1a1_defs m1_defs map_runs_def dest: dom_lemmas)


text {* All together now... *}

lemmas PO_m1_trans_refines_m1a_trans = 
  PO_m1_step1_refines_m1a_step1 PO_m1_step2_refines_m1a_step2
  PO_m1_step3_refines_m1a_step3 PO_m1_step4_refines_m1a_step4
  PO_m1_step5_refines_m1a_step5 PO_m1_step6_refines_m1a_skip 
  PO_m1_step7_refines_m1a_skip PO_m1_leak_refines_m1a_leak

lemma PO_m1_refines_init_m1a [iff]:
  "init m1 \<subseteq>  R1a1``(init m1a)"
by (auto simp add: R1a1_defs m1a_defs m1_loc_defs)

lemma PO_m1_refines_trans_m1a [iff]:
  "{R1a1} 
     (trans m1a), (trans m1) 
   {> R1a1}"
apply (auto simp add: m1_def m1_trans_def m1a_def m1a_trans_def
         intro!: PO_m1_trans_refines_m1a_trans)
apply (force intro!: PO_m1_trans_refines_m1a_trans)+
done


text {* Observation consistency. *}

lemma obs_consistent_med1a1 [iff]: 
  "obs_consistent R1a1 med1a1 m1a m1"
by (auto simp add: obs_consistent_def R1a1_def med1a1_def m1a_def m1_def)


text {* Refinement result. *}

lemma PO_m1_refines_m1a [iff]: 
  "refines R1a1 med1a1 m1a m1"
by (rule Refinement_basic) (auto del: subsetI)

lemma  m1_implements_m1a [iff]: "implements med1a1 m1a m1"
by (rule refinement_soundness) (fast)



subsubsection {* inv (inherited): Key secrecy *}
(*invh**************************************************************************)

text {* Secrecy, as external and internal invariant *}

definition 
  m1_secrecy :: "'x m1_pred" where
  "m1_secrecy \<equiv> {s. knC (runs s) \<subseteq> azC (runs s) \<union> Domain (leak s) \<times> UNIV}"

lemmas m1_secrecyI = m1_secrecy_def [THEN setc_def_to_intro, rule_format]
lemmas m1_secrecyE [elim] = m1_secrecy_def [THEN setc_def_to_elim, rule_format]


lemma PO_m1_obs_secrecy [iff]: "oreach m1 \<subseteq> m1_secrecy"
apply (rule_tac Q=m1x_secrecy in external_invariant_translation)
apply (auto del: subsetI)
apply (fastforce simp add: med1a1_def intro!: m1_secrecyI)
done

lemma PO_m1_secrecy [iff]: "reach m1 \<subseteq> m1_secrecy"
by (rule external_to_internal_invariant) (auto del: subsetI)

(*
subsubsection {* inv (inherited): Disjointness of session and static keys *}
(******************************************************************************)

lemma PO_m1_inv0b_key [iff]: "reach m1 \<subseteq> m1a_inv0b_key"
apply (rule_tac Pa=m1a_inv0b_key and Qa=m1a_inv0b_key and Q=m1a_inv0b_key
       in internal_invariant_translation)
apply (auto del: subsetI)
apply (force simp add: med1a1_def runs1a1_def vimage_def m1a_inv0b_key_def)
done
*)

subsubsection {* inv (inherited): Initiator auth server. *}
(*invh*************************************************************************)

text {* Simplified version of invariant @{text "m1a_inv2i_serv"}. *}

definition 
  m1_inv2i_serv :: "'x m1r_pred" 
where
  "m1_inv2i_serv \<equiv> {s. \<forall>A B Ra Na Kab nla.
     A \<notin> bad \<longrightarrow> 
     runs s Ra = Some (Init, [A, B], aKey Kab # nla) \<longrightarrow>
     Na = Ra$na \<longrightarrow>
       (\<exists>Rs. Kab = sesK (Rs$sk) \<and> runs s Rs = Some (Serv, [A, B], [aNon Na]))
  }"

lemmas m1_inv2i_servI = m1_inv2i_serv_def [THEN setc_def_to_intro, rule_format]
lemmas m1_inv2i_servE [elim] = m1_inv2i_serv_def [THEN setc_def_to_elim, rule_format]
lemmas m1_inv2i_servD = m1_inv2i_serv_def [THEN setc_def_to_dest, rule_format, rotated 2]


text {* Proof of invariance. *}

lemma PO_m1_inv2i_serv [iff]: "reach m1 \<subseteq> m1_inv2i_serv"
apply (rule_tac Pa=m1a_inv2i_serv and Qa=m1a_inv2i_serv and Q=m1_inv2i_serv
       in internal_invariant_translation)
apply (auto del: subsetI)
apply (auto simp add: m1a_inv2i_serv_def med1a1_def vimage_def 
            intro!: m1_inv2i_servI)
apply (rename_tac s A B Ra Kab nla)
apply (drule_tac x=A in spec, clarsimp)
apply (drule_tac x=B in spec) 
apply (drule_tac x=Ra in spec) 
apply (drule_tac x=Kab in spec) 
apply (clarsimp simp add: runs1a1_def)
done

declare PO_m1_inv2i_serv [THEN subsetD, intro]


subsubsection {* inv (inherited): Responder auth server. *}
(*invh*************************************************************************)

text {* Simplified version of invarant @{text "m1a_inv2r_serv"}. *}

definition 
  m1_inv2r_serv :: "'x m1r_pred"
where
  "m1_inv2r_serv \<equiv> {s. \<forall>A B Rb Kab nlb.
     B \<notin> bad \<longrightarrow> 
     runs s Rb = Some (Resp, [A, B], aKey Kab # nlb) \<longrightarrow>
       (\<exists>Rs Na. Kab = sesK (Rs$sk) \<and> runs s Rs = Some (Serv, [A, B], [aNon Na]))
  }"

lemmas m1_inv2r_servI = m1_inv2r_serv_def [THEN setc_def_to_intro, rule_format]
lemmas m1_inv2r_servE [elim] = m1_inv2r_serv_def [THEN setc_def_to_elim, rule_format]
lemmas m1_inv2r_servD = m1_inv2r_serv_def [THEN setc_def_to_dest, rule_format, rotated -1]


text {* Proof of invariance. *}

lemma PO_m1_inv2r_serv [iff]: "reach m1 \<subseteq> m1_inv2r_serv"
apply (rule_tac Pa=m1a_inv2r_serv and Qa=m1a_inv2r_serv and Q=m1_inv2r_serv
       in internal_invariant_translation)
apply (auto del: subsetI)
apply (auto simp add: simp add: m1a_inv2r_serv_def med1a1_def vimage_def 
            intro!: m1_inv2r_servI)
apply (rename_tac s A B Rb Kab nlb)
apply (drule_tac x=A in spec)
apply (drule_tac x=B in spec, clarsimp) 
apply (drule_tac x=Rb in spec)
apply (drule_tac x=Kab in spec) 
apply (clarsimp simp add: runs1a1_def)
done

declare PO_m1_inv2r_serv [THEN subsetD, intro]


subsubsection {* inv (inherited): Initiator key freshness *}
(*invh*************************************************************************)

definition 
  m1_inv3_ifresh :: "'x m1_pred"
where
  "m1_inv3_ifresh \<equiv> {s. \<forall>A A' B B' Ra Ra' Kab nl nl'.
     runs s Ra  = Some (Init, [A,  B],  aKey Kab # nl) \<longrightarrow>
     runs s Ra' = Some (Init, [A', B'], aKey Kab # nl') \<longrightarrow>
     A \<notin> bad \<longrightarrow> B \<notin> bad \<longrightarrow> Kab \<notin> Domain (leak s) \<longrightarrow>
       Ra = Ra'
  }"

lemmas m1_inv3_ifreshI = m1_inv3_ifresh_def [THEN setc_def_to_intro, rule_format]
lemmas m1_inv3_ifreshE [elim] = m1_inv3_ifresh_def [THEN setc_def_to_elim, rule_format]
lemmas m1_inv3_ifreshD = m1_inv3_ifresh_def [THEN setc_def_to_dest, rule_format, rotated 1]

lemma PO_m1_inv3_ifresh [iff]: "reach m1 \<subseteq> m1_inv3_ifresh"
apply (rule_tac Pa=m1a_inv1_ifresh and Qa=m1a_inv1_ifresh and Q=m1_inv3_ifresh 
       in internal_invariant_translation)
apply (auto del: subsetI)
apply (auto simp add: med1a1_def runs1a1_def vimage_def m1_inv3_ifresh_def)
done


(******************************************************************************)
subsection {* Refinement of @{text "a0i"} for initiator/responder *}
(******************************************************************************)

subsubsection {* Simulation relation *}
(******************************************************************************)

text {* We define two auxiliary functions to reconstruct the signals of the
initial model from completed initiator and responder runs. For the initiator, 
we get an injective agreement with the responder on Kab and Nb. *}

type_synonym
  irsig = "key \<times> nonce"

abbreviation
  ir_commit :: "[runs_t, agent, agent, key, nonce] \<Rightarrow> rid_t set" 
where
  "ir_commit runz A B Kab Nb \<equiv> {Ra. 
     runz Ra = Some (Init, [A, B], [aKey Kab, aNon Nb])
  }"

fun
  ir_runs2sigs :: "runs_t \<Rightarrow> irsig signal \<Rightarrow> nat"
where
  "ir_runs2sigs runz (Commit [A, B] (Kab, Nb)) =
     card (ir_commit runz A B Kab Nb)"

| "ir_runs2sigs runz (Running [A, B] (Kab, Nb)) =
     (if \<exists>Rb nl. Nb = Rb$nb \<and> runz Rb = Some (Resp, [A, B], aKey Kab # nl) 
      then 1 else 0)"

| "ir_runs2sigs runz _ = 0"


text {* Simulation relation and mediator function. We map completed initiator 
and responder runs to commit and running signals, respectively. *}

definition 
  med_a0im1_ir :: "m1_obs \<Rightarrow> irsig a0i_obs" where
  "med_a0im1_ir o1 \<equiv> \<lparr> signals = ir_runs2sigs (runs o1), corrupted = Domain (leak o1) \<times> UNIV \<rparr>"

definition
  R_a0im1_ir :: "(irsig a0i_state \<times> m1_state) set" where
  "R_a0im1_ir \<equiv> {(s, t). signals s = ir_runs2sigs (runs t) \<and> corrupted s = Domain (leak t) \<times> UNIV}"

lemmas R_a0im1_ir_defs = R_a0im1_ir_def med_a0im1_ir_def 


subsubsection {* Lemmas about the abstraction function *}
(******************************************************************************)

lemma ir_runs2sigs_empty [simp]: 
   "runz = empty \<Longrightarrow> ir_runs2sigs runz = (\<lambda>s. 0)"
by (rule ext, erule rev_mp) 
   (rule ir_runs2sigs.induct, auto)

lemma finite_ir_commit [simp, intro!]: 
   "finite (dom runz) \<Longrightarrow> finite (ir_commit runz A B Kab Nb)"
by (auto intro: finite_subset dest: dom_lemmas)


text {* Update lemmas *}

lemma ir_runs2sigs_upd_init_none [simp]:
  "\<lbrakk> Ra \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Ra \<mapsto> (Init, [A, B], []))) = ir_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ir_runs2sigs.induct, auto dest: dom_lemmas)

lemma ir_runs2sigs_upd_resp_none [simp]:
  "\<lbrakk> Rb \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], []))) = ir_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ir_runs2sigs.induct, auto dest: dom_lemmas)

lemma ir_runs2sigs_upd_serv_none [simp]:
  "\<lbrakk> Rs \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Rs \<mapsto> (Serv, [A, B], nl))) = ir_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ir_runs2sigs.induct, auto dest: dom_lemmas)

lemma ir_runs2sigs_upd_init_some [simp]:
  "\<lbrakk> runz Ra = Some (Init, [A, B], []) \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Ra \<mapsto> (Init, [A, B], [aKey Kab]))) = ir_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ir_runs2sigs.induct, auto)

lemma ir_runs2sigs_upd_resp [simp]:
  "\<lbrakk> runz Rb = Some (Resp, [A, B], []) \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], [aKey Kab]))) =
     (ir_runs2sigs runz)(Running [A, B] (Kab, Rb$nb) := 1)"
apply (rule ext, erule rev_mp) 
apply (rule ir_runs2sigs.induct, fastforce+) 
done

lemma ir_runs2sigs_upd_init [simp]:
  "\<lbrakk> runz Ra = Some (Init, [A, B], [aKey Kab]); finite (dom runz) \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Ra \<mapsto> (Init, [A, B], [aKey Kab, aNon Nb]))) = 
     (ir_runs2sigs runz)
       (Commit [A, B] (Kab, Nb) := Suc (card (ir_commit runz A B Kab Nb)))"
apply (rule ext, erule rev_mp, erule rev_mp) 
apply (rule_tac ?a0.0=runz in ir_runs2sigs.induct, auto)
-- {* 1 subgoal, solved using @{thm "card_insert_disjoint"} *}
apply (rename_tac runz)
apply (rule_tac 
         s="card (insert Ra (ir_commit runz A B Kab Nb))" 
       in trans, fast, auto)
done

lemma ir_runs2sigs_upd_resp_some [simp]:
  "\<lbrakk> runz Rb = Some (Resp, [A, B], [aKey K]) \<rbrakk>
  \<Longrightarrow> ir_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], [aKey K, END]))) = ir_runs2sigs runz"
by (rule ext, erule rev_mp) 
   (rule ir_runs2sigs.induct, fastforce+)


text {* Needed for injectiveness of agreement. *}

lemma m1_inv2i_serv_lemma:
  "\<lbrakk> runs t Ra  = Some (Init, [A, B], [aKey Kab, aNon Nb]);
     runs t Ra' = Some (Init, [A, B], [aKey Kab]); 
     A \<notin> bad; t \<in> m1_inv2i_serv \<rbrakk>
  \<Longrightarrow> P"
apply (frule m1_inv2i_servD, auto)
apply (rotate_tac 1)
apply (frule m1_inv2i_servD, auto) 
done


subsubsection {* Refinement proof *}
(******************************************************************************)

lemma PO_m1_step1_refines_ir_a0i_skip:
  "{R_a0im1_ir} 
     Id, (m1_step1 Ra A B Na) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs m1_defs, safe, auto)

lemma PO_m1_step2_refines_ir_a0i_skip:
  "{R_a0im1_ir} 
     Id, (m1_step2 Rb A B) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs m1_defs, safe, auto)

lemma PO_m1_step3_refines_ir_a0i_skip:
  "{R_a0im1_ir} 
     Id, (m1_step3 Rs A B Na Kab) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs m1_defs, safe, auto)

lemma PO_m1_step4_refines_ir_a0i_skip:
  "{R_a0im1_ir} 
     Id, (m1_step4 Ra A B Na Kab) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step5_refines_ir_a0i_running:
  "{R_a0im1_ir} 
     (a0i_running [A, B] (Kab, Nb)), (m1_step5 Rb A B Nb Kab) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step6_refines_ir_a0i_commit:
  "{R_a0im1_ir \<inter> UNIV \<times> (m1_inv2i_serv \<inter> m1_inv0_fin)} 
     (a0i_commit [A, B] (Kab, Nb)), (m1_step6 Ra A B Na Nb Kab) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs a0i_defs m1_defs, safe, auto)
   (auto dest: m1_inv2i_serv_lemma)

lemma PO_m1_step7_refines_ir_a0i_skip:
  "{R_a0im1_ir} 
     Id, (m1_step7 Rb A B Nb Kab) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_leak_refines_ir_a0i_corrupt:
  "{R_a0im1_ir} 
     (a0i_corrupt ({sesK (Rs$sk)} \<times> UNIV)), (m1_leak Rs Ra Rb A B) 
   {> R_a0im1_ir}"
by (simp add: PO_rhoare_defs R_a0im1_ir_defs a0i_defs m1_defs, safe, auto)


text {* All together now... *}

lemmas PO_m1_trans_refines_ir_a0i_trans = 
  PO_m1_step1_refines_ir_a0i_skip PO_m1_step2_refines_ir_a0i_skip
  PO_m1_step3_refines_ir_a0i_skip PO_m1_step4_refines_ir_a0i_skip
  PO_m1_step5_refines_ir_a0i_running PO_m1_step6_refines_ir_a0i_commit
  PO_m1_step7_refines_ir_a0i_skip PO_m1_leak_refines_ir_a0i_corrupt 

lemma PO_m1_refines_ir_init_a0i [iff]:
  "init m1 \<subseteq>  R_a0im1_ir``(init a0i)"
by (auto simp add: R_a0im1_ir_defs a0i_defs m1_defs
         intro!: exI [where x="\<lparr>signals = \<lambda>s. 0, corrupted = corrKey \<times> UNIV \<rparr>"])

lemma PO_m1_refines_ir_trans_a0i [iff]:
  "{R_a0im1_ir \<inter> reach a0i \<times> reach m1} 
     (trans a0i), (trans m1) 
   {> R_a0im1_ir}"
apply (rule_tac pre'="R_a0im1_ir \<inter> UNIV \<times> (m1_inv2i_serv \<inter> m1_inv0_fin)" 
       in relhoare_conseq_left, auto)
apply (auto simp add: m1_def m1_trans_def a0i_def a0i_trans_def
            intro!: PO_m1_trans_refines_ir_a0i_trans)
done


text {* Observation consistency. *}

lemma obs_consistent_med_a0im1_ir [iff]: 
  "obs_consistent R_a0im1_ir med_a0im1_ir a0i m1"
by (auto simp add: obs_consistent_def R_a0im1_ir_def med_a0im1_ir_def 
         a0i_def m1_def)

text {* Refinement result. *}

lemma PO_m1_refines_ir_a0i [iff]: 
  "refines 
     (R_a0im1_ir \<inter> reach a0i \<times> reach m1)
     med_a0im1_ir a0i m1"
by (rule Refinement_using_invariants) (auto)

lemma  m1_implements_ir_a0i: "implements med_a0im1_ir a0i m1"
by (rule refinement_soundness) (fast)


(******************************************************************************)
subsection {* Refinement of @{text "a0i"} for responder/initiator *}
(******************************************************************************)

subsubsection {* Simulation relation *}
(******************************************************************************)

text {* We define two auxiliary functions to reconstruct the signals of the
initial model from initiator and responder runs. For the responder, we get an 
injective agreement with the initiator on Kab and Nb. *}

type_synonym
  risig = "key \<times> nonce"

abbreviation
  ri_running :: "[runs_t, agent, agent, key, nonce] \<Rightarrow> rid_t set"
where
  "ri_running runz A B Kab Nb \<equiv> {Ra. 
     runz Ra = Some (Init, [A, B], [aKey Kab, aNon Nb])
  }"

fun
  ri_runs2sigs :: "runs_t \<Rightarrow> risig signal \<Rightarrow> nat"
where
  "ri_runs2sigs runz (Commit [B, A] (Kab, Nb)) = 
     (if \<exists>Rb. Nb = Rb$nb \<and> runz Rb = Some (Resp, [A, B], [aKey Kab, END]) 
      then 1 else 0)"

| "ri_runs2sigs runz (Running [B, A] (Kab, Nb)) = 
     card (ri_running runz A B Kab Nb)"

| "ri_runs2sigs runz _ = 0"


text {* Simulation relation and mediator function. We map completed initiator 
and responder runs to commit and running signals, respectively. *}

definition 
  med_a0im1_ri :: "m1_obs \<Rightarrow> risig a0i_obs" where
  "med_a0im1_ri o1 \<equiv> \<lparr> signals = ri_runs2sigs (runs o1), corrupted = Domain (leak o1) \<times> UNIV \<rparr>"

definition
  R_a0im1_ri :: "(risig a0i_state \<times> m1_state) set" where
  "R_a0im1_ri \<equiv> {(s, t). signals s = ri_runs2sigs (runs t) \<and> corrupted s = Domain (leak t) \<times> UNIV}"

lemmas R_a0im1_ri_defs = R_a0im1_ri_def med_a0im1_ri_def 


subsubsection {* Lemmas about the auxiliary functions *}
(******************************************************************************)

lemma ri_runs2sigs_empty [simp]: 
  "runz = empty \<Longrightarrow> ri_runs2sigs runz = (\<lambda>s. 0)"
by (rule ext, erule rev_mp) 
   (rule ri_runs2sigs.induct, auto)

lemma finite_inv_ri_running [simp, intro!]: 
   "finite (dom runz) \<Longrightarrow> finite (ri_running runz A B Kab Nb)"
by (auto intro: finite_subset dest: dom_lemmas)


text {* Update lemmas *}

lemma ri_runs2sigs_upd_init_none [simp]:
  "\<lbrakk> Na \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Na \<mapsto> (Init, [A, B], []))) = ri_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ri_runs2sigs.induct, auto dest: dom_lemmas)

lemma ri_runs2sigs_upd_resp_none [simp]:
  "\<lbrakk> Rb \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], []))) = ri_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ri_runs2sigs.induct, auto dest: dom_lemmas)

lemma ri_runs2sigs_upd_serv_none [simp]:
  "\<lbrakk> Rs \<notin> dom runz \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Rs \<mapsto> (Serv, [A, B], nl))) = ri_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ri_runs2sigs.induct, auto dest: dom_lemmas)

lemma ri_runs2sigs_upd_init [simp]:
  "\<lbrakk> runz Ra = Some (Init, [A, B], [aKey Kab]); finite (dom runz) \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Ra \<mapsto> (Init, [A, B], [aKey Kab, aNon Nb]))) =
     (ri_runs2sigs runz)
       (Running [B, A] (Kab, Nb) := Suc (card (ri_running runz A B Kab Nb)))"
apply (rule ext, erule rev_mp, erule rev_mp)
apply (rule_tac ?a0.0=runz in ri_runs2sigs.induct, auto)
-- {* 1 subgoal, solved using @{thm "card_insert_disjoint"} *}
apply (rename_tac runz)
apply (rule_tac 
         s="card (insert Ra (ri_running runz A B Kab Nb))" 
       in trans, fast, auto)
done

lemma ri_runs2sigs_upd_init_some [simp]:
  "\<lbrakk> runz Ra = Some (Init, [A, B], []) \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Ra \<mapsto> (Init, [A, B], [aKey Kab]))) = ri_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ri_runs2sigs.induct, auto)

lemma ri_runs2sigs_upd_resp_some [simp]:
  "\<lbrakk> runz Rb = Some (Resp, [A, B], [])\<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], [aKey K]))) = ri_runs2sigs runz"
by (rule ext, erule rev_mp)
   (rule ri_runs2sigs.induct, auto)

lemma ri_runs2sigs_upd_resp_some2 [simp]:
  "\<lbrakk> runz Rb = Some (Resp, [A, B], [aKey Kab]) \<rbrakk>
  \<Longrightarrow> ri_runs2sigs (runz(Rb \<mapsto> (Resp, [A, B], [aKey Kab, END]))) = 
     (ri_runs2sigs runz)(Commit [B, A] (Kab, Rb$nb) := 1)"
apply (rule ext, erule rev_mp)
apply (rule ri_runs2sigs.induct, fastforce+)
done


subsubsection {* Refinement proof *}
(******************************************************************************)

lemma PO_m1_step1_refines_ri_a0i_skip:
  "{R_a0im1_ri} 
     Id, (m1_step1 Ra A B Na) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs m1_defs, safe, auto)

lemma PO_m1_step2_refines_ri_a0i_skip:
  "{R_a0im1_ri} 
     Id, (m1_step2 Rb A B) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs m1_defs, safe, auto)

lemma PO_m1_step3_refines_ri_a0i_skip:
  "{R_a0im1_ri} 
     Id, (m1_step3 Rs A B Na Kab) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step4_refines_ri_a0i_skip:
  "{R_a0im1_ri} 
     Id, (m1_step4 Ra A B Nb Kab) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step5_refines_ri_a0i_skip:
  "{R_a0im1_ri} 
     Id, (m1_step5 Rb A B Nb Kab) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step6_refines_ri_a0i_running:
  "{R_a0im1_ri \<inter> UNIV \<times> m1_inv0_fin} 
     (a0i_running [B, A] (Kab, Nb)), (m1_step6 Ra A B Na Nb Kab) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_step7_refines_ri_a0i_commit:
  "{R_a0im1_ri \<inter> UNIV \<times> m1_inv0_fin} 
     (a0i_commit [B, A] (Kab, Nb)), (m1_step7 Rb A B Nb Kab) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)

lemma PO_m1_leak_refines_ri_a0i_corrupt:
  "{R_a0im1_ri} 
     (a0i_corrupt ({sesK (Rs$sk)} \<times> UNIV)), (m1_leak Rs Ra Rb A B) 
   {> R_a0im1_ri}"
by (simp add: PO_rhoare_defs R_a0im1_ri_defs a0i_defs m1_defs, safe, auto)


text {* All together now... *}

lemmas PO_m1_trans_refines_ri_a0i_trans = 
  PO_m1_step1_refines_ri_a0i_skip PO_m1_step2_refines_ri_a0i_skip
  PO_m1_step3_refines_ri_a0i_skip PO_m1_step4_refines_ri_a0i_skip
  PO_m1_step5_refines_ri_a0i_skip PO_m1_step6_refines_ri_a0i_running
  PO_m1_step7_refines_ri_a0i_commit PO_m1_leak_refines_ri_a0i_corrupt

lemma PO_m1_refines_ri_init_a0i [iff]:
  "init m1 \<subseteq>  R_a0im1_ri``(init a0i)"
by (auto simp add: R_a0im1_ri_defs a0i_defs m1_defs
         intro!: exI [where x="\<lparr>signals = \<lambda>s. 0, corrupted = corrKey \<times> UNIV \<rparr>"])

lemma PO_m1_refines_ri_trans_a0i [iff]:
  "{R_a0im1_ri \<inter> a0i_inv1_iagree \<times> m1_inv0_fin} 
     (trans a0i), (trans m1) 
   {> R_a0im1_ri}"
by (auto simp add: m1_def m1_trans_def a0i_def a0i_trans_def)
   (blast intro!: PO_m1_trans_refines_ri_a0i_trans)+


text {* Observation consistency. *}

lemma obs_consistent_med_a0im1_ri [iff]: 
  "obs_consistent R_a0im1_ri med_a0im1_ri a0i m1"
by (auto simp add: obs_consistent_def R_a0im1_ri_def med_a0im1_ri_def a0i_def m1_def)


text {* Refinement result. *}

lemma PO_m1_refines_ri_a0i [iff]: 
  "refines (R_a0im1_ri \<inter> a0i_inv1_iagree \<times> m1_inv0_fin) med_a0im1_ri a0i m1"
by (rule Refinement_using_invariants) (auto)

lemma  m1_implements_ri_a0i: "implements med_a0im1_ri a0i m1"
by (rule refinement_soundness) (fast)


subsubsection {* inv3 (inherited): Responder and initiator *}
(*invh*************************************************************************)

text {* This is a translation of the agreement property to Level 1. It
follows from the refinement and is needed to prove inv4. *}

definition 
  m1_inv3r_init :: "'x m1_pred"
where
  "m1_inv3r_init \<equiv> {s. \<forall>A B Rb Kab.
     B \<notin> bad \<longrightarrow> A \<notin> bad \<longrightarrow> Kab \<notin> Domain (leak s) \<longrightarrow>
     runs s Rb = Some (Resp, [A, B], [aKey Kab, END]) \<longrightarrow>
       (\<exists>Ra nla. runs s Ra = Some (Init, [A, B], aKey Kab # aNon (Rb$nb) # nla))
  }"

lemmas m1_inv3r_initI = 
  m1_inv3r_init_def [THEN setc_def_to_intro, rule_format]
lemmas m1_inv3r_initE [elim] = 
  m1_inv3r_init_def [THEN setc_def_to_elim, rule_format]
lemmas m1_inv3r_initD = 
  m1_inv3r_init_def [THEN setc_def_to_dest, rule_format, rotated -1]


text {* Invariance proof. *}

lemma PO_m1_inv3r_init [iff]: "reach m1 \<subseteq> m1_inv3r_init"
apply (rule INV_from_Refinement_basic [OF PO_m1_refines_ri_a0i])
apply (auto simp add: R_a0im1_ri_def a0i_inv1_iagree_def
            intro!:  m1_inv3r_initI)
apply (rename_tac s A B Rb Kab a)
apply (drule_tac x="[B, A]" in spec, clarsimp)
apply (drule_tac x="Kab" in spec)
(* apply (drule_tac x="Rb$nb" in spec, auto) *)
apply (subgoal_tac "card (ri_running (runs s) A B Kab (Rb$nb)) > 0", auto) 
done


subsubsection {* inv4: Key freshness for responder *}
(*inv**************************************************************************)

definition 
  m1_inv4_rfresh :: "'x m1_pred"
where
  "m1_inv4_rfresh \<equiv> {s. \<forall>Rb Rb' A A' B B' Kab.
     runs s Rb  = Some (Resp, [A,  B ], [aKey Kab, END]) \<longrightarrow> 
     runs s Rb' = Some (Resp, [A', B'], [aKey Kab, END]) \<longrightarrow> 
     B \<notin> bad \<longrightarrow> A \<notin> bad \<longrightarrow> Kab \<notin> Domain (leak s) \<longrightarrow>
       Rb = Rb'
  }"

lemmas m1_inv4_rfreshI = m1_inv4_rfresh_def [THEN setc_def_to_intro, rule_format]
lemmas m1_inv4_rfreshE [elim] = m1_inv4_rfresh_def [THEN setc_def_to_elim, rule_format]
lemmas m1_inv4_rfreshD = m1_inv4_rfresh_def [THEN setc_def_to_dest, rule_format, rotated 1]


text {* Proof of key freshness for responder  *}

lemma PO_m1_inv4_rfresh_init [iff]:
  "init m1 \<subseteq> m1_inv4_rfresh"
by (auto simp add: m1_defs intro!: m1_inv4_rfreshI)

lemma PO_m1_inv4_rfresh_trans [iff]:
  "{m1_inv4_rfresh \<inter> m1_inv3r_init \<inter> m1_inv2r_serv \<inter> m1_inv3_ifresh \<inter> m1_secrecy} 
      trans m1 
   {> m1_inv4_rfresh}"
apply (simp add: PO_hoare_defs m1_defs, safe intro!: m1_inv4_rfreshI, simp_all)
apply (auto dest: m1_inv4_rfreshD) 

-- {* 4 subgoals, from responder's final step 7 *}  
  apply (rename_tac Rb A A' B B' Kab xa xe)
  apply (frule_tac B=B in m1_inv2r_servD, fast, fast, clarsimp)
  apply (case_tac "B' \<notin> bad", auto dest: m1_inv2r_servD)
  apply (subgoal_tac "(sesK (Rs$sk), B') \<in> azC (runs xa)")
  prefer 2 apply (erule m1_secrecyE, auto)
  apply (erule azC.cases, auto)

  apply (rename_tac Rb A A' B B' Kab xa xe)
  apply (frule_tac B=B in m1_inv2r_servD, fast, fast, clarify)
  apply (subgoal_tac "(sesK (Rs$sk), B') \<in> azC (runs xa)")
  prefer 2 apply (erule m1_secrecyE, auto)
  apply (erule azC.cases, auto)

  apply (rename_tac Rb' A A' B B' Kab xa xe Ra)
  apply (case_tac "A' \<notin> bad \<and> B' \<notin> bad", auto)
    apply (frule m1_inv3r_initD, auto)
    apply (rename_tac Raa nla)
    apply (frule_tac Ra=Ra in m1_inv3_ifreshD, auto)
    apply (subgoal_tac "Ra = Raa", auto)

    -- {* @{text "A' \<in> bad"} *}
    apply (frule_tac B=B in m1_inv2r_servD, fast, fast, clarify) 
    apply (rename_tac Rs Na) 
    apply (case_tac "B' \<notin> bad", auto dest: m1_inv2r_servD) 
    apply (subgoal_tac "(sesK (Rs$sk), B') \<in> azC (runs xa)")
    prefer 2 apply (erule m1_secrecyE, auto)
    apply (erule azC.cases, auto)

    -- {* @{text "B' \<in> bad"} *}
    apply (frule_tac B=B in m1_inv2r_servD, fast, fast, clarify)
    apply (rename_tac Rs Na) 
    apply (subgoal_tac "(sesK (Rs$sk), B') \<in> azC (runs xa)")
    prefer 2 apply (erule m1_secrecyE, auto)
    apply (erule azC.cases, auto)

  apply (frule m1_inv3r_initD, auto)
  apply (rename_tac Raa nla)
  apply (subgoal_tac "Raa = Ra", auto)
done

lemma PO_m1_inv4_rfresh [iff]: "reach m1 \<subseteq> m1_inv4_rfresh"
apply (rule_tac 
         J="m1_inv3r_init \<inter> m1_inv2r_serv \<inter> m1_inv3_ifresh \<inter> m1_secrecy" 
       in inv_rule_incr) 
apply (auto simp add: Int_assoc del: subsetI)
done

lemma PO_m1_obs_inv4_rfresh [iff]: "oreach m1 \<subseteq> m1_inv4_rfresh"
by (rule external_from_internal_invariant)
   (auto del: subsetI)


end

