(* Author: Alexander Bentkamp, Universität des Saarlandes
*)

section \<open>Rank and Submatrices\<close>

theory DL_Rank_Submatrix
imports DL_Rank DL_Submatrix DL_Missing_Matrix
begin

lemma row_submatrix_UNIV:
assumes "i < card {i. i < dim\<^sub>r A \<and> i \<in> I}"
shows "row (submatrix A I UNIV) i = row A (pick I i)"
proof (rule vec_eqI)
  show dim_eq:"dim\<^sub>v (row (submatrix A I UNIV) i) = dim\<^sub>v (row A (pick I i))"
    unfolding vec_elemsD[OF row_dim] dim_submatrix by auto
  fix j assume "j < dim\<^sub>v (row A (pick I i))"
  then have "j < dim\<^sub>c (submatrix A I UNIV)" "j < dim\<^sub>c A" "j < card {j. j < dim\<^sub>c A \<and> j \<in> UNIV}" using dim_eq by auto
  show "row (submatrix A I UNIV) i $ j = row A (pick I i) $ j"
    unfolding row_def vec_index_vec[OF `j < dim\<^sub>c (submatrix A I UNIV)`] vec_index_vec[OF `j < dim\<^sub>c A`]
    using submatrix_index[OF assms `j < card {j. j < dim\<^sub>c A \<and> j \<in> UNIV}`] using pick_UNIV by auto
qed

lemma distinct_cols_submatrix_UNIV:
assumes "distinct (cols (submatrix A I UNIV))"
shows "distinct (cols A)"
using assms proof (rule contrapos_pp)
  assume "\<not> distinct (cols A)"
  then obtain i j where "i < dim\<^sub>c A" "j < dim\<^sub>c A" "(cols A)!i = (cols A)!j" "i\<noteq>j"
    using distinct_conv_nth cols_length by metis
  have "i < dim\<^sub>c (submatrix A I UNIV)" "j < dim\<^sub>c (submatrix A I UNIV)"
    unfolding dim_submatrix using `i < dim\<^sub>c A` `j < dim\<^sub>c A`by simp_all
  then have "i < length (cols (submatrix A I UNIV))" "j < length (cols (submatrix A I UNIV))"
    unfolding cols_length by simp_all
  have "(cols (submatrix A I UNIV))!i = (cols (submatrix A I UNIV))!j"
  proof (rule vec_eqI)
    show "dim\<^sub>v (cols (submatrix A I UNIV) ! i) = dim\<^sub>v (cols (submatrix A I UNIV) ! j)"
      by (simp add: \<open>i < dim\<^sub>c (submatrix A I UNIV)\<close> \<open>j < dim\<^sub>c (submatrix A I UNIV)\<close>)
    fix k assume "k < dim\<^sub>v (cols (submatrix A I UNIV) ! j)"
    then have "k < dim\<^sub>r (submatrix A I UNIV)"
      using \<open>j < length (cols (submatrix A I UNIV))\<close>  by auto
    then have  "k < card {j. j < dim\<^sub>r A \<and> j \<in> I}"  using dim_submatrix(1) by metis
    have i_transfer:"cols (submatrix A I UNIV) ! i $ k = (cols A) ! i $ (pick I k)"
      unfolding cols_nth[OF `i < dim\<^sub>c (submatrix A I UNIV)`] col_def vec_index_vec[OF `k < dim\<^sub>r (submatrix A I UNIV)`]
      unfolding submatrix_index[OF `k < card {j. j < dim\<^sub>r A \<and> j \<in> I}` `i < dim\<^sub>c (submatrix A I UNIV)`[unfolded dim_submatrix]]
      unfolding pick_UNIV cols_nth[OF `i < dim\<^sub>c A`] col_def vec_index_vec[OF pick_le[OF `k < card {j. j < dim\<^sub>r A \<and> j \<in> I}`]]
      by metis
    have j_transfer:"cols (submatrix A I UNIV) ! j $ k = (cols A) ! j $ (pick I k)"
      unfolding cols_nth[OF `j < dim\<^sub>c (submatrix A I UNIV)`] col_def vec_index_vec[OF `k < dim\<^sub>r (submatrix A I UNIV)`]
      unfolding submatrix_index[OF `k < card {j. j < dim\<^sub>r A \<and> j \<in> I}` `j < dim\<^sub>c (submatrix A I UNIV)`[unfolded dim_submatrix]]
      unfolding pick_UNIV cols_nth[OF `j < dim\<^sub>c A`] col_def vec_index_vec[OF pick_le[OF `k < card {j. j < dim\<^sub>r A \<and> j \<in> I}`]]
      by metis
    show "cols (submatrix A I UNIV) ! i $ k = cols (submatrix A I UNIV) ! j $ k"
      using \<open>cols A ! i = cols A ! j\<close> i_transfer j_transfer by auto
  qed
  then show "\<not> distinct (cols (submatrix A I UNIV))" unfolding distinct_conv_nth
    using `i < length (cols (submatrix A I UNIV))` `j < length (cols (submatrix A I UNIV))` \<open>i \<noteq> j\<close> by blast
