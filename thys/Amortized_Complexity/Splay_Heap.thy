section "Splay Heap"

theory Splay_Heap
imports Amor "~~/src/HOL/Library/Tree"
begin

text{* Splay heaps were invented by Okasaki~\cite{Okasaki}. *}


subsection{* Definition and Correctness *}

fun partition :: "'a::linorder \<Rightarrow> 'a tree \<Rightarrow> 'a tree * 'a tree" where
"partition p Leaf = (Leaf,Leaf)" |
"partition p (Node l a r) =
  (if a \<le> p then
     case r of
       Leaf \<Rightarrow> (Node l a r, Leaf) |
       Node rl b rr \<Rightarrow>
         if b \<le> p
         then let (rrl,rrr) = partition p rr in (Node (Node l a rl) b rrl, rrr)
         else let (rll,rlr) = partition p rl in (Node l a rll, Node rlr b rr)
   else case l of
       Leaf \<Rightarrow> (Leaf, Node l a r) |
       Node ll b lr \<Rightarrow>
         if b \<le> p
         then let (lrl,lrr) = partition p lr in (Node ll b lrl, Node lrr a r)
         else let (lll,llr) = partition p ll in (lll, Node llr b (Node lr a r)))" 

definition insert :: "'a::linorder \<Rightarrow> 'a tree \<Rightarrow> 'a tree" where
"insert x h = (let (l,r) = partition x h in Node l x r)"

fun del_min :: "'a::linorder tree \<Rightarrow> 'a tree" where
"del_min Leaf = Leaf" |
"del_min (Node Leaf _ r) = r" |
"del_min (Node (Node ll a lr) b r) =
  (if ll = Leaf then Node lr b r else Node (del_min ll) a (Node lr b r))"

lemma size_partition: "partition p t = (l',r') \<Longrightarrow> size t = size l' + size r'"
by (induction p t arbitrary: l' r' rule: partition.induct)
   (auto split: if_splits tree.splits prod.splits)

lemma set_partition: "\<lbrakk> bst_eq(t); partition p t = (l',r') \<rbrakk>
 \<Longrightarrow> set_tree t = set_tree l' \<union> set_tree r'"
proof(induction p t arbitrary: l' r' rule: partition.induct)
  case 1 thus ?case by simp
next
  case (2 p l a r)
  show ?case
  proof cases
    assume "a \<le> p"
    show ?thesis
    proof (cases r)
      case Leaf thus ?thesis using `a \<le> p` "2.prems" by auto
    next
      case (Node rl b rr)
      show ?thesis
      proof cases
        assume "b \<le> p"
        thus ?thesis using Node `a \<le> p` "2.prems" "2.IH"(1)[OF _ Node]
          by (auto split: prod.splits)
      next
        assume "\<not> b \<le> p"
        thus ?thesis using Node `a \<le> p` "2.prems" "2.IH"(2)[OF _ Node]
          by (auto split: prod.splits)
      qed
    qed
  next
    assume "\<not> a \<le> p"
    show ?thesis
    proof (cases l)
      case Leaf thus ?thesis using `\<not> a \<le> p` "2.prems" by auto
    next
      case (Node ll b lr)
      show ?thesis
      proof cases
        assume "b \<le> p"
        thus ?thesis using Node `\<not> a \<le> p` "2.prems" "2.IH"(3)[OF _ Node]
          by (auto split: prod.splits)
      next
        assume "\<not> b \<le> p"
        thus ?thesis using Node `\<not> a \<le> p` "2.prems" "2.IH"(4)[OF _ Node]
          by (auto split: prod.splits)
      qed
    qed
  qed
qed

