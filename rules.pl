% These predicates invoke the ownership enforcement requirements of the
% find-owners plugin and provide opt-in & opt-out predicates. The find-owners
% plugin operates by adding the 'Owner-Review-Vote' label with a may, need, or ok
% requirement to a change depending on whether the change is covered by an
% opt-in or opt-out clause and whether or not the change has adequate ownership
% approval. CLs are unaffected by this filter by default.
% See the find-owners documentation for more details.
% https://gerrit.googlesource.com/plugins/find-owners/+doc/master/src/main/resources/Documentation/config.md

submit_filter(In, Out) :-
    In =.. [submit | A],
    check_branch_review(A, B),
    check_bot_commit(B, C),
    hide_lcq_label(C, D),
    Temp =.. [submit | D],
    check_find_owners(Temp, Out).

% Prune the special labels from commits applying to this root project repository.
submit_rule(Out) :-
    gerrit:default_submit(In),
    In =.. [submit | A],
    check_branch_review(A, B),
    check_bot_commit(B, C),
    hide_lcq_label(C, D),
    Out =.. [submit | D].

%% opt_in_find_owners
%  Governs which changes are affected by the find-owners submit filter.
%  Please keep clauses restricted to single projects, users, branches, or
%  simple regex expressions.
%  find-owners is enabled by default for 'refs/heads/master' as well as the
%  active development branch for projects which do not use master.
%  Consult full.xml on the master branch of chromiumos/manifest for the list
%  of active development branches.
opt_in_find_owners :-
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_branch('refs/heads/main').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/bluez'),
    gerrit:change_branch('refs/heads/chromeos-5.44').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/edk2'),
    ( gerrit:change_branch('refs/heads/chromeos-2017.08')
    ; gerrit:change_branch('refs/heads/chromeos-cml-branch1')
    ; gerrit:change_branch('refs/heads/chromeos-cnl')
    ; gerrit:change_branch('refs/heads/chromeos-glk')
    ; gerrit:change_branch('refs/heads/chromeos-icl')
    ).
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/fwupd'),
    gerrit:change_branch('refs/heads/fwupd-1.2.5').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/hostap'),
    ( gerrit:change_branch('refs/heads/wpa_supplicant-2.6')
    ; gerrit:change_branch('refs/heads/wpa_supplicant-2.8')
    ).
opt_in_find_owners :-
    ( gerrit:change_project('chromiumos/third_party/libsigrok')
    ; gerrit:change_project('chromiumos/third_party/libsigrokdecode')
    ; gerrit:change_project('chromiumos/third_party/libsigrok-cli')
    ),
    gerrit:change_branch('refs/heads/chromeos').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/ltp'),
    gerrit:change_branch('refs/heads/chromeos-20150119').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/mesa'),
    ( gerrit:change_branch('refs/heads/debian')
    ; gerrit:change_branch('refs/heads/chromeos-freedreno')
    ; gerrit:change_branch('refs/heads/mesa-img')
    ).
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/pyelftools'),
    gerrit:change_branch('refs/heads/master-0.22').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/portage_tool'),
    gerrit:change_branch('refs/heads/chromeos-2.3.49').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/trousers'),
    gerrit:change_branch('refs/heads/master-0.3.13').

%% opt_out_find_owners
%  Specifies exceptions to the conditions covered by opt_in_find_owners.
%  Please keep clauses to simple cases as in opt_in_find_owners.
opt_out_find_owners :-
    gerrit:change_project('chromiumos/third_party/kernel').
opt_out_find_owners :-
    gerrit:change_project('chromiumos/third_party/coreboot').
% Bot commits should always ignore OWNERS.
opt_out_find_owners :-
    gerrit:commit_label(label('Bot-Commit', 1), _).

%% check_find_owners(InputLabels, OutputLabels)
%  If opt_out_find_owners is true, remove all 'Owner-Review-Vote' labels from
%  InputLabels and return them as OutputLabels, else if opt_in_find_owners is
%  true, call find_owners:submit_filter on InputLabels, else default to no
%  find_owners filter and remove any labels applied by the plugin via
%  change_find_owners_labels.
check_find_owners(In, Out) :-
    ( opt_out_find_owners -> find_owners:remove_need_label(In, Temp)
    ; opt_in_find_owners -> find_owners:submit_filter(In, Temp)
    ; In = Temp
    ),
    Temp =.. [submit | OldLabels],
    change_find_owners_labels(OldLabels, ProcessedLabels),
    Out =.. [submit | ProcessedLabels].

%% change_find_owners_labels(InputLabels, OutputLabels)
% Removes label('Owner-Approved',_) after final filter so as to not show
% extraneous labels to users.
% Also changes any label('Owner-Review-Vote', may(_)) to
% label('Owner-Review-Vote', need(_)) so that the Submit button is hidden
% for changes which are opted-in and lack sufficient ownership approval.
change_find_owners_labels([], []).
change_find_owners_labels([H | T], R) :-
    H = label('Owner-Approved', _),
    !,
    change_find_owners_labels(T, R).
change_find_owners_labels([H1 | T], [H2 | R]) :-
    H1 = label('Owner-Review-Vote', may(_)),
    !,
    H2 = label('Owner-Review-Vote', need(_)),
    change_find_owners_labels(T, R).
change_find_owners_labels([H | T], [H | R]) :-
    change_find_owners_labels(T, R).

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
