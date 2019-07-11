% These predicates invoke the ownership enforcement requirements of the
% find-owners plugin and provide opt-in & opt-out predicates. The find-owners
% plugin operates by adding the 'Owner-Review-Vote' label with a may, need, or ok
% requirement to a change depending on whether the change is covered by an
% opt-in or opt-out clause and whether or not the change has adequate ownership
% approval. CLs are unaffected by this filter by default.
% See the find-owners documentation for more details.
% https://gerrit.googlesource.com/plugins/find-owners/+doc/master/src/main/resources/Documentation/config.md

submit_filter(In, Out) :-
    check_find_owners(In, Out).

%% opt_in_find_owners
%  Governs which changes are affected by the find-owners submit filter.
%  Please keep clauses restricted to single projects, users, branches, or
%  simple regex expressions.
%  When opting-in projects be sure to only enable find-owners for the active
%  development branch. This will typically be 'refs/heads/master'.
opt_in_find_owners :-
    gerrit:change_project('chromiumos/chromite'),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/docs'),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project(ProjectName),
    regex_matches('chromiumos/infra/.*', ProjectName),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/manifest'),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/platform/tast'),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/platform/tast-tests'),
    gerrit:change_branch('refs/heads/master').
opt_in_find_owners :-
    gerrit:change_project('chromiumos/third_party/portage_tool'),
    gerrit:change_branch('refs/heads/chromeos-2.3.49').

%% opt_out_find_owners
%  Specifies exceptions to the conditions covered by opt_in_find_owners.
%  Please keep clauses to simple cases as in opt_in_find_owners.
opt_out_find_owners :-
    false.

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
