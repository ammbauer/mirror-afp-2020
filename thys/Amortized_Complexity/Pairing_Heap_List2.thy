(* Author: Tobias Nipkow *)

subsection {* Mixed Tree/List Representation *}

theory Pairing_Heap_List2
imports
  Amortized_Framework
  Priority_Queue_ops_meld2
  Lemmas_log
begin

text{* The Pairing Heap theory by Hauke Brinkop follows the original publication
\cite{FredmanSST86} and represents pairing heaps as binary trees, although conceptually
the type also involves lists and options. This theory makes these conceptual types explicit
while following Brinkop's proofs. As a consequence no invariants are necessary, but size
and potential functions need to be defined on multiple types. *}

datatype 'a hp = Hp 'a (hps: "'a hp list")

type_synonym 'a heap = "'a hp option"

fun lift_hp :: "'b \<Rightarrow> ('a hp \<Rightarrow> 'b) \<Rightarrow> 'a heap \<Rightarrow> 'b" where
"lift_hp c f None = c" |
"lift_hp c f (Some h) = f h"

fun link :: "'a :: linorder hp \<Rightarrow> 'a hp \<Rightarrow> 'a hp" where
"link (Hp x lx) (Hp y ly) = 
    (if x < y then Hp x (Hp y ly # lx) else Hp y (Hp x lx # ly))"

fun meld :: "'a :: linorder heap \<Rightarrow> 'a heap \<Rightarrow> 'a heap" where
"meld h None = h" |
"meld None h = h" |
"meld (Some h1) (Some h2) = Some(link h1 h2)"

lemma meld_None[simp]: "meld None h = h"
by(cases h)auto

hide_const (open) insert

fun insert :: "'a \<Rightarrow> 'a :: linorder heap \<Rightarrow> 'a heap" where
"insert x None = Some(Hp x [])" |
"insert x (Some h) = Some(link (Hp x []) h)"

fun pass\<^sub>1 :: "'a :: linorder hp list \<Rightarrow> 'a hp list" where
  "pass\<^sub>1 [] = []"
| "pass\<^sub>1 [h] = [h]" 
| "pass\<^sub>1 (h1#h2#hs) = link h1 h2 # pass\<^sub>1 hs"

fun pass\<^sub>2 :: "'a :: linorder hp list \<Rightarrow> 'a heap" where
  "pass\<^sub>2 [] = None"
| "pass\<^sub>2 (h#hs) = Some(case pass\<^sub>2 hs of None \<Rightarrow> h | Some h' \<Rightarrow> link h h')"

fun del_min :: "'a :: linorder heap \<Rightarrow> 'a heap" where
  "del_min None = None"
| "del_min (Some(Hp x hs)) = pass\<^sub>2 (pass\<^sub>1 hs)"

fun size_hps :: "'a hp list \<Rightarrow> nat" where
"size_hps(Hp x hsl # hsr) = size_hps hsl + size_hps hsr + 1" |
"size_hps [] = 0"

definition size_hp :: "'a hp \<Rightarrow> nat" where
[simp]: "size_hp h = size_hps(hps h) + 1"

lemma size_hp_Hp[simp]: "size_hp(Hp x hs) = size_hps hs + 1"
by simp

fun \<Phi>_hps :: "'a hp list \<Rightarrow> real" where
"\<Phi>_hps [] = 0" |
"\<Phi>_hps (Hp x hsl # hsr) = \<Phi>_hps hsl + \<Phi>_hps hsr + log 2 (size_hps hsl + size_hps hsr + 1)"

definition \<Phi>_hp :: "'a hp \<Rightarrow> real" where
[simp]: "\<Phi>_hp h = \<Phi>_hps (hps h) + log 2 (size_hps(hps(h))+1)"

abbreviation \<Phi>_heap :: "'a heap \<Rightarrow> real" where
"\<Phi>_heap \<equiv> lift_hp 0 \<Phi>_hp"

abbreviation size_heap :: "'a heap \<Rightarrow> nat" where
"size_heap \<equiv> lift_hp 0 size_hp"

lemma \<Phi>_hps_ge0: "\<Phi>_hps hs \<ge> 0"
by (induction hs rule: size_hps.induct) auto

declare algebra_simps[simp]

lemma size_hps_Cons[simp]: "size_hps(h # hs) = size_hp h + size_hps hs"
by(cases h) simp

lemma link2: "link (Hp x lx) h = (case h of (Hp y ly) \<Rightarrow> 
    (if x < y then Hp x (Hp y ly # lx) else Hp y (Hp x lx # ly)))"
by(simp split: hp.split)

lemma size_hps_link: "size_hps(hps (link h1 h2)) = size_hp h1 + size_hp h2 - 1" 
by (induction rule: link.induct) simp_all

lemma pass\<^sub>1_size[simp]: "size_hps (pass\<^sub>1 hs) = size_hps hs" 
by (induct hs rule: pass\<^sub>1.induct) (simp_all add: size_hps_link)

lemma pass\<^sub>2_None[simp]: "pass\<^sub>2 hs = None \<longleftrightarrow> hs = []"
by(cases hs) auto

lemma \<Delta>\<Phi>_insert: "\<Phi>_heap (insert x h) - \<Phi>_heap h \<le> log 2 (size_heap h + 1)"
by(induct h)(auto simp: link2 split: hp.split)

lemma \<Delta>\<Phi>_link: "\<Phi>_hp (link h1 h2) - \<Phi>_hp h1 - \<Phi>_hp h2 \<le> 2 * log 2 (size_hp h1 + size_hp h2)"
by (induction h1 h2 rule: link.induct) (simp  add: add_increasing)

fun sum_ub :: "'a hp list \<Rightarrow> real" where
  "sum_ub [] = 0"
| "sum_ub [Hp _ _] = 0"
| "sum_ub [Hp _ lx, Hp _ ly] = 2*log 2 (2 + size_hps lx + size_hps ly)" 
| "sum_ub (Hp _ lx # Hp _ ly # ry) = 2*log 2 (2 + size_hps lx + size_hps ly + size_hps ry) 
    - 2*log 2 (size_hps ry) - 2 + sum_ub ry"


lemma \<Delta>\<Phi>_pass1_sum_ub: "\<Phi>_hps (pass\<^sub>1 h) - \<Phi>_hps h  \<le> sum_ub h"
proof (induction h rule: sum_ub.induct)
  case (3 lx x ly y)
  have 0: "\<And>x y::real. 0 \<le> x \<Longrightarrow> x \<le> y \<Longrightarrow> x \<le> 2*y" by linarith
  show ?case by (simp add: add_increasing 0)
next
  case (4 x hsx y hsy z hsize_hp)
  let ?ry = "z # hsize_hp"
  let ?rx = "Hp y hsy # ?ry"
  let ?h = "Hp x hsx # ?rx"
  have "\<Phi>_hps(pass\<^sub>1 ?h) - \<Phi>_hps ?h  
    \<le> log 2 (1 + size_hps hsx + size_hps hsy) - log 2 (1 + size_hps hsy + size_hps ?ry) + sum_ub ?ry"
    using "4.IH" by simp
  also have "log 2 (1 + size_hps hsx + size_hps hsy) - log 2 (1 + size_hps hsy + size_hps ?ry) 
    \<le> 2*log 2 (size_hps ?h) - 2*log 2 (size_hps ?ry) - 2"
  proof -
    have "log 2 (1 + size_hps hsx + size_hps hsy) + log 2 (size_hps ?ry) - 2*log 2 (size_hps ?h) 
      = log 2 ((1 + size_hps hsx + size_hps hsy)/(size_hps ?h) ) + log 2 (size_hps ?ry / size_hps ?h)"
      by (simp add: log_divide)
    also have "\<dots> \<le> -2" 
    proof -
      have "2 + \<dots>
        \<le> 2*log 2 ((1 + size_hps hsx + size_hps hsy) / size_hps ?h +  size_hps ?ry / size_hps ?h)"  
        using ld_sum_inequality [of "(1 + size_hps hsx + size_hps hsy) / size_hps ?h" "(size_hps ?ry / size_hps ?h)"] by simp
      also have "\<dots> \<le> 0" by (simp add: field_simps log_divide add_pos_nonneg)
      finally show ?thesis by linarith
    qed 
    finally have "log 2 (1 + size_hps hsx + size_hps hsy) + log 2 (size_hps ?ry) + 2
      \<le>  2*log 2 (size_hps ?h)" by simp
    moreover have "log 2 (size_hps ?ry) \<le> log 2 (size_hps ?rx)" by simp
    ultimately have "log 2 (1 + size_hps hsx + size_hps hsy) - \<dots> 
      \<le>  2*log 2 (size_hps ?h) - 2*log 2 (size_hps ?ry) - 2" by linarith
    thus ?thesis by simp
  qed
  finally show ?case by (simp)
qed simp_all


lemma \<Delta>\<Phi>_pass1: assumes "hs \<noteq> []"
  shows "\<Phi>_hps (pass\<^sub>1 hs) - \<Phi>_hps hs \<le> 2 * log 2 (size_hps hs) - length hs + 2"
proof - 
  have "sum_ub hs \<le> 2 * log 2 (size_hps hs) - length hs + 2" 
    using assms by (induct hs rule: sum_ub.induct) (simp_all)
  thus ?thesis using \<Delta>\<Phi>_pass1_sum_ub[of hs] by linarith
qed

lemma size_hps_pass2: "pass\<^sub>2 hs = Some h \<Longrightarrow> size_hps hs = size_hps(hps h)+1"
apply(induction hs arbitrary: h rule: \<Phi>_hps.induct)
apply (auto simp: link2 split: option.split hp.split)
done

lemma \<Delta>\<Phi>_pass2: "hs \<noteq> [] \<Longrightarrow> \<Phi>_heap (pass\<^sub>2 hs) - \<Phi>_hps hs \<le> log 2 (size_hps hs)"
proof (induction hs)
  case (Cons h hs)
  thus ?case
  proof -
    obtain x hs2 where [simp]: "h = Hp x hs2" by (metis hp.exhaust)
    show ?thesis
    proof (cases "pass\<^sub>2 hs")
      case [simp]: (Some h2)
      obtain y hs3 where [simp]: "h2 = Hp y hs3" by (metis hp.exhaust)
      from size_hps_pass2[OF Some] Cons show ?thesis
        by(cases "hs=[]")(auto simp: add_mono)
    qed simp
  qed
qed simp

lemma \<Delta>\<Phi>_del_min: assumes "hps h \<noteq> []"
  shows "\<Phi>_heap (del_min (Some h)) - \<Phi>_heap (Some h) 
  \<le> 3 * log 2 (size_hps(hps h)) - length(hps h) + 2"
proof -
  let ?\<Delta>\<Phi>\<^sub>1 = "\<Phi>_hps(hps h) - \<Phi>_hp h" 
  let ?\<Delta>\<Phi>\<^sub>2 = "\<Phi>_heap(pass\<^sub>2(pass\<^sub>1 (hps h))) - \<Phi>_hps (hps h)"
  let ?\<Delta>\<Phi> = "\<Phi>_heap (del_min (Some h)) - \<Phi>_heap (Some h)"
  have "\<Phi>_heap(pass\<^sub>2(pass\<^sub>1(hps h))) - \<Phi>_hps (pass\<^sub>1(hps h)) \<le> log 2 (size_hps(hps h))" 
    using \<Delta>\<Phi>_pass2[of "pass\<^sub>1(hps h)"] using size_hps.elims assms by force
  moreover have "\<Phi>_hps (pass\<^sub>1 (hps h)) - \<Phi>_hps (hps h) \<le>  2*\<dots> - length (hps h) + 2"
    using \<Delta>\<Phi>_pass1[OF assms] by blast
  moreover have "?\<Delta>\<Phi>\<^sub>1 \<le> 0" by (cases h) simp
  moreover have "?\<Delta>\<Phi> = ?\<Delta>\<Phi>\<^sub>1 + ?\<Delta>\<Phi>\<^sub>2" by (cases h) simp
  ultimately show ?thesis by linarith
qed


fun exec :: "'a :: linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a heap list \<Rightarrow> 'a heap" where
"exec Empty [] = None" | 
"exec Del_min [h] = del_min h" |
"exec (Insert x) [h] = insert x h" |
"exec Meld [h1,h2] = meld h1 h2"

fun t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 :: "'a hp list \<Rightarrow> nat" where
  "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 [] = 1"
| "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 [_] = 1"
| "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 (_ # _ # hs) = 1 + t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 hs"

fun t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 :: "'a hp list \<Rightarrow> nat" where
 "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 [] = 1"
| "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 (_ # hs) = 1 + t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 hs"

fun cost :: "'a :: linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a heap list \<Rightarrow> nat" where
"cost Empty _ = 1" |
"cost Del_min [None] = 1" |
"cost Del_min [Some(Hp x hs)] = 1 + t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 (pass\<^sub>1 hs) + t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 hs" |
"cost (Insert a) _ = 1" |
"cost Meld _ = 1"

fun U :: "'a :: linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a heap list \<Rightarrow> real" where
"U Empty _ = 1" |
"U (Insert a) [h] = log 2 (size_heap h + 1) + 1" |
"U Del_min [h] = 3*log 2 (size_heap h + 1) + 5" |
"U Meld [h1,h2] = 2*log 2 (size_heap h1 + size_heap h2 + 1) + 1"

interpretation pairing: Amortized
where arity = arity and exec = exec and cost = cost and inv = "\<lambda>_. True"
and \<Phi> = \<Phi>_heap and U = U
proof
  case goal2 show ?case by (cases s) (auto simp: \<Phi>_hps_ge0)
next
  case goal3 thus ?case by (cases f) (auto)
next
  case goal4 show ?case
  proof (cases f)
    case Empty with goal4 show ?thesis by(auto)
  next
    case Insert
    thus ?thesis using Insert \<Delta>\<Phi>_insert goal4 by auto
  next
    case [simp]: Del_min
    then obtain ho where [simp]: "ss = [ho]" using goal4 by auto
    show ?thesis
    proof (cases ho)
      case [simp]: (Some h)
        show ?thesis
        proof (cases h)
        case [simp]: (Hp x hs)
        have "t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>2 (pass\<^sub>1 hs) + t\<^sub>p\<^sub>a\<^sub>s\<^sub>s\<^sub>1 hs \<le> 2 + length hs"
          by (induct hs rule: pass\<^sub>1.induct) simp_all
        hence  "cost f ss \<le> 1 + \<dots>" by simp
        moreover have  "\<Phi>_heap (del_min ho) - \<Phi>_heap ho \<le> 3*log 2 (size_heap ho + 1) - length hs + 2"
        proof (cases "hs = []")
          case False
          hence "\<Phi>_heap (del_min ho) - \<Phi>_heap ho \<le> 3*log 2 (size_hps hs) - length hs + 2"
            using  \<Delta>\<Phi>_del_min[of h] by simp
          also have "\<dots> \<le> 3*log 2 (size_heap ho + 1) - length hs + 2"
            using False size_hps.elims by force
          finally show ?thesis .
        qed simp
        ultimately show ?thesis by simp
      qed
    qed simp
  next
    case [simp]: Meld
    then obtain ho1 ho2 where [simp]: "ss = [ho1, ho2]"
      using goal4 by(auto simp: numeral_eq_Suc)
    show ?thesis
    proof (cases "ho1 = None \<or> ho2 = None")
      case True thus ?thesis by auto
    next
      case False
      then obtain h1 h2 where [simp]: "ho1 = Some h1" "ho2 = Some h2" by auto
      have "\<Phi>_heap (meld ho1 ho2) - \<Phi>_heap ho1 - \<Phi>_heap ho2 \<le> 2 * log 2 (size_heap ho1 + size_heap ho2)"
        using \<Delta>\<Phi>_link[of h1 h2] by simp
      also have "\<dots> \<le> 2 * log 2 (size_hp h1 + size_hp h2 + 1)" by (simp)
      finally show ?thesis by(simp)
    qed
  qed
qed simp

end
