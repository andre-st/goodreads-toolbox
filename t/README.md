# QA Plan


## Quality goals

| Goal                                 | Why
|----------------------------------|-------------------------------------
| Low costs (TCO)                                | Solo-developer non-profit side-project; Out of scope: distributed scraping with unique IP addresses (request throttling); we can easily wait for results
| Correctness                   | Worst case: wasted computer time, missed book discovery opportunities, too many annoying/useless emails (recentrated)
| Fault-tolerance                    | Scraping can take hours: expect Internet connection issues, Goodreads has exceptions, sometimes over capacity, invalid dates
| Resumability                    | Scraping can take hours: allow intentional breaks, expect program or computer crashes, power issues -- we don't want to start from the beginning
| Ease of use on UNIX systems                                  | Out of scope: Windows, GUIs, Browser-Addons, SaaS too much effort, although it would increase potential user base
| Learnability                      | Many program options and functions (libs), you cannot remember everything
| Unattendability                   | Scraping can take hours: allow people leaving the computer/process or running the toolbox on a remote computer/server
| Testability                 | Scraping the Goodreads website expects stable HTML/JS-parts and we cannot know in advance when and where changes will occur (long-term failure). So regular and throughout (i.e., automated) testing is needed.
| Repair Turnaround Time        | Scraping can take hours: shouldn't impact regular debugging too much
| Integrity                          | Users on GR might try to abuse our programs or other programs (reading our outputs) by saving rogue strings in reviews, usernames etc



## QA activities

| Activity              | Coverage/Frequency                                 | Notes
|-----------------------|----------------------------------------------------|-------------------------------------------
| Unit testing          | libraries' public functions                        | 
| Regression testing    | run unit-tests before changes are pushed to GitHub | automatically via [a git-hook](../git-hooks/pre-push), reducing the chance of distributing a buggy release
| Manual testing        | user-scripts, when sth. significant changed        | automated UI tests are not worth the effort
| Syntactic check       | user-scripts, before each commit                   | automatically via [a git-hook](../git-hooks/pre-commit), because small (accidental) changes are not always manually tested but might break things too
| PushLogicDownTheStack | user-scripts                                       | have very little code in the user-scripts by moving as much code as possible into the libs (down the stack). Tests covering the libs would cover most fallible code, good enough to gain confidence; less repetition in user-scripts, centralized changes
| Persistent caching    | all scraped raw source data (not results)          | 
| Outwait I/O issues    | libraries                                          | wait, retry n times, skip less important
| Test as a tutorial    | libraries, emergent                                | reduce errors caused by incorrect use or assumptions; no need to write (outdated) tutorials
| Inline man pages      | user-scripts, program parameters, examples         | Man-page POD-header in each script: more likely to be up-to-date, can be extracted and displayed on incorrect program use; correct use supports correctness goal
| Help files            | user-scripts, everything but program parameters    | Markdown-file in help-directory, with screenshot, motivation, install instructions, lessons learned etc; correct use/expectation management supports correctness goal
| Field failure reports | ask for reports, contact opts in scripts / help    | 
| Issue tracking        | all                                                | GitHub Issue Tracker; feedback (feature requests, usage problems); troubleshooting history
| Version control       | all                                                | Git, GitHub, reverting code/source history, releasing, sync between computers



## QA activities evaluation

| Goal                  | Unit | Regr | ManT | Synt | Down | Cache| Wait | Help  | Issue| VC  
|-----------------------|------|------|------|------|------|------|------|-------|------|------
| Correctness           | ++   | ++   | ++   | ++   | ++   | none | none | +     | +    | none
| Fault-tolerance       | none | none | none | none | none | none | ++   | none  | none | none
| Resumability          | none | none | none | none | none | ++   | +    | none  | none | none
| Learnability          | ++   | none | none | none | none | none | none | ++    | none | none
| Unattendability       | none | none | none | none | none | none | ++   | none  | none | none
| Testability           | ++   | ++   | none | none | ++   | +    | none | none  | none | none
| RepairTurnaroundTime  | ++   | ++   | none | none | ++   | ++   | none | none  | none | +   
| Integrity             | none | none | none | none | none | none | none | none  | none | none


Values: ++, +, -, none (does not address this goal)



## Observations and limitations

- some unit-tests need 3-5 minutes due to request throttling (and we need to test online to detect website changes): gsearch, greadreviews; 
	running unit-tests before each commit would be too annoying and would motivate circumvention. So we only test before each push. I use a cache-age < 24h for some tests, though, so that debugging tests doesn't become a PITA.
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


