section "Splay Heap Analysis"

theory Splay_Heap_Analysis
imports
  "../Splay_Tree/Splay_Heap"
  Amor
  Priority_Queue_ops
  Lemmas_log
begin

text \<open>Timing functions must be kept in sync with the corresponding functions
on splay heaps.\<close>

fun t_part :: "'a::linorder \<Rightarrow> 'a tree \<Rightarrow> nat" where
"t_part p Leaf = 1" |
"t_part p (Node l a r) =
  (if a \<le> p then
     case r of
       Leaf \<Rightarrow> 1 |
       Node rl b rr \<Rightarrow> if b \<le> p then t_part p rr + 1 else t_part p rl + 1
   else case l of
       Leaf \<Rightarrow> 1 |
       Node ll b lr \<Rightarrow> if b \<le> p then t_part p lr + 1 else t_part p ll + 1)" 

definition t_in :: "'a::linorder \<Rightarrow> 'a tree \<Rightarrow> nat" where
"t_in x h = t_part x h"

fun t_dm :: "'a::linorder tree \<Rightarrow> nat" where
"t_dm Leaf = 1" |
"t_dm (Node Leaf _ r) = 1" |
"t_dm (Node (Node ll a lr) b r) = (if ll=Leaf then 1 else t_dm ll + 1)"

abbreviation "\<phi> t == log 2 (size1 t)"

fun \<Phi> :: "'a tree \<Rightarrow> real" where
"\<Phi> Leaf = 0" |
"\<Phi> (Node l a r) = \<Phi> l + \<Phi> r + \<phi> (Node l a r)"

lemma amor_del_min: "t_dm t + \<Phi> (del_min t) - \<Phi> t \<le> 2 * \<phi> t + 1"
proof(induction t rule: t_dm.induct)
  case (3 ll a lr b r)
  let ?t = "Node (Node ll a lr) b r"
  show ?case
  proof cases
    assume [simp]: "ll = Leaf"
    have 1: "log 2 (real (size1 lr) + real (size1 r))
        \<le> 3 * log 2 (1 + (real (size1 lr) + real (size1 r)))" (is "?l \<le> 3 * ?r")
    proof -
      have "?l \<le> ?r" by(simp add: size1_def)
      also have "\<dots> \<le> 3 * ?r" by(simp)
      finally show ?thesis .
    qed
    have 2: "log 2 (1 + real (size1 lr)) \<ge> 0" by simp
    thus ?case apply simp using 1 2 by linarith
  next
    assume ll[simp]: "\<not> ll = Leaf"
    let ?l' = "del_min ll"
    let ?s = "Node ll a lr"  let ?t = "Node ?s b r"
    let ?s' = "Node lr b r"  let ?t' = "Node ?l' a ?s'"
    have 0: "\<phi> ?t' \<le> \<phi> ?t" by(simp add: size1_def)
    have 1: "\<phi> ll < \<phi> ?s" by(simp add: size1_def)
    have 2: "log 2 (size1 ll + size1 ?s') \<le> log 2 (size1 ?t)" by(simp add: size1_def)
    have "t_dm ?t + \<Phi> (del_min ?t) - \<Phi> ?t
        = 1 + t_dm ll + \<Phi> (del_min ?t) - \<Phi> ?t" by simp
    also have "\<dots> \<le> 2 + 2 * \<phi> ll + \<Phi> ll - \<Phi> ?l'  + \<Phi> (del_min ?t) - \<Phi> ?t"
      using 3 ll by linarith
    also have "\<dots> = 2 + 2 * \<phi> ll + \<phi> ?t' + \<phi> ?s' - \<phi> ?t - \<phi> ?s" by(simp)
    also have "\<dots> \<le> 2 + \<phi> ll + \<phi> ?s'" using 0 1 by linarith
    also have "\<dots> < 2 * \<phi> ?t + 1" using 2 ld_ld_1_less[of "size1 ll" "size1 ?s'"]
      by (simp add: size1_def)
    finally show ?case by simp
  qed
