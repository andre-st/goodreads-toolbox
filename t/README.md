# QA Plan


## Quality goals

| Goal                                           | Rationale/Notes
|------------------------------------------------|-------------------------------------
| Costs                                          | Solo-developer side-project; everything should be able to run on a single personal computer
| Functionality: Correctness                     | garbage in, garbage out
| Functionality: Robustness                      | Loading data can take hours: consider Internet connection issues, Goodreads has exceptions, sometimes over capacity, invalid dates
| Functionality: Robustness: Resumability        | Loading data can take hours: consider intentional pauses, program or computer crashes, power issues - we don't want to start from the beginning
| Usability                                      | Out: Windows, GUIs, Browser-Addons, SaaS too much effort, although it heavily reduces potential user base besides me
| Usability: Learnability                        | program usage, behavior and outputs, library usage (devs)
| Usability: Consistency and Familiarity         | CLI programs, consistent option names, consistent look & feel (reports, help files etc)
| Usability: Run unattended                      | Loading data can take hours: consider people leaving the computer/process or running it on a remote computer/server
| Maintainability: Testability                   | We scrape data from the Goodreads website and cannot know changes in advance; we have to consider it a long-term failure and need to probe it regularly; GR, however, rarely changes or removes something on their website (desktop)
| Maintainability: Repair turnaround time (RTAT) | Loading data can take hours: shouldn't impact debugging too much



## QA activities

| Activity                  | Coverage or Frequency                              | Domain  | Notes
|---------------------------|----------------------------------------------------|---------|------------------------------------------
| Unit testing              | libraries' public functions                        | testing | always online-testing, primary goal is early detection of changes to the Goodreads.com website that would break our scraper
| Regression testing        | run unit-tests before changes are pushed to GitHub | testing | automatically thru [a git-hook](../git-hooks/pre-push), reducing chance of distributing a buggy release
| Manual testing            | user-scripts, when logical lines of code changed   | testing | -
| Static analysis           | user-scripts, before each commit                   | testing | automatically thru [a git-hook](../git-hooks/pre-commit), because small (accidental) changes are not always manually tested but might break things too
| Push logic down the stack | user-scripts                                       | design  | have very little code in the user-scripts by moving as much code as possible into the libs (down the stack). Tests covering the libs would cover most fallible code, good enough to gain confidence; less repitition in user-scripts, centralized changes
| Persistent caching        | all source data (not results)                      | design  | eases debugging, program resumability, experimenting with parameters; loading data from GR is very time-consuming
| Outwait I/O issues        | libraries                                          | design  | local internet problems, or more often: Goodreads exceptions etc., goal is to run unattended because runtimes are very long
| Test as a tutorial        | libraries, emergent                                | dev     | reduce errors caused by incorrect use or assumptions
| Inline Man-pages          | user-scripts, program parameters, examples         | field   | Man-page POD-header in each script: more likely to be up-to-date, can be extracted and displayed on incorrect program use; correct use supports correctness goal
| Help files                | user-scripts, everything but program parameters    | field   | Markdown-file in help-directory, with screenshot, motivation, install instructions, lessons learned etc; correct use/expectation management supports correctness goal
| Field failure reports     | ask for reports, contact opts in scripts / help    | field   | 
| Issue tracking            | all                                                | PM      | GitHub Issue Tracker; feedback (feature requests, usage problems); troubleshooting history
| Version control           | all                                                | SCM     | Git, GitHub, reverting code/source history, releasing, sync between computers



## QA activities evaluation

| Goal                    | Unit test | Regression | Manual test | Static A. | Down stack | Cache | Outwait | Man/Help | Versioning | Issue/report
|-------------------------|-----------|------------|-------------|-----------|------------|-------|---------|----------|------------|---------------
| Correctness             | ++        | ++         | ++          | ++        | ++         | none  | none    | +        | none       | +
| Robustness              | none      | none       | none        | none      | none       | ++    | ++      | none     | none       | none
| Learnability            | ++        | none       | none        | none      | none       | none  | none    | ++       | none       | none
| Run unattended          | none      | none       | none        | none      | none       | none  | ++      | none     | none       | none
| Testability             | ++        | ++         | none        | none      | ++         | ++    | none    | none     | none       | none
| Repair turnaround time  | ++        | ++         | none        | none      | ++         | ++    | none    | none     | +          | none


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


