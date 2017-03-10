(*  Title:       Termination of the hydra battle
    Author:      Jasmin Blanchette <jasmin.blanchette at inria.fr>, 2017
    Maintainer:  Jasmin Blanchette <jasmin.blanchette at inria.fr>
*)

section \<open>Termination of the Hydra Battle\<close>

theory Hydra_Battle
imports Syntactic_Ordinal
begin

hide_const (open) Nil Cons

text \<open>
The @{text h} function and its auxiliaries @{text f} and @{text d} represent the
hydra battle. The @{text encode} function converts a hydra (represented as a
Lisp-like tree) to a syntactic ordinal. The definitions follow Dershowitz and
Moser.
\<close>

datatype lisp =
  Nil
| Cons (car: lisp) (cdr: lisp)
where
  "car Nil = Nil"
| "cdr Nil = Nil"

primrec encode :: "lisp \<Rightarrow> hmultiset" where
  "encode Nil = 0"
| "encode (Cons l r) = HMSet {#encode l#} + encode r"

primrec f :: "nat \<Rightarrow> lisp \<Rightarrow> lisp \<Rightarrow> lisp" where
  "f 0 y x = x"
| "f (Suc m) y x = Cons y (f m y x)"

lemma encode_f: "encode (f n y x) = HMSet (replicate_mset n (encode y)) + encode x"
  by (induct n) (auto simp: HMSet_plus[symmetric])

function d :: "nat \<Rightarrow> lisp \<Rightarrow> lisp" where
  "d n x =
   (if car x = Nil then cdr x
    else if car (car x) = Nil then f n (cdr (car x)) (cdr x)
    else Cons (d n (car x)) (cdr x))"
  by pat_completeness auto
termination
  by (relation "measure (\<lambda>(_, x). size x)", rule wf_measure, rename_tac n x, case_tac x, auto)

declare d.simps[simp del]

function h :: "nat \<Rightarrow> lisp \<Rightarrow> lisp" where
  "h n x = (if x = Nil then Nil else h (n + 1) (d n x))"
  by pat_completeness auto
termination
proof -
  let ?R = "inv_image {(m, n). m < n} (\<lambda>(n, x). encode x)"

  show ?thesis
  proof (relation ?R)
    show "wf ?R"
      by (rule wf_inv_image) (rule wf)
  next
    fix n x
    assume x_cons: "x \<noteq> Nil"
    thus "((n + 1, d n x), n, x) \<in> ?R"
      unfolding inv_image_def mem_Collect_eq prod.case
    proof (induct x)
      case (Cons l r)
      note ihl = this(1)
      show ?case
      proof (subst d.simps, simp, intro conjI impI)
        assume l_cons: "l \<noteq> Nil"
        {
          assume "car l = Nil"
          show "encode (f n (cdr l) r) < HMSet {#encode l#} + encode r"
            using l_cons by (cases l) (auto simp: encode_f)
        }
        {
          show "encode (d n l) < encode l"
            by (rule ihl[OF l_cons])
        }
      qed
    qed simp
  qed
qed

declare h.simps[simp del]

end
