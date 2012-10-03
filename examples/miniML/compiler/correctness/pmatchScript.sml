open HolKernel bossLib boolLib boolSimps listTheory pred_setTheory finite_mapTheory alistTheory lcsymtacs
open MiniMLTheory MiniMLTerminationTheory miscTheory miniMLExtraTheory compileTerminationTheory intLangTheory
val _ = intLib.deprecate_int()
val _ = new_theory "pmatch"
val fsd = full_simp_tac std_ss

(* Characterise MAP-like constants *)

val exps_to_Cexps_MAP = store_thm(
"exps_to_Cexps_MAP",
``∀s es. exps_to_Cexps s es = MAP (exp_to_Cexp s) es``,
gen_tac >> Induct >> rw[exp_to_Cexp_def])

val pes_to_Cpes_MAP = store_thm(
"pes_to_Cpes_MAP",
``∀s pes. pes_to_Cpes s pes = MAP (λ(p,e). let (pvs,Cp) = pat_to_Cpat s [] p in (Cp, exp_to_Cexp s e)) pes``,
gen_tac >> Induct >- rw[exp_to_Cexp_def] >>
Cases >> rw[exp_to_Cexp_def])

val defs_to_Cdefs_MAP = store_thm(
"defs_to_Cdefs_MAP",
``∀s defs. defs_to_Cdefs s defs = (MAP FST defs, MAP (λ(d,vn,e). ([vn],INL (exp_to_Cexp s e))) defs)``,
gen_tac >> Induct >- rw[exp_to_Cexp_def] >>
qx_gen_tac `d` >> PairCases_on `d` >> rw[exp_to_Cexp_def])

val vs_to_Cvs_MAP = store_thm(
"vs_to_Cvs_MAP",
``∀s vs. vs_to_Cvs s vs = MAP (v_to_Cv s) vs``,
gen_tac >> Induct >> rw[v_to_Cv_def])

val env_to_Cenv_MAP = store_thm(
"env_to_Cenv_MAP",
``∀s env. env_to_Cenv s env = MAP (λ(x,v). (x, v_to_Cv s v)) env``,
gen_tac >> Induct >- rw[exp_to_Cexp_def,v_to_Cv_def] >>
Cases >> rw[exp_to_Cexp_def,v_to_Cv_def])

(* fresh_var lemmas *)

val fresh_var_not_in = store_thm("fresh_var_not_in",
``∀s. (∃n. num_to_hex_string n ∉ s) ⇒ fresh_var s ∉ s``,
rw[CompileTheory.fresh_var_def] >>
numLib.LEAST_ELIM_TAC >> fs[] >>
PROVE_TAC[])

val FINITE_has_fresh_string = store_thm(
"FINITE_has_fresh_string",
``∀s. FINITE s ⇒ ∃n. num_to_hex_string n ∉ s``,
rw[] >>
qexists_tac `LEAST n. n ∉ IMAGE num_from_hex_string s` >>
numLib.LEAST_ELIM_TAC >>
conj_tac >- (
  PROVE_TAC[INFINITE_NUM_UNIV,IMAGE_FINITE,NOT_IN_FINITE] ) >>
rw[] >> pop_assum (qspec_then `num_to_hex_string n` mp_tac) >>
rw[SIMP_RULE(srw_ss())[FUN_EQ_THM]bitTheory.num_hex_string])

val NOT_fresh_var = store_thm(
"NOT_fresh_var",
``∀s x. x ∈ s ∧ FINITE s ⇒ x ≠ fresh_var s``,
PROVE_TAC[FINITE_has_fresh_string,fresh_var_not_in])

val fresh_var_not_in_any = store_thm(
"fresh_var_not_in_any",
``FINITE s ∧ t ⊆ s ⇒ fresh_var s ∉ t``,
PROVE_TAC[fresh_var_not_in,SUBSET_DEF,FINITE_has_fresh_string])

(* free vars lemmas *)

val free_vars_remove_mat_vp = store_thm(
"free_vars_remove_mat_vp",
``(∀p fk sk v.
    (free_vars FEMPTY (remove_mat_vp fk sk v p) DIFF {v;fk} =
     free_vars FEMPTY sk DIFF Cpat_vars p DIFF {v;fk})) ∧
  (∀ps fk sk v n.
   (free_vars FEMPTY (remove_mat_con fk sk v n ps) DIFF {v;fk} =
    free_vars FEMPTY sk DIFF BIGUNION (IMAGE Cpat_vars (set ps)) DIFF {v;fk}))``,
ho_match_mp_tac (TypeBase.induction_of(``:Cpat``)) >>
strip_tac >- (
  rw[EXTENSION] >> PROVE_TAC[] ) >>
strip_tac >- (
  rw[EXTENSION] >> PROVE_TAC[] ) >>
strip_tac >- (
  rw[FOLDL_UNION_BIGUNION] >>
  fs[EXTENSION] >> METIS_TAC[] ) >>
strip_tac >- (
  rw[EXTENSION] >> PROVE_TAC[] ) >>
rw[LET_THM] >>
qmatch_abbrev_tac `free_vars FEMPTY (remove_mat_vp fk sk0 v0 p) DIFF {v0} UNION {v} DIFF {v; fk} = vs DIFF {v; fk}` >>
simp_tac std_ss [Once EXTENSION] >>
qx_gen_tac `x` >>
fs[] >>
Cases_on `x=v` >> fs[] >>
Cases_on `x=fk` >> fs[] >>
Cases_on `x=v0` >> fs[] >- (
  unabbrev_all_tac >>
  match_mp_tac fresh_var_not_in_any >>
  fs[SUBSET_DEF] ) >>
qpat_assum `∀fk sk v. P = Q` (qspecl_then [`fk`,`sk0`,`v0`] mp_tac) >>
simp_tac std_ss [Once EXTENSION] >>
disch_then (qspec_then `x` mp_tac) >>
fs[] >> strip_tac >>
first_x_assum (qspecl_then [`fk`,`sk`,`v`,`n+1`] mp_tac) >>
simp_tac std_ss [Once EXTENSION] >>
disch_then (qspec_then `x` mp_tac) >>
fs[] >> strip_tac >>
fs[Abbr`vs`] >> PROVE_TAC[])

val free_vars_remove_mat_vp_SUBSET = store_thm(
"free_vars_remove_mat_vp_SUBSET",
``(∀p fk sk v. free_vars FEMPTY (remove_mat_vp fk sk v p) ⊆
  {v;fk} ∪ (free_vars FEMPTY sk DIFF Cpat_vars p)) ∧
(∀ps fk sk v n. free_vars FEMPTY (remove_mat_con fk sk v n ps) ⊆
  {v;fk} ∪ (free_vars FEMPTY sk DIFF BIGUNION (IMAGE Cpat_vars (set ps))))``,
ho_match_mp_tac (TypeBase.induction_of(``:Cpat``)) >>
strip_tac >- (
  rw[SUBSET_DEF] >> rw[] ) >>
strip_tac >- rw[] >>
strip_tac >- rw[FOLDL_UNION_BIGUNION] >>
strip_tac >- rw[] >>
srw_tac[DNF_ss][LET_THM,SUBSET_DEF] >>
res_tac >> fs[] >>
res_tac >> fs[])

val free_vars_remove_mat_var = store_thm(
"free_vars_remove_mat_var",
``∀v pes. free_vars FEMPTY (remove_mat_var v pes) DIFF {v} =
  BIGUNION (IMAGE (λ(p,e). free_vars FEMPTY e DIFF Cpat_vars p) (set pes)) DIFF {v}``,
ho_match_mp_tac remove_mat_var_ind >>
strip_tac >- rw[remove_mat_var_def] >>
rw[remove_mat_var_def] >>
rw[] >>
full_simp_tac std_ss [EXTENSION,IN_UNION,IN_DIFF,IN_SING] >>
qx_gen_tac `x` >>
Cases_on `x=v` >> fsd[] >>
Cases_on `x=fk` >> fsd[] >- (
  `fk ∉ free_vars FEMPTY sk` by (
    unabbrev_all_tac >>
    match_mp_tac fresh_var_not_in_any >>
    fs[SUBSET_DEF] ) >>
  fsd[] >>
  PROVE_TAC[] ) >>
mp_tac (CONJUNCT1 free_vars_remove_mat_vp) >>
fsd[EXTENSION,IN_DIFF,IN_INSERT,IN_SING] >>
metis_tac[])

(* Misc. lemmas *)

