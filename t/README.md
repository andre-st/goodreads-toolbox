# QA Plan


## Quality goals

| Goal                                       | Rationale
|--------------------------------------------|-------------------------------------
| Costs                                      | Solo-developer side-project; everything should be able to run on a single personal computer
| Functionality_Correctness                  | garbage in, garbage out
| Functionality_Robustness                   | Loading data can take hours: consider Internet connection issues, Goodreads has exceptions, sometimes over capacity, invalid dates
| Functionality_Robustness_Resumability      | Loading data can take hours: consider intentional pauses, program or computer crashes, power issues - we don't want to start from the beginning
| Usability                                  | Out: Windows, GUIs, Browser-Addons, SaaS too much effort, although it heavily reduces potential user base besides me
| Usability_Learnability                     | program usage, behavior and outputs, library usage (devs)
| Usability_ConsistencyAndFamiliarity        | CLI programs, consistent option names, consistent look & feel (reports, help files etc)
| Usability_RunUnattended                    | Loading data can take hours: consider people leaving the computer/process or running it on a remote computer/server
| Maintainability_Testability                | We scrape data from the Goodreads website and cannot know changes in advance; we have to consider it a long-term failure and need to probe it regularly; GR, however, rarely changes or removes something on their website (desktop)
| Maintainability_RepairTurnaroundTime(RTAT) | Loading data can take hours: shouldn't impact debugging too much



## QA activities

| Activity              | Coverage or Frequency                              | Notes
|-----------------------|----------------------------------------------------|-------------------------------------------
| UnitTesting           | libraries' public functions                        | always online-testing, primary goal is early detection of changes to the Goodreads.com website that would break our scraper
| RegressionTesting     | run unit-tests before changes are pushed to GitHub | automatically thru [a git-hook](../git-hooks/pre-push), reducing chance of distributing a buggy release
| ManualTesting         | user-scripts, when logical lines of code changed   | 
| StaticAnalysis        | user-scripts, before each commit                   | automatically thru [a git-hook](../git-hooks/pre-commit), because small (accidental) changes are not always manually tested but might break things too
| PushLogicDownTheStack | user-scripts                                       | have very little code in the user-scripts by moving as much code as possible into the libs (down the stack). Tests covering the libs would cover most fallible code, good enough to gain confidence; less repitition in user-scripts, centralized changes
| PersistentCaching     | all scraped source data (not results)              | eases debugging, program resumability, experimenting with parameters; loading data from GR is very time-consuming
| OutwaitIOIssues       | libraries                                          | local internet problems, or more often: Goodreads exceptions etc., goal is to run unattended because runtimes are very long
| TestAsATutorial       | libraries, emergent                                | reduce errors caused by incorrect use or assumptions
| InlineManPages        | user-scripts, program parameters, examples         | Man-page POD-header in each script: more likely to be up-to-date, can be extracted and displayed on incorrect program use; correct use supports correctness goal
| HelpFiles             | user-scripts, everything but program parameters    | Markdown-file in help-directory, with screenshot, motivation, install instructions, lessons learned etc; correct use/expectation management supports correctness goal
| FieldFailureReports   | ask for reports, contact opts in scripts / help    |  
| IssueTracking         | all                                                | GitHub Issue Tracker; feedback (feature requests, usage problems); troubleshooting history
| VersionControl        | all                                                | Git, GitHub, reverting code/source history, releasing, sync between computers



## QA activities evaluation

| Goal                  | Unit test | Regression | Manual test | Static A. | Down stack | Cache | Outwait | Man/Help | Versioning | Issue/report
|-----------------------|-----------|------------|-------------|-----------|------------|-------|---------|----------|------------|---------------
| Correctness           | ++        | ++         | ++          | ++        | ++         | none  | none    | +        | none       | +
| Robustness            | none      | none       | none        | none      | none       | ++    | ++      | none     | none       | none
| Learnability          | ++        | none       | none        | none      | none       | none  | none    | ++       | none       | none
| RunUnattended         | none      | none       | none        | none      | none       | none  | ++      | none     | none       | none
| Testability           | ++        | ++         | none        | none      | ++         | ++    | none    | none     | none       | none
| RepairTurnaroundTime  | ++        | ++         | none        | none      | ++         | ++    | none    | none     | +          | none


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