qed

lemma cols_submatrix_subset: "set (cols (submatrix A UNIV J)) \<subseteq> set (cols A)"
proof
  fix c assume "c \<in> set (cols (submatrix A UNIV J))"
  then obtain j where "j < length (cols (submatrix A UNIV J))" "cols (submatrix A UNIV J) ! j = c"
    by (meson in_set_conv_nth)
  then have "j < dim\<^sub>c (submatrix A UNIV J)" by simp
  then have "j < card {j. j < dim\<^sub>c A \<and> j \<in> J}" by (simp add: dim_submatrix(2))
  have "cols (submatrix A UNIV J) ! j = cols A ! (pick J j)"
    unfolding cols_nth[OF `j < dim\<^sub>c (submatrix A UNIV J)`] cols_nth[OF pick_le[OF `j < card {j. j < dim\<^sub>c A \<and> j \<in> J}`]]
  proof (rule vec_eqI)
    show "dim\<^sub>v (col (submatrix A UNIV J) j) = dim\<^sub>v (col A (pick J j))" unfolding dim_col dim_submatrix by auto
    fix i assume "i < dim\<^sub>v (col A (pick J j))"
    then have "i < dim\<^sub>r A" by simp
    then have "i < dim\<^sub>r (submatrix A UNIV J)" using \<open>dim\<^sub>v (col (submatrix A UNIV J) j) = dim\<^sub>v (col A (pick J j))\<close> by auto
    show "col (submatrix A UNIV J) j $ i = col A (pick J j) $ i"
      unfolding col_def vec_index_vec[OF `i < dim\<^sub>r (submatrix A UNIV J)`] vec_index_vec[OF `i < dim\<^sub>r A`]
      using submatrix_index by (metis (no_types, lifting) \<open>dim\<^sub>v (col (submatrix A UNIV J) j) = dim\<^sub>v (col A (pick J j))\<close>
      \<open>i < dim\<^sub>v (col A (pick J j))\<close> \<open>j < dim\<^sub>c (submatrix A UNIV J)\<close> dim_col dim_submatrix(1) dim_submatrix(2) pick_UNIV)
  qed
  then show "c \<in> set (cols A)"
    using `cols (submatrix A UNIV J) ! j = c`
    using pick_le[OF `j < card {j. j < dim\<^sub>c A \<and> j \<in> J}`] by (metis cols_length nth_mem)
qed

lemma (in vec_space) lin_dep_submatrix_UNIV:
assumes "A \<in> carrier\<^sub>m n nc"
assumes "lin_dep (set (cols A))"
assumes "distinct (cols (submatrix A I UNIV))"
shows "LinearCombinations.module.lin_dep F (module\<^sub>v TYPE('a) (card {i. i < n \<and> i \<in> I})) (set (cols (submatrix A I UNIV)))"
  (is "LinearCombinations.module.lin_dep F ?M (set ?S')")
