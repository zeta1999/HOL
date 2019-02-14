signature hhTranslate =
sig

include Abbrev

  val is_tptp_fv : term -> bool
  val is_tptp_bv : term -> bool
  val is_app : term -> bool
  val atoms : term -> term list
  val must_pred : term -> bool
  
  (* new definitions using free variables *)
  val ATOM_CONV     : conv -> conv
  val LIFT_CONV     : (int * int) ref -> conv
  val RPT_LIFT_CONV : (int * int) ref -> term -> thm list
  
  (* inserting apply operators *)
  val APP_CONV_ONCE      : conv
  val APP_CONV_STRIPCOMB : conv
  val APP_CONV_BV        : conv
  val APP_CONV_BV_REC    : conv
  val APP_CONV_MAX       : conv
  val APP_CONV_MAX_REC   : conv  

  (* arity equations *)
  val strip_type : hol_type -> (hol_type list * hol_type)
  val collect_arity : term -> (term * int) list
  val mk_arity_eq : (term * int) -> term

  (* translation *)
  val translate_nocache : (int * term) -> (term * term list)
  val translate : term -> (term * term list)
  val translate_thm : thm -> (term * term list)


end
