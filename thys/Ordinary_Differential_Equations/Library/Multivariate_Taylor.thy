section \<open>Multivariate Taylor\<close>
theory Multivariate_Taylor
imports
  "~~/src/HOL/Analysis/Analysis"
  "../ODE_Auxiliarities"
begin

no_notation vec_nth (infixl "$" 90)
notation blinfun_apply (infixl "$" 999)

lemma
  fixes f::"'a::real_normed_vector \<Rightarrow> 'b::banach"
    and Df::"'a \<Rightarrow> 'a list \<Rightarrow> 'b"
  assumes "n > 0"
  assumes Df_Nil: "\<And>a. Df a [] = f a"
  assumes Df_Cons: "\<And>a ds. a \<in> closed_segment X (X + H) \<Longrightarrow> length ds < n \<Longrightarrow>
      ((\<lambda>a. Df a ds) has_derivative (\<lambda>d. Df a (d#ds))) (at a)"
  defines "i \<equiv> \<lambda>x.
      ((1 - x) ^ (n - 1) / fact (n - 1)) *\<^sub>R Df (X + x *\<^sub>R H) (replicate n H)"
  shows multivariate_taylor_has_integral:
    "(i has_integral f (X + H) - (\<Sum>i<n. (1 / fact i) *\<^sub>R Df X (replicate i H))) {0..1}"
  and multivariate_taylor:
    "f (X + H) = (\<Sum>i<n. (1 / fact i) *\<^sub>R Df X (replicate i H)) + integral {0..1} i"
  and multivariate_taylor_integrable:
    "i integrable_on {0..1}"
proof goal_cases
  case 1
  let ?G = "closed_segment X (X + H)"
  define line where "line t = X + t *\<^sub>R H" for t
  have segment_eq: "closed_segment X (X + H) = line ` {0 .. 1}"
    by (auto simp: line_def closed_segment_def algebra_simps)
  have line_deriv: "\<And>x. (line has_derivative (\<lambda>t. t *\<^sub>R H)) (at x)"
    by (auto intro!: derivative_eq_intros simp: line_def [abs_def])
  define g where "g = f o line"
  define Dg where "Dg n t = Df (line t) (replicate n H)" for n :: nat and t :: real
  note \<open>n > 0\<close>
  moreover
  have Dg0: "Dg 0 = g" by (auto simp add: Dg_def Df_Nil g_def)
  moreover
  have DgSuc: "(Dg m has_vector_derivative Dg (Suc m) t) (at t within {0..1})"
    if "m < n" "0 \<le> t" "t \<le> 1" for m::nat and t::real
  proof -
    from that have [intro]: "line t \<in> ?G" using assms
      by (auto simp: segment_eq)
    note [derivative_intros] = has_derivative_compose[OF _ Df_Cons]
    interpret Df: linear "(\<lambda>d. Df (line t) (d#replicate m H))"
      by (auto intro!: has_derivative_linear derivative_intros \<open>m < n\<close>)
    note [derivative_intros] =
      has_derivative_compose[OF _ line_deriv]
    show ?thesis
      using Df.scaleR \<open>m < n\<close>
      by (auto simp: Dg_def [abs_def] has_vector_derivative_def g_def
         intro!: derivative_eq_intros)
  qed
  ultimately
  have g_taylor: "(i has_integral g 1 - (\<Sum>i<n. ((1 - 0) ^ i / fact i) *\<^sub>R Dg i 0)) {0 .. 1}"
    unfolding i_def Dg_def [abs_def] line_def
    by (rule taylor_has_integral) auto
  then show c: ?case using \<open>n > 0\<close> by (auto simp: g_def line_def Dg_def)
  case 2 show ?case using c integral_unique by force
  case 3 show ?case using c by force
qed

text \<open>in particular...\<close>

lemma
  multivariate_taylor2:
  fixes f::"'a::real_normed_vector \<Rightarrow> 'b::banach"
  assumes f'[derivative_intros]:
    "\<And>y. y \<in> closed_segment a x \<Longrightarrow> (f has_derivative op $ (f' y)) (at y)"
  assumes f''[derivative_intros]:
    "\<And>y. y \<in> closed_segment a x \<Longrightarrow> (f' has_derivative op $ (f'' y)) (at y)"
  shows "((\<lambda>xa. (1 - xa) *\<^sub>R f'' (a + xa *\<^sub>R (x - a)) (x - a) (x - a)) has_integral f x - f a - f' a (x - a)) {0 .. 1}"
proof -
  let ?G = "closed_segment a x"
  define Df where "Df x ds =
    (case ds of [] \<Rightarrow> f x
    | [d] \<Rightarrow> f' x d
    | [d1, d2] \<Rightarrow> f'' x d1 d2)" for x ds
  have Df_Nil: "\<And>a. Df a [] = f a"
    by (auto simp: Df_def)
  have Df_Cons: "((\<lambda>a. Df a ds) has_derivative (\<lambda>d. Df a (d # ds))) (at a)"
    if "a \<in> ?G" "length ds < 2" for a::'a and ds::"'a list"
    using that
    by (cases ds)
       (auto simp add: Df_def assms blinfun.zero_right
        intro!: derivative_eq_intros)
  from multivariate_taylor_has_integral[of 2 Df f a "x - a", OF _ Df_Nil Df_Cons]
  show ?thesis
    by (simp add: assms numeral_eq_Suc Df_def algebra_simps)
qed

lemma
  multivariate_taylor3:
  fixes f::"'a::real_normed_vector \<Rightarrow> 'b::banach"
  assumes f'[derivative_intros]:
    "\<And>y. y \<in> closed_segment a x \<Longrightarrow> (f has_derivative op $ (f' y)) (at y)"
  assumes f''[derivative_intros]:
    "\<And>y. y \<in> closed_segment a x \<Longrightarrow> (f' has_derivative op $ (f'' y)) (at y)"
  assumes f'''[derivative_intros]:
    "\<And>y. y \<in> closed_segment a x \<Longrightarrow> (f'' has_derivative op $ (f''' y)) (at y)"
  shows
    "((\<lambda>xa. ((1 - xa)\<^sup>2/2) *\<^sub>R f''' (a + xa *\<^sub>R (x - a)) (x - a) (x - a) (x - a))
      has_integral
        f x - f a - f' a (x - a) - f'' a (x - a) (x - a) /\<^sub>R 2) {0..1}"
proof -
  let ?G = "closed_segment a x"
  define Df where "Df x ds =
    (case ds of [] \<Rightarrow> f x
    | [d] \<Rightarrow> f' x d
    | [d1, d2] \<Rightarrow> f'' x d1 d2
    | [d1, d2, d3] \<Rightarrow> f''' x d1 d2 d3)" for x ds
  have Df_Nil: "\<And>a. Df a [] = f a"
    by (auto simp: Df_def)
  have Df_Cons: "((\<lambda>a. Df a ds) has_derivative (\<lambda>d. Df a (d # ds))) (at a)"
    if "a \<in> ?G" "length ds < 3" for a::'a and ds::"'a list"
  proof -
    from that consider "ds = []" | "\<exists>d1. ds = [d1]" | "\<exists>d1 d2. ds = [d1, d2]"
      apply (cases ds)
      subgoal by simp
      subgoal for d ds by (cases ds) auto
      done
    then show ?thesis
      apply cases
      using \<open>a \<in> ?G\<close>
      by (auto simp add: Df_def assms blinfun.zero_right
          intro!: derivative_eq_intros)
  qed
  from multivariate_taylor_has_integral[of 3 Df f a "x - a", OF _ Df_Nil Df_Cons]
  show ?thesis
    by (simp add: assms numeral_eq_Suc Df_def algebra_simps)
qed


subsection \<open>Symmetric second derivative\<close>

lemma symmetric_second_derivative_aux:
  assumes first_fderiv[derivative_intros]:
    "\<And>a. a \<in> G \<Longrightarrow> (f has_derivative (f' a)) (at a within G)"
  assumes second_fderiv[derivative_intros]:
    "\<And>i. ((\<lambda>x. f' x i) has_derivative (\<lambda>j. f'' j i)) (at a within G)"
  assumes "i \<noteq> j" "i \<noteq> 0" "j \<noteq> 0"
  assumes "a \<in> G"
  assumes "\<And>s t. s \<in> {0..1} \<Longrightarrow> t \<in> {0..1} \<Longrightarrow> a + s *\<^sub>R i + t *\<^sub>R j \<in> G"
  shows "f'' j i = f'' i j"
proof -
  let ?F = "at_right (0::real)"
  define B where "B i j = {a + s *\<^sub>R i + t *\<^sub>R j |s t. s \<in> {0..1} \<and> t \<in> {0..1}}" for i j
  have "B i j \<subseteq> G" using assms by (auto simp: B_def)
  {
    fix e::real and i j::'a
    assume "e > 0"
    assume "i \<noteq> j" "i \<noteq> 0" "j \<noteq> 0"
    assume "B i j \<subseteq> G"
    let ?ij' = "\<lambda>s t. \<lambda>u. a + (s * u) *\<^sub>R i + (t * u) *\<^sub>R j"
    let ?ij = "\<lambda>t. \<lambda>u. a + (t * u) *\<^sub>R i + u *\<^sub>R j"
    let ?i = "\<lambda>t. \<lambda>u. a + (t * u) *\<^sub>R i"
    let ?g = "\<lambda>u t. f (?ij t u) - f (?i t u)"
    have filter_ij'I: "\<And>P. P a \<Longrightarrow> eventually P (at a within G) \<Longrightarrow>
      eventually (\<lambda>x. \<forall>s\<in>{0..1}. \<forall>t\<in>{0..1}. P (?ij' s t x)) ?F"
    proof -
      fix P
      assume "P a"
      assume "eventually P (at a within G)"
      hence "eventually P (at a within B i j)" by (rule filter_leD[OF at_le[OF \<open>B i j \<subseteq> G\<close>]])
      then obtain d where d: "d > 0" and "\<And>x d2. x \<in> B i j \<Longrightarrow> x \<noteq> a \<Longrightarrow> dist x a < d \<Longrightarrow> P x"
        by (auto simp: eventually_at)
      with \<open>P a\<close> have P: "\<And>x d2. x \<in> B i j \<Longrightarrow> dist x a < d \<Longrightarrow> P x" by (case_tac "x = a") auto
      let ?d = "min (min (d/norm i) (d/norm j) / 2) 1"
      show "eventually (\<lambda>x. \<forall>s\<in>{0..1}. \<forall>t\<in>{0..1}. P (?ij' s t x)) (at_right 0)"
        unfolding eventually_at
      proof (rule exI[where x="?d"], safe)
        show "0 < ?d" using \<open>0 < d\<close> \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> by simp
        fix x s t :: real assume *: "s \<in> {0..1}" "t \<in> {0..1}" "0 < x" "dist x 0 < ?d"
        show "P (?ij' s t x)"
        proof (rule P)
          have "\<And>x y::real. x \<in> {0..1} \<Longrightarrow> y \<in> {0..1} \<Longrightarrow> x * y \<in> {0..1}"
            by (auto intro!: order_trans[OF mult_left_le_one_le])
          hence "s * x \<in> {0..1}" "t * x \<in> {0..1}" using * by (auto simp: dist_norm)
          thus "?ij' s t x \<in> B i j" by (auto simp: B_def)
          have "norm (s *\<^sub>R x *\<^sub>R i + t *\<^sub>R x *\<^sub>R j) \<le> norm (s *\<^sub>R x *\<^sub>R i) + norm (t *\<^sub>R x *\<^sub>R j)"
            by (rule norm_triangle_ineq)
          also have "\<dots> < d / 2 + d / 2" using * \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close>
            by (intro add_strict_mono) (auto simp: ac_simps dist_norm
              pos_less_divide_eq le_less_trans[OF mult_left_le_one_le])
          finally show "dist (?ij' s t x) a < d" by (simp add: dist_norm)
        qed
      qed
    qed
    have filter_ijI: "eventually (\<lambda>x. \<forall>t\<in>{0..1}. P (?ij t x)) ?F"
      if "P a" "eventually P (at a within G)" for P
      using filter_ij'I[OF that]
        by eventually_elim (force dest: bspec[where x=1])
    have filter_iI: "eventually (\<lambda>x. \<forall>t\<in>{0..1}. P (?i t x)) ?F"
      if "P a" "eventually P (at a within G)" for P
      using filter_ij'I[OF that] by eventually_elim force
    {
      from second_fderiv[of i, simplified has_derivative_iff_norm, THEN conjunct2,
        THEN tendstoD, OF \<open>0 < e\<close>]
      have "eventually (\<lambda>x. norm (f' x i - f' a i - f'' (x - a) i) / norm (x - a) \<le> e)
          (at a within G)"
        by eventually_elim (simp add: dist_norm)
      from filter_ijI[OF _ this] filter_iI[OF _ this] \<open>0 < e\<close>
      have
        "eventually (\<lambda>ij. \<forall>t\<in>{0..1}. norm (f' (?ij t ij) i - f' a i - f'' (?ij t ij - a) i) /
          norm (?ij t ij - a) \<le> e) ?F"
        "eventually (\<lambda>ij. \<forall>t\<in>{0..1}. norm (f' (?i t ij) i - f' a i - f'' (?i t ij - a) i) /
          norm (?i t ij - a) \<le> e) ?F"
        by auto
      moreover
      have "eventually (\<lambda>x. x \<in> G) (at a within G)" unfolding eventually_at_filter by simp
      hence eventually_in_ij: "eventually (\<lambda>x. \<forall>t\<in>{0..1}. ?ij t x \<in> G) ?F" and
        eventually_in_i: "eventually (\<lambda>x. \<forall>t\<in>{0..1}. ?i t x \<in> G) ?F"
        using \<open>a \<in> G\<close> by (auto dest: filter_ijI filter_iI)
      ultimately
      have "eventually (\<lambda>u. norm (?g u 1 - ?g u 0 - (u * u) *\<^sub>R f'' j i) \<le>
          u * u * e * (2 * norm i + 3 * norm j)) ?F"
      proof eventually_elim
        case (elim u)
        hence ijsub: "(\<lambda>t. ?ij t u) ` {0..1} \<subseteq> G" and isub: "(\<lambda>t. ?i t u) ` {0..1} \<subseteq> G" by auto
        note has_derivative_subset[OF _ ijsub, derivative_intros]
        note has_derivative_subset[OF _ isub, derivative_intros]
        let ?g' = "\<lambda>t. (\<lambda>ua. u *\<^sub>R ua *\<^sub>R (f' (?ij t u) i - (f' (?i t u) i)))"
        have g': "((?g u) has_derivative ?g' t) (at t within {0..1})" if "t \<in> {0..1}" for t::real
        proof -
          from elim that have linear_f': "\<And>c x. f' (?ij t u) (c *\<^sub>R x) = c *\<^sub>R f' (?ij t u) x"
              "\<And>c x. f' (?i t u) (c *\<^sub>R x) = c *\<^sub>R f' (?i t u) x"
            using linear_cmul[OF has_derivative_linear, OF first_fderiv] by auto
          show ?thesis
            using elim \<open>t \<in> {0..1}\<close>
            by (auto intro!: derivative_eq_intros has_derivative_in_compose[of  "\<lambda>t. ?ij t u" _ _ _ f]
                has_derivative_in_compose[of  "\<lambda>t. ?i t u" _ _ _ f]
              simp: linear_f' scaleR_diff_right mult.commute)
        qed
        from elim(1) \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> \<open>0 < e\<close> have f'ij: "\<And>t. t \<in> {0..1} \<Longrightarrow>
            norm (f' (a + (t * u) *\<^sub>R i + u *\<^sub>R j) i - f' a i - f'' ((t * u) *\<^sub>R i + u *\<^sub>R j) i) \<le>
            e * norm ((t * u) *\<^sub>R i + u *\<^sub>R j)"
          using  linear_0[OF has_derivative_linear, OF second_fderiv]
          by (case_tac "u *\<^sub>R j + (t * u) *\<^sub>R i = 0") (auto simp: field_simps
            simp del: pos_divide_le_eq simp add: pos_divide_le_eq[symmetric])
        from elim(2) have f'i: "\<And>t. t \<in> {0..1} \<Longrightarrow> norm (f' (a + (t * u) *\<^sub>R i) i - f' a i -
          f'' ((t * u) *\<^sub>R i) i) \<le> e * abs (t * u) * norm i"
          using \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> linear_0[OF has_derivative_linear, OF second_fderiv]
          by (case_tac "t * u = 0") (auto simp: field_simps simp del: pos_divide_le_eq
            simp add: pos_divide_le_eq[symmetric])
        have "norm (?g u 1 - ?g u 0 - (u * u) *\<^sub>R f'' j i) =
          norm ((?g u 1 - ?g u 0 - u *\<^sub>R (f' (a + u *\<^sub>R j) i - (f' a i)))
            + u *\<^sub>R (f' (a + u *\<^sub>R j) i - f' a i - u *\<^sub>R f'' j i))"
            (is "_ = norm (?g10 + ?f'i)")
          by (simp add: algebra_simps linear_cmul[OF has_derivative_linear, OF second_fderiv]
            linear_add[OF has_derivative_linear, OF second_fderiv])
        also have "\<dots> \<le> norm ?g10 + norm ?f'i"
          by (blast intro: order_trans add_mono norm_triangle_le)
        also
        have "0 \<in> {0..1::real}" by simp
        have "\<forall>t \<in> {0..1}. onorm ((\<lambda>ua. (u * ua) *\<^sub>R (f' (?ij t u) i - f' (?i t u) i)) -
              (\<lambda>ua. (u * ua) *\<^sub>R (f' (a + u *\<^sub>R j) i - f' a i)))
            \<le> 2 * u * u * e * (norm i + norm j)" (is "\<forall>t \<in> _. onorm (?d t) \<le> _")
        proof
          fix t::real assume "t \<in> {0..1}"
          show "onorm (?d t) \<le> 2 * u * u * e * (norm i + norm j)"
          proof (rule onorm_le)
            fix x
            have "norm (?d t x) =
                norm ((u * x) *\<^sub>R (f' (?ij t u) i - f' (?i t u) i - f' (a + u *\<^sub>R j) i + f' a i))"
              by (simp add: algebra_simps)
            also have "\<dots> =
                abs (u * x) * norm (f' (?ij t u) i - f' (?i t u) i - f' (a + u *\<^sub>R j) i + f' a i)"
              by simp
            also have "\<dots> = abs (u * x) * norm (
                 f' (?ij t u) i - f' a i - f'' ((t * u) *\<^sub>R i + u *\<^sub>R j) i
               - (f' (?i t u) i - f' a i - f'' ((t * u) *\<^sub>R i) i)
               - (f' (a + u *\<^sub>R j) i - f' a i - f'' (u *\<^sub>R j) i))"
               (is "_ = _ * norm (?dij - ?di - ?dj)")
              using \<open>a \<in> G\<close>
              by (simp add: algebra_simps
                linear_add[OF has_derivative_linear[OF second_fderiv]])
            also have "\<dots> \<le> abs (u * x) * (norm ?dij + norm ?di + norm ?dj)"
              by (rule mult_left_mono[OF _ abs_ge_zero]) norm
            also have "\<dots> \<le> abs (u * x) *
              (e * norm ((t * u) *\<^sub>R i + u *\<^sub>R j) + e * abs (t * u) * norm i + e * (\<bar>u\<bar> * norm j))"
              using f'ij f'i f'ij[OF \<open>0 \<in> {0..1}\<close>] \<open>t \<in> {0..1}\<close>
              by (auto intro!: add_mono mult_left_mono)
            also have "\<dots> = abs u * abs x * abs u *
              (e * norm (t *\<^sub>R i + j) + e * norm (t *\<^sub>R i) + e * (norm j))"
              by (simp add: algebra_simps norm_scaleR[symmetric] abs_mult del: norm_scaleR)
            also have "\<dots> =
                u * u * abs x * (e * norm (t *\<^sub>R i + j) + e * norm (t *\<^sub>R i) + e * (norm j))"
              by (simp add: ac_simps)
            also have "\<dots> = u * u * e * abs x * (norm (t *\<^sub>R i + j) + norm (t *\<^sub>R i) + norm j)"
              by (simp add: algebra_simps)
            also have "\<dots> \<le> u * u * e * abs x * ((norm (1 *\<^sub>R i) + norm j) + norm (1 *\<^sub>R i) + norm j)"
              using \<open>t \<in> {0..1}\<close> \<open>0 < e\<close>
              by (intro mult_left_mono add_mono) (auto intro!: norm_triangle_le add_right_mono
                mult_left_le_one_le zero_le_square)
            finally show "norm (?d t x) \<le> 2 * u * u * e * (norm i + norm j) * norm x"
              by (simp add: ac_simps)
          qed
        qed
        with differentiable_bound_linearization[where f="?g u" and f'="?g'", of 0 1 _ 0, OF _ g']
        have "norm ?g10 \<le> 2 * u * u * e * (norm i + norm j)" by simp
        also have "norm ?f'i \<le> abs u *
          norm ((f' (a + (u) *\<^sub>R j) i - f' a i - f'' (u *\<^sub>R j) i))"
          using linear_cmul[OF has_derivative_linear, OF second_fderiv]
          by simp
        also have "\<dots> \<le> abs u * (e * norm ((u) *\<^sub>R j))"
          using f'ij[OF \<open>0 \<in> {0..1}\<close>] by (auto intro: mult_left_mono)
        also have "\<dots> = u * u * e * norm j" by (simp add: algebra_simps abs_mult)
        finally show ?case by (simp add: algebra_simps)
      qed
    }
  } note wlog = this
  have e': "norm (f'' j i - f'' i j) \<le> e * (5 * norm j + 5 * norm i)" if "0 < e" for e t::real
  proof -
    have "B i j = B j i" using \<open>i \<noteq> j\<close> by (force simp: B_def)+
    with assms \<open>B i j \<subseteq> G\<close> have "j \<noteq> i" "B j i \<subseteq> G" by (auto simp:)
    from wlog[OF \<open>0 < e\<close> \<open>i \<noteq> j\<close> \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> \<open>B i j \<subseteq> G\<close>]
         wlog[OF \<open>0 < e\<close> \<open>j \<noteq> i\<close> \<open>j \<noteq> 0\<close> \<open>i \<noteq> 0\<close> \<open>B j i \<subseteq> G\<close>]
    have "eventually (\<lambda>u. norm ((u * u) *\<^sub>R f'' j i - (u * u) *\<^sub>R f'' i j)
         \<le> u * u * e * (5 * norm j + 5 * norm i)) ?F"
    proof eventually_elim
      case (elim u)
      have "norm ((u * u) *\<^sub>R f'' j i - (u * u) *\<^sub>R f'' i j) =
        norm (f (a + u *\<^sub>R j + u *\<^sub>R i) - f (a + u *\<^sub>R j) -
         (f (a + u *\<^sub>R i) - f a) - (u * u) *\<^sub>R f'' i j
         - (f (a + u *\<^sub>R i + u *\<^sub>R j) - f (a + u *\<^sub>R i) -
         (f (a + u *\<^sub>R j) - f a) -
         (u * u) *\<^sub>R f'' j i))" by (simp add: field_simps)
      also have "\<dots> \<le> u * u * e * (2 * norm j + 3 * norm i) + u * u * e * (3 * norm j + 2 * norm i)"
        using elim by (intro order_trans[OF norm_triangle_ineq4]) (auto simp: ac_simps intro: add_mono)
      finally show ?case by (simp add: algebra_simps)
    qed
    hence "eventually (\<lambda>u. norm ((u * u) *\<^sub>R (f'' j i - f'' i j)) \<le>
        u * u * e * (5 * norm j + 5 * norm i)) ?F"
      by (simp add: algebra_simps)
    hence "eventually (\<lambda>u. (u * u) * norm ((f'' j i - f'' i j)) \<le>
        (u * u) * (e * (5 * norm j + 5 * norm i))) ?F"
      by (simp add: ac_simps)
    hence "eventually (\<lambda>u. norm ((f'' j i - f'' i j)) \<le> e * (5 * norm j + 5 * norm i)) ?F"
      unfolding mult_le_cancel_left eventually_at_filter
      by eventually_elim auto
    then show ?thesis
      by (auto simp add:eventually_at dist_norm dest!: bspec[where x="d/2" for d])
  qed
  have e: "norm (f'' j i - f'' i j) < e" if "0 < e" for e::real
  proof -
    let ?e = "e/2/(5 * norm j + 5 * norm i)"
    have "?e > 0" using \<open>0 < e\<close> \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> by (auto intro!: divide_pos_pos add_pos_pos)
    from e'[OF this] have "norm (f'' j i - f'' i j) \<le> ?e * (5 * norm j + 5 * norm i)" .
    also have "\<dots> = e / 2" using \<open>i \<noteq> 0\<close> \<open>j \<noteq> 0\<close> by (auto simp: ac_simps add_nonneg_eq_0_iff)
    also have "\<dots> < e" using \<open>0 < e\<close> by simp
    finally show ?thesis .
  qed
  have "norm (f'' j i - f'' i j) = 0"
  proof (rule ccontr)
    assume "norm (f'' j i - f'' i j) \<noteq> 0"
    hence "norm (f'' j i - f'' i j) > 0" by simp
    from e[OF this] show False by simp
  qed
  thus ?thesis by simp
qed

locale second_derivative_within =
  fixes f f' f'' a G
  assumes first_fderiv[derivative_intros]:
    "\<And>a. a \<in> G \<Longrightarrow> (f has_derivative blinfun_apply (f' a)) (at a within G)"
  assumes in_G: "a \<in> G"
  assumes second_fderiv[derivative_intros]:
    "(f' has_derivative blinfun_apply f'') (at a within G)"
begin

lemma symmetric_second_derivative_within:
  assumes "a \<in> G"
  assumes "\<And>s t. s \<in> {0..1} \<Longrightarrow> t \<in> {0..1} \<Longrightarrow> a + s *\<^sub>R i + t *\<^sub>R j \<in> G"
  shows "f'' i j = f'' j i"
  apply (cases "i = j \<or> i = 0 \<or> j = 0")
    apply (force simp add: blinfun.zero_right blinfun.zero_left)
  using first_fderiv _ _ _ _ assms
  by (rule symmetric_second_derivative_aux[symmetric])
    (auto intro!: derivative_eq_intros simp: blinfun.bilinear_simps assms)

end

locale second_derivative =
  fixes f::"'a::real_normed_vector \<Rightarrow> 'b::banach"
    and f' :: "'a \<Rightarrow> 'a \<Rightarrow>\<^sub>L 'b"
    and f'' :: "'a \<Rightarrow>\<^sub>L 'a \<Rightarrow>\<^sub>L 'b"
    and a :: 'a
    and G :: "'a set"
  assumes first_fderiv[derivative_intros]:
    "\<And>a. a \<in> G \<Longrightarrow> (f has_derivative f' a) (at a)"
  assumes in_G: "a \<in> interior G"
  assumes second_fderiv[derivative_intros]:
    "(f' has_derivative f'') (at a)"
begin

lemma symmetric_second_derivative:
  assumes "a \<in> interior G"
  shows "f'' i j = f'' j i"
proof -
  from assms have "a \<in> G"
    using interior_subset by blast
  interpret second_derivative_within
    by unfold_locales
      (auto intro!: derivative_intros intro: has_derivative_at_within \<open>a \<in> G\<close>)
  from assms open_interior[of G] interior_subset[of G]
  obtain e where e: "e > 0" "\<And>y. dist y a < e \<Longrightarrow> y \<in> G"
    by (force simp: open_dist)
  define e' where "e' = e / 3"
  define i' j' where "i' = e' *\<^sub>R i /\<^sub>R norm i" and "j' = e' *\<^sub>R j /\<^sub>R norm j"
  hence "norm i' \<le> e'" "norm j' \<le> e'"
    by (auto simp: field_simps e'_def \<open>0 < e\<close> less_imp_le)
  hence "\<bar>s\<bar> \<le> 1 \<Longrightarrow> \<bar>t\<bar> \<le> 1 \<Longrightarrow> norm (s *\<^sub>R i' + t *\<^sub>R j') \<le> e' + e'" for s t
    by (intro norm_triangle_le[OF add_mono])
      (auto intro!: order_trans[OF mult_left_le_one_le])
  also have "\<dots> < e" by (simp add: e'_def \<open>0 < e\<close>)
  finally
  have "f'' $ i' $ j' = f'' $ j' $ i'"
    by (intro symmetric_second_derivative_within \<open>a \<in> G\<close> e)
      (auto simp add: dist_norm)
  thus ?thesis
    using e(1)
    by (auto simp: i'_def j'_def e'_def
      blinfun.zero_right blinfun.zero_left
      blinfun.scaleR_left blinfun.scaleR_right algebra_simps)
qed

end

lemma
  uniform_explicit_remainder_taylor_1:
  fixes f::"'a::{banach,heine_borel,perfect_space} \<Rightarrow> 'b::banach"
  assumes f'[derivative_intros]: "\<And>x. x \<in> G \<Longrightarrow> (f has_derivative blinfun_apply (f' x)) (at x)"
  assumes f'_cont: "\<And>x. x \<in> G \<Longrightarrow> isCont f' x"
  assumes "open G"
  assumes "J \<noteq> {}" "compact J" "J \<subseteq> G"
  assumes "e > 0"
  obtains d R
  where "d > 0"
    "\<And>x z. f z = f x + f' x (z - x) + R x z"
    "\<And>x y. x \<in> J \<Longrightarrow> y \<in> J \<Longrightarrow> dist x y < d \<Longrightarrow> norm (R x y) \<le> e * dist x y"
    "continuous_on (G \<times> G) (\<lambda>(a, b). R a b)"
proof -
  from assms have "continuous_on G f'" by (auto intro!: continuous_at_imp_continuous_on)
  note [continuous_intros] = continuous_on_compose2[OF this]
  define R where "R x z = f z - f x - f' x (z - x)" for x z
  from compact_in_open_separated[OF \<open>J \<noteq> {}\<close> \<open>compact J\<close> \<open>open G\<close> \<open>J \<subseteq> G\<close>]
  obtain \<eta> where \<eta>: "0 < \<eta>" "{x. infdist x J \<le> \<eta>} \<subseteq> G" (is "?J' \<subseteq> _")
    by auto
  hence infdist_in_G: "infdist x J \<le> \<eta> \<Longrightarrow> x \<in> G" for x
    by auto
  have dist_in_G: "\<And>y. dist x y < \<eta> \<Longrightarrow> y \<in> G" if "x \<in> J" for x
    by (auto intro!: infdist_in_G infdist_le2 that simp: dist_commute)

  have "compact ?J'" by (rule compact_infdist_le; fact)
  let ?seg = ?J'
  from \<open>continuous_on G f'\<close>
  have ucont: "uniformly_continuous_on ?seg f'"
    using \<open>?seg \<subseteq> G\<close>
    by (auto intro!: compact_uniformly_continuous \<open>compact ?seg\<close> intro: continuous_on_subset)

  define e' where "e' = e / 2"
  have "e' > 0" using \<open>e > 0\<close> by (simp add: e'_def)
  from ucont[unfolded uniformly_continuous_on_def, rule_format, OF \<open>0 < e'\<close>]
  obtain du where du:
    "du > 0"
    "\<And>x y. x \<in> ?seg \<Longrightarrow> y \<in> ?seg \<Longrightarrow> dist x y < du \<Longrightarrow> norm (f' x - f' y) < e'"
    by (auto simp: dist_norm)
  have "min \<eta> du > 0" using \<open>du > 0\<close> \<open>\<eta> > 0\<close> by simp
  moreover
  have "f z = f x + f' x (z - x) + R x z" for x z
    by (auto simp: R_def)
  moreover
  {
    fix x z::'a
    assume "x \<in> J" "z \<in> J"
    hence "x \<in> G" "z \<in> G" using assms by auto

    assume "dist x z < min \<eta> du"
    hence d_eta: "dist x z < \<eta>" and d_du: "dist x z < du"
      by (auto simp add: min_def split: if_split_asm)

    from \<open>dist x z < \<eta>\<close> have line_in:
      "\<And>xa. 0 \<le> xa \<Longrightarrow> xa \<le> 1 \<Longrightarrow> x + xa *\<^sub>R (z - x) \<in> G"
      "(\<lambda>xa. x + xa *\<^sub>R (z - x)) ` {0..1} \<subseteq> G"
      by (auto intro!: dist_in_G \<open>x \<in> J\<close> le_less_trans[OF mult_left_le_one_le]
        simp: dist_norm norm_minus_commute)

    have "R x z = f z - f x - f' x (z - x)"
      by (simp add: R_def)
    also have "f z - f x = f (x + (z - x)) - f x" by simp
    also have "f (x + (z - x)) - f x = integral {0..1} (\<lambda>t. (f' (x + t *\<^sub>R (z - x))) (z - x))"
      using \<open>dist x z < \<eta>\<close>
      by (intro mvt_integral[of "ball x \<eta>" f f' x "z - x"])
        (auto simp: dist_norm norm_minus_commute at_within_ball \<open>0 < \<eta>\<close> mem_ball
          intro!: le_less_trans[OF mult_left_le_one_le] derivative_eq_intros dist_in_G \<open>x \<in> J\<close>)
    also have
      "(integral {0..1} (\<lambda>t. (f' (x + t *\<^sub>R (z - x))) (z - x)) - (f' x) (z - x)) =
        integral {0..1} (\<lambda>t. f' (x + t *\<^sub>R (z - x)) - f' x) (z - x)"
      by (simp add: Henstock_Kurzweil_Integration.integral_diff integral_linear[where h="\<lambda>y. blinfun_apply y (z - x)", simplified o_def]
        integrable_continuous_real continuous_intros line_in
        blinfun.bilinear_simps[symmetric])
    finally have "R x z = integral {0..1} (\<lambda>t. f' (x + t *\<^sub>R (z - x)) - f' x) (z - x)"
      .
    also have "norm \<dots> \<le> norm (integral {0..1} (\<lambda>t. f' (x + t *\<^sub>R (z - x)) - f' x)) * norm (z - x)"
      by (auto intro!: order_trans[OF norm_blinfun])
    also have "\<dots> \<le> e' * (1 - 0) * norm (z - x)"
      using d_eta d_du \<open>0 < \<eta>\<close>
      by (intro mult_right_mono integral_bound)
        (auto simp: dist_norm norm_minus_commute
          intro!: line_in du[THEN less_imp_le] infdist_le2[OF \<open>x \<in> J\<close>] line_in continuous_intros
            order_trans[OF mult_left_le_one_le] le_less_trans[OF mult_left_le_one_le])
    also have "\<dots> \<le> e * dist x z" using \<open>0 < e\<close> by (simp add: e'_def norm_minus_commute dist_norm)
    finally have "norm (R x z) \<le> e * dist x z" .
  }
  moreover
  {
    from f' have f_cont: "continuous_on G f"
      by (rule has_derivative_continuous_on[OF has_derivative_at_within])
    from f'_cont have f'_cont: "continuous_on G f'"
      by (auto intro!: continuous_at_imp_continuous_on)

    note continuous_on_diff2=continuous_on_diff[OF continuous_on_compose[OF continuous_on_snd] continuous_on_compose[OF continuous_on_fst], where s="G \<times> G", simplified]
    have "continuous_on (G \<times> G) (\<lambda>(a, b). f b - f a)"
      by (rule iffD1[OF continuous_on_cong continuous_on_diff2[OF f_cont f_cont]], auto)
    moreover have "continuous_on (G \<times> G) (\<lambda>(a, b). f' a (b - a))"
      by (auto intro!: continuous_intros simp: split_beta')
    ultimately have "continuous_on (G \<times> G) (\<lambda>(a, b). R a b)"
      by (rule iffD1[OF continuous_on_cong[OF refl] continuous_on_diff, rotated], auto simp: R_def)
  }
  ultimately
  show thesis ..
qed

no_notation
  blinfun_apply (infixl "$" 999)
notation vec_nth (infixl "$" 90)

end
