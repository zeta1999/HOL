(* ========================================================================= *)
(* FILE          : tacticToe.sml                                             *)
(* DESCRIPTION   : Automated theorem prover based on tactic selection        *)
(* AUTHOR        : (c) Thibault Gauthier, University of Innsbruck            *)
(* DATE          : 2017                                                      *)
(* ========================================================================= *)

structure tacticToe :> tacticToe =
struct

open HolKernel Abbrev boolLib aiLib
  smlLexer smlParser smlExecute smlRedirect smlInfix
  mlFeature mlThmData mlTacticData mlNearestNeighbor mlTreeNeuralNetwork
  psMinimize
  tttSetup tttLearn tttSearch

val ERR = mk_HOL_ERR "tacticToe"

(* -------------------------------------------------------------------------
   Time limit
   ------------------------------------------------------------------------- *)

fun set_timeout r = (ttt_search_time := r)

(* -------------------------------------------------------------------------
   Preselection of theorems
   ------------------------------------------------------------------------- *)

fun select_thmfea (symweight,thmfea) gfea =
  let
    val l0 = thmknn_wdep (symweight,thmfea) (!ttt_presel_radius) gfea
    val d = dset String.compare l0
    val l1 = filter (fn (k,v) => dmem k d) thmfea
  in
    (symweight, l1)
  end

(* -------------------------------------------------------------------------
   Preselection of tactics
   ------------------------------------------------------------------------- *)

fun select_tacfea tacdata gfea =
  let
    val calls = #calls tacdata
    val callfea = map_assoc #fea calls
    val symweight = learn_tfidf callfea
    val sel1 = callknn (symweight,callfea) (!ttt_presel_radius) gfea
    val sel2 = add_calldep (#calldep tacdata) (!ttt_presel_radius) sel1
    val tacnnfea = map (fn x => ((#ortho x, #nntm x), #fea x)) sel2
  in
    (symweight,tacnnfea)
  end

(* -------------------------------------------------------------------------
   Main function
   ------------------------------------------------------------------------- *)

fun main_tactictoe (thmdata,tacdata) tnno goal =
  let
    val _ = hidef QUse.use infix_file
    (* preselection *)
    val goalf = fea_of_goal true goal
    val _ = debug "preselection of theorems"
    val ((thmsymweight,thmfeadict),t1) =
      add_time (select_thmfea thmdata) goalf
    val _ = debug ("preselection of theorems time: " ^ rts_round 6 t1)
    val _ = debug "preselection of tactics"
    val ((tacsymweight,tacfea),t2) = add_time (select_tacfea tacdata) goalf
    val _ = debug ("preselection of tactics time: " ^ rts_round 6 t2)
    (* caches *)
    val thm_cache = ref (dempty (cpl_compare goal_compare Int.compare))
    val tac_cache = ref (dempty goal_compare)
    (* predictors *)
    fun thmpred n g =
      dfind (g,n) (!thm_cache) handle NotFound =>
      let val r = thmknn (thmsymweight,thmfeadict) n (fea_of_goal true g) in
        thm_cache := dadd (g,n) r (!thm_cache); r
      end
    val metis_flag = is_tactic "metisTools.METIS_TAC []"
    val metis_stac = "metisTools.METIS_TAC " ^ thmlarg_placeholder
    val metis_nntm = 
      if metis_flag 
      then nntm_of_applyexp (extract_applyexp (extract_smlexp metis_stac))
      else T
      handle Interrupt => raise Interrupt | _ => T
    fun tacpred g =
      dfind g (!tac_cache) handle NotFound =>
        let
          val thmidl = thmpred (!ttt_thmlarg_radius) g
          val l = fea_of_goal true g
          val stacnnl1 = tacnnknn (tacsymweight,tacfea) (!ttt_presel_radius) l
          val stacnnl2 = 
            if metis_flag then 
              mk_sameorder_set (fst_compare String.compare) 
                ((metis_stac, metis_nntm) :: stacnnl1)
            else stacnnl1
          val istacl = inst_stacnnl (thmidl,g) stacnnl2 
        in
          tac_cache := dadd g istacl (!tac_cache); istacl
        end
    val _ = debug "search"
  in
    search (tacpred,tnno) goal
  end

(* -------------------------------------------------------------------------
   Return values
   ------------------------------------------------------------------------- *)

fun read_status status = case status of
   ProofSaturated =>
   (print_endline "saturated"; (NONE, FAIL_TAC "tactictoe: saturated"))
 | ProofTimeout   =>
   (print_endline "timeout"; (NONE, FAIL_TAC "tactictoe: timeout"))
 | Proof s        =>
   (print_endline ("  " ^ s); 
    (SOME s, hidef (tactic_of_sml (!ttt_search_time)) s))

(* -------------------------------------------------------------------------
   Interface
   ------------------------------------------------------------------------- *)

val ttt_tacdata_cache = ref (dempty (list_compare String.compare))
fun clean_ttt_tacdata_cache () =
  ttt_tacdata_cache := dempty (list_compare String.compare)

fun has_boolty x = type_of x = bool
fun has_boolty_goal goal = all has_boolty (snd goal :: fst goal)

fun tactictoe_aux goal =
  if not (has_boolty_goal goal)
  then raise ERR "tactictoe" "type bool expected"
  else
  let
    val cthyl = current_theory () :: ancestry (current_theory ())
    val thmdata = hidef create_thmdata ()
    val tacdata =
      dfind cthyl (!ttt_tacdata_cache) handle NotFound =>
      let val tacdata_aux = create_tacdata () in
        ttt_tacdata_cache := dadd cthyl tacdata_aux (!ttt_tacdata_cache);
        tacdata_aux
      end
    val (proofstatus,_) = hidef 
      (main_tactictoe (thmdata,tacdata) (NONE,NONE)) goal
    val (staco,tac) = read_status proofstatus
  in
    tac
  end

fun ttt goal = (tactictoe_aux goal) goal

fun tactictoe term =
  let val goal = ([],term) in TAC_PROOF (goal, tactictoe_aux goal) end


end (* struct *)
