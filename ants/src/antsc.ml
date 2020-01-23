open Printf
open Ast


let num_label_error = ref 0 (*les compteurs de labels*)
let num_label = ref 0

let incremente_error () : string =
  (*Renvoie un nouveau label*)
  incr num_label_error ;
  "label_error" ^ (string_of_int !num_label_error)

let incremente_fresh () : string = incr num_label ;
  "label" ^ (string_of_int !num_label)

let list_of_functions = ref []



let rec find_function (l : (int * (command * CodeMap.Span.t) list) list)
    (fonction_name : int) : (command * CodeMap.Span.t) list =
  (*Recherche si une fonction est definie et renvoie les commandes a effectuer*)
  match l with
  | [] -> failwith "Fonction non definie ! "
  | (x, y) :: _ when x = fonction_name -> y
  | _ :: q -> find_function q fonction_name

and print_nt_command2 (t : command) (out : out_channel) : unit =
  (*affiche une commande*)
  match t with
  | Comment _ -> ()
  | Move ((commands, _)) ->
      let new_label_error = incremente_error() in
      let new_label = incremente_fresh() in
      Printf.fprintf out "Move %s \n" new_label_error;
      Printf.fprintf out "Goto %s \n" new_label;
      Printf.fprintf out "\n%s:\n" new_label_error;
      iter_print_nt_command2 commands out;
      Printf.fprintf out "Goto %s \n" new_label;
      Printf.fprintf out "\n%s:\n" (new_label) ;
  | Turn ((dir, _)) ->
      Printf.fprintf out "Turn %t" (print_nt_direction2 dir)
  | Pickup ((commands, _)) ->
      let new_label_error = incremente_error() in
      let new_label = incremente_fresh() in
      Printf.fprintf out "PickUp %s \n" new_label_error;
      Printf.fprintf out "Goto %s \n" new_label;
      Printf.fprintf out "\n%s:\n" new_label_error;
      iter_print_nt_command2 commands out;
      Printf.fprintf out "Goto %s \n" new_label;
      Printf.fprintf out "\n%s:\n" new_label;
  | Drop -> Printf.fprintf out "Drop\n"
  | Mark ((i, _)) ->
      Printf.fprintf out "Mark ";
      print_int i;
  | Unmark ((i, _)) ->
      Printf.fprintf out "Unmark ";
      print_int i;
      print_newline ()
  | For ((nb, _), (repeatcmd, _))->
      for _ = 1 to nb do
        iter_print_nt_command2 repeatcmd out
      done
  | Def ((ident, _), (defcmd, _))->
      list_of_functions := (ident, defcmd) :: !list_of_functions;
  | Call (ident, _) ->
      let cmd_to_print = (find_function !list_of_functions ident) in
      iter_print_nt_command2 cmd_to_print out
  | Flip ((p, _), (lcommandyes, _), (lcommandno, _)) ->
      let lbyes = incremente_fresh () in
      let lbno = incremente_fresh () in
      let lbout = incremente_fresh () in
      Printf.fprintf out "Flip %d %s %s\n" p lbyes lbno;
      Printf.fprintf out "\n%s:\n" lbyes;
      iter_print_nt_command2 lcommandyes out;
      Printf.fprintf out "Goto %s\n" lbout;
      Printf.fprintf out "\n%s:\n" lbno;
      iter_print_nt_command2 lcommandno out;
      Printf.fprintf out "Goto %s\n" lbout;
      Printf.fprintf out "\n%s:\n" lbout;
  | If ((test, _), (thencmd, sp1), (elsecmd, sp2)) -> begin
      let lbthen = incremente_fresh () in
      let lbelse = incremente_fresh () in
      let lbout = incremente_fresh () in
      let spthen = (thencmd, sp1) in
      let spelse = (elsecmd, sp2) in
      match test with
      | Rock ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | FoeMarker ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Friend ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Foe ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Friendwf ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Foewf ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Food ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Home ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | FoeHome ((dir, _)) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | Marker ((dir, _), _) -> print_test_dir_if dir test out lbthen lbelse lbout thencmd elsecmd
      | True -> iter_print_nt_command2 thencmd out
      | False -> iter_print_nt_command2 elsecmd out
      | And ((test1, spt1), sptest2) ->
          let sptest1 = (test1, spt1) in
          let new_t = If (sptest1, ([If (sptest2, spthen, spelse), spt1], spt1), spelse) in
          print_nt_command2 new_t out
      | Or (sptest1, (test2, spt2)) -> (*if a || b then cmd1 else cmd2    est equivalent a    if a then cmd1 else if b then cmd1 else cmd2*)
          let sptest2 = (test2, spt2) in
          let new_t = If (sptest1, spthen, ([If (sptest2, spthen, spelse), spt2], spt2)) in
          print_nt_command2 new_t out
      | Not sptest ->  (*if not a then cmd1 else cmd2   est equivalent a  if a then cmd2 else cmd1*)
          let new_t = If (sptest, spelse, spthen) in
          print_nt_command2 new_t out
      | Equal ((t1, spt1), (t2, spt2)) -> (*a == b est equivalent a (a and b) or (not a and not b)*)
          let sptest1 = (t1, spt1) in
          let sptest2 = (t2, spt2) in
          let new_t = If ((Or ((And (sptest1, sptest2), spt1), (And ((Not sptest1, spt1), (Not sptest2, spt2)),spt1)), spt1), spthen, spelse) in
          print_nt_command2 new_t out
  end
  | While ((test, _), (cmds, _)) ->
      match test with
      | Rock ((dir, _)) -> print_test_dir_while dir test out cmds
      | FoeMarker ((dir, _)) -> print_test_dir_while dir test out cmds
      | Friend ((dir, _)) -> print_test_dir_while dir test out cmds
      | Foe ((dir, _)) -> print_test_dir_while dir test out cmds
      | Friendwf ((dir, _)) -> print_test_dir_while dir test out cmds
      | Foewf ((dir, _)) -> print_test_dir_while dir test out cmds
      | Food ((dir, _)) -> print_test_dir_while dir test out cmds
      | Home ((dir, _)) -> print_test_dir_while dir test out cmds
      | FoeHome ((dir, _)) -> print_test_dir_while dir test out cmds
      | Marker ((dir, _), _) -> print_test_dir_while dir test out cmds
      | True ->
          let while_lbl = incremente_fresh () in
          Printf.fprintf out "\n%s:\n" while_lbl;
          iter_print_nt_command2 cmds out;
          Printf.fprintf out "Goto %s\n" while_lbl
      | False -> ()
      | _ -> failwith "Non implemente"