val pat_to_Cpat_empty_pvs = store_thm(
"pat_to_Cpat_empty_pvs",
``(∀p m pvs. pat_to_Cpat m pvs p = (FST (pat_to_Cpat m [] p) ++ pvs, SND (pat_to_Cpat m [] p))) ∧
  (∀ps m pvs. pats_to_Cpats m pvs ps = ((FLAT (MAP (FST o pat_to_Cpat m []) ps))++pvs, MAP (SND o pat_to_Cpat m []) ps))``,
ho_match_mp_tac (TypeBase.induction_of``:pat``) >>
strip_tac >- rw[pat_to_Cpat_def] >>
strip_tac >- rw[pat_to_Cpat_def] >>
strip_tac >- rw[pat_to_Cpat_def] >>
strip_tac >- rw[pat_to_Cpat_def] >>
Cases
>- rw[pat_to_Cpat_def]
>- rw[pat_to_Cpat_def] >>
rpt strip_tac >>
simp_tac(srw_ss())[pat_to_Cpat_def,LET_THM] >>
qabbrev_tac `p = pats_to_Cpats m pvs ps` >>
PairCases_on `p` >> fs[] >>
qabbrev_tac `q = pats_to_Cpats m p0 l` >>
PairCases_on `q` >> fs[] >>
qabbrev_tac `r = pats_to_Cpats m [] l` >>
PairCases_on `r` >> fs[] >>
fs[pat_to_Cpat_def,LET_THM] >>
first_x_assum (qspecl_then [`m`,`pvs`] mp_tac) >>
rpt (pop_assum (mp_tac o SYM o SIMP_RULE(srw_ss())[markerTheory.Abbrev_def])) >>
simp_tac(srw_ss())[] >> rpt (disch_then assume_tac) >>
first_assum (qspecl_then [`m`,`p0`] mp_tac) >>
qpat_assum `X = (q0,q1)` mp_tac >>
qpat_assum `X = (r0,r1)` mp_tac >>
simp_tac(srw_ss())[] >> rw[])

(* intermediate language pattern-matching *)

val (Cpmatch_rules,Cpmatch_ind,Cpmatch_cases) = Hol_reln`
  (Cpmatch (CPvar x) v (FEMPTY |+ (x,v))) ∧
  (Cpmatch (CPlit l) (CLitv l) FEMPTY) ∧
  (Cpmatch_list ps vs env
   ⇒ Cpmatch (CPcon n ps) (CConv n vs) env) ∧
  (Cpmatch_list [] [] FEMPTY) ∧
  (Cpmatch p v env ∧ Cpmatch_list ps vs envs
    ⇒ Cpmatch_list (p::ps) (v::vs) (envs ⊌ env))`

val (Cpnomatch_rules,Cpnomatch_ind,Cpnomatch_cases) = Hol_reln`
  (l ≠ l' ⇒ Cpnomatch (CPlit l) (CLitv l')) ∧
  (c ≠ c' ⇒ Cpnomatch (CPcon c ps) (CConv c' vs)) ∧
  (Cpnomatch_list ps vs ⇒
   Cpnomatch (CPcon c ps) (CConv c vs)) ∧
  (Cpnomatch p v ∧ (LENGTH ps = LENGTH vs) ⇒ Cpnomatch_list (p::ps) (v::vs)) ∧
  (Cpmatch p v env ∧ Cpnomatch_list ps vs ⇒ Cpnomatch_list (p::ps) (v::vs))`

val (Cpmatch_error_rules,Cpmatch_error_ind,Cpmatch_error_cases) = Hol_reln`
  (Cpmatch_error (CPlit l) (CConv c vs)) ∧
  (Cpmatch_error (CPlit l) (CRecClos env ns defs n)) ∧
  (Cpmatch_error (CPcon c ps) (CLitv l)) ∧
  (Cpmatch_error (CPcon c ps) (CRecClos env ns defs n)) ∧
  (Cpmatch_list_error ps vs ⇒ Cpmatch_error (CPcon c ps) (CConv c' vs)) ∧
  (Cpmatch_list_error (p::ps) []) ∧
  (Cpmatch_list_error [] (v::vs)) ∧
  (Cpmatch_error p v ⇒ Cpmatch_list_error (p::ps) (v::vs)) ∧
  (Cpmatch_list_error ps vs ⇒ Cpmatch_list_error (p::ps) (v::vs))`

val Cpmatch_NOT_Cpnomatch = store_thm("Cpmatch_NOT_Cpnomatch",
  ``(∀p v env. Cpmatch p v env ⇒ ¬Cpnomatch p v) ∧
    (∀ps vs env. Cpmatch_list ps vs env ⇒ ¬Cpnomatch_list ps vs)``,
  ho_match_mp_tac Cpmatch_ind >>
  strip_tac >- rw[Once Cpnomatch_cases] >>
  strip_tac >- rw[Once Cpnomatch_cases] >>
  strip_tac >- ( rw[] >> rw[Once Cpnomatch_cases] ) >>
  strip_tac >- rw[Once Cpnomatch_cases] >>
  rw[] >> rw[Once Cpnomatch_cases])

val Cpmatch_list_error_LENGTH = store_thm("Cpmatch_list_error_LENGTH",
 ``∀ps vs. LENGTH ps ≠ LENGTH vs ⇒ Cpmatch_list_error ps vs``,
 Induct >> rw[Once Cpmatch_error_cases] >>
 Cases_on `vs` >> fs[])

val Cpmatch_trichotomy = store_thm("Cpmatch_trichotomy",
  ``(∀p v. (∃env. Cpmatch p v env) ∨ Cpnomatch p v ∨ Cpmatch_error p v) ∧
    (∀ps vs.  (∃env. Cpmatch_list ps vs env) ∨ Cpnomatch_list ps vs ∨ Cpmatch_list_error ps vs)``,
  ho_match_mp_tac(TypeBase.induction_of``:Cpat``) >>
  strip_tac >- rw[Once Cpmatch_cases] >>
  strip_tac >- (
    rw[Once Cpmatch_cases] >>
    rw[Once Cpmatch_error_cases] >>
    rw[Once Cpnomatch_cases] >>
    Cases_on `v` >> rw[] >> PROVE_TAC[] ) >>
  strip_tac >- (
    rw[] >>
    rw[Once Cpmatch_cases] >>
    rw[Once Cpnomatch_cases] >>
    rw[Once Cpmatch_error_cases] >>
    Cases_on `v` >> rw[] >>
    Cases_on `m=n` >> rw[]  ) >>
  strip_tac >- (
    rw[Once Cpmatch_cases] >>
    rw[Once Cpnomatch_cases] >>
    rw[Once Cpmatch_error_cases] >>
    Cases_on `vs` >> rw[] >> PROVE_TAC[] ) >>
  rw[] >>
  rw[Once Cpmatch_cases] >>
  rw[Once Cpnomatch_cases] >>
  rw[Once Cpmatch_error_cases] >>
  Cases_on `vs` >> rw[] >>
  PROVE_TAC[Cpmatch_list_error_LENGTH] )

