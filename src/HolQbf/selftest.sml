(* Copyright (c) 2010 Tjark Weber. All rights reserved. *)

(* Unit tests for HolQbfLib *)

val _ = print "Testing HolQbfLib "

val _ = QbfTrace.trace := 0

(*****************************************************************************)
(* check whether Squolem is installed                                        *)
(*****************************************************************************)

val squolem_installed = Lib.can HolQbfLib.disprove ``?x. x /\ ~x``

val _ = if not squolem_installed then
          print "(Squolem not installed? Some tests will be skipped.) "
        else ()

(*****************************************************************************)
(* Utility functions                                                         *)
(*****************************************************************************)

fun die s =
  if !Globals.interactive then
    raise (Fail s)
  else (
    print ("\n" ^ s ^ "\n");
    OS.Process.exit OS.Process.failure
  )

fun read_after_write t =
let
  val path = FileSys.tmpName ()
in
  QDimacs.write_qdimacs_file path t;
  case Term.match_term t (QDimacs.read_qdimacs_file path) of
    (_, []) =>
    print "."
  | _ =>
    die "Term read requires type substitution to match original term."
end
handle Feedback.HOL_ERR {origin_structure, origin_function, message} =>
  die ("Read after write failed on term '" ^ Hol_pp.term_to_string t ^
    "': exception HOL_ERR (in " ^ origin_structure ^ "." ^ origin_function ^
    ", message: " ^ message ^ ")")

fun disprove t =
  if squolem_installed then
    let val _ = HolQbfLib.disprove t
    in
      print "."
    end
    handle Feedback.HOL_ERR {origin_structure, origin_function, message} =>
      die ("Disprove failed on term '" ^ Hol_pp.term_to_string t ^
        "': exception HOL_ERR (in " ^ origin_structure ^ "." ^ origin_function ^
        ", message: " ^ message ^ ")")
  else ()

val prove = disprove

(*****************************************************************************)
(* Test cases                                                                *)
(*****************************************************************************)

val _ = List.app read_after_write
  [
    ``(p \/ ~q) /\ r``,
    ``?p. (p \/ ~q) /\ r``,
    ``?q. (p \/ ~q) /\ r``,
    ``?r. (p \/ ~q) /\ r``,
    ``!p. ?q. (p \/ ~q) /\ r``,
    ``!p q. ?r. (p \/ ~q) /\ r``,
    ``!p. ?q r. (p \/ ~q) /\ r``,
    ``?p. !q. ?r. (p \/ ~q) /\ r``
  ]

val _ = List.app disprove
  [
    ``?x. x /\ ~x``,
    ``!x. ?y. x /\ y``,
    ``!x. ?y. (x \/ y) /\ ~y``
  ]

val _ = List.app prove
  [
    ``?x. x``,
    ``!x. ?y. x \/ y``,
    ``!x. ?y. (x \/ y) /\ (~x \/ y)``
  ]

(*****************************************************************************)

val _ = print " done, all tests successful.\n"

val _ = OS.Process.exit OS.Process.success
