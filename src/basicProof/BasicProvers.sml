(*---------------------------------------------------------------------------
       Some proof automation, which moreover has few theory
       dependencies, and so can be used in places where bossLib
       is overkill.
 ---------------------------------------------------------------------------*)

structure BasicProvers :> BasicProvers =
struct

open HolKernel boolLib;
type simpset = simpLib.simpset;


infix THEN THENL ORELSE;

val ERR = mk_HOL_ERR "BasicProvers";

local open simpLib
      infix ++
      val EXPAND_COND_CONV =
           SIMP_CONV (pureSimps.pure_ss ++ boolSimps.COND_elim_ss) []
      val EXPAND_COND_TAC = CONV_TAC EXPAND_COND_CONV
      val EXPAND_COND = CONV_RULE EXPAND_COND_CONV
in
fun PROVE thl tm = Tactical.prove (tm,
  EXPAND_COND_TAC THEN mesonLib.MESON_TAC (map EXPAND_COND thl))

fun PROVE_TAC thl =
  REPEAT (POP_ASSUM MP_TAC)
    THEN EXPAND_COND_TAC
    THEN mesonLib.ASM_MESON_TAC (map EXPAND_COND thl)

fun GEN_PROVE_TAC x y z thl =   (* for ZAP_TAC *)
  REPEAT (POP_ASSUM MP_TAC)
    THEN EXPAND_COND_TAC
    THEN mesonLib.GEN_MESON_TAC x y z (map EXPAND_COND thl)

end;


(*---------------------------------------------------------------------------*
 * When invoked, we know that th is an equality, at least one side of which  *
 * is a variable.                                                            *
 *---------------------------------------------------------------------------*)

fun is_bool_atom tm =
  is_var tm andalso (type_of tm = bool)
  orelse is_neg tm andalso is_var (dest_neg tm);


fun orient th =
 let val c = concl th
 in if is_bool_atom c
    then (if is_neg c then EQF_INTRO th else EQT_INTRO th)
    else let val (lhs,rhs) = dest_eq c
         in if is_var lhs
            then if is_var rhs
                 then case Term.compare (lhs, rhs)
                       of LESS  => SYM th
                        | other => th
                 else th
            else SYM th
         end
 end;


fun VSUBST_TAC tm = UNDISCH_THEN tm (SUBST_ALL_TAC o orient);

fun var_eq tm =
   let val (lhs,rhs) = dest_eq tm
   in
       aconv lhs rhs
     orelse
       (is_var lhs andalso not (mem lhs (free_vars rhs)))
     orelse
       (is_var rhs andalso not (mem rhs (free_vars lhs)))
   end
   handle _ => is_bool_atom tm


fun grab P f v =
  let fun grb [] = v
        | grb (h::t) = if (P h) then f h else grb t
  in grb
  end;

fun ASSUM_TAC f P = W (fn (asl,_) => grab P f NO_TAC asl)

fun ASSUMS_TAC f P = W (fn (asl,_) =>
  case filter P asl
    of []     => NO_TAC
     | assums => MAP_EVERY f assums);

fun CONCL_TAC f P = W (fn (_,c) => if (P c) then f else NO_TAC);

fun const_coords c =
  let val {Name,Thy,...} = dest_thy_const c in (Name,Thy) end;

fun constructed constr_set tm =
  let val (lhs,rhs) = dest_eq tm
  in
  (aconv lhs rhs)
     orelse
   let val maybe1 = const_coords(fst(strip_comb lhs))
       val maybe2 = const_coords(fst(strip_comb rhs))
   in Binaryset.member(constr_set,maybe1)
         andalso
      Binaryset.member(constr_set,maybe2)
   end
  end
  handle HOL_ERR _ => false;

fun LIFT_SIMP ss tm =
   UNDISCH_THEN tm (STRIP_ASSUME_TAC o simpLib.SIMP_RULE ss []);


local fun DTHEN ttac = fn (asl,w) =>
        let val (ant,conseq) = dest_imp_only w
            val (gl,prf) = ttac (Thm.ASSUME ant) (asl,conseq)
        in (gl, Thm.DISCH ant o prf)
        end
in
val BOSS_STRIP_TAC = Tactical.FIRST [GEN_TAC,CONJ_TAC, DTHEN STRIP_ASSUME_TAC]
end;

fun add_constr tyinfo set =
   let open TypeBase TypeBase.TypeInfo
       val C = constructors_of tyinfo
   in Binaryset.addList (set, map const_coords C)
   end;

infix &&;

fun (ss && thl) = simpLib.++(ss,simpLib.rewrites thl);

fun add_simpls tyinfo ss = ss && TypeBase.TypeInfo.simpls_of tyinfo;

fun is_dneg tm = 1 < snd(strip_neg tm);

fun breakable tm =
    is_exists tm orelse
    is_conj tm   orelse
    is_disj tm   orelse
    is_dneg tm   orelse
    T=tm         orelse
    F=tm;

