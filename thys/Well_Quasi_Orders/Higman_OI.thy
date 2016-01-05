(*  Title:      Well-Quasi-Orders
    Author:     Christian Sternagel <c.sternagel@gmail.com>
    Maintainer: Christian Sternagel
    License:    LGPL
*)

section \<open>A Proof of Higman's Lemma via Open Induction\<close>

theory Higman_OI
imports
  "../Open_Induction/Open_Induction"
  Minimal_Elements
  Almost_Full
begin

subsection \<open>Some facts about the suffix relation\<close>

lemma wfp_on_suffix:
  "wfp_on suffix A"
by (rule wfp_on_mono [OF subset_refl, of _ _ "measure_on length A"])
   (auto simp: suffix_def)

lemma po_on_suffix:
  "po_on suffix A"
by (force simp: suffix_def po_on_def transp_on_def irreflp_on_def)

lemma antisymp_on_suffix:
  "antisymp_on suffix A"
by (auto simp: antisymp_on_def suffix_def)


subsection \<open>Lexicographic Order on Infinite Sequences\<close>

lemma antisymp_on_LEX:
  assumes "irreflp_on P A" and "antisymp_on P A"
  shows "antisymp_on (LEX P) (SEQ A)"
proof
  fix f g assume SEQ: "f \<in> SEQ A" "g \<in> SEQ A" and "LEX P f g" and "LEX P g f"
  then obtain i j where "P (f i) (g i)" and "P (g j) (f j)"
    and "\<forall>k<i. f k = g k" and "\<forall>k<j. g k = f k" by (auto simp: LEX_def)
  then have "P (f (min i j)) (f (min i j))"
    using assms(2) and SEQ by (cases "i = j") (auto simp: antisymp_on_def min_def, force)
  with assms(1) and SEQ show  "f = g" by (auto simp: irreflp_on_def)
qed

lemma LEX_trans:
  assumes "transp_on P A" and "f \<in> SEQ A" and "g \<in> SEQ A" and "h \<in> SEQ A"
    and "LEX P f g" and "LEX P g h"
  shows "LEX P f h"
using assms by (auto simp: LEX_def transp_on_def) (metis less_trans linorder_neqE_nat)

lemma qo_on_LEXEQ:
  "transp_on P A \<Longrightarrow> qo_on (LEXEQ P) (SEQ A)"
by (auto simp: qo_on_def reflp_on_def transp_on_def [of "LEXEQ P"] dest: LEX_trans)

context minimal_element
begin

lemma lb_LEX_lexmin:
  assumes chain: "chain_on (LEX P) C (SEQ A)" and "C \<noteq> {}"
  shows "lb (LEX P) C (lexmin C)"
proof -
  have "C \<subseteq> SEQ A" using chain by (auto simp: chain_on_def)
  note * = this \<open>C \<noteq> {}\<close>
  { fix f assume "f \<in> C" and "f \<noteq> lexmin C"
    then have neq: "\<exists>i. f i \<noteq> lexmin C i" by auto
    def i \<equiv> "LEAST i. f i \<noteq> lexmin C i"
    from LeastI_ex [OF neq, folded i_def]
      and not_less_Least [where P = "\<lambda>i. f i \<noteq> lexmin C i", folded i_def]
      have neq: "f i \<noteq> lexmin C i" and eq: "\<forall>j<i. f j = lexmin C j" by auto
    then have "f \<in> eq_upto C (lexmin C) i" using \<open>f \<in> C\<close> by auto
    then have fi: "f i \<in> ith (eq_upto C (lexmin C) i) i" (is "f i \<in> ?A") by blast
    moreover have "f i \<in> A" using \<open>f \<in> C\<close> and \<open>C \<subseteq> SEQ A\<close> by auto
    ultimately have not_P: "\<not> P (f i) (lexmin C i)"
      using lexmin_minimal [OF *, of "f i" i] by blast
    have "chain_on (LEX P) (eq_upto C (lexmin C) i) (SEQ A)"
      by (rule subchain_on [OF _ chain]) auto
    then have "chain_on P ?A A"
      by (simp add: LEX_chain_on_eq_upto_imp_ith_chain_on)
    moreover from lexmin_mem [OF *] have "lexmin C i \<in> ?A" by auto
    ultimately have "P (lexmin C i) (f i)"
      using fi and not_P and neq by (force simp: chain_on_def)
    with eq have "LEX P (lexmin C) f" by (auto simp: LEX_def) }
  then show ?thesis by (auto simp: lb_def)
