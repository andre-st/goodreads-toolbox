# QA Plan


## Quality goals

| Goal                                         | Rationale
|----------------------------------------------|-------------------------------------
| Costs__LowTCO                                | Solo-developer non-commerical side-project; everything should be able to run on a single personal computer (time > money)
| Functionality__Correctness                   | Garbage in, garbage out
| Functionality__Robustness                    | Loading data can take hours: consider Internet connection issues, Goodreads has exceptions, sometimes over capacity, invalid dates
| Reliability__Resumability                    | Loading data can take hours: consider intentional pauses, program or computer crashes, power issues -- we don't want to start from the beginning
| Usability                                    | Out of scope: Windows, GUIs, Browser-Addons, SaaS too much effort, although it would increase potential user base
| Usability__Learnability                      | Program usage and outputs, library usage (devs)
| Usability__ConsistencyAndFamiliarity         | Typical CLI programs, consistent option names accross all programs, consistent look & feel (reports, help files etc)
| Usability__RunUnattended                     | Loading data can take hours: consider people leaving the computer/process or running it on a remote computer/server
| Maintainability__Testability                 | Scraping the Goodreads website expects stable HTML/JS-parts, we cannot know in advance when and where changes will occur (long-term failure), so throughout testing is required; GR, however, rarely changes or removes something on their website (desktop)
| Maintainability__RepairTurnaroundTime        | Loading data can take hours: shouldn't impact regular debugging too much
| Security__Integrity                          | Users on GR might try to abuse our programs or other programs reading our outputs by saving rogue strings in reviews or usernames etc 



## QA activities

| Activity                     | Coverage/Frequency                                 | Notes
|------------------------------|----------------------------------------------------|-------------------------------------------
| `(UT)` Unit testing          | libraries' public functions                        | 
| `(RT)` Regression testing    | run unit-tests before changes are pushed to GitHub | automatically via [a git-hook](../git-hooks/pre-push), reducing chance of distributing a buggy release
| `(MT)` Manual testing        | user-scripts, when logical lines of code changed   | 
| `(SA)` Static analysis       | user-scripts, before each commit                   | automatically via [a git-hook](../git-hooks/pre-commit), because small (accidental) changes are not always manually tested but might break things too
| `(PL)`-PushLogicDownTheStack | user-scripts                                       | have very little code in the user-scripts by moving as much code as possible into the libs (down the stack). Tests covering the libs would cover most fallible code, good enough to gain confidence; less repitition in user-scripts, centralized changes
| `(CA)` Persistent caching    | all scraped source data (not results)              | 
| `(IO)` Outwait I/O issues    | libraries                                          | wait, retry n times, skip less important
| `(TT)` Test as a tutorial    | libraries, emergent                                | reduce errors caused by incorrect use or assumptions
| `(MA)` Inline man pages      | user-scripts, program parameters, examples         | Man-page POD-header in each script: more likely to be up-to-date, can be extracted and displayed on incorrect program use; correct use supports correctness goal
| `(HL)` Help files            | user-scripts, everything but program parameters    | Markdown-file in help-directory, with screenshot, motivation, install instructions, lessons learned etc; correct use/expectation management supports correctness goal
| `(FR)` Field failure reports | ask for reports, contact opts in scripts / help    | 
| `(IS)` Issue tracking        | all                                                | GitHub Issue Tracker; feedback (feature requests, usage problems); troubleshooting history
| `(VC)` Version control       | all                                                | Git, GitHub, reverting code/source history, releasing, sync between computers



## QA activities evaluation

| Goal                  | UT   | RT   | MT   | SA   | PL   | CA   | IO   | MA/HL | IS   | VC
|-----------------------|------|------|------|------|------|------|------|-------|------|------
| Correctness           | ++   | ++   | ++   | ++   | ++   | none | none | +     | +    | none
| Robustness            | none | none | none | none | none | ++   | ++   | none  | none | none
| Learnability          | ++   | none | none | none | none | none | none | ++    | none | none
| Run Unattended        | none | none | none | none | none | none | ++   | none  | none | none
| Testability           | ++   | ++   | none | none | ++   | ++   | none | none  | none | none
| RepairTurnaroundTime  | ++   | ++   | none | none | ++   | ++   | none | none  | none | +   
| Integrity             | none | none | none | none | none | none | none | none  | none | none


Values: ++, +, -, none (does not address this goal)



## Observations and limitations

- some unit-tests need 3-5 minutes due to request throttling (and we need to test online to detect website changes): gsearch, greadreviews; 
	running unit-tests before each commit would be too annoying and would motivate circumvention. So we only test before each push.
- users might download a release that breaks because GR changed things quite after the tested release; I run some programs daily but not all the tests



## Setup

Rename `config.pl-example` to `config.pl` and edit the file. 
Replace the email, pass, user-id values.

Running all tests via a GNU/Linux terminal:

```console
$ cd goodreads
$ prove
t/gisxxx.t ........... ok
t/glogin.t ........... ok
t/gmeter.t ........... ok
t/greadauthors.t ..... ok
...
t/gverifyxxx.t ....... ok
All tests successful.
Files=16, Tests=253, 11 wallclock secs ( 0.16 usr  0.03 sys +  9.75 cusr  0.48 csys = 10.42 CPU)
Result: PASS
```


