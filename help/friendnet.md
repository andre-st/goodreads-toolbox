# friendnet.pl

![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)


## Analyze your Goodreads.com social network

Spiders your social network and creates files with edges and nodes which can be
easily processed with social network analysis software.


## Output

```console
$ head friendnet-nodes.csv friendnet-edges.csv
==> friendnet-nodes.csv <==
id,name,img_url
50965461,"Peter Hesar",https://images.gr-assets.com/users/1514444137p2/50911111.jpg
15232357,"Carole Arsifeult",https://images.gr-assets.com/users/139552226262/15222217.jpg
41256336,"Jordan Teller",https://images.gr-assets.com/users/1427180778p2/41444336.jpg
4112343,Tim,https://images.gr-assets.com/users/1432411115p2/4114553.jpg

==> friendnet-edges.csv <==
from,to
15234712,18525218
15234712,8251216
15234712,13152689
15234712,9362611
```

Comma-separated values (CSV) files can be easily processed with any social network 
analysis (SNA) software such as `R` with the `igraph` package or similar.
You can ran other statistics software or query languages against CSV-files too, 
e.g. `q` is SQL for CSV. 
A user sent me a screenshot with Excel processing these data, which looked good too.


## Social network analysis (SNA)

Generated network type: 
- Egocentric (not sociocentric/complete), 
- Directed   (not undirected), 
- Binary     (not valued), 
- One-Mode   (not bipartite/multi-mode), 
- Connected  (not disconnected)


![Network](img/friendnet.png?raw=true "Network")


```R
TODO: R/igraph-examples:
- direct influence on neighbours (degree centrality)
- brokerage or gatekeeping potential (betweeness centrality)
- influence entire network most quickly or: who hears news first (closeness centrality)
- influence over whole network, not just neighbours (eigen centrality)
- probability that any message will arrive (page rank)
- linked by many nodes that are linking many other nodes (Kleinberg authority score)
- community detection
- ...
```

```console
TODO: q-example "Members popular among your friends"
```


## How to generate this on a GNU/Linux operating system

1. [Install the toolbox](../README.md#Getting-started)

```console
$ ./friendnet.pl --help
$ ./friendnet.pl goodlogin@example.com

Enter GR password for goodlogin@example.com: ******************
Signing in to Goodreads... OK
Traversing #18418712's social network (depth=2)...
Covered: [100%]
Writing network data to: 
./list-out/friendnet-5685856-nodes.csv  (N=76622)
./list-out/friendnet-5685856-edges.csv  (N=106974)

Total time: 195 minutes
```

**Note:**

You can break the process with <kbd>CTRL</kbd>-<kbd>C</kbd> and continue later
without having to re-read all online sources again, as reading from
Goodreads.com is very time consuming.  The script internally uses a
**file-cache** which is busted after 31 days and saves to /tmp/FileCache/.



## Observations and limitations

- long runtime: Goodreads slows down all requests and we have to load a lot of data



## Feedback

If you like this project, give it a star on GitHub.
Report bugs or suggestions [via GitHub](https://github.com/andre-st/goodreads-toolbox/issues) 
or see the [AUTHORS.md](../AUTHORS.md) file.


## See also

- [friendrated.pl](friendrated.md) - Books common among the people you follow
- [friendgroup.pl](friendgroup.md) - Groups common among the people you follow
- [likeminded.pl](likeminded.md)   - Find Goodreads members with similar book taste
- [recentrated.pl](recentrated.md) - Know when people rate or write reviews about a book
- [similarauth.pl](similarauth.md) - Find all similar authors
- [search.pl](search.md)           - Sort books-search results by popularity or date published
- [savreviews.pl](savreviews.md)   - Get all reviews of a book