qed auto

lemma zig_zig:
fixes s u r r1' r2' T a b
defines "t == Node s a (Node u b r)" and "t' == Node (Node s a u) b r1'"
assumes "size r1' \<le> size r"
    "t_part p r + \<Phi> r1' + \<Phi> r2' - \<Phi> r \<le> 2 * \<phi> r + 1"
shows "t_part p r + 1 + \<Phi> t' + \<Phi> r2' - \<Phi> t \<le> 2 * \<phi> t + 1"
proof -
  have 1: "\<phi> r \<le> \<phi> (Node u b r)" by (simp add: size1_def)
  have 2: "log 2 (real (size1 s + size1 u + size1 r1')) \<le> \<phi> t"
    using assms(3) by (simp add: t_def size1_def)
  from ld_ld_1_less[of "size1 s + size1 u" "size1 r"] 
  have "1 + \<phi> r + log 2 (size1 s + size1 u) \<le> 2 * log 2 (size1 s + size1 u + size1 r)"
    by(simp add: size1_def)
  thus ?thesis using assms 1 2 by (simp add: algebra_simps)
qed

lemma zig_zag:
fixes s u r r1' r2' a b
defines "t \<equiv> Node s a (Node r b u)" and "t1' == Node s a r1'" and "t2' \<equiv> Node u b r2'"
assumes "size r = size r1' + size r2'"
    "t_part p r + \<Phi> r1' + \<Phi> r2' - \<Phi> r \<le> 2 * \<phi> r + 1"
shows "t_part p r + 1 + \<Phi> t1' + \<Phi> t2' - \<Phi> t \<le> 2 * \<phi> t + 1"
proof -
  have 1: "\<phi> r \<le> \<phi> (Node u b r)" by (simp add: size1_def)
  have 2: "\<phi> r \<le> \<phi> t" by (simp add: t_def size1_def)
  from ld_ld_less2[of "size1 s + size1 r1'" "size1 u + size1 r2'"] 
  have "1 + log 2 (size1 s + size1 r1') + log 2 (size1 u + size1 r2') \<le> 2 * \<phi> t"
    by(simp add: assms(4) size1_def t_def ac_simps)
  thus ?thesis using assms 1 2 by (simp add: algebra_simps)
qed

lemma amor_partition: "bst_eq t \<Longrightarrow> partition p t = (l',r')
  \<Longrightarrow> t_part p t + \<Phi> l' + \<Phi> r' - \<Phi> t \<le> 2 * log 2 (size1 t) + 1"
proof(induction p t arbitrary: l' r' rule: partition.induct)
  case 1 thus ?case by simp