val Cpmatch_determ = store_thm("Cpmatch_determ",
  ``(∀p v env. Cpmatch p v env ⇒ ∀env'. Cpmatch p v env' ⇒ (env' = env)) ∧
    (∀ps vs env. Cpmatch_list ps vs env ⇒ ∀env'. Cpmatch_list ps vs env' ⇒ (env' = env))``,
  ho_match_mp_tac Cpmatch_ind >>
  strip_tac >- rw[Once Cpmatch_cases] >>
  strip_tac >- rw[Once Cpmatch_cases] >>
  strip_tac >- (
    rw[] >>
    first_x_assum match_mp_tac >>
    fs[Once Cpmatch_cases] ) >>
  strip_tac >- rw[Once Cpmatch_cases] >>
  rw[] >>
  pop_assum mp_tac >>
  rw[Once Cpmatch_cases] >>
  PROVE_TAC[])

val (Cevaluate_match_rules,Cevaluate_match_ind,Cevaluate_match_cases) = Hol_reln`
  (Cevaluate_match v [] FEMPTY NONE) ∧
  (Cpmatch p v env
    ⇒ Cevaluate_match v ((p,e)::pes) env (SOME e)) ∧
  (Cpnomatch p v ∧ Cevaluate_match v pes env r
    ⇒ Cevaluate_match v ((p,e)::pes) env r)`

(* correctness *)

val pmatch_Cpmatch = store_thm("pmatch_Cpmatch",
  ``(∀cenv p v env env'. (pmatch cenv p v env = Match (env' ++ env))
      ⇒ ∀m. Cpmatch (SND (pat_to_Cpat m [] p)) (v_to_Cv m v)
              (alist_to_fmap (env_to_Cenv m env'))) ∧
    (∀cenv ps vs env env'. (pmatch_list cenv ps vs env = Match (env' ++ env))
      ⇒ ∀m. Cpmatch_list (SND (pats_to_Cpats m [] ps)) (vs_to_Cvs m vs)
              (alist_to_fmap (env_to_Cenv m env')))``,
  ho_match_mp_tac pmatch_ind >>
  strip_tac >- (
    rw[pmatch_def,bind_def,
       pat_to_Cpat_def,Once Cpmatch_cases,
       env_to_Cenv_MAP,alist_to_fmap_MAP_values,
       alist_to_fmap_def] >> rw[] ) >>
  strip_tac >- (
    rw[pat_to_Cpat_def,Once Cpmatch_cases,v_to_Cv_def,
       pmatch_def,env_to_Cenv_MAP] >> rw[] ) >>
  strip_tac >- (
    fs[pmatch_def] >>
    rpt gen_tac >> strip_tac >>
    Cases_on `ALOOKUP cenv n` >> fs[] >>
    qmatch_assum_rename_tac `ALOOKUP cenv n = SOME p`[] >>
    PairCases_on `p` >> fs[] >>
    Cases_on `ALOOKUP cenv n'` >> fs[] >>
    qmatch_assum_rename_tac `ALOOKUP cenv n' = SOME p`[] >>
    PairCases_on `p` >> fs[] >>
    rw[] >>
    pop_assum mp_tac >> rw[] >>
    rw[pat_to_Cpat_def] >> rw[v_to_Cv_def] >>
    rw[Once Cpmatch_cases] >>
    first_x_assum (qspec_then `m` mp_tac) >> rw[] ) >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- (
    rw[pmatch_def,env_to_Cenv_MAP,pat_to_Cpat_def,vs_to_Cvs_MAP] >>
    rw[Once Cpmatch_cases] ) >>
  strip_tac >- (
    rw[pmatch_def] >>
    pop_assum mp_tac >>
    fs[Once pmatch_nil] >>
    rw[Once (CONJUNCT1 pmatch_nil)] >>
    Cases_on `pmatch cenv p v []` >> fs[] >> rw[] >>
    qmatch_assum_rename_tac `pmatch cenv p v [] = Match env0`[] >>
    Cases_on `pmatch_list cenv ps vs []` >> fs[] >> rw[] >>
    qmatch_assum_rename_tac `pmatch_list cenv ps vs [] = Match env1`[] >>
    fs[Once (Q.INST[`env`|->`env0++env`]pmatch_nil)] >>
    rpt (first_x_assum (qspec_then `m` mp_tac)) >> rw[] >>
    rw[Once Cpmatch_cases] >>
    rw[pat_to_Cpat_def,vs_to_Cvs_MAP] >>
    qabbrev_tac `Cps = pats_to_Cpats m [] ps` >>
    PairCases_on `Cps` >> fs[] >>
    qabbrev_tac `Cp = pat_to_Cpat m Cps0 p` >>
    PairCases_on `Cp` >> fs[] >>
    fs[Once pat_to_Cpat_empty_pvs] >>
    fs[markerTheory.Abbrev_def] >> rw[] >>
    fs[env_to_Cenv_MAP,vs_to_Cvs_MAP] >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[pmatch_def] >>
  rw[pmatch_def])

val pmatch_Cpnomatch = store_thm("pmatch_Cpnomatch",
  ``(∀cenv p v env. good_cenv cenv ∧ (pmatch cenv p v env = No_match)
      ⇒ ∀m. good_cmap cenv m ⇒
            Cpnomatch (SND (pat_to_Cpat m [] p)) (v_to_Cv m v)) ∧
    (∀cenv ps vs env env'. good_cenv cenv ∧ (pmatch_list cenv ps vs env = No_match) ∧ (LENGTH ps = LENGTH vs)
      ⇒ ∀m. good_cmap cenv m ⇒
            Cpnomatch_list (SND (pats_to_Cpats m [] ps)) (vs_to_Cvs m vs))``,
  ho_match_mp_tac pmatch_ind >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- (
    rw[pmatch_def,lit_same_type_def] >>
    pop_assum mp_tac >> BasicProvers.EVERY_CASE_TAC >>
    rw[pat_to_Cpat_def,Once Cpnomatch_cases,v_to_Cv_def] ) >>
  strip_tac >- (
    fs[pmatch_def] >>
    rpt gen_tac >> strip_tac >>
    Cases_on `ALOOKUP cenv n` >> fs[] >>
    qmatch_assum_rename_tac `ALOOKUP cenv n = SOME p`[] >>
    PairCases_on `p` >> fs[] >>
    Cases_on `ALOOKUP cenv n'` >> fs[] >>
    qmatch_assum_rename_tac `ALOOKUP cenv n' = SOME p`[] >>
    PairCases_on `p` >> fs[] >>
    rw[] >>
    pop_assum mp_tac >> rw[] >>
    rw[pat_to_Cpat_def] >> rw[v_to_Cv_def] >>
    rw[Once Cpnomatch_cases]
      >- PROVE_TAC[pairTheory.SND,optionTheory.SOME_11,pairTheory.PAIR_EQ] >>
    fs[good_cenv_def,good_cmap_def] >>
    imp_res_tac ALOOKUP_MEM >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- rw[pmatch_def] >>
  strip_tac >- (
    rw[pmatch_def] >>
    pop_assum mp_tac >>
    pop_assum mp_tac >>
    fs[Once pmatch_nil] >>
    rw[Once (CONJUNCT1 pmatch_nil)] >>
    Cases_on `pmatch cenv p v []` >> fs[] >> rw[] >- (
      rw[pat_to_Cpat_def,vs_to_Cvs_MAP] >>
      rw[Once Cpnomatch_cases] >>
      fs[Once pat_to_Cpat_empty_pvs] >>
      rw[]) >>
    qpat_assum `X = No_match` mp_tac >>
    simp_tac(srw_ss())[Once (CONJUNCT1 pmatch_nil)] >>
    rw[] >>
    rw[pat_to_Cpat_def,vs_to_Cvs_MAP] >>
    rw[Once Cpnomatch_cases] >>
    fs[Once pat_to_Cpat_empty_pvs] >>
    fs[vs_to_Cvs_MAP] >> rw[] >>
    `l = l ++ []` by rw[] >>
    qpat_assum `x = Match l` mp_tac >>
    pop_assum SUBST1_TAC >> strip_tac >>
    imp_res_tac pmatch_Cpmatch >>
    pop_assum (qspec_then `m` mp_tac) >>
    rw[] >>
    disj2_tac >>
    qexists_tac`alist_to_fmap (env_to_Cenv m l)` >> rw[] >>
    first_x_assum (match_mp_tac o MP_CANON) >>
    rw[Once pmatch_nil] ) >>
  strip_tac >- rw[pmatch_def] >>
  rw[pmatch_def])

val matchres_def = Define`
  matchres env cenv env' e r = ∃env''. (env' = env'' ++ env) ∧ (r = Rval (env'',e))`

val evaluate_match_with_Cevaluate_match = store_thm("evaluate_match_with_Cevaluate_match",
  ``∀pes r. evaluate_match_with (matchres env) cenv env v pes r ⇒
      ∀m. good_cenv cenv ∧ good_cmap cenv m ⇒
        ((r = Rerr (Rraise Bind_error))
            ⇒ Cevaluate_match (v_to_Cv m v)
                (MAP (λ(p,e). (SND (pat_to_Cpat m [] p),e)) pes)
                FEMPTY NONE) ∧
        ∀env' e. (r = Rval (env',e))
          ⇒ Cevaluate_match (v_to_Cv m v)
              (MAP (λ(p,e). (SND (pat_to_Cpat m [] p),e)) pes)
              (alist_to_fmap (env_to_Cenv m env')) (SOME e)``,
  ho_match_mp_tac evaluate_match_with_ind >>
  strip_tac >- ( rw[] >> rw[Once Cevaluate_match_cases] ) >>
  strip_tac >- (
    rw[] >> rw[Once Cevaluate_match_cases] >>
    fs[matchres_def] >>
    PROVE_TAC[pmatch_Cpmatch] ) >>
  strip_tac >- (
    rw[] >>
    rw[Once Cevaluate_match_cases] >>
    PROVE_TAC[pmatch_Cpnomatch] ) >>
  strip_tac >- rw[] >> rw[] )

val evaluate_match_with_matchres = store_thm("evaluate_match_with_matchres",
  ``∀pes r. evaluate_match_with P cenv env v pes r ⇒
            (r ≠ Rerr Rtype_error) ⇒
            ((r = Rerr (Rraise Bind_error)) ∧
             evaluate_match_with (matchres env) cenv env v pes (Rerr (Rraise Bind_error))) ∨
            ∃menv mr. evaluate_match_with (matchres env) cenv env v pes (Rval (menv,mr)) ∧
                      P cenv (menv++env) mr r``,
  ho_match_mp_tac evaluate_match_with_ind >>
  strip_tac >- rw[Once evaluate_match_with_cases] >>
  strip_tac >- (
    rw[] >>
    disj2_tac >>
    rw[Once evaluate_match_with_cases] >>
    rw[matchres_def] >>
    fs[Once pmatch_nil] >>
    Cases_on `pmatch cenv p v []` >>fs[] >>
    PROVE_TAC[] ) >>
  strip_tac >- (
    rw[] >> fs[] >>
    rw[Once evaluate_match_with_cases] >>
    disj2_tac >>
    rw[Once evaluate_match_with_cases] >>
    PROVE_TAC[] ) >>
  strip_tac >- rw[] >>
  rw[])

val evaluate_match_with_matchres_closed = store_thm("evaluate_match_with_matchres_closed",
  ``∀pes r. evaluate_match_with (matchres env) cenv env v pes r ⇒
            EVERY closed (MAP SND env) ∧ closed v ⇒
            every_result (λ(menv,mr). EVERY closed (MAP SND menv) ∧
                                      ∃p. MEM (p,mr) pes ∧
                                          (set (MAP FST menv) = pat_vars p)) r ``,
  ho_match_mp_tac evaluate_match_with_ind >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[matchres_def] >>
    fs[] >>
    fs[Once pmatch_nil] >>
    Cases_on `pmatch cenv p v []` >> fs[] >>
    qspecl_then [`cenv`,`p`,`v`,`[]`] mp_tac (CONJUNCT1 pmatch_closed) >>
    fs[] >> fsrw_tac[DNF_ss][] ) >>
  strip_tac >- (
    rw[] >> fs[] >>
    Cases_on `r` >> fs[] >>
    fs[pairTheory.UNCURRY] >>
    fsrw_tac[DNF_ss][] >> PROVE_TAC[]) >>
  strip_tac >- rw[] >>
  rw[])

val Cevaluate_match_MAP_exp = store_thm("Cevaluate_match_MAP_exp",
  ``∀pes env r. Cevaluate_match v pes env r ⇒
      ∀f. Cevaluate_match v (MAP (λ(p,e). (p, f e)) pes) env (OPTION_MAP f r)``,
  ho_match_mp_tac Cevaluate_match_ind >>
  strip_tac >- rw[Once Cevaluate_match_rules] >>
  strip_tac >- rw[Once Cevaluate_match_cases] >>
  rw[] >>
  rw[Once Cevaluate_match_cases])

val Cpmatch_list_LENGTH = store_thm("Cpmatch_list_LENGTH",
  ``∀ps vs menv. Cpmatch_list ps vs menv ⇒ (LENGTH ps = LENGTH vs)``,
  Induct >> rw[Once Cpmatch_cases] >> rw[] >> PROVE_TAC[])

val Cpmatch_list_nil = store_thm("Cpmatch_list_nil",
  ``(Cpmatch_list [] vs e = ((vs = []) ∧ (e = FEMPTY))) ∧
    (Cpmatch_list ps [] e = ((ps = []) ∧ (e = FEMPTY)))``,
  rw[Once Cpmatch_cases] >>
  rw[Once Cpmatch_cases] )
val _ = export_rewrites["Cpmatch_list_nil"]

val Cpmatch_list_APPEND = store_thm("Cpmatch_list_APPEND",
  ``∀p0 p1 vs e. Cpmatch_list (p0 ++ p1) vs e =
            ∃e0 e1. Cpmatch_list p0 (TAKE (LENGTH p0) vs) e0 ∧
                    Cpmatch_list p1 (DROP (LENGTH p0) vs) e1 ∧
                    (e = e1 ⊌ e0)``,
  Induct >- (
    rw[Once Cpmatch_cases] >>
    rw[FUNION_FEMPTY_2] >>
    Cases_on `p1` >> fs[] >>
    rw[Once Cpmatch_cases,SimpRHS] ) >>
  rw[Once Cpmatch_cases] >>
  Cases_on `vs` >> fs[] >>
  rw[Once Cpmatch_cases,SimpRHS] >>
  srw_tac[DNF_ss][FUNION_ASSOC] >>
  PROVE_TAC[])

val Cpmatch_FDOM = store_thm("Cpmatch_FDOM",
  ``(∀p v env. Cpmatch p v env ⇒ (FDOM env = Cpat_vars p)) ∧
    (∀ps vs env. Cpmatch_list ps vs env ⇒ (FDOM env = BIGUNION (IMAGE Cpat_vars (set ps))))``,
  ho_match_mp_tac Cpmatch_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[FOLDL_UNION_BIGUNION] >>
  strip_tac >- rw[] >>
  rw[UNION_COMM])

val Cpmatch_closed = store_thm("Cpmatch_closed",
  ``(∀p v e. Cpmatch p v e ⇒ Cclosed c v ⇒ ∀v. v ∈ FRANGE e ⇒ Cclosed c v) ∧
    (∀ps vs e. Cpmatch_list ps vs e ⇒ EVERY (Cclosed c) vs ⇒ ∀v. v ∈ FRANGE e ⇒ Cclosed c v)``,
  ho_match_mp_tac Cpmatch_ind >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (rw[] >> fs[Once Cclosed_cases]) >>
  rw[] >>
  fsrw_tac[DNF_ss][FRANGE_DEF,FUNION_DEF] >>
  rw[])

val Cpmatch_strongind = theorem"Cpmatch_strongind"

val Cpmatch_remove_mat = store_thm("Cpmatch_remove_mat",
  ``(∀p v menv. Cpmatch p v menv ⇒
       ∀env x fk e r0.
         (FLOOKUP env x = SOME v) ∧ fk ∈ FDOM env ∧ x ∉ Cpat_vars p ∧
         Cclosed FEMPTY v ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed FEMPTY v) ∧
         free_vars FEMPTY e ⊆ Cpat_vars p ∪ FDOM env ∧
         Cevaluate FEMPTY (menv ⊌ env) e r0
       ⇒ ∃r. Cevaluate FEMPTY env (remove_mat_vp fk e x p) r ∧
             result_rel (syneq FEMPTY) r r0) ∧
    (∀ps vs menv. Cpmatch_list ps vs menv ⇒
       ∀env x c vs0 ps0 menv0 fk e r0.
         (FLOOKUP env x = SOME (CConv c (vs0++vs))) ∧
         fk ∈ FDOM env ∧
         x ∉ BIGUNION (IMAGE Cpat_vars (set (ps0++ps))) ∧
         EVERY (Cclosed FEMPTY) (vs0++vs) ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed FEMPTY v) ∧
         free_vars FEMPTY e ⊆ BIGUNION (IMAGE Cpat_vars (set (ps0++ps))) ∪ FDOM env ∧
         Cpmatch_list ps0 vs0 menv0 ∧
         Cevaluate FEMPTY (menv ⊌ menv0 ⊌ env) e r0
       ⇒ ∃r. Cevaluate FEMPTY (menv0 ⊌ env) (remove_mat_con fk e x (LENGTH ps0) ps) r ∧
             result_rel (syneq FEMPTY) r r0)``,
  ho_match_mp_tac Cpmatch_strongind >>
  strip_tac >- (
    rw[remove_mat_var_def] >>
    rw[Once Cevaluate_cases] >>
    fs[FLOOKUP_DEF] >>
    fs[FUNION_FUPDATE_1,FUNION_FEMPTY_1] >>
    PROVE_TAC[result_rel_refl,syneq_refl]) >>
  strip_tac >- (
    rw[remove_mat_vp_def] >>
    fs[FLOOKUP_DEF] >>
    rw[Once Cevaluate_cases] >>
    srw_tac[DNF_ss][] >>
    disj1_tac >>
    CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `T` >>
    fs[FUNION_FEMPTY_1] >>
    rw[Once Cevaluate_cases] >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
    PROVE_TAC[result_rel_refl,syneq_refl]) >>
  strip_tac >- (
    rw[] >>
    rw[Once Cevaluate_cases] >>
    srw_tac[DNF_ss][] >>
    disj1_tac >>
    CONV_TAC SWAP_EXISTS_CONV >> qexists_tac `T` >>
    fs[] >>
    fs[RIGHT_EXISTS_AND_THM,GSYM CONJ_ASSOC] >>
    conj_tac >- (
      rw[Once Cevaluate_cases] >>
      fs[FLOOKUP_DEF] ) >>
    `0 = LENGTH ([]:Cpat list)` by rw[] >> pop_assum SUBST1_TAC >>
    `env = FEMPTY ⊌ env` by rw[FUNION_FEMPTY_1] >> pop_assum SUBST1_TAC >>
    first_x_assum (match_mp_tac o MP_CANON) >>
    fs[FOLDL_UNION_BIGUNION] >>
    rw[FUNION_FEMPTY_2] >>
    fs[Once Cclosed_cases]) >>
  strip_tac >- (
    rw[FUNION_FEMPTY_1] >>
    PROVE_TAC[result_rel_refl,syneq_refl] ) >>
  rpt gen_tac >> strip_tac >>
  rpt gen_tac >> strip_tac >>
  rw[LET_THM] >>
  rw[Once Cevaluate_cases] >>
  srw_tac[DNF_ss][] >>
  disj1_tac >>
  rw[Once Cevaluate_cases] >>
  srw_tac[DNF_ss][] >>
  disj2_tac >>
  map_every (fn q => CONV_TAC SWAP_EXISTS_CONV >> qexists_tac q) [`c`,`vs0++v::vs`] >>
  `x ∈ FDOM env` by fs[FLOOKUP_DEF] >>
  `LENGTH ps0 = LENGTH vs0` by imp_res_tac Cpmatch_list_LENGTH >>
  fs[] >>
  fs[RIGHT_EXISTS_AND_THM,GSYM CONJ_ASSOC] >>
  conj_tac >- (
    imp_res_tac Cpmatch_FDOM >>
    fsrw_tac[DNF_ss][FUNION_DEF] >>
    rw[] >> fs[FLOOKUP_DEF] >>
    PROVE_TAC[] ) >>
  fs[rich_listTheory.EL_LENGTH_APPEND] >>
  first_x_assum (qspecl_then [`env`,`x`,`c`,`vs0 ++ [v]`,`ps0++[p]`,`menv ⊌ menv0`,`fk`,`e`,`r0`] mp_tac) >>
  fs[] >>
  fs[FUNION_ASSOC] >>
  fs[Cpmatch_list_APPEND] >>
  fs[rich_listTheory.FIRSTN_LENGTH_APPEND] >>
  fs[rich_listTheory.BUTFIRSTN_LENGTH_APPEND] >>
  simp_tac(srw_ss())[Q.SPEC`[p]`(CONJUNCT2 Cpmatch_cases)] >>
  fsrw_tac[DNF_ss][] >>
  fs[FUNION_FEMPTY_1] >>
  fsrw_tac[DNF_ss][CONJ_ASSOC] >>
  qho_match_abbrev_tac `(∀x y. P x y ⇒ Q x y) ⇒ R` >>
  strip_tac >>
  `Q menv0 menv` by (
    pop_assum match_mp_tac >>
    unabbrev_all_tac >>
    rw[] >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    PROVE_TAC[] ) >>
  pop_assum mp_tac >> pop_assum kall_tac >>
  unabbrev_all_tac >> rw[] >>
  qmatch_abbrev_tac `∃r. Cevaluate FEMPTY env' (remove_mat_vp fk e' x' p) r ∧ result_rel (syneq FEMPTY) r r0` >>
  first_x_assum (qspecl_then [`env'`,`x'`,`fk`,`e'`] mp_tac) >>
  fs[FLOOKUP_DEF,Abbr`env'`] >>
  `x' ∉ Cpat_vars p` by (
    unabbrev_all_tac >>
    match_mp_tac fresh_var_not_in_any >>
    rw[] ) >>
  `x' ∉ FDOM menv` by metis_tac[Cpmatch_FDOM] >>
  fs[FUNION_FUPDATE_2,FUNION_ASSOC] >>
  fs[GSYM AND_IMP_INTRO] >>
  fs[RIGHT_FORALL_IMP_THM] >>
  qmatch_abbrev_tac `(P ⇒ Q) ⇒ R` >>
  `P` by (
    unabbrev_all_tac >>
    fsrw_tac[DNF_ss][] >>
    match_mp_tac IN_FRANGE_DOMSUB_suff >>
    match_mp_tac IN_FRANGE_FUNION_suff >>
    fs[] >>
    imp_res_tac Cpmatch_closed ) >>
  fs[] >> pop_assum kall_tac >>
  unabbrev_all_tac >>
  qmatch_abbrev_tac `(P ⇒ Q) ⇒ R` >>
  `P` by (
    unabbrev_all_tac >>
    qspecl_then [`ps`,`fk`,`e`,`x`,`LENGTH vs0 + 1`] mp_tac
      (CONJUNCT2 free_vars_remove_mat_vp_SUBSET) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    imp_res_tac Cpmatch_FDOM >>
    fsrw_tac[DNF_ss][] >>
    metis_tac[] ) >>
  fs[] >> pop_assum kall_tac >>
  unabbrev_all_tac >>
  qho_match_abbrev_tac `(∀r. P r ⇒ Q r) ⇒ R` >>
  qsuff_tac `∃rx. P rx ∧ result_rel (syneq FEMPTY) r rx` >- (
    rw[] >>
    `Q rx` by metis_tac[] >>
    unabbrev_all_tac >>
    fs[] >>
    metis_tac[result_rel_syneq_trans,result_rel_syneq_sym]) >>
  unabbrev_all_tac >>
  rw[] >>
  match_mp_tac Cevaluate_FUPDATE >>
  fs[] >>
  imp_res_tac Cpmatch_FDOM >>
  qspecl_then [`ps`,`fk`,`e`,`x`,`LENGTH vs0 + 1`] mp_tac
    (CONJUNCT2 free_vars_remove_mat_vp_SUBSET) >>
  strip_tac >>
  fsrw_tac[DNF_ss][SUBSET_DEF] >>
  conj_tac >- metis_tac[] >>
  conj_tac >- (
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    imp_res_tac Cpmatch_closed >> fs[] >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] ) >>
  match_mp_tac fresh_var_not_in_any >>
  fsrw_tac[DNF_ss][SUBSET_DEF] >>
  metis_tac[])

val Cpnomatch_strongind = theorem"Cpnomatch_strongind"

val Cpnomatch_remove_mat = store_thm("Cpnomatch_remove_mat",
  ``(∀p v. Cpnomatch p v ⇒
       ∀env x fk e r0.
         (FLOOKUP env x = SOME v) ∧ fk ∈ FDOM env ∧
         x ∉ Cpat_vars p ∧
         fk ∉ Cpat_vars p ∧
         Cclosed FEMPTY v ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed FEMPTY v) ∧
         free_vars FEMPTY e ⊆ Cpat_vars p ∪ FDOM env ∧
         Cevaluate FEMPTY env (CCall (CVar fk) []) r0
         ⇒ ∃r. Cevaluate FEMPTY env (remove_mat_vp fk e x p) r ∧
               result_rel (syneq FEMPTY) r r0) ∧
    (∀ps vs. Cpnomatch_list ps vs ⇒
       ∀env x c ps0 vs0 menv fk e r0.
         (FLOOKUP env x = SOME (CConv c (vs0 ++ vs))) ∧ fk ∈ FDOM env ∧
         x ∉ BIGUNION (IMAGE Cpat_vars (set (ps0 ++ ps))) ∧
         fk ∉ BIGUNION (IMAGE Cpat_vars (set (ps0 ++ ps))) ∧
         EVERY (Cclosed FEMPTY) (vs0 ++ vs) ∧ (∀v. v ∈ FRANGE env ⇒ Cclosed FEMPTY v) ∧
         free_vars FEMPTY e ⊆ BIGUNION (IMAGE Cpat_vars (set (ps0 ++ ps))) ∪ FDOM env ∧
         Cpmatch_list ps0 vs0 menv ∧
         Cevaluate FEMPTY env (CCall (CVar fk) []) r0
         ⇒ ∃r. Cevaluate FEMPTY (menv ⊌ env) (remove_mat_con fk e x (LENGTH ps0) ps) r ∧
               result_rel (syneq FEMPTY) r r0)``,
  ho_match_mp_tac Cpnomatch_ind >>
  strip_tac >- (
    rw[] >>
    rw[Once Cevaluate_cases] >>
    srw_tac[DNF_ss][] >>
    disj1_tac >>
    CONV_TAC SWAP_EXISTS_CONV >>qexists_tac `F` >> fs[] >>
    rw[Once Cevaluate_cases] >>
    fs[FLOOKUP_DEF] >>
    rw[Cevaluate_list_with_Cevaluate,Cevaluate_list_with_cons] >>
    PROVE_TAC[result_rel_refl,syneq_refl]) >>
  strip_tac >- (
    rw[] >>
    rw[Once Cevaluate_cases] >>
    rw[Once Cevaluate_cases] >>
    fsrw_tac[DNF_ss][] >>
    fs[FLOOKUP_DEF] >>
    PROVE_TAC[result_rel_refl,syneq_refl]) >>
  strip_tac >- (
    rw[FLOOKUP_DEF] >>
    rw[Once Cevaluate_cases] >>
    rw[Once Cevaluate_cases] >>
    fsrw_tac[DNF_ss][] >>
    first_x_assum (qspecl_then [`env`,`x`,`c`,`[]`,`[]`,`FEMPTY`,`fk`,`e`] mp_tac) >>
    (* first_x_assum (qspecl_then [`env`,`x`,`c`,`[]`,`fk`,`e`] mp_tac) >> *)
    fs[FUNION_FEMPTY_1] >>
    fs[Once Cclosed_cases,FOLDL_UNION_BIGUNION]) >>
  strip_tac >- (
    rw[FLOOKUP_DEF,LET_THM] >>
    rw[Once Cevaluate_cases] >>
    rw[Once Cevaluate_cases] >>
    rw[Cevaluate_proj] >>
    imp_res_tac Cpmatch_FDOM >>
    Cases_on `x ∈ FDOM menv` >- (
      pop_assum mp_tac >> fs[] >>
      metis_tac[] ) >>
    fs[FUNION_DEF] >>
    imp_res_tac Cpmatch_list_LENGTH >>
    fsrw_tac[ARITH_ss][] >>
    simp_tac std_ss[Once(GSYM APPEND_ASSOC)] >>
    rw[rich_listTheory.EL_LENGTH_APPEND] >>
    Q.PAT_ABBREV_TAC`u = fresh_var (X ∪ free_vars FEMPTY e ∪ Y)` >>
    first_x_assum (qspecl_then [`(menv ⊌ env) |+ (u,v)`,`u`,`fk`] mp_tac) >>
    fs[FAPPLY_FUPDATE_THM] >>
    `∀v. v ∈ FRANGE (menv ⊌ env) ⇒ Cclosed FEMPTY v` by (
      unabbrev_all_tac >>
      match_mp_tac IN_FRANGE_FUNION_suff >>
      imp_res_tac Cpmatch_closed >> fs[] ) >>
    `∀v. v ∈ FRANGE ((menv ⊌ env) \\ u) ⇒ Cclosed FEMPTY v` by (
      match_mp_tac IN_FRANGE_DOMSUB_suff >> rw[]) >>
    `free_vars FEMPTY (CCall (CVar fk) []) ⊆ FDOM env` by rw[] >>
    `u ∉ free_vars FEMPTY (CCall (CVar fk) [])` by (
      unabbrev_all_tac >>
      match_mp_tac fresh_var_not_in_any >>
      rw[] ) >>
    `u ∉ Cpat_vars p` by (
      unabbrev_all_tac >>
      match_mp_tac fresh_var_not_in_any >>
      rw[] ) >>
    qspecl_then [`FEMPTY`,`env`,`CCall (CVar fk) []`,`r0`,`u`,`v`] mp_tac Cevaluate_FUPDATE >>
    `fk ∉ Cpat_vars p` by metis_tac[] >> fs[] >>
    rw[] >>
    fsrw_tac[DNF_ss][] >>
    Q.PAT_ABBREV_TAC`ee= remove_mat_con fk e x n ps` >>
    first_x_assum (qspec_then `ee` mp_tac) >>
    fs[] >>
    Q.PAT_ABBREV_TAC`P = free_vars FEMPTY ee ⊆ X` >>
    `P` by (
      unabbrev_all_tac >>
      qspecl_then [`ps`,`fk`,`e`,`x`,`LENGTH vs0 + 1`] mp_tac
        (CONJUNCT2 free_vars_remove_mat_vp_SUBSET) >>
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      metis_tac[]) >> qunabbrev_tac`P` >> fs[] >>
    qho_match_abbrev_tac `(∀x. P x ⇒ R x) ⇒ Z` >>
    qsuff_tac `∃x. P x ∧ result_rel (syneq FEMPTY) r0 x` >- (
      unabbrev_all_tac >> fs[] >>
      PROVE_TAC[result_rel_syneq_trans,result_rel_syneq_sym] ) >>
    qunabbrev_tac`P` >> fs[] >>
    qho_match_abbrev_tac `∃r1. Cevaluate FEMPTY (env1 |+ (u,v)) exp1 r1 ∧ P r1` >>
    qspecl_then [`FEMPTY`,`env`,`exp1`,`r0`,`u`,`v`] mp_tac Cevaluate_FUPDATE >>
    fs[] >>
    fs[Abbr`P`,Abbr`exp1`,Abbr`env1`] >>
    qspecl_then [`FEMPTY`,`env`,`CCall (CVar fk) []`,`r0`] mp_tac Cevaluate_free_vars_env >>
    fs[] >>
    disch_then (Q.X_CHOOSE_THEN `r2` strip_assume_tac) >>
    qabbrev_tac `env1 = (menv ⊌ env) |+ (u,v)` >>
    qspecl_then [`FEMPTY`,`env1`,`CCall (CVar fk)[]`,`r2`] mp_tac Cevaluate_any_super_env >>
    fs[] >>
    `fk ∈ FDOM env1` by fs[Abbr`env1`] >>
    `DRESTRICT env1 {fk} = DRESTRICT env {fk}` by (
      fs[DRESTRICT_EQ_DRESTRICT] >>
      fs[SUBMAP_DEF,FDOM_DRESTRICT] >>
      fs[Once EXTENSION] >>
      fs[DRESTRICT_DEF] >>
      `env1 ' fk = env ' fk` by (
        rw[Abbr`env1`] >>
        rw[FAPPLY_FUPDATE_THM] >>
        rw[FUNION_DEF] >>
        metis_tac[] ) >>
      fs[] >>
      metis_tac[] ) >>
    fs[] >>
    `∀v. v ∈ FRANGE env1 ⇒ Cclosed FEMPTY v` by (
      unabbrev_all_tac >>
      match_mp_tac IN_FRANGE_FUPDATE_suff >>
      fs[] ) >>
    fs[] >>
    PROVE_TAC[result_rel_syneq_trans,result_rel_syneq_sym]) >>
  rw[FLOOKUP_DEF,LET_THM] >>
  rw[Once Cevaluate_cases] >>
  rw[Once Cevaluate_cases] >>
  rw[Cevaluate_proj] >>
  imp_res_tac Cpmatch_FDOM >>
  Cases_on `x ∈ FDOM menv` >- (
    pop_assum mp_tac >> fs[] >>
    metis_tac[] ) >>
  fs[FUNION_DEF] >>
  imp_res_tac Cpmatch_list_LENGTH >>
  fsrw_tac[ARITH_ss][] >>
  simp_tac std_ss[Once(GSYM APPEND_ASSOC)] >>
  rw[rich_listTheory.EL_LENGTH_APPEND] >>
  qspecl_then [`p`,`v`,`env`] mp_tac (CONJUNCT1 Cpmatch_remove_mat) >>
  fs[] >>
  Q.PAT_ABBREV_TAC`u = fresh_var (X ∪ free_vars FEMPTY e ∪ Y)` >>
  Q.PAT_ABBREV_TAC`ee = remove_mat_con fk e x n ps` >>
  Q.PAT_ABBREV_TAC`env0 = X |+ (u,v)` >>
  disch_then (qspecl_then [`env0`,`u`,`fk`,`ee`] mp_tac) >>
  imp_res_tac Cpmatch_closed >>
  `FLOOKUP env0 u = SOME v` by (unabbrev_all_tac >> fs[FLOOKUP_DEF]) >> fs[] >>
  `fk ∈ FDOM env0` by (unabbrev_all_tac >> fs[]) >> fs[] >>
  `u ∉ Cpat_vars p` by (unabbrev_all_tac >> match_mp_tac fresh_var_not_in_any >> rw[]) >> fs[] >>
  `∀v. v ∈ FRANGE env0 ⇒ Cclosed FEMPTY v` by (
    unabbrev_all_tac >>
    match_mp_tac IN_FRANGE_FUPDATE_suff >>
    asm_simp_tac std_ss[] >>
    match_mp_tac IN_FRANGE_FUNION_suff >>
    fs[] ) >> fs[] >>
  `free_vars FEMPTY ee ⊆ Cpat_vars p ∪ FDOM env0` by (
    unabbrev_all_tac >>
    ntac 4 (pop_assum kall_tac) >>
    qspecl_then [`ps`,`fk`,`e`,`x`,`LENGTH vs0 + 1`] mp_tac
      (CONJUNCT2 free_vars_remove_mat_vp_SUBSET) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    metis_tac[]) >> fs[] >>
  qsuff_tac `∃rx. Cevaluate FEMPTY (env ⊌ env0) ee rx ∧ result_rel (syneq FEMPTY) rx r0` >-
    PROVE_TAC[result_rel_syneq_trans,result_rel_syneq_sym] >>
  first_x_assum (qspecl_then [`env0`,`x`,`c`,`ps0 ++ [p]`,`vs0 ++ [v]`,`env ⊌ menv`,`fk`,`e`] mp_tac) >>
  `x ∈ FDOM env0` by fs[Abbr`env0`] >> fs[] >>
  `env0 ' x = CConv c (vs0 ++ [v] ++ vs)` by (
    qunabbrev_tac`env0` >>
    `u ∉ {x}` by (
      unabbrev_all_tac >>
      match_mp_tac fresh_var_not_in_any >>
      rw[] ) >>
    `x ∉ FDOM env` by metis_tac[] >>
    fs[FAPPLY_FUPDATE_THM,FUNION_DEF]>> fs[] ) >> fs[] >>
  qho_match_abbrev_tac `(∀x. P ∧ Q x ⇒ R x) ⇒ Z` >>
  `P` by (
    unabbrev_all_tac >> rw[] >>
    metis_tac[] ) >> qunabbrev_tac`P` >> fs[] >>
  qunabbrev_tac`Q` >> fs[] >>
  qho_match_abbrev_tac `(∀x. P ∧ Q x ⇒ R x) ⇒ Z` >>
  `P` by (
    unabbrev_all_tac >> rw[] >>
    metis_tac[] ) >> qunabbrev_tac`P` >> fs[] >>
  qunabbrev_tac`Q` >> fs[] >>
  qho_match_abbrev_tac `(∀x. P ∧ Q x ⇒ R x) ⇒ Z` >>
  `P` by (
    unabbrev_all_tac >> rw[] >>
    ntac 10 (pop_assum kall_tac) >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    metis_tac[]) >> qunabbrev_tac`P` >> fs[] >>
  qunabbrev_tac `Q` >> fs[] >>
  fs[Cpmatch_list_APPEND] >>
  fs[rich_listTheory.BUTFIRSTN_LENGTH_APPEND] >>
  fs[rich_listTheory.FIRSTN_LENGTH_APPEND] >>
  simp_tac std_ss[Q.SPEC`[p]` (CONJUNCT2 Cpmatch_cases)] >>
  fsrw_tac[DNF_ss][] >>
  fs[FUNION_FEMPTY_1] >>
  disch_then (mp_tac o Q.SPEC`menv` o CONV_RULE SWAP_FORALL_CONV) >>
  disch_then (mp_tac o Q.SPEC`env` o CONV_RULE SWAP_FORALL_CONV) >>
  fs[] >>
  qunabbrev_tac`R` >> fs[] >>
  qunabbrev_tac`Z` >> fs[] >>
  `u ∉ FDOM env` by (
    unabbrev_all_tac >>
    match_mp_tac fresh_var_not_in_any >>
    fsrw_tac[DNF_ss][SUBSET_DEF] ) >>
  qspecl_then[`FEMPTY`,`env'`,`CCall (CVar fk) []`,`r0`] mp_tac Cevaluate_free_vars_env >>
  fs[] >>
  disch_then (Q.X_CHOOSE_THEN`r2` strip_assume_tac) >>
  `DRESTRICT env0 {fk} = DRESTRICT env' {fk}` by (
    fs[DRESTRICT_EQ_DRESTRICT] >>
    fs[SUBMAP_DEF,DRESTRICT_DEF] >>
    `u ∉ {fk}` by (
      unabbrev_all_tac >>
      match_mp_tac fresh_var_not_in_any >>
      rw[] ) >>
    pop_assum mp_tac >>
    asm_simp_tac (srw_ss())[FAPPLY_FUPDATE_THM] >>
    strip_tac >>
    `fk ∉ FDOM menv` by (
      asm_simp_tac(srw_ss())[] >>
      metis_tac[] ) >>
    `env0 ' fk = env' ' fk` by (
      qunabbrev_tac`env0` >>
      asm_simp_tac(srw_ss())[FUNION_DEF,FAPPLY_FUPDATE_THM] ) >>
    asm_simp_tac(srw_ss())[] >>
    asm_simp_tac(srw_ss())[Once EXTENSION] >>
    qunabbrev_tac`env0` >>
    simp_tac std_ss [FDOM_FUPDATE,FDOM_FUNION] >>
    simp_tac(srw_ss())[] >>
    metis_tac[] ) >>
  qspecl_then[`FEMPTY`,`env0`,`CCall (CVar fk) []`,`r2`] mp_tac Cevaluate_any_super_env >>
  fs[] >>
  disch_then (Q.X_CHOOSE_THEN `r3` strip_assume_tac) >>
  disch_then (qspec_then `r3` mp_tac) >> fs[] >>
  disch_then (Q.X_CHOOSE_THEN `r4` strip_assume_tac) >>
  qspecl_then [`FEMPTY`,`env ⊌ menv ⊌ env0`,`ee`,`r4`] mp_tac Cevaluate_free_vars_env >>
  fs[] >>
  Q.PAT_ABBREV_TAC`P = free_vars FEMPTY ee ⊆ X` >>
  `P` by (
    fsrw_tac[DNF_ss][SUBSET_DEF,Abbr`P`] >>
    metis_tac[] ) >> qunabbrev_tac`P` >> fs[] >>
  qho_match_abbrev_tac`(P ⇒ Q) ⇒ R` >>
  `P` by (
    qunabbrev_tac `P` >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] ) >>
  qunabbrev_tac`P` >> fs[] >>
  qunabbrev_tac`Q`>>qunabbrev_tac`R` >>
  disch_then (Q.X_CHOOSE_THEN `r5` strip_assume_tac) >>
  qspecl_then [`FEMPTY`,`env ⊌ env0`,`ee`,`r5`] mp_tac Cevaluate_any_super_env >>
  fs[] >>
  `DRESTRICT (env ⊌ env0) (free_vars FEMPTY ee) = DRESTRICT (env ⊌ menv ⊌ env0) (free_vars FEMPTY ee)` by (
    qunabbrev_tac`env0` >>
    simp_tac std_ss[GSYM FUNION_ASSOC] >>
    asm_simp_tac std_ss[FUNION_FUPDATE_2] >>
    `u ∉ free_vars FEMPTY ee` by (
      qunabbrev_tac`ee` >>
      qspecl_then [`ps`,`fk`,`e`,`x`,`LENGTH vs0 + 1`] mp_tac (CONJUNCT2 free_vars_remove_mat_vp_SUBSET) >>
      asm_simp_tac (std_ss++DNF_ss) [SUBSET_DEF,IN_UNION,IN_DIFF] >>
      strip_tac >>
      `u ∉ {x;fk}` by (
        qunabbrev_tac`u` >>
        match_mp_tac fresh_var_not_in_any >>
        rw[] ) >>
      `u ∉ free_vars FEMPTY e` by (
        qunabbrev_tac`u` >>
        match_mp_tac fresh_var_not_in_any >>
        rw[] >> rw[SUBSET_DEF]) >>
      metis_tac[] ) >>
    asm_simp_tac std_ss[DRESTRICT_FUPDATE] >>
    simp_tac std_ss[FUNION_ASSOC,FUNION_IDEMPOT] >>
    Cases_on `u ∈ BIGUNION (IMAGE Cpat_vars (set ps0))` >>
    asm_simp_tac std_ss[FUNION_ASSOC] >>
    asm_simp_tac std_ss[FUNION_FUPDATE_2,DRESTRICT_FUPDATE,FUNION_ASSOC] ) >>
  fs[] >>
  qho_match_abbrev_tac`(P ⇒ Q) ⇒ R` >>
  `P` by (
    qunabbrev_tac `P` >>
    match_mp_tac IN_FRANGE_FUNION_suff >> fs[] ) >>
  qunabbrev_tac`P` >> fs[] >>
  metis_tac[result_rel_syneq_trans,result_rel_syneq_sym] )

val Cevaluate_match_strongind = theorem"Cevaluate_match_strongind"

val Cevaluate_match_least_el = store_thm("Cevaluate_match_least_el",
  ``∀pes env r. Cevaluate_match v pes env r ⇒ ∀e. (r = SOME e) ⇒
      ∃i p. i < LENGTH pes ∧ (EL i pes = (p,e)) ∧ Cpmatch p v env ∧
      ∀j. j < i ⇒ Cpnomatch (FST (EL j pes)) v``,
  ho_match_mp_tac Cevaluate_match_ind >>
  rw[] >- ( qexists_tac `0` >> rw[] ) >>
  qexists_tac `SUC i` >> rw[] >>
  Cases_on `j` >> rw[] >>
  fs[])

val Cevaluate_match_NONE_FEMPTY = store_thm("Cevaluate_match_NONE_FEMPTY",
  ``Cevaluate_match v pes env NONE ⇒ (env = FEMPTY)``,
  qsuff_tac `∀pes env r. Cevaluate_match v pes env r ⇒ (r = NONE) ⇒ (env = FEMPTY)` >- PROVE_TAC[] >>
  ho_match_mp_tac Cevaluate_match_ind >> rw[])

val Cevaluate_match_remove_mat_var = store_thm("Cevaluate_match_remove_mat_var",
  ``∀pes menv mr. Cevaluate_match v pes menv mr ⇒
      ∀env x. (FLOOKUP env x = SOME v) ∧
              x ∉ BIGUNION (IMAGE (Cpat_vars o FST) (set pes)) ∧
              BIGUNION (IMAGE (λ(p,e). free_vars FEMPTY e DIFF Cpat_vars p) (set pes)) ⊆ FDOM env ∧
              Cclosed FEMPTY v ∧
              (∀v. v ∈ FRANGE env ⇒ Cclosed FEMPTY v) ⇒
       case mr of
       | NONE => Cevaluate FEMPTY env (remove_mat_var x pes) (Rerr (Rraise Bind_error))
       | SOME e => ∀r0. Cevaluate FEMPTY (menv ⊌ env) e r0 ⇒
           ∃r. Cevaluate FEMPTY env (remove_mat_var x pes) r ∧ result_rel (syneq FEMPTY) r r0``,
  ho_match_mp_tac Cevaluate_match_strongind >>
  strip_tac >- rw[remove_mat_var_def] >>
  strip_tac >- (
    rw[remove_mat_var_def,LET_THM] >>
    rw[Once Cevaluate_cases] >>
    fsrw_tac[DNF_ss][] >>
    Q.PAT_ABBREV_TAC`fk = fresh_var X` >>
    qmatch_abbrev_tac `∃r. Cevaluate FEMPTY ee (remove_mat_vp fk e x p) r ∧ result_rel (syneq FEMPTY) r r0` >>
    qspecl_then [`p`,`v`,`menv`] mp_tac (CONJUNCT1 Cpmatch_remove_mat) >>
    fs[] >>
    disch_then (qspecl_then [`ee`,`x`,`fk`,`e`] mp_tac) >>
    fsrw_tac[DNF_ss][pairTheory.FORALL_PROD] >>
    `fk ∉ {x} ∪ free_vars FEMPTY e` by (
      qunabbrev_tac`fk` >> match_mp_tac fresh_var_not_in_any >> rw[SUBSET_DEF] ) >>
    `FLOOKUP ee x = SOME v` by fs[Abbr`ee`,FLOOKUP_UPDATE] >> fs[] >>
    `fk ∈ FDOM ee` by fs[Abbr`ee`] >> fs[] >>
    `x ∉ Cpat_vars p` by metis_tac[] >> fs[] >>
    `∀v. v ∈ FRANGE ee ⇒ Cclosed FEMPTY v` by (
      unabbrev_all_tac >>
      match_mp_tac IN_FRANGE_FUPDATE_suff  >>
      fs[] >>
      rw[Once Cclosed_cases] >>
      qspecl_then [`x`,`pes`] strip_assume_tac free_vars_remove_mat_var >>
      pop_assum mp_tac >>
      srw_tac[DNF_ss][Once EXTENSION,SUBSET_DEF] >>
      fsrw_tac[DNF_ss][pairTheory.EXISTS_PROD,SUBSET_DEF] >>
      `x ∈ FDOM env` by fs[FLOOKUP_DEF] >>
      fsrw_tac[DNF_ss][pairTheory.FORALL_PROD] >>
      metis_tac[] ) >> fs[] >>
    `free_vars FEMPTY e ⊆ Cpat_vars p ∪ FDOM ee` by (
      fsrw_tac[DNF_ss][SUBSET_DEF] >>
      rw[Abbr`ee`] >>
      metis_tac[] ) >> fs[] >>
    qsuff_tac `∃rx. Cevaluate FEMPTY (menv ⊌ ee) e rx ∧ result_rel (syneq FEMPTY) r0 rx` >-
      metis_tac[result_rel_syneq_trans,result_rel_syneq_sym] >>
    unabbrev_all_tac >>
    Q.PAT_ABBREV_TAC`fv = fresh_var (free_vars FEMPTY X)` >>
    Q.PAT_ABBREV_TAC`fk = fresh_var (a ∪ b)` >>
    Cases_on `fk ∈ FDOM menv` >>
    rw[FUNION_FUPDATE_2] >- metis_tac[result_rel_refl,syneq_refl] >>
    match_mp_tac (MP_CANON Cevaluate_FUPDATE) >>
    fs[] >>
    imp_res_tac Cpmatch_FDOM >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    conj_tac >- PROVE_TAC[] >>
    match_mp_tac IN_FRANGE_FUNION_suff >>
    fs[] >>
    imp_res_tac Cpmatch_closed) >>
  rw[] >>
  rw[remove_mat_var_def] >>
  qspecl_then [`p`,`v`] mp_tac (CONJUNCT1 Cpnomatch_remove_mat) >>
  rw[] >>
  Q.PAT_ABBREV_TAC`ex = CLetfun F [fk] X Y` >>
  qsuff_tac `∀r0. (case mr of NONE => (r0 = Rerr (Rraise Bind_error))
                   | SOME e => Cevaluate FEMPTY (menv ⊌ env) e r0)
                   ⇒ ∃r. Cevaluate FEMPTY env ex r ∧ result_rel (syneq FEMPTY) r r0` >- (
    Cases_on `mr` >> fs[] ) >>
  qx_gen_tac `r0` >>
  strip_tac >>
  qunabbrev_tac`ex` >>
  rw[Once Cevaluate_cases] >>
  Q.PAT_ABBREV_TAC`cl = CRecClos env X Y Z` >>
  Q.PAT_ABBREV_TAC`env1 = env |+ X` >>
  fs[pairTheory.FORALL_PROD] >>
  `x ∉ Cpat_vars p` by metis_tac[] >>
  first_x_assum (qspecl_then [`env1`,`x`,`fk`,`e`] mp_tac) >>
  fs[] >>
  `fk ∉ {x}` by (
    qunabbrev_tac`fk` >>
    match_mp_tac fresh_var_not_in_any >>
    rw[] ) >>
  fs[] >>
  `Cclosed FEMPTY cl` by (
    unabbrev_all_tac >>
    rw[Once Cclosed_cases] >>
    qmatch_abbrev_tac `a ⊆ b ∪ c` >>
    qsuff_tac `a ⊆ b` >- rw[SUBSET_DEF] >>
    qsuff_tac `a DIFF {x} ⊆ b DIFF {x}` >- (
      unabbrev_all_tac >>
      rw[SUBSET_DEF] >>
      fs[FLOOKUP_DEF] >>
      metis_tac[] ) >>
    qunabbrev_tac`a` >>
    rw[free_vars_remove_mat_var] >>
    qunabbrev_tac`b` >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    metis_tac[] ) >>
  `FLOOKUP env1 x = SOME v` by (
    qunabbrev_tac`env1` >>
    rw[FLOOKUP_UPDATE] ) >>
  `fk ∈ FDOM env1` by rw[Abbr`env1`] >>
  `fk ∉ Cpat_vars p` by (
    qunabbrev_tac`fk` >>
    match_mp_tac fresh_var_not_in_any >>
    rw[SUBSET_DEF] ) >>
  `∀v. v ∈ FRANGE env1 ⇒ Cclosed FEMPTY v` by (
    qunabbrev_tac`env1` >>
    match_mp_tac IN_FRANGE_FUPDATE_suff >>
    rw[] ) >>
  `free_vars FEMPTY e ⊆ Cpat_vars p ∪ FDOM env1` by (
    qunabbrev_tac`env1` >>
    fsrw_tac[DNF_ss][SUBSET_DEF] >>
    metis_tac[] ) >>
  fs[] >>
  qsuff_tac
  `∃r1. Cevaluate FEMPTY env1 (CCall (CVar fk) []) r1 ∧
        result_rel (syneq FEMPTY) r1 r0` >-
      metis_tac[result_rel_syneq_trans] >>
  ntac 5 (pop_assum kall_tac) >>
  rw[Once Cevaluate_cases,Abbr`env1`,Abbr`cl`] >>
  rw[Cevaluate_list_with_Cevaluate] >>
  rw[find_index_def] >>
  rw[extend_rec_env_def] >>
  Q.PAT_ABBREV_TAC`fv = fresh_var s` >>
  Q.PAT_ABBREV_TAC`cl = CRecClos env X Y Z` >>
  first_x_assum (qspecl_then [`env`,`x`] mp_tac) >>
  fs[] >>
  qmatch_abbrev_tac `(P ⇒ Q) ⇒ R` >>
  `P` by ( metis_tac[] ) >>
  pop_assum mp_tac >> simp_tac std_ss [] >>
  disch_then kall_tac >> qunabbrev_tac`P` >>
  qunabbrev_tac`Q` >> qunabbrev_tac`R` >>
  `∀r2. Cevaluate FEMPTY env (remove_mat_var x pes) r2 ⇒
   ∃r3. Cevaluate FEMPTY (env |+ (fv,cl)) (remove_mat_var x pes) r3 ∧
        result_rel (syneq FEMPTY) r2 r3` by (
    rw[] >>
    qspecl_then [`FEMPTY`,`env`,`remove_mat_var x pes`,`r2`,`fv`,`cl`] mp_tac Cevaluate_FUPDATE >>
    fs[] >>
    `free_vars FEMPTY (remove_mat_var x pes) ⊆ FDOM env` by (
      qspecl_then [`x`,`pes`] mp_tac free_vars_remove_mat_var >>
      simp_tac(srw_ss()++DNF_ss)[Once EXTENSION,pairTheory.EXISTS_PROD] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,pairTheory.FORALL_PROD] >>
      fs[FLOOKUP_DEF] >>
      metis_tac[] ) >>
    fs[] >>
    metis_tac[fresh_var_not_in,FINITE_has_fresh_string,FINITE_free_vars]) >>
  Cases_on `mr` >> fs[] >- (
    strip_tac >> res_tac >> fs[] ) >>
  metis_tac[result_rel_syneq_trans,result_rel_syneq_sym])

val Cpmatch_syneq = store_thm("Cpmatch_syneq",
  ``(∀p v env. Cpmatch p v env ⇒ ∀c w. syneq c v w ⇒ ∃env'. Cpmatch p w env' ∧ fmap_rel (syneq c) env env') ∧
    (∀ps vs env. Cpmatch_list ps vs env ⇒ ∀c ws. EVERY2 (syneq c) vs ws ⇒ ∃env'. Cpmatch_list ps ws env' ∧ fmap_rel (syneq c) env env')``,
  ho_match_mp_tac Cpmatch_ind >>
  strip_tac >- rw[Once Cpmatch_cases,fmap_rel_def] >>
  strip_tac >- rw[Once Cpmatch_cases,Once syneq_cases] >>
  strip_tac >- (
    rw[Once syneq_cases] >>
    res_tac >>
    rw[Once Cpmatch_cases] ) >>
  strip_tac >- rw[Once Cpmatch_cases] >>
  rw[] >>
  rw[Once Cpmatch_cases] >>
  Cases_on `ws` >> fs[] >>
  res_tac >>
  srw_tac[DNF_ss][] >>
  metis_tac[fmap_rel_FUNION_rels])

val Cpnomatch_syneq = store_thm("Cpnomatch_syneq",
  ``(∀p v. Cpnomatch p v ⇒ ∀c w. syneq c v w ⇒ Cpnomatch p w) ∧
    (∀ps vs. Cpnomatch_list ps vs ⇒ ∀c ws. EVERY2 (syneq c) vs ws ⇒ Cpnomatch_list ps ws)``,
  ho_match_mp_tac Cpnomatch_ind >>
  rw[] >>
  TRY (
    rw[Once Cpnomatch_cases] >>
    fs[Once syneq_cases] >>
    res_tac >> NO_TAC) >>
  Cases_on `ws` >> fs[] >>
  rw[Once Cpnomatch_cases] >>
  fs[EVERY2_EVERY] >>
  metis_tac[Cpmatch_syneq])

val Cevaluate_match_syneq = store_thm("Cevaluate_match_syneq",
  ``∀pes env r. Cevaluate_match v pes env r ⇒
      ∀c w. syneq c v w ⇒ ∃env'. Cevaluate_match w pes env' r ∧ fmap_rel (syneq c) env env'``,
  ho_match_mp_tac Cevaluate_match_ind >>
  strip_tac >- rw[Once Cevaluate_match_cases] >>
  strip_tac >- (
    rw[Once Cevaluate_match_cases] >>
    imp_res_tac Cpmatch_syneq >>
    rw[Once Cevaluate_match_cases] >>
    metis_tac[] ) >>
  rw[] >>
  rw[Once Cevaluate_match_cases] >>
  metis_tac[Cpnomatch_syneq])

val Cevaluate_match_closed = store_thm("Cevaluate_match_closed",
  ``∀pes env r. Cevaluate_match v pes env r ⇒ Cclosed c v ⇒ (∀v. v ∈ FRANGE env ⇒ Cclosed c v)``,
  ho_match_mp_tac Cevaluate_match_ind >>
  rw[Cpmatch_closed] >>
  imp_res_tac Cpmatch_closed)

val _ = export_theory()