qed

lemma glb_LEX_lexmin:
  assumes "chain_on (LEX P) C (SEQ A)" and "C \<noteq> {}"
  shows "glb (LEX P) C (lexmin C)"
proof -
  have "C \<subseteq> SEQ A" using assms(1) by (auto simp: chain_on_def)
  then have "lexmin C \<in> SEQ A" using \<open>C \<noteq> {}\<close> by (intro lexmin_SEQ_mem)
  have "lb (LEX P) C (lexmin C)" by (rule lb_LEX_lexmin [OF assms])
  moreover
  { fix f assume lb: "lb (LEX P) C f" and "f \<noteq> lexmin C"
    then have neq: "\<exists>i. f i \<noteq> lexmin C i" by auto
    def i \<equiv> "LEAST i. f i \<noteq> lexmin C i"
    from LeastI_ex [OF neq, folded i_def]
      and not_less_Least [where P = "\<lambda>i. f i \<noteq> lexmin C i", folded i_def]
    have neq: "f i \<noteq> lexmin C i" and eq: "\<forall>j<i. f j = lexmin C j" by auto
    from eq_upto_lexmin_non_empty [OF \<open>C \<subseteq> SEQ A\<close> \<open>C \<noteq> {}\<close>] obtain h
      where "h \<in> eq_upto C (lexmin C) (Suc i)" and "h \<in> C" by (auto simp: eq_upto_def)
    then have hi: "h i = lexmin C i" and eq': "\<forall>j<i. h i = lexmin C i" by (auto)
    with lb and \<open>h \<in> C\<close> have "LEXEQ P f h" by (auto simp: lb_def)
    with \<open>f \<noteq> lexmin C\<close> and eq and eq' and hi and neq
      have "P (f i) (lexmin C i)" apply (auto simp: LEX_def)
      by (metis SEQ_iff \<open>h \<in> eq_upto C (lexmin C) (Suc i)\<close> \<open>lexmin C \<in> SEQ A\<close> eq_uptoE less_Suc_eq linorder_neqE_nat minimal neq)
    with eq have "LEXEQ P f (lexmin C)" by (auto simp: LEX_def) }
  ultimately show ?thesis by (auto simp: glb_def)
qed

lemma dc_on_LEXEQ:
  "dc_on (LEXEQ P) (SEQ A)"
proof
  fix C assume "chain_on (LEXEQ P) C (SEQ A)" and "C \<noteq> {}"
  then have chain: "chain_on (LEX P) C (SEQ A)" by (auto simp: chain_on_def)
  then have "C \<subseteq> SEQ A" by (auto simp: chain_on_def)
  then have "lexmin C \<in> SEQ A" using \<open>C \<noteq> {}\<close> by (intro lexmin_SEQ_mem)
  have "glb (LEX P) C (lexmin C)" by (rule glb_LEX_lexmin [OF chain \<open>C \<noteq> {}\<close>])
  then have "glb (LEXEQ P) C (lexmin C)" by (auto simp: glb_def lb_def)
  with \<open>lexmin C \<in> SEQ A\<close> show "\<exists>f \<in> SEQ A. glb (LEXEQ P) C f" by blast
qed

lemma open_on_good:
  assumes antisym: "antisymp_on P A"
  shows "open_on (LEXEQ P) (good Q) (SEQ A)"
proof
  fix C assume chain: "chain_on (LEXEQ P) C (SEQ A)" and ne: "C \<noteq> {}"
    and "\<exists>g \<in> SEQ A. glb (LEXEQ P) C g \<and> good Q g"
  then obtain g where g: "g \<in> SEQ A" and "glb (LEXEQ P) C g"
    and good: "good Q g" by blast
  then have glb: "glb (LEX P) C g" by (auto simp: glb_def lb_def)
  from chain have "chain_on (LEX P) C (SEQ A)" and C: "C \<subseteq> SEQ A" by (auto simp: chain_on_def)
  note * = glb_LEX_lexmin [OF this(1) \<open>C \<noteq> {}\<close>]
  have "lexmin C \<in> SEQ A" using \<open>C \<noteq> {}\<close> using C by (intro lexmin_SEQ_mem)
  from glb_unique [OF _ g this glb *] and antisymp_on_LEX [OF po_on_imp_irreflp_on [OF po] antisym]
    have [simp]: "lexmin C = g" by auto
  from good obtain i j :: nat where "i < j" and "Q (g i) (g j)" by (auto simp: good_def)
  moreover from eq_upto_lexmin_non_empty [OF C ne, of "Suc j"]
    obtain f where "f \<in> eq_upto C g (Suc j)" by auto
  ultimately have "f \<in> C" and "Q (f i) (f j)" by auto
  then show "\<exists>f \<in> C. good Q f" using \<open>i < j\<close> by (auto simp: good_def)