next
  case (2 p l a r)
  show ?case
  proof cases
    assume "a \<le> p"
    show ?thesis
    proof (cases r)
      case Leaf thus ?thesis using `a \<le> p` "2.prems" by fastforce
    next
      case [simp]: (Node rl b rr)
      let ?t = "Node l a r"
      show ?thesis
      proof cases
        assume "b \<le> p"
        with `a \<le> p` "2.prems" obtain rrl
          where 0: "partition p rr = (rrl, r')" "l' = Node (Node l a rl) b rrl"
          by (auto split: tree.splits prod.splits)
        have "size rrl \<le> size rr"
          using size_partition[OF 0(1)] by (simp add: size1_def)
        with 0 `a \<le> p` `b \<le> p` "2.prems"(1) "2.IH"(1)[OF _ Node , of rrl r']
          zig_zig[where s=l and u=rl and r=rr and r1'=rrl and r2'=r' and p=p, of a b]
        show ?thesis by (simp add: algebra_simps)
      next
        assume "\<not> b \<le> p"
        with `a \<le> p` "2.prems" obtain rll rlr 
          where 0: "partition p rl = (rll, rlr)" "l' = Node l a rll" "r' = Node rlr b rr"
          by (auto split: tree.splits prod.splits)
        from 0 `a \<le> p` `\<not> b \<le> p` "2.prems"(1) "2.IH"(2)[OF _ Node, of rll rlr]
          size_partition[OF 0(1)]
          zig_zag[where s=l and u=rr and r=rl and r1'=rll and r2'=rlr and p=p, of a b]
        show ?thesis by (simp add: algebra_simps)
      qed
    qed
  next
    assume "\<not> a \<le> p"
    show ?thesis
    proof (cases l)
      case Leaf thus ?thesis using `\<not> a \<le> p` "2.prems" by fastforce
    next
      case [simp]: (Node ll b lr)
      let ?t = "Node l a r"
      show ?thesis
      proof cases
        assume "b \<le> p"
        with `\<not> a \<le> p` "2.prems" obtain lrl lrr 
          where 0: "partition p lr = (lrl, lrr)" "l' = Node ll b lrl" "r' = Node lrr a r"
          by (auto split: tree.splits prod.splits)
        from 0 `\<not> a \<le> p` `b \<le> p` "2.prems"(1) "2.IH"(3)[OF _ Node, of lrl lrr]
          size_partition[OF 0(1)]
          zig_zag[where s=r and u=ll and r=lr and r1'=lrr and r2'=lrl and p=p, of a b]
        show ?thesis by (auto simp: algebra_simps)
      next
        assume "\<not> b \<le> p"
        with `\<not> a \<le> p` "2.prems" obtain llr
          where 0: "partition p ll = (l',llr)" "r' = Node llr b (Node lr a r)"
          by (auto split: tree.splits prod.splits)
        have "size llr \<le> size ll"
          using size_partition[OF 0(1)] by (simp add: size1_def)
        with 0 `\<not> a \<le> p` `\<not> b \<le> p` "2.prems"(1) "2.IH"(4)[OF _ Node, of l' llr]
          zig_zig[where s=r and u=lr and r=ll and r1'=llr and r2'=l' and p=p, of a b]
        show ?thesis by (auto simp: algebra_simps)
      qed
    qed
  qed
qed

fun nxt\<^sub>p\<^sub>q :: "'a::linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a tree \<Rightarrow> 'a tree" where
"nxt\<^sub>p\<^sub>q (Insert a) h = insert a h" |
"nxt\<^sub>p\<^sub>q Del_min h = del_min h"

fun t\<^sub>p\<^sub>q :: "'a::linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a tree \<Rightarrow> nat" where
"t\<^sub>p\<^sub>q (Insert a) h = t_in a h" |
"t\<^sub>p\<^sub>q Del_min h = t_dm h"

interpretation splay_heap: amor
where init = "Leaf" and nxt = "nxt\<^sub>p\<^sub>q" and inv = "bst_eq"
and t = t\<^sub>p\<^sub>q and \<Phi> = \<Phi>
and U = "\<lambda>f s. case f of Del_min \<Rightarrow> 2 * \<phi> s + 1 | Insert _ \<Rightarrow> 3 * log 2 (size1 s + 1) + 1"
proof (standard, goal_cases)
  case 1 show ?case by simp
next
  case (2 _ f) thus ?case
    by(cases f)
       (auto simp: insert_def bst_del_min dest: bst_partition split: prod.splits)
next
  case (3 s) show ?case by(induction s) (auto simp: size1_def)
next
  case 4 show ?case by(simp)
next
  case (5 s f)
  show ?case
  proof (cases f)
    case Del_min with 5 show ?thesis by(simp add: amor_del_min)
  next
    case (Insert x)
    { fix l r assume 1: "partition x s = (l,r)"
      have "log 2 (1 + size s) < log 2 (2 + size s)" by simp
      with 1 amor_partition[OF 5 1] size_partition[OF 1] Insert have ?thesis
        by(simp add: t_in_def insert_def algebra_simps size1_def
             del: log_less_cancel_iff) }
    thus ?thesis using Insert by(simp add: insert_def split: prod.split)
  qed
qed

end