proof -
  obtain v where 2:"v \<in> carrier\<^sub>v nc" and 3:"v \<noteq> \<zero>\<^sub>v nc" and "A \<otimes>\<^sub>m\<^sub>v v = \<zero>\<^sub>v n"
    using vec_space.lin_depE[OF assms(1) assms(2) distinct_cols_submatrix_UNIV[OF assms(3)]] by auto
  have 1: "submatrix A I UNIV \<in> carrier\<^sub>m (card {i. i < n \<and> i \<in> I}) nc"
    apply (rule mat_carrierI) unfolding dim_submatrix using `A \<in> carrier\<^sub>m n nc` by auto
  have 4:"submatrix A I UNIV \<otimes>\<^sub>m\<^sub>v v = \<zero>\<^sub>v (card {i. i < n \<and> i \<in> I})"
  proof (rule vec_eqI)
    show dim_eq:"dim\<^sub>v (submatrix A I UNIV \<otimes>\<^sub>m\<^sub>v v) = dim\<^sub>v (\<zero>\<^sub>v (card {i. i < n \<and> i \<in> I}))" using "1" by auto
    fix i assume "i < dim\<^sub>v (\<zero>\<^sub>v (card {i. i < n \<and> i \<in> I}))"
    then have i_le:"i < card {i. i < n \<and> i \<in> I}" by auto
    have "(submatrix A I UNIV \<otimes>\<^sub>m\<^sub>v v) $ i = row (submatrix A I UNIV) i \<bullet> v" using dim_eq i_le by auto
    also have "... = row A (pick I i) \<bullet> v" using row_submatrix_UNIV
      by (metis (no_types, lifting)  dim_eq dim_mat_mult_vec dim_submatrix(1) \<open>i < dim\<^sub>v (\<zero>\<^sub>v (card {i. i < n \<and> i \<in> I}))\<close>)
    also have "... = 0"
      using `A \<otimes>\<^sub>m\<^sub>v v = \<zero>\<^sub>v n` i_le[THEN pick_le] by (metis assms(1) index_mat_mult_vec mat_carrierD(1) vec_zero_index(1))
    also have "... = \<zero>\<^sub>v (card {i. i < n \<and> i \<in> I}) $ i" by (simp add: i_le)
    finally show "(submatrix A I UNIV \<otimes>\<^sub>m\<^sub>v v) $ i = \<zero>\<^sub>v (card {i. i < n \<and> i \<in> I}) $ i" by metis
  qed
  show ?thesis using vec_space.lin_depI[OF 1 2 3 4] using assms(3) by auto
qed

lemma (in vec_space) rank_gt_minor:
assumes "A \<in> carrier\<^sub>m n nc"
assumes "det (submatrix A I J) \<noteq> 0"
shows "card {j. j < nc \<and> j \<in> J} \<le> rank A"
proof -
  have square:"dim\<^sub>r (submatrix A I J) = dim\<^sub>c (submatrix A I J)"
   using det_def `det (submatrix A I J) \<noteq> 0` by metis
  then have full_rank:"vec_space.rank (dim\<^sub>r (submatrix A I J)) (submatrix A I J) = dim\<^sub>r (submatrix A I J)"
   using vec_space.low_rank_det_zero assms(2) mat_carrierI by auto
  then have distinct:"distinct (cols (submatrix A I J))" using vec_space.non_distinct_low_rank
   using square less_irrefl mat_carrierI by fastforce
  then have indpt:"LinearCombinations.module.lin_indpt F (module\<^sub>v TYPE('a) (dim\<^sub>r (submatrix A I J))) (set (cols (submatrix A I J)))"
     using vec_space.full_rank_lin_indpt[OF _ full_rank distinct] square by fastforce

  have distinct2: "distinct (cols (submatrix (submatrix A UNIV J) I UNIV))" using submatrix_split distinct by metis
  have indpt2:"LinearCombinations.module.lin_indpt F (module\<^sub>v TYPE('a) (card {i. i < n \<and> i \<in> I})) (set (cols (submatrix (submatrix A UNIV J) I UNIV)))"
    using submatrix_split dim_submatrix(1) indpt by (metis (full_types) assms(1) mat_carrierD(1))

  have "submatrix A UNIV J \<in> carrier\<^sub>m n (dim\<^sub>c (submatrix A UNIV J))"
    apply (rule mat_carrierI) unfolding dim_submatrix(1) using `A \<in> carrier\<^sub>m n nc` mat_carrierD by simp_all
  have "lin_indpt (set (cols (submatrix A UNIV J)))"
    using indpt2 vec_space.lin_dep_submatrix_UNIV[OF `submatrix A UNIV J \<in> carrier\<^sub>m n (dim\<^sub>c (submatrix A UNIV J))` _ distinct2] by blast
  have distinct3:"distinct (cols (submatrix A UNIV J))" by (metis distinct distinct_cols_submatrix_UNIV submatrix_split)
  show ?thesis using
    rank_ge_card_indpt[OF `A \<in> carrier\<^sub>m n nc` cols_submatrix_subset `lin_indpt (set (cols (submatrix A UNIV J)))`,
    unfolded distinct_card[OF distinct3, unfolded cols_length dim_submatrix], unfolded mat_carrierD(2)[OF `A \<in> carrier\<^sub>m n nc`]]
    by blast
qed

end
