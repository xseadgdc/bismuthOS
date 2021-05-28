% These predicates check for the Bot-Commit label and manage the Branch-Review label

submit_filter(In, Out) :-
    In =.. [submit | A],
    check_branch_review(A, B),
    check_bot_commit(B, C),
    hide_lcq_label(C, D),
    Out =.. [submit | D].

% Prune the special labels from commits applying to this root project repository.
submit_rule(Out) :-
    gerrit:default_submit(In),
    In =.. [submit | A],
    check_branch_review(A, B),
    check_bot_commit(B, C),
    hide_lcq_label(C, D),
    Out =.. [submit | D].

%% opt_in_branch_review
%  This predicate controls which changes the Branch-Review label appears on.
%  The Branch-Review label is required for submission on any CL on which it
%  appears.
opt_in_branch_review :- false.

%% opt_out_branch_review
%  This predicate overrides the opt_in_branch_review predicate and causes
%  the Branch-Review label to be removed from any CL for which opt_out is true.
opt_out_branch_review :-
    gerrit:commit_message_matches('^Exempt-From-Branch-Review:').

%% check_branch_review(InputLabels, OutputLabels)
%  This predicate removes the Branch-Review label if opt_out_branch_review is
%  true, otherwise it preserves the Branch-Review label if opt_in_branch_review
%  is true, otherwise it defaults to removing the Branch-Review label.
check_branch_review(Ls, R) :-
    (  opt_out_branch_review
        -> gerrit:remove_label(Ls, label('Branch-Review', _), R)
    ;  opt_in_branch_review -> R = Ls
    ;  \+ opt_in_branch_review
        -> gerrit:remove_label(Ls, label('Branch-Review', _), R)
    ).

%% check_bot_commit(InputLabels, OutputLabels)
%  This predicate checks for the existence of a 'Bot-Commit' +1 vote and
%  if it is found removes the 'Code-Review' and 'Verified' labels entirely. If
%  no 'Bot-Commit' vote is found, then this predicate removes the 'Bot-Commit'
%  label entirely.
%  The 'Bot-Commit' label is for use by automated bots to submit changes that
%  are not intended for human review, but still need to go through the Commit
%  Queue.
check_bot_commit(Ls, R) :-
(   gerrit:commit_label(label('Bot-Commit', 1), _)
        -> (gerrit:remove_label(Ls, label('Code-Review', _), Temp),
            gerrit:remove_label(Temp, label('Verified', _), R))
;   gerrit:remove_label(Ls, label('Bot-Commit', _), R)
).

%% hide_lcq_label(InputLabels, OutputLabels)
%  This predicate unconditionally removes the 'Legacy-Commit-Queue' label from
%  all CLs.
hide_lcq_label(Ls, R) :-
    gerrit:remove_label(Ls, label('Legacy-Commit-Queue', _), R).