(* This is an expensive test ....  *)

fun splittable w =
   Lib.can (find_term (fn tm => is_cond tm andalso free_in tm w)) w;


fun LIFT_SPLIT_SIMP ss simp tm =
   UNDISCH_THEN tm
     (fn th => MP_TAC (simpLib.SIMP_RULE ss [] th)
                 THEN IF_CASES_TAC
                 THEN simp
                 THEN REPEAT BOSS_STRIP_TAC);

fun SPLIT_SIMP simp = TRY IF_CASES_TAC THEN simp ;


(*---------------------------------------------------------------------------
      STP_TAC (Simplify then Prove)

   The following is a straightforward but quite helpful simplification
   procedure. It treats the rewrite rules for all declared datatypes as
   being built-in, so that the user does not have to mention them.

   0. Build a simpset from the given ss and the rewrites coming from
      any constructors that are found in TypeBase.

   1. Remove all universal quantifiers and break down all conjunctions

   2. Eliminate all "var-equalities" from the assumptions

   3. Simplify the goal with respect to the assumptions and the given
      simplification set.

   4. Case split on conditionals as much as possible.

   5. Strip as much as possible to the assumptions.

   6. Until there is no change in the complete goal, attempt to do one
      of the following:

         * eliminate a var-equality

         * break up an equation between constructors in the assumptions

         * break up an equation between constructors in the goal

         * break up conjunctions, disjunctions, existentials, or
           double negations occurring in the assumptions.

         * eliminate occurrences of T (toss it away) and F (prove the goal)
           in the assumptions.

         * elimininate free occurrences of if-then-else in the
           assumptions, simplifying the goal afterwards.

    7. Apply the finishing tactic.

 ---------------------------------------------------------------------------*)

local fun compare ((s1,s2),(t1,t2)) =
        case String.compare(s1,t1)
         of EQUAL => String.compare (s2,t2)
          | other => other
      val constr_set0 = Binaryset.empty compare
in
fun PRIM_STP_TAC ss finisher =
  let open TypeBase TypeBase.TypeInfo
      val tyl = listItems (theTypeBase())
      val constr_set = rev_itlist add_constr tyl constr_set0
      val has_constr_eqn = Lib.can (find_term (constructed constr_set))
      val ASM_SIMP = simpLib.ASM_SIMP_TAC ss []
  in
    REPEAT (GEN_TAC ORELSE CONJ_TAC)
     THEN REPEAT (ASSUM_TAC VSUBST_TAC var_eq)
     THEN ASM_SIMP
     THEN TRY (IF_CASES_TAC THEN REPEAT IF_CASES_TAC THEN ASM_SIMP)
     THEN REPEAT BOSS_STRIP_TAC
     THEN REPEAT (CHANGED_TAC
            (ASSUM_TAC VSUBST_TAC var_eq
               ORELSE ASSUMS_TAC (LIFT_SIMP ss) has_constr_eqn
               ORELSE ASSUM_TAC (LIFT_SIMP ss) breakable
               ORELSE CONCL_TAC ASM_SIMP has_constr_eqn)
               ORELSE ASSUM_TAC (LIFT_SPLIT_SIMP ss ASM_SIMP) splittable
               ORELSE CONCL_TAC (SPLIT_SIMP ASM_SIMP) splittable)
     THEN TRY finisher
  end
end;

(*---------------------------------------------------------------------------
    Adding simplification sets in for all datatypes each time
    STP_TAC is invoked can be slow. In such cases, use
    PRIM_STP tac instead.
 ---------------------------------------------------------------------------*)

fun STP_TAC ss finisher =
  let open TypeBase TypeBase.TypeInfo
      val tyl = listItems (theTypeBase())
      val ss' = rev_itlist add_simpls tyl ss
  in
    PRIM_STP_TAC ss' finisher
  end;


fun RW_TAC ss thl = STP_TAC (ss && thl) NO_TAC
val bool_ss = boolSimps.bool_ss;

open simpLib
infix ++
val (srw_ss : simpset ref) = let
  open TypeBase TypeBase.TypeInfo
  val base = boolSimps.bool_ss
  val tyl = listItems (theTypeBase())
in
  ref (rev_itlist add_simpls tyl base)
end;

fun update_fn tyi = srw_ss := (!srw_ss && TypeBase.TypeInfo.simpls_of tyi)
val _ = TypeBase.TypeInfo.register_update_fn update_fn

fun get_srw_ss () = !srw_ss
fun augment_srw_ss ssdl =
    (srw_ss := foldl (fn (ssd,ss) => ss ++ ssd) (!srw_ss) ssdl)

fun SRW_TAC ssdl thl = let
  val ss = foldl (fn (ssd, ss) => ss ++ ssd) (!srw_ss) ssdl
in
  PRIM_STP_TAC (ss && thl) NO_TAC
end;

end;