lemma bst_partition:
  "bst_eq(t) \<Longrightarrow> partition p t = (l',r') \<Longrightarrow> bst_eq (Node l' p r')"
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
      case (Node rl b rr)
      show ?thesis
      proof cases
        assume "b \<le> p"
        thus ?thesis
          using Node `a \<le> p` "2.prems" "2.IH"(1)[OF _ Node] set_partition[of rr]
          by (fastforce split: prod.splits)
      next
        assume "\<not> b \<le> p"
        thus ?thesis
          using Node `a \<le> p` "2.prems" "2.IH"(2)[OF _ Node] set_partition[of rl]
          by (fastforce split: prod.splits)
      qed
    qed
  next
    assume "\<not> a \<le> p"
    show ?thesis
    proof (cases l)
      case Leaf thus ?thesis using `\<not> a \<le> p` "2.prems" by fastforce
    next
      case (Node ll b lr)
      show ?thesis
      proof cases
        assume "b \<le> p"
        thus ?thesis
          using Node `\<not> a \<le> p` "2.prems" "2.IH"(3)[OF _ Node] set_partition[of lr]
          by (fastforce split: prod.splits)
      next
        assume "\<not> b \<le> p"
        thus ?thesis
          using Node `\<not> a \<le> p` "2.prems" "2.IH"(4)[OF _ Node] set_partition[of ll]
          by (fastforce split: prod.splits)
      qed
    qed
  qed
qed


lemma size_del_min[simp]: "size(del_min t) = size t - 1"
by(induction t rule: del_min.induct) (auto simp: neq_Leaf_iff)

lemma set_del_min: "set_tree(del_min t) \<le> set_tree t"
by (induction t rule: del_min.induct) auto

lemma bst_del_min: "bst_eq t \<Longrightarrow> bst_eq(del_min t)"
apply(induction t rule: del_min.induct)
  apply simp
 apply simp
using set_del_min by fastforce


subsection{* Analysis *}

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

lemma add_log_log1:
  assumes "x > 0" "y > 0" shows "1 + log 2 x + log 2 y < 2 * log 2 (x+y)"
proof -
  have 1: "2*x*y < (x+y)^2" using assms
    by(simp add: numeral_eq_Suc algebra_simps add_pos_pos)
  show ?thesis
    apply(rule powr_less_cancel_iff[of 2, THEN iffD1])
     apply simp
    using assms 1 by(simp add: powr_add log_powr[symmetric] powr_numeral)
qed

lemma add_log_log2: assumes "x \<ge> 2" "y \<ge> 2"
  shows "1 + log 2 x + log 2 y \<le> 2 * log 2 (x + y - 1)"
proof-
  from assms have "2*x \<le> x*x" "2*y \<le> y*y" by simp_all
  hence 1: "2 * x * y \<le> (x + y - 1)^2"
    by(simp add: numeral_eq_Suc algebra_simps)
  show ?thesis
    apply(rule powr_le_cancel_iff[of 2, THEN iffD1])
     apply simp
    using assms 1 by(simp add: powr_add log_powr[symmetric] powr_numeral)
qed