and print_test_if (test : tests) : unit =
  (*affiche un test simple du langage d'arrivee*)
  match test with
  | Rock _ -> print_string "Rock"
  | FoeMarker _ -> print_string "FoeMarker"
  | Friend _ -> print_string "Friend"
  | Foe _ -> print_string "Foe"
  | Friendwf _ -> print_string "FriendWithFood"
  | Foewf _ -> print_string "FoeWithFood"
  | Food _ -> print_string "Food"
  | Home _ -> print_string "Home"
  | FoeHome _ -> print_string "FoeHome"
  | Marker (_, (i, _)) -> print_string ("Marker " ^ (string_of_int i))
  | _ -> failwith "Print d'un test qui n'est pas dans le langage d'arrivé"

and print_test_dir_if (dir : availabledir) (test : tests) (out : out_channel)
    (lbthen : string) (lbelse : string) (lbout : string)
    (thencmd : (command * CodeMap.Span.t) list)
    (elsecmd : (command * CodeMap.Span.t) list) : unit =
  (*affiche un if simple*)
  Printf.fprintf out "Sense %t%s %s " (print_nt_availabledir2 dir) lbthen lbelse;
  print_test_if test;
  print_newline ();
  Printf.fprintf out "\n%s:\n" lbthen;
  iter_print_nt_command2 thencmd out;
  Printf.fprintf out "Goto %s\n" lbout;
  Printf.fprintf out "\n%s:\n" lbelse;
  iter_print_nt_command2 elsecmd out;
  Printf.fprintf out "Goto %s\n" lbout;
  Printf.fprintf out "\n%s:\n" lbout;

and print_test_dir_while (dir : availabledir) (test : tests) (out : out_channel)
    (cmd : (command * CodeMap.Span.t) list) : unit =
  (*Print un while simple*)
  let while_lbl = incremente_fresh () in
  let out_lbl = incremente_fresh () in
  let cmd_lbl = incremente_fresh () in
  Printf.fprintf out "\n%s:\n" while_lbl;
  Printf.fprintf out "Sense %t%s %s " (print_nt_availabledir2 dir) cmd_lbl out_lbl;
  print_test_if test;
  print_newline ();
  Printf.fprintf out "\n%s:\n" cmd_lbl;
  iter_print_nt_command2 cmd out;
  Printf.fprintf out "Goto %s\n" while_lbl;
  Printf.fprintf out "\n%s:\n" out_lbl

and print_nt_direction2 (t : direction) (out : out_channel) : unit =
  (*affiche une direction droite-gauche*)
  match t with
  | Left -> Printf.fprintf out "Left "
  | Right -> Printf.fprintf out "Right "

and print_nt_program2 (t : program) (out : out_channel) : unit =
  (*affiche le programme*)
  print_string "start:\n";
  match t with
  | Program ((arg0, _)) -> Printf.fprintf out "%t" (non_empty_iter_print_nt_command2  arg0)


and print_nt_availabledir2 (t : availabledir) (out : out_channel) : unit =
  (*affiche les quatres directions de tests*)
  match t with
  | Ahead -> Printf.fprintf out "Ahead "
  | Here -> Printf.fprintf out "Here "
  | LeftAhead -> Printf.fprintf out "LeftAhead "
  | RightAhead -> Printf.fprintf out "RightAhead "

and non_empty_iter_print_nt_command2 (l : (command * CodeMap.Span.t) list)
    (out : out_channel) : unit =
  (*imprime une liste de commande non vide*)
  let rec print (l : (command * CodeMap.Span.t) list) (out : out_channel) : unit =
    match l with
    | [] -> ()
    | (e, _)::[] ->
      print_nt_command2 e out
    | (e, _)::l ->
      Printf.fprintf out "%t" (print_nt_command2 e) ;
      print l out
  in
  print l out;


and iter_print_nt_command2 (l : (command * CodeMap.Span.t) list)
    (out : out_channel) : unit =
  (*imprime une liste de commande*)
  if l = [] then () else begin

    let rec print (l : (command * CodeMap.Span.t) list) (out : out_channel) : unit =
      match l with
      | [] -> ()
      | (e, _)::[] ->
        print_nt_command2 e out;
        print_newline ()
      | (e, _)::l ->
        print_nt_command2 e out;
        print_newline ();
        print l out
    in
    print l out;

  end



let print_availabledir = print_nt_availabledir2

let print_command = iter_print_nt_command2

let print_direction = print_nt_direction2

let print_program = print_nt_program2






let process_file filename =
  (* Ouvre le fichier et cree un lexer. *)
  let file = open_in filename in
  let lexer = Lexer.of_channel file in
  (* Parse le fichier. *)
  let (program, span) = Parser.parse_program lexer in
  printf "syntax abstract tree at position %t:\n%t\n" (CodeMap.Span.print span) (print_program program);
  print_string "Goto start\n"

(* Le point de depart du compilateur. *)
let _ =
  (* On commence par lire le nom du fichier à compiler passe en paramètre. *)
  if Array.length Sys.argv <= 1 then begin
    (* Pas de fichier... *)
    eprintf "no file provided.\n";
    exit 1
  end else begin
    try
      (* On compile le fichier. *)
      process_file (Sys.argv.(1))
    with
    | Lexer.Error (e, span) ->
      eprintf "Lex error: %t: %t\n" (CodeMap.Span.print span) (Lexer.print_error e)
    | Parser.Error (e, span) ->
      eprintf "Parse error: %t: %t\n" (CodeMap.Span.print span) (Parser.print_error e)
  end