qed

end

lemma higman:
  assumes "almost_full_on P A"
  shows "almost_full_on (list_emb P) (lists A)"
proof
  interpret minimal_element suffix "lists A"
    by (unfold_locales) (intro po_on_suffix wfp_on_suffix)+
  fix f presume "f \<in> SEQ (lists A)"
  with qo_on_LEXEQ [OF po_on_imp_transp_on [OF po_on_suffix]] dc_on_LEXEQ
    and open_on_good [OF antisymp_on_suffix]
    show "good (list_emb P) f"
  proof (induct rule: open_induct_on)
    case (less f)
    def h \<equiv> "\<lambda>i. hd (f i)"
    show ?case
    proof (cases "\<exists>i. f i = []")
      case False
      then have ne: "\<forall>i. f i \<noteq> []" by auto
      with \<open>f \<in> SEQ (lists A)\<close> have "\<forall>i. h i \<in> A" by (auto simp: h_def ne_lists)
      from almost_full_on_imp_homogeneous_subseq [OF assms this]
        obtain \<phi> :: "nat \<Rightarrow> nat" where mono: "\<And>i j. i < j \<Longrightarrow> \<phi> i < \<phi> j"
        and P: "\<And>i j. i < j \<Longrightarrow> P (h (\<phi> i)) (h (\<phi> j))" by blast
      def f' \<equiv> "\<lambda>i. if i < \<phi> 0 then f i else tl (f (\<phi> (i - \<phi> 0)))"
      have f': "f' \<in> SEQ (lists A)" using ne and \<open>f \<in> SEQ (lists A)\<close>
        by (auto simp: f'_def dest: list.set_sel)
      have [simp]: "\<And>i. \<phi> 0 \<le> i \<Longrightarrow> h (\<phi> (i - \<phi> 0)) # f' i = f (\<phi> (i - \<phi> 0))"
        "\<And>i. i < \<phi> 0 \<Longrightarrow> f' i = f i" using ne by (auto simp: f'_def h_def)
      moreover have "suffix (f' (\<phi> 0)) (f (\<phi> 0))" using ne by (auto simp: f'_def)
      ultimately have "LEX suffix f' f" by (auto simp: LEX_def)
      with LEX_imp_not_LEX [OF this] have "strict (LEXEQ suffix) f' f"
        using po_on_suffix [of UNIV] unfolding po_on_def irreflp_on_def transp_on_def by blast
      from less(2) [OF f' this] have "good (list_emb P) f'" .
      then obtain i j where "i < j" and emb: "list_emb P (f' i) (f' j)" by (auto simp: good_def)
      consider "j < \<phi> 0" | "\<phi> 0 \<le> i" | "i < \<phi> 0" and "\<phi> 0 \<le> j" by arith
      then show ?thesis
      proof (cases)
        case 1 with \<open>i < j\<close> and emb show ?thesis by (auto simp: good_def)
      next
        case 2
        with \<open>i < j\<close> and P have "P (h (\<phi> (i - \<phi> 0))) (h (\<phi> (j - \<phi> 0)))" by auto
        with emb have "list_emb P (h (\<phi> (i - \<phi> 0)) # f' i) (h (\<phi> (j - \<phi> 0)) # f' j)" by auto
        then have "list_emb P (f (\<phi> (i - \<phi> 0))) (f (\<phi> (j - \<phi> 0)))" using 2 and \<open>i < j\<close> by auto
        moreover with 2 and \<open>i <j\<close> have "\<phi> (i - \<phi> 0) < \<phi> (j - \<phi> 0)" using mono by auto
        ultimately show ?thesis by (auto simp: good_def)
      next
        case 3
        with emb have "list_emb P (f i) (f' j)" by auto
        moreover have "f (\<phi> (j - \<phi> 0)) = h (\<phi> (j - \<phi> 0)) # f' j" using 3 by auto
        ultimately have "list_emb P (f i) (f (\<phi> (j - \<phi> 0)))" by auto
        moreover have "i < \<phi> (j - \<phi> 0)" using mono [of 0 "j - \<phi> 0"] and 3 by force
        ultimately show ?thesis by (auto simp: good_def)
      qed
    qed auto
  qed
qed blast

end