lemma amor_del_min: "t_dm t + \<Phi> (del_min t) - \<Phi> t \<le> 2 * \<phi> t + 1"
proof(induction t rule: t_dm.induct)
  case (3 ll a lr b r)
  let ?t = "Node (Node ll a lr) b r"
  show ?case
  proof cases
    assume [simp]: "ll = Leaf"
    have 1: "log 2 (real (size1 lr) + real (size1 r))
        \<le> 3 * log 2 (real (size1 lr) + real (size1 r) + 1)" (is "?l \<le> 3 * ?r")
    proof -
      have "?l \<le> ?r" by(simp add: size1_def)
      also have "\<dots> \<le> 3 * ?r" by(simp)
      finally show ?thesis .
    qed
    have 2: "log 2 (real (size1 lr) + 1) \<ge> 0" by simp
    thus ?case apply(simp add: real_of_nat_Suc) using 1 2 by linarith
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
    also have "\<dots> < 2 * \<phi> ?t + 1" using 2 add_log_log1[of "size1 ll" "size1 ?s'"]
      by (simp add: size1_def real_of_nat_Suc)
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
  from add_log_log1[of "size1 s + size1 u" "size1 r"] 
  have "1 + \<phi> r + log 2 (size1 s + size1 u) \<le> 2 * log 2 (size1 s + size1 u + size1 r)"
    by(simp add: size1_def real_of_nat_Suc)
  thus ?thesis using assms 1 2 by (simp add: real_of_nat_Suc algebra_simps)
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
  from add_log_log2[of "size1 s + size1 r1'" "size1 u + size1 r2'"] 
  have "1 + log 2 (size1 s + size1 r1') + log 2 (size1 u + size1 r2') \<le> 2 * \<phi> t"
    by(simp add: assms(4) size1_def real_of_nat_Suc t_def ac_simps)
  thus ?thesis using assms 1 2 by (simp add: real_of_nat_Suc algebra_simps)
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
      case (Node rl b rr)[simp]
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
        show ?thesis by (simp add: real_of_nat_Suc algebra_simps)
      next
        assume "\<not> b \<le> p"
        with `a \<le> p` "2.prems" obtain rll rlr 
          where 0: "partition p rl = (rll, rlr)" "l' = Node l a rll" "r' = Node rlr b rr"
          by (auto split: tree.splits prod.splits)
        from 0 `a \<le> p` `\<not> b \<le> p` "2.prems"(1) "2.IH"(2)[OF _ Node, of rll rlr]
          size_partition[OF 0(1)]
          zig_zag[where s=l and u=rr and r=rl and r1'=rll and r2'=rlr and p=p, of a b]
        show ?thesis by (simp add: real_of_nat_Suc algebra_simps)
      qed
    qed
  next
    assume "\<not> a \<le> p"
    show ?thesis
    proof (cases l)
      case Leaf thus ?thesis using `\<not> a \<le> p` "2.prems" by fastforce
    next
      case (Node ll b lr)[simp]
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
        show ?thesis by (auto simp: real_of_nat_Suc algebra_simps)
      next
        assume "\<not> b \<le> p"
        with `\<not> a \<le> p` "2.prems" obtain llr
          where 0: "partition p ll = (l',llr)" "r' = Node llr b (Node lr a r)"
          by (auto split: tree.splits prod.splits)
        have "size llr \<le> size ll"
          using size_partition[OF 0(1)] by (simp add: size1_def)
        with 0 `\<not> a \<le> p` `\<not> b \<le> p` "2.prems"(1) "2.IH"(4)[OF _ Node, of l' llr]
          zig_zig[where s=r and u=lr and r=ll and r1'=llr and r2'=l' and p=p, of a b]
        show ?thesis by (auto simp: real_of_nat_Suc algebra_simps)
      qed
    qed
  qed
qed

datatype 'a op\<^sub>p\<^sub>q = Insert 'a | Delmin

fun nxt\<^sub>p\<^sub>q :: "'a::linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a tree \<Rightarrow> 'a tree" where
"nxt\<^sub>p\<^sub>q (Insert a) h = insert a h" |
"nxt\<^sub>p\<^sub>q Delmin h = del_min h"

fun t\<^sub>p\<^sub>q :: "'a::linorder op\<^sub>p\<^sub>q \<Rightarrow> 'a tree \<Rightarrow> nat" where
"t\<^sub>p\<^sub>q (Insert a) h = t_in a h" |
"t\<^sub>p\<^sub>q Delmin h = t_dm h"

interpretation splay_heap: amor
where init = "Leaf" and nxt = "nxt\<^sub>p\<^sub>q" and inv = "bst_eq"
and t = t\<^sub>p\<^sub>q and \<Phi> = \<Phi>
and U = "\<lambda>f s. case f of Delmin \<Rightarrow> 2 * \<phi> s + 1 | Insert _ \<Rightarrow> 3 * log 2 (size1 s + 1) + 1"
proof
  case goal1 show ?case by simp
next
  case goal2 thus ?case
    by(cases f)
       (auto simp: insert_def bst_del_min dest: bst_partition split: prod.splits)
next
  case goal3 show ?case by(induction s) (auto simp: size1_def)
next
  case goal4 show ?case by(simp)
next
  case goal5
  show ?case
  proof (cases f)
    case Delmin with goal5 show ?thesis by(simp add: amor_del_min)
  next
    case (Insert x)
    { fix l r assume 1: "partition x s = (l,r)"
      have "log 2 (1 + size s) < log 2 (2 + size s)" by simp
      with 1 amor_partition[OF goal5 1] size_partition[OF 1] Insert have ?thesis
        by(simp add: t_in_def insert_def real_of_nat_Suc algebra_simps size1_def
             del: log_less_cancel_iff) }
    thus ?thesis using Insert by(simp add: insert_def split: prod.split)
  qed
qed

end
