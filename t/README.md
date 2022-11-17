# Quality Plan

Table of contents:
- [Quality goals](#quality-goals)
- [Realization](#realization)
- [Evaluation](#evaluation)
- [Setup unit tests](#setup-unit-tests)
- [Conventions](#conventions)
- [Lessons learned](#lessons-learned)


## Quality goals

| Essential Goals¹                   | Why² + Scope
|------------------------------------|-------------------------------------
| Monetary costs &#8815; PC+Internet | Solo-developer non-profit side-project; Out of scope: distributed scraping with unique IP addresses (due to request throttling); we can easily wait for results
| Unattendability                    | Scraping can take hours: allow people leaving the computer/process or running the toolbox on a remote computer/server
| Fault-tolerance                    | Scraping can take hours: expect Internet connection issues, Goodreads has exceptions and is sometimes over capacity or in maintenance mode, invalid dates, ...; supports unattendability goal (FT is not high availability)
| Resumability                       | Scraping can take hours: allow intentional breaks, expect program or computer crashes, power issues -- we don't want to start from the beginning
| Testability                        | Scraping the Goodreads website expects stable HTML/JS-parts and we cannot know in advance when and where changes will occur (long-term failure). So regular and throughout (i.e., automated) testing is needed.
| Correctness                        | Worst case: wasted computer time and power-consumption, missed book discovery opportunities, too many annoying/useless emails (recentrated); Out of scope: formal proofs, deep specifications
| Repair Turnaround Time             | Scraping can take hours: shouldn't impact regular debugging too much
| Ease of use on UNIX systems        | Out of scope: Windows, GUIs, Browser-Addons, SaaS too much effort, although it would increase potential user base
| Learnability                       | Lot of program options and functions (libs), you cannot remember everything; no docs = no users; correct use and some expectation management supports correctness goal
| Integrity                          | Users on GR might try to abuse scrapers such as our programs or other programs (reading our outputs) by saving rogue strings in reviews, usernames etc (XSS)


¹) [List of possible goals...](https://en.wikipedia.org/wiki/List_of_system_quality_attributes)  
²) Risks, worst-case, constraints, ...



## Realization

| Activity¹              | Coverage/Frequency                                    | Operational Notes
|------------------------|-------------------------------------------------------|-------------------------------------------
| Unit testing           | libraries' public functions                           | Use cache &lt; 24h
| Regression testing     | before pushing to GitHub and inside new Docker images | Running unit-tests automatically via [a git-hook](../git-hooks/pre-push) reduces chance of distributing a buggy release; per-commit would be annoying because some tests need 3-8 minutes (w/o cache)
| Manual testing         | user-scripts, when sth. significant changed           | Automated UI tests are not worth the effort here. <br>Manual fault-injection: Disable network. <br>As a one-man side project, this also has its limits in terms of effort
| Syntactic check        | user-scripts, before each commit                      | Automatically via [a git-hook](../git-hooks/pre-commit), because small (accidental) changes are not always manually tested but break things too; `use strict; use warnings;`
| PushLogicDownTheStack  | user-scripts                                          | Have very little code in the user-scripts by moving as much code as possible into the libs (down the technology stack). <br>Tests covering the libs would cover most fallible code, good enough to gain confidence. External libraries are usually more mature. <br>Less repetition in user-scripts, centralized changes, technical debt and code smells isolated (API higher importance)
| Persistent caching     | all scraped raw source data (not results)             | Caching the _sources_ makes it easier (faster) to fix scraping and calculation errors. Caching (false) _results_ would require to download sources again which takes much time. CPU is cheap, I/O expensive. <br>Also easier to build apps _on top_ of that, apps don't need to care about caching/it's fully transparent.
| Outwait I/O issues     | libraries                                             | Wait, retry n times, skip less important
| HTML entity encoding   | user-scripts HTML generation                          | Prevent XSS
| Docker container       | all                                                   | Scripted builds/uploads via Makefile; I moved from DockerHub to GitHub, automatic builds cost money now
| Makefile               | dependencies, Docker, developer-setup                 | 
| Unit test = tutorial   | libraries, emergent                                   | Reduce errors caused by incorrect use or assumptions; no need to write (outdated) tutorials
| Inline man pages       | user-scripts, program parameters, examples            | Use Man-page POD-header in each script: more likely to be up-to-date, and can be extracted and displayed on incorrect program use
| Help files             | user-scripts, everything but program parameters (DRY) | Markdown-file in help-directory, with screenshot, motivation, install instructions, lessons learned etc; program parameters documented in man pages
| Documented conventions | user-scripts, common program parameters               | developer, consistent look and feel, principle of least astonishment (POLA)
| Field failure reports  | ask for reports, contact opts in scripts / help       | 
| Issue tracking         | all                                                   | GitHub Issue Tracker: feedback (feature requests, usage problems), troubleshooting history
| Version control        | all                                                   | Git and GitHub: reverting code/source history, releasing, sync between computers
| Use free softw. only   | all                                                   | Free as in beer


¹) Quality assurance activities: defect prevention and product evaluation (quality control/testing)


Considerable:  
- Perl taint mode (`perl -T`)





## Evaluation

| Goal                  | Unit | Regr | ManT | Synt | Down | Cach | Wait | HtmE | Dock | Make | ManP | Help | Conv | Issu | VC   | Free | Overall
|-----------------------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|
| Monetary costs        | none | none | none | none | none | none | none | none | none | none | none | none | none | none | none | +++  | strong
| Correctness           | +++  | +++  | +++  | ++   | +++  | none | none | none | ++   | none | +    | +    | +    | ++   | none | none | strong
| Unattendability       | none | none | none | none | none | none | +++  | none | none | none | none | none | none | none | none | none | weak
| Fault-tolerance       | none | none | +    | none | none | none | +++  | none | none | none | none | none | none | none | none | none | weak
| Resumability          | none | none | none | none | none | +++  | +    | none | none | none | none | none | none | none | none | none | strong
| Testability           | +++  | +++  | none | none | +++  | +    | none | none | +    | none | none | none | none | none | none | none | strong
| RepairTurnaroundTime  | +++  | +++  | none | none | ++   | +++  | none | none | none | none | none | none | none | none | +    | none | strong
| Ease of Use on UNIX   | none | none | none | none | none | none | none | none | +++  | ++   | +++  | +++  | +    | none | none | none | strong
| Learnability          | ++   | none | none | none | none | none | none | none | none | none | +++  | +++  | +    | none | none | none | strong
| Integrity             | none | none | none | none | none | none | none | ++   | none | none | none | none | none | none | none | none | at-risk

Values: +++, ++, +, none (does not address this goal)  
Overall assurance: strong, weak, at-risk

Note: As a rule of thumb, it takes at least two "+++" activities and one "++" to give a "strong" overall rating. 
Likewise, it takes at least two "++" and one "+" activities to rate a "weak" overall rating.




## Setup unit tests

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



## Conventions

### Program calling conventions

Don't redesignate these switches in new or extended programs:
```
-c,  --cache
-d,  --dict
-i,  --ignore-errors
-o,  --outdir     or  --outfile
-r,  --minrated   or  --ratings    (TODO confusing)
-s,  --shelf
-u,  --userid
-?,  --help
```


## Lessons learned

### Speeding up scraping

- pay attention to the _print_ functions of Goodreads, they may offer more data for 1 request than the web view, e.g., 200 book titles instead of 30 (requires login!)
- due to Goodreads request throttling, multi-threading requests had no significant performance impact but made code more complex;
	It will likely require access with multiple IP addresses. 
	So far it didn't seem worth the effort.
- the official API is slow too; 
	there is also the risk that this will be slowed down even more if Goodreads has capacity problems again. 
	This API is [not used internally](https://www.goodreads.com/topic/show/18536888-is-the-public-api-maintained-at-all#comment_number_1) and is rather neglected.
	API users are of secondary importance compared to web users.
- use a cache
- although good idea when scraping, on Goodreads there's no need to retain backwards compatibility to older page versions from other servers


### Typical scraping mistakes on Goodreads pages

- number formats: "1,123,123"
- dates such as "Jan 01, 1010"
- TODO


