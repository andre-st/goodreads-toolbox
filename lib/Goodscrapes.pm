package Goodscrapes;
use strict;
use warnings;
use 5.18.0;
use utf8;

###############################################################################

=pod

=encoding utf8

=head1 NAME

Goodscrapes - Simple Goodreads.com scraping helpers (HTML API)


=head1 VERSION

=over

=item * Updated: 2018-08-12

=item * Since: 2014-11-05

=back

=cut

our $VERSION = '1.91';  # X.XX version format required by Perl


=head1 COMPARED TO THE OFFICIAL API

=over

=item * focuses on analysing, not updating info on GR

=item * less limited, e.g., reading shelves and reviews of other members:
        the official API just gets you excerpts(!) of max. 300(!) reviews,
        Goodscrapes can scrape thousands of fulltext reviews.

=item * official is slow too; API users are even second-class citizen

=item * theoretically this library is more likely to break, 
        but Goodreads progresses very very slowly: nothing
        actually broke since 2014 (I started this);
        actually their API seems to change more often than
        their web pages; they can and do disable API functions 
        without being noticed by the majority, but they cannot
        easily disable important webpages that we use too

=item * this library grew with every new usecase and program;
        it retries operations on errors on Goodreads.com,
        which are not seldom (over capacity, exceptions etc);
        it saw a lot of flawed data such as wrong review dates 
        ("Jan 01, 1010"), which broke Time::Piece.

=item * Goodreads "isn't eating its own dog food"
        https://www.goodreads.com/topic/show/18536888-is-the-public-api-maintained-at-all#comment_number_1

=back


=head1 LIMITATIONS

=over

=item * slow: version with concurrent AnyEvent::HTTP requests was marginally 
        faster, so I sticked with simpler code; doesn't actually matter
        due to Amazon's and Goodreads' request throttling. You can only
        speed things up significantly with a pool of work-sharing computers 
        and unique IP addresses...

=item * just text pattern matching, no ECMAScript execution and DOM parsing
        (so far sufficient and faster)

=back


=head1 HOW TO USE

=over

=item * for real-world usage examples see Andre's Goodreads Toolbox

=item * C<_> prefix means I<private> function or constant (don't use)

=item * C<ra> prefix means array reference, C<rh> prefix means hash reference

=item * C<on> prefix or C<fn> suffix means function variable

=item * constants are uppercase, functions lowercase
	   
=item * Goodscrapes code in your program is usually recognizable by the
        'g' or 'GOOD' prefix in the function or constant name

=item * common internal abbreviations: 
        pfn = progress function, bfn = book handler function, 
        pag = page number, nam = name, au = author, bk = book, uid = user id,
        bid = book id, aid = author id, rat = rating, tit = title, 
        q   = query string, slf = shelf name, shv = shelves names, 
        t0  = start time of an operation, ret = return code, 
        tmp = temporary helper variable

=back


=head1 AUTHOR

https://github.com/andre-st/


=cut

###############################################################################


use base 'Exporter';
our @EXPORT = qw( 
	$GOOD_ERRMSG_NOBOOKS
	$GOOD_ERRMSG_NOMEMBERS
	gverifyuser
	gverifyshelf
	gisbaduser
	gmeter
	gsetcookie 
	gsetcache
	gsearch
	greadbook
	greadshelf 
	greadauthors
	greadauthorbk
	greadsimilaraut
	greadreviews
	greadfolls 
	amz_book_html 
	);


# Perl core:
use Time::Piece;
# Third party:
use URI::Escape;
use HTML::Entities;
use WWW::Curl::Easy;
use Cache::Cache qw( $EXPIRES_NEVER $EXPIRES_NOW );
use Cache::FileCache;


# Non-module message strings to be used in programs:
our $GOOD_ERRMSG_NOBOOKS   = "[FATAL] No books found. Check the privacy settings at Goodreads.com and ensure access by 'anyone (including search engines)'.";
our $GOOD_ERRMSG_NOMEMBERS = '[FATAL] No members found. Check cookie and try empty /tmp/FileCache/';


# Misc module constants:
our $_USERAGENT    = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13';
our $_COOKIEPATH   = '.cookie';
our $_NOBOOKIMGURL = 'https://s.gr-assets.com/assets/nophoto/book/50x75-a91bf249278a81aabab721ef782c4a74.png';
our $_NOUSERIMGURL = 'https://s.gr-assets.com/assets/nophoto/user/u_50x66-632230dc9882b4352d753eedf9396530.png';
our $_SORTNEW      = 'newest';
our $_SORTOLD      = 'oldest';
our $_EARLIEST     = Time::Piece->strptime( '1970-01-01', '%Y-%m-%d' );
our $_STATOKAY     = 0;
our $_STATWARN     = 1;  # Ignore or retry
our $_STATERROR    = 2;  # Abort  or retry
our @_BADPROFILES  = 
[
	'1000834',  #  3.000 books   NOT A BOOK author
	'5158478',  # 10.000 books   Anonymous
	'2938140',  #  2.218 books   Jacob Grimm (Grimm brothers)
	'128382',   #  2.802 books   Leo Tolstoy
	'173327'    #    365 books   Germany (Gov?)
];


# Reviews search dictionaries:
our @_REVSRCHDICT = qw(
	3 4 5
	ing ion tio ati ent ter the ate con men ess tra ine and nce res pro per cti ect for tic sth rat sta ste ica ive ver est
	tin str tor one ist all int com rea ant ite age lin ble ran rin cal der nte anc ity ure oun eri ain ers ear nal iti her
	act ted era tur sti ons ort art lan lat man ell igh tri nes ial ous gra ast nti enc ack ice ide par cha lit ric min ass
	ill cat red pla und ree ard eat pre dis out ove ont ght our din ian tal mat eme ang sio tiv tat che ina nta hea ona sto
	ome abl ali ral ake nde lea ead ssi tan nge low eas rac ntr mon ind tte rit car ore den lar rou tro hin ili ten pri wor
	ria are end rec ner ren nin har olo ary ele lle ish chi ave tre han ari unt ith kin sin ula ere ail ope lic wit ser ost
	les ins spe fic omp ies nat ase orm ern ace lac ood cre ene sur ust gen ple col tai pin sit ces ini ens ock mar por ans
	ori ato ris hor rop cou eve rti nit use tle tar uct oli air ndi mer pos cle ber erm ese ron ani sis tem log cor ise ord
	ler rai ath gre rma ime ire rom ile oll ert met bil off tch edi ara win lli oni ach led can las att old sho own llo pen
	cia omm arr ade ose duc thr eco cen ros ory inc shi nic ana cul ale war ora son sel osi ult acc mor ame dia roc rad eed
	rie lec ita esi tru app fer rap row ven ger ark ici ond eli ret cke ton rch oth mal spo ick ete ong tes owe lly lis tim
	nst pec fin cro bra erv cto nsi rel ote rot wer ura rol sse adi ien qua hol sea let eal oss que fac val eti ole gin tho
	vel ane nis ign ual sha ork cur qui uni bla uri gro dit tom ker thi mou pol rge bre lla aci oma iss mic she ram uti tit
	len yst sen rem fro cho tis lig iat oin ifi hit oot pan isi nch equ eta ape dge nts ket pat hro ffi rre sal hou nne mis
	eni ery rde ban roo err mpl whi cla ami ean ode ffe pho pti ded rus des ier spi bac ogr ras sec cer mil bro eci sca bar
	ima tab amp net loc flo cap ala tec arc wat arg atu unc ctu tia ism exp nci emi ivi vic pea bri ppe ush eet mit los dic
	usi lon lue bea orn clo hav rse cie scr ero cas omi mpe sid nda rth rro sig cra imp abi lia emo ann ett rog ech oti nse
	emp med ute rep rio fil loo arm dat rig ook ngl eel lay tie fla ize pli itt oce ash mot dro dow inf eak aph ool bal ank
	rce oph sor sol fis elf mag nto rid ono asi roa sed fir ttl ema rod ruc pha een erc hic urn hes pot cri ses ild ott uit
	ull mbe nar spa pac eck ict tel ept get hal reg ugh put ela mos not dea sys bli del mea eng rag oto rim ncy hip ned lem
	sup oad mpa set cin sub onc lie rip riv sco woo cit ext ume hil avi bel ata tee alt gle uth non ium abo lif eth phi ful
	try eep evi isc cel eac lor bor bus fre nan sch bas lou etr dra ors dec odu eld iza bat mme nia vin dri bit way aut iou
	ves ped dle rri til top hel vis arb nsu ppl cut oil nve stu itu erg ref sou blo hee ink rke pon lum hon ece ump atc cep
	lim mod bou his pit sat umb ngu tea hoo rte mas cop but phy ssu pic ife rna ubl bon ngs sic ike ola olu oat boo ngi poi
	ctr iso gat tak utt rvi ogi ily lde wee ray nom lam dar gar rni rdi eam fie mak mul erf ogy add eig nds bin dep tag imi
	tac oci san pul pai rve urs tme hai irc uck oug rmi ics ama orc cco mac fra cus fun ars fec ecu lti gic sla def ked wel
	ced ena sil vol tif lab hed ito nor oca mus aff vat day hig ndu goo cid mpo sia pet cli leg mai mmo elo upp edu soc hem
	hre ndo urr pal hot lev cce dre ipe ney sma lot ino ota ski pas ule bir pur lve alu zat mes tti nec fly jec iel arl liv
	dev liz ird egi gan cos ein rib wal iva eye bur rob foo eer isa vio lut adv rne orr fri eav nag loa edg cte epa blu hat
	pow wea oor vit uar sso als bul amm ano emb dan dem gua uro ega onf plo eno ldi fee nni yel urc lid rab sul ied ges gla
	omb rry oup lop aft ida mun dio cis nth sum iff law sna rum run eff siv idi rta oom too die iol rcu rev lus esc cip nco
	mmi efe yme opp tua alo nct uat rov ysi num ede syn tud uil hen sci icu coa rso inv ndr phe oke yin aga van obi ham rra
	itc asu rav any opi uff apa nee rsi ype pay fle squ chn nos gal raw uen heo ely oly rst sem amo hop ich lad urt flu nel
	bee exc ues toc tha lip oge onn hos odi amb ior gas tto boa dom ovi ged cir aus gol spr ibl ung omo efi now udi xpe aro
	has ppo eor agr gue nam sce cil mmu arn oid ssa gui aly onv fou pie pra rty ift rme isp org rew dus nfo vid ibi inn raf
	owl mel mov eaf ois gri uto nsp isk rga gem atr oar ico key fit iga rof orp nme rds ipp osp alk hri pir whe awa ody div
	nio lai two nea urg esp fal gna rei sli nut vil dam swi rmo sts nou dou kno lag dir api gul ila opo agi ige hom igi ipl
	erp coo ety gai ril pee yer fai mol ecr nol cum don epo pil gis icl dif hyp agn epi iqu mem epe var req sle gon egr doc
	cab mma ava opt oro lte neu erb shr avo lau beh obl opl new tum ask glo lov ude aki fam ago ror spl mpt irs scu aso ndl
	yea som cru giv eha wil tta clu fli tig lys riz ben cov inu bio nif chr ocu cam ibr oub pme ycl tou iri iet gne ncr cki
	imm nig rts uir its ckl gio hum lik lee geo iro oon rif bot hyd fen det typ och cyc ado erl ppr see ais pub rer ppi eur
	ibu nim eph eso pap rgi uce kee was uch uid fol vir iod irt omy mid hur dul tax aul bui ait oxi irr bed icr sty upe nai
	ved ods ilt cot arp vie bod ydr axi tol thy tow alc uss oco lio tas tub opa zin nak deb rly dde osc bol ube gam rci iab
	dal kle swe anu lta sib hie ira alm ubs far bab ddi pop fig aye orl rey aug mpi hod bet plu abb cks ada rbo sph mpr het
	cem hap ibe gia rui nfl aca chu nen uis rli smo ltu nso wri box abs rar rva stl une nke eek rsh mpu tly aid epr ilk mbi
	enn ngt acr lex niz pel exa idg nsa iag nfe uma eop fus tip nfi elt alv smi rbi ken lls oul tut oof eva bst una cta unn
	nna zon lyc ply apo tun bia eca rpo gly ets loy afe ebr stm exi aco mbl ipa tap esh occ asp uns urp ofi rld tog imu ege
	fes rki cup pig dog pid xtr fur ilo sag dee igu egu olt coc efo dur ccu eon gge iar lse uca bje cei sac uta fte rfa rub
	oop uli ees ddl bbl itr rak uan nga oos dmi gli uag hir ony rba umm sus tam vem hru nem rtu aym llu dru fat asc gea teg
	wom gth ilm tus umi aba ntu rul adm aud oic cts git bly ief wed pou ske hni ntl eto mia nas rms saf sun xte dor voi dly
	ipt rgy fea gni icy uin cod noc dig cau obs oba urv doo cio nki ynd hun jus zed usc agg alf hts lob urf hys poo nvi fru
	hte rpe eem nsf cif fet exe tos ova pip bru diu hec hab sue els suc mbo rfo sam joi oft zar moo lun apt dne fav hno gur
	lap udg ymp zer ady osa via tyl pto wan etl hag oac dve lth acu abe efu iew opy pte rbl wis fas ubb dol ley mbr noi neg
	bag sly gel how bic wne wre yca yle bbe psy tne lib imb oal obe slo umo fan fib rik swa wav ays odo uls arf sno urb you
	eou lep nab ids kni vor mba iec ouc enu vou efl edl ops tot sof nap vac ych idd ehi sne ury tid oct rle rsa pta rup adj
	etw rwa dua kil irl sym bad rug dwa vet ecl eec opm tex cui chl egg tei luc sex ypo usa wir hid igr nua wle ats eol asa
	eap ebe gir wes irm nuc wei bes lom pis cry pse ngo opu rtr wag jac tep cyt aim sim hio neo reb coi oso mum dry sui cko
	mph nop sme eda ego twi unk nac owi tir hei bow lug rpl oan oas rbe rks sop abr erd lef lub rau aps idu wid bun lav bso
	scl cci dva lph xpo aun evo cad lur epl ucl siz ulo roj atm opr roi ifo oje nsh mur upt eum hoe usl eba etu job ixe alp
	sep env fix hob tiz acy dim aem leo orb owa uge niv hoc kit ocy rpr uga ias yth gag sar aur oki pes esu tib tyr yli haw
	rtm pus nnu twe yna deg erw ngr seq hme ips nus sab oxy bse pum xed eft nsc ucc cav utu etc kne eut ewa apy pag fau ilv
	auc azi kes uty agu sau uld onm oud reh xic dju syc upl nno xch iot big hib ald gno vas cqu ipm eho epu eag ruf sfe xam
	urd leu awk ebt leb liq eab acq bom gun mig mix peo bec yed ify ewe uel had rph iam rtl ulp inh inj dli gor ugg asm eau
	ils yan eit gus niu ncl saw lmo rco nov hae iry hau rok dos map uts edo mec otr lil jun sav sua uic veh hia lym orw nur
	ews wai bis aby obj pun spu eds ulf oes utr yto osu who awn eiv alg aze ido ots ows iev rrh ofe mut fel lco mir lpi cea
	ddr mad mom hyl ios nie rto hly usp cka got ltr nsm cog riu aig dil poc uou ogn dut seu lty xpl iog rhe nju tli xid imo
	oms onk gov dvi hlo pia slu ams gme aer eru ths asy iny iop bug jur rut owd ptu toi adl apl vot igg ipi nad reo dai sky
	thu hra rfe rfl uip umn phr pyr nip nod uer yro yte ggl lfi olv oda sif xim xis hif isl nul toe vei kel udd dex nef goa
	yri ads ewo jud pad fid izi hoi owt abu eil ems chy onu niq sev arv oga tet yti aya dip ibb thm nca nog uci unf max ebo
	fem hog iac sug iom lyi eis yra ldr nbi quo oya wha dov xce sai ajo ocr nqu raz upi voc ewi xer cof obb cow jor mok mog
	uor acl hti kag usn moc udy elv nha rgo unb rox ufo bud ilu twa wth doi pio lyt oym igo loi rue bbi due fed yla ehe nuf
	tma itl yar erh mee rca rno yre ubi lme sie rud buc dop emu taf maj hle nre gfi iph avy chm hus odd ubj bid jou pod rha
	ulu isu exh tul ivo coh nfa dyn ndw soi tox haf lne nty ggi unr ghe ffl tla utc mbu mob muc glu ogu adr pep rnm shu dum
	lei nny beg boy cet edd ylo civ hut vey buy odp xin aza gob rys vag efr ols swo ums url jum rcl gum nob rda hyt dpe ipo
	nks uco yes exu rcr stn eez sod suf coe ngf nei yal yon agl rho eev nex tod ayi uad epp utp ynt ufa efa lax oye unp tty
	deo dst ffo uai zen usk dwe toa eke gau nfr uet luo ndy dys rru tsh vai azo kis lcu nav dag dap elm oak cca enz ius izo
	buf nsl nli rfi sad vul edn aty gou bum shm elp upr lwa nil adu edr nae dot ebi mst nle ryo thl rgu haz oby osy eud gil
	olf ryi cky lsi nvo yco aqu obo foc eps upo ebu eze xil gmy him inl esa oho rla tnu ims pne tpu psi veg uba uno das dhe
	eus hwa rlo did rns lel udo upa mud myo ogg lod nsw rix cyl urk ffa kid xpr iru nue rdo cuc dab hym utl gie uot lva rmu
	vip wax hep pyg rtn sap ttr fue ppa pru ckn dwi ppy teo ygm tuf wde xpa aka dib ulb wra wif cac iki kan yll ghi ghl lud
	cak gap inp fox onl tob xec cee zzl cub kir mam nly oit rwo gec ubt laz tay bsc cys nid eir lfa lua osm ncu uee bos ioc
	rpi ssm awe gho hbo ogo rfu rmy roe sot ssl lki oty awi hth lak nau nkl oet six tba poe say unl ypt erk kat hak kie oen
	agm boi eef lvi rnb ups ckb hac noo rqu wic adh enr tmo sei syl enh lga nwa cob npu sfo zle ilw cue meg atf enb kli lge
	lyp mop nze gos ssy nje oks ckw god moi xua gnm fiv lka ogl tfi uve hma aes bbo lui nva pik yma ffs nfu dun miz tfu ubm
	vab vib eot mni viv yie ymb gaz gma oqu apr bog idl igm kal vig abd emm fti nuo aic miu isf lci wro fut tga wou nhi pok
	umu eom ghb ngb gga goi cim dac hne lux rct rsu sef lca mys ued axe oir sni aws oys roy uda bei ftw ifu sas sew esk idn
	lbu ryn egy fev koo nhe dsc kly lul nla oru rtg sir ulk wet aux otc soa gib gog uzz dth rgr cic enl foi ntm tfo ync fug
	ubr aeo arw bsi lts lds soo yph ayo lma teb yge zoo alb rpt thd ulm xtu lbe dsh emy exo fab hex hov pth shy tau xes xia
	bay eyo ahe awf oam awl ryp sbe ggr jar onz pab tsi yno lba liu oel kar lae yfi ixt obu otb sku uds vap itz nka ugu xat
	gru odg bef edy irp ccl eic ffu ifl odl xha puf ugs nui jaw kic ixi seg wol bdo hyr thw web yne bak itn nep ohe ocl rvo
	ulc bai izz nbo xit ddy iap idt inq urm rwi bey esm mps rsp dba elu euk enf ska bik emn onj dca xti apu cht lgi llf olk
	pup rdl uln eys ibo joy nbe ozo seh rae ryt smu aum dod dox irg nyl nym siu eos rbu vec mmy rhi ubu jet nbu nho unm wam
	xyg iba lfu tup unw yng bie heq omf bby ndb wbe yot awb eny gif hdr sks zel maz mie uum uxi bba hoa kul lbo mne ndm tbi
	uas obt shl tuc ovo rej rhy amy lmi nev sip tew lst mew rls ryl wim yee ymo mab myc oed seb diz rpa ulg egm fia jew nzy
	egl hiv hmi xio huc lch axo gbi itm osh xhi ypr foa fts oov uiv bub fyi inb ecy gab kla noe oef owh ypi axa dwo kwa owf
	oze pht htl ksh bov dgi eip eoc hug lew lke lro nun oxe pom zym lso ohn rah uvi hli hub ngh adc bam fon kwe ssn ygo phu
	xan mfo pau yda amu eje gee gut jer nro xci wig lyf owb ugl ccr cuu dei vea xon ayl dew jug lky orq rwe tav aha euc uph
	aho elb eog rps bta dla euv kab lfl lto obr tse cig dma paw tue aor fow inm unh adg cag jam wsp yor azz mug roh sov tad
	yse chw isy tok ffr tov xyl geb gwo isd kha tst wns ciu elc tef xem ceo ckt few ipu mna sfu teu fos gyp htn npr oer psu
	sba uke yce dau ecc gim nba otl bry gid iad ipr nma reu yss aec ieg kho shw sow wak xcl egn hiz ilr otu zil ggy hok idy
	kip ubo uft zza eup kup lwo amn lyn mso fum lpa tze uko bts dho dso dye peu tiq uie wen bib cun ika orf sve dfi jel jui
	nsk oap cef eid eim npo oem pov tiu fei olp rex yab deh ulv ymm dup edb nsv taw gop nwo onw syr toy lol nud xca xcu cae
	eyb hef ilb mse owr shn tdo xen yit cyp dme ngn onr rtz uru vau bob bys hew kra lks mle ohi ybo hyg kto lps ybr aln ctl
	kim lln mye pst kon ogs peg pud rao ucu xac ybe ymn ags nub rdr rua rye wfi esn ewt hay lyb lye mim pty atl ezi kou pef
	rtf tca thn tja won hyb nri oxa uak ubc xle ckg gyr kma odr wfl wni hla isr ndf ofo pog snu dyl edw gyn ngd ofa sax usu
	wny aru cku gst kdo pew roz tsc duo hwo kgr kst pav wli ywo anz fif fog may oha pso sfa utd zeb anl chs eki tof zab anx
	ifr kbi ndp yba ygi zol anh neb rur wry ymi ckh gad gha ifa iit ldo llb njo olc pae ttu xif zor egs kro lgo sms ssh sud
	wab cai gdo gym ilf nlo orh ozz ryd sey xie yps mbs nik noz ntb wip caf dbo lsa npa olm omn pug tui irb loe phl rka ysp
	afi ckf eyi llm lsh sak sbo sut axl hik hwe lfo rax rgl tco ueb aed ehy kov lpe lyg rdw yog bap oka rpu shb sob ssf xur
	zan gta hfu kru nxi stp tni yac cib eiz rcy bev mio ntw ohy buz ckp dgm fuc ilg lce ldl pbe rsl ybi asb kfa myr nkr nof
	ueu cch ggs jok tym ypa afl esq eya kor wly yru adw htj isg xib ckr lal neq yop gns nky nzo ugi vow afo dmo eks eod lry
	lya pam puc vre adf bmi cua dlo kta nkt odc ruv wfu wiv yni ysm
	); # N=3349, most frequent english n-grams first


our @_REVSRCHDICT_OPTIMIZED = qw(
	3 4 5

	let wit ing put ten met ass ini bit lit men job get rat cut mix our
	are owe win all con hit the use pre ran ist ate you art per era ton
	her end ter lot old one and low fit was fan too ill dec add tho pay
	row tra ver act mad sat awe nor ive can new car had ish for tan pro
	she lea ice not age two cat got off far lay wee tea try day kid est
	sin way red etc par sit ser com cos led sum fed see own son mum por
	out via saw fun rid ear ink now eat his hes mid but eye han ugh ron
	bar who ask dit yea fav how pop bad due bug don sci sad set ame hot
	man dry ago air lie fly run did bat law bed tip leg cry has mom tie
	bag yes boy top ese gem him bus map war fix amo odd wat its app tal
	owl mil dog las pun arc nth che buy egg fat der dia ler mal pig key
	tom mis pet sun beg big alt hid que dat any box eso sex del rip nos
	sea sky ama leo hog und ban sus lee aug mon mas til den ans hut yer
	aka itu bet pen dig net nov asi boa ele los eve lei dio una vas tak
	gap ale ont fue min tag les bow non hal sem imo rob uni sue ein ook
	dan aun boo fin tem qui ins arm nel ora ref tim ani hop pan sam chi
	hat ada lil esa nut poi inc sub api pat aid umm bin lad def uno doo
	oli oct nit mes vol lap bir din pra pie tha mit dis sis uit ect sur
	cap ben mai int ali ilk pub max dos mia eva dal raw flu wer ile des
	gue dar pot bon elf har ven dip log ide apa mud wel bom woo ray cup
	toe ant aim gar ero	
	
	    ion tio ati ent                     ess     ine     nce res    
	    cti         tic sth     sta ste ica             tin str tor    
				 rea     ite     lin ble     rin cal     nte anc ity
	ure oun eri ain ers     nal iti         ted     tur sti ons ort    
	lan lat     ell igh tri nes ial ous gra
	
	); # N=390, most frequent english trigrams tested against Harry Potter
	   # reviews: each led to 10-30 unique(!) hits, best first.
	   # Appended most frequent english trigrams which are not
	   # already present in the Harry Potter set.
	   # Works better with a larger set of available reviews.
	   # Randomization yield no improvements (rather opposite).
	   # Consider searching with trigram combinations ("let ing") 
	   # in order to get more unique results.


our $_cookie    = undef;
our $_cache_age = $EXPIRES_NOW;  # see gsetcache()
our $_cache     = new Cache::FileCache({ namespace => 'Goodscrapes' });



=head1 DATA STRUCTURES

=head2 Note

=over

=item * never cast 'id' to int or use %d format string, despite digits only, 
        compare as strings

=item * don't expect all attributes set (C<undef>), this depends on context

=back


=head2 %book

=over

=item * id          =E<gt> C<string>

=item * title       =E<gt> C<string>

=item * isbn        =E<gt> C<string>

=item * num_pages   =E<gt> C<int>

=item * num_reviews =E<gt> C<int>

=item * num_ratings =E<gt> C<int>    103 for example

=item * avg_rating  =E<gt> C<float>  4.36 for example

=item * stars       =E<gt> C<int>    rounded avg_rating, e.g., 4

=item * user_rating =E<gt> C<int>    number of stars 1,2,3,4 or 5

=item * url         =E<gt> C<string>

=item * img_url     =E<gt> C<string>

=item * year        =E<gt> C<int>    (publishing date)

=item * rh_author   =E<gt> C<L<%user|"%user">> reference

=back


=head2 %user

=over

=item * id          =E<gt> C<string>

=item * name        =E<gt> C<string>

=item * age         =E<gt> C<int>    (not supported yet)

=item * is_friend   =E<gt> C<bool>

=item * is_author   =E<gt> C<bool>

=item * is_female   =E<gt> C<bool>   (not supported yet)

=item * is_private  =E<gt> C<bool>   (not supported yet)

=item * is_staff    =E<gt> C<bool>   (not supported yet), is a Goodreads.com employee

=item * url         =E<gt> C<string> URL to the user's profile page

=item * works_url   =E<gt> C<string> URL to the author's distinct works (is_author == 1)

=item * img_url     =E<gt> C<string>

=item * _seen       =E<gt> C<int>    incremented if user already exists in a load-target structure

=back


=head2 %review

=over

=item * id          =E<gt> C<string>

=item * rh_user     =E<gt> C<L<%user|"%user">> reference

=item * book_id     =E<gt> C<string>

=item * rating      =E<gt> C<int> 
                       with 0 meaning no rating, "added" or "marked it as abandoned" 
                       or something similar

=item * rating_str  =E<gt> C<string> 
                       represention of rating, e.g., 3/5 as S<"[***  ]"> or S<"[TTT  ]"> 
                       if there's additional text

=item * text        =E<gt> C<string>

=item * date        =E<gt> C<Time::Piece>

=item * url         =E<gt> C<string>  full text review

=back

=cut




=head1 PUBLIC ROUTINES



=head2 C<string> gverifyuser( I<$user_id_to_verify> )

=over

=item * returns a sanitized, valid Goodreads user id or kills 
        the current process with an error message

=back

=cut

sub gverifyuser
{
	my $uid = shift || '';
	
	return $1 if $uid =~ /(\d+)/ 
		or die( "[FATAL] Invalid Goodreads user ID \"$uid\"" );
}




=head2 C<string> gverifyshelf( I<$name_to_verify> )

=over

=item * returns the given shelf name if valid 

=item * returns a shelf which includes all books if no name given

=item * kills the current process with an error message if name is malformed

=back

=cut

sub gverifyshelf
{
	my $nam = shift || ''; # '%23ALL%23';
	
	die( "[FATAL] Invalid Goodreads shelf name \"$nam\". Look at your shelf URLs." )
		if length $nam == 0 || $nam =~ /[^%a-zA-Z0-9_\-,]/;
		
	return $nam;
}




=head2 C<$value> _require_arg( I<$name, $value> )

TODO: line of code is useless when died

=cut

sub _require_arg
{
	my $nam = shift;
	my $val = shift;
	die( "[FATAL] Argument \"$nam\" expected." ) if !defined $val;
	return $val;
}




=head2 C<bool> gisbaduser( I<$user_or_author_id> )

=over

=item * returns true if the given user or author is blacklisted 
        and slows down any analysis

=back

=cut

sub gisbaduser
{
	my $uid = shift;
	return grep{ $_ eq $uid } @_BADPROFILES;
}




=head2 C<sub> gmeter( I<$unit_str = ''> )

=over

=item * generates a CLI progress indicator function $f, with 
        I<$f-E<gt>( 20 )> adding 20 to the previous value and 
        printing the sum like "40 unit_str".
        Given a second argument with the max value, 
        it will print a percentage.
        in a modern terminal, the text remains at the same 
        position if called multiple times

=back

=cut

sub gmeter
{
	my $unit = shift || '';
	return sub{
		state $is_first = 1;
		state $v        = 0;
		
		my $f  = defined $_[1]  ?  "%3d%%"                      :  "%5s $unit";
		   $v += defined $_[1]  ?  $_[1] ? $_[0]/$_[1]*100 : 0  :  ($_[0] || 0);  # 2nd ? avoids div by zero
		   $v  = 100 if defined $_[1] && $v > 100;  # Allows to trigger "100%" by passing (1, 1)
		my $s  = sprintf( $f, $v );
		
		print "\b" x (length $s) if !$is_first;  # Backspaces prev meter if any (same-width format str)
		print $s;
		$is_first = 0;
	};
}




=head2 C<void> gsetcookie(I<{ content =E<gt> undef, filepath =E<gt> '.cookie' }>)

=over

=item * I<filepath> is ignored if I<content> is set

=item * some Goodreads.com pages are only accessible by authenticated members

=item * copy-paste cookie from Chrome's DevTools network-view

=back

=cut

sub gsetcookie
{
	my (%args) = @_;
	my $path = $args{ filepath } || $_COOKIEPATH;
	$_cookie = $args{ content  } || undef;
	
	return if defined( $_cookie );
	
	local $/=undef;
	open( my $fh, "<", $path ) or die(
			"\n[FATAL] Cookie missing. Save a Goodreads.com cookie to the file \"$path\". ".
			"Check out https://www.youtube.com/watch?v=o_CYdZBPDCg for a tutorial ".
			"on cookie-extraction using Chrome's DevTools Network-view." );
	
	binmode( $fh );
	$_cookie = <$fh>;
	close( $fh );
}




=head2 C<bool> gtestcookie()

=over

=item * not supported at the moment

=back

=cut

sub gtestcookie()
{
	# TODO: check against a page that needs sign-in
	# TODO: call in gsetcookie() or by the lib-user separately?
	
	warn( "[WARN] Not yet implemented: gtestcookie()" );
	return 1;
}




=head2 C<void> gsetcache( I<$number, $unit = 'days'> )

=over

=item * scraping Goodreads.com is a very slow process

=item * scraped documents can be cached if you don't need them "fresh"

=item * during development time

=item * during long running sessions (cheap recovery on crash, power blackout or pauses)

=item * when experimenting with parameters

=item * unit can be C<"minutes">, C<"hours">, C<"days">

=back

=cut

sub gsetcache
{
	my $num     = shift || 0;
	my $unit    = shift || 'days';
	$_cache_age = "${num} ${unit}";
}




=head2 C<L<%book|"%book">> greadbook( $book_id )

=cut

sub greadbook
{
	my $bid = shift;
	return _extract_book( _html( _book_url( $bid ) ) );
}




=head2 C<void> greadshelf(I<{ from_user_id, ra_from_shelves, rh_into =E<gt> undef, 
			on_book =E<gt> sub{}, on_progress =E<gt> sub{} }>)

=over

=item * reads a list of books present in the given shelves of the given user

=item * I<ra_from_shelves>: string-array with shelf names

=item * I<rh_into>: C<(id =E<gt> L<%book|"%book">,...)>

=item * I<on_book>: receives \L<%book|"%book"> argument

=item * I<on_progress>: see C<gmeter()>

=back

=cut

sub greadshelf
{
	my (%args) = @_;
	my $uid    = gverifyuser( $args{ from_user_id });
	my $ra_shv =_require_arg( 'ra_from_shelves', $args{ ra_from_shelves });
	my $rh     = $args{ rh_into     } || undef;
	my $bfn    = $args{ on_book     } || sub{};
	my $pfn    = $args{ on_progress } || sub{};
	my %books; # Using pre-populated $rh would confuse progess counters
	
	gverifyshelf( $_ ) foreach (@$ra_shv);
	
	for my $s (@$ra_shv)
	{
		my $pag = 1;
		while( _extract_books( \%books, $bfn, $pfn, _html( _shelf_url( $uid, $s, $pag++ ) ) ) ) {}
	}
	
	%$rh = ( %$rh, %books ) if $rh;  # Merge
}




=head2 C<void> greadauthors(I<{ from_user_id, ra_from_shelves, rh_into, on_progress =E<gt> sub{} }>)

=over

=item * gets a list of authors whose books are present in the given shelves of the given user

=item * I<ra_from_shelves>: string-array with shelf names

=item * I<on_progress>: see gmeter()

=item * If you need authors I<and> books data, then use C<greadshelf>
        which also populates the I<author> property of every book

=item * skips authors where C<gisbaduser()> is true

=back

=cut

sub greadauthors
{
	my (%args) = @_;
	my $rh     = $args{ rh_into     } ||   \{};
	my $pfn    = $args{ on_progress } || sub{};
	my %auts;  # Using pre-populated $rh would confuse progress counters
	
	my $pickauthorsfn = sub
	{
		my $aid = $_[0]->{rh_author}->{id};
		return if gisbaduser( $aid );
		$pfn->( 1 ) if !exists $auts{$aid};  # Don't count duplicates (multiple shelves)
		$auts{$aid} = $_[0]->{rh_author};
	};
	
	greadshelf( from_user_id    => $args{ from_user_id    },
	            ra_from_shelves => $args{ ra_from_shelves },
	            on_book         => $pickauthorsfn );
	
	%$rh = ( %$rh, %auts ) if $rh;  # Merge
}




=head2 C<void> greadauthorbk(I<{ rh_into, author_id, on_book =E<gt> sub{}, 
			on_progress =E<gt> sub{} }>)

=over

=item * reads the Goodreads.com list of books written by the given author

=item * I<rh_into>: C<(id =E<gt> L<%book|"%book">,...)>

=item * I<on_book>: receives \L<%book|"%book"> argument

=item * I<on_progress>: see C<gmeter()>

=back

=cut

sub greadauthorbk
{
	my (%args) = @_;	
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $aid    = gverifyuser( $args{ author_id });
	my $bfn    = $args{ on_book     } || sub{};
	my $pfn    = $args{ on_progress } || sub{};
	my $pag    = 1;
	
	while( _extract_author_books( $rh, $bfn, $pfn, _html( _author_books_url( $aid, $pag++ ) ) ) ) {};
}




=head2 C<void> greadreviews(I<{ ... }>)

=over

=item * loads ratings (no text), reviews (text), "to-read", "added" etc;
        you can filter later or via I<on_filter> parameter

=item * I<for_book>: C<L<%book|"%book">>

=item * I<rh_into>: reference to C<(id =E<gt> L<%review|"%review">,...)>

=item * I<since>: of type C<Time::Piece> [optional]

=item * I<on_filter>: return false to drop review (1st argument)

=item * I<on_progress>: see C<gmeter()> [optional]

=item * I<rigor>: [optional, default 2]
  level 0   = search newest reviews only (max 300 ratings)
  level 1   = search with a combination of filters (max 5400 ratings)
  level 2   = like 1 plus dict-search if more than 3000 ratings with stall-time of 2 minutes
  level n   = like 1 plus dict-search with stall-time of n minutes
  level n>9 = use a larger dictionary (slowest level)

=back

=cut

sub greadreviews
{
	my (%args) = @_;
	my $book   =_require_arg( 'for_book', $args{ for_book });
	my $rigor  = defined $args{ rigor } ? $args{ rigor } : 2;
	my $rh     = $args{ rh_into     } || undef;
	my $ffn    = $args{ on_filter   } || sub{ return 1 };
	my $pfn    = $args{ on_progress } || sub{};
	my $since  = $args{ since       } || $_EARLIEST;
	   $since  = Time::Piece->strptime( $since->ymd, '%Y-%m-%d' );  # Nullified time in GR too
	my $limit  = defined $book->{num_ratings} ? $book->{num_ratings} : 5000000;
	my $bid    = $book->{id};
	my %revs;  # unique and empty, otherwise we cannot easily compute limits
	
	# Goodreads reviews filters get us dissimilar(!) subsets which are merged
	# here: Don't assume that these filters just load a _subset_ of what you
	# see if _no filters_ are applied. Given enough ratings and reviews, each
	# filter finds reviews not included in any other revs.  Theoretical
	# limit here is 5400 reviews: 6*3 filter combinations * max. 300 displayed 
	# reviews (Goodreads limit).
	# 
	my @rateargs = $rigor == 0 ? ( undef     ) : ( undef, 1..5                 );
	my @sortargs = $rigor == 0 ? ( $_SORTNEW ) : ( undef, $_SORTNEW, $_SORTOLD );
	for my $r (@rateargs)
	{
		for my $s (@sortargs)
		{
			my $pag = 1;
			while( _extract_revs( \%revs, $pfn, $ffn, $since, _html( _revs_url( $bid, $s, $r, undef, $pag++ ) ) ) ) {};
			
			# "to-read", "added" have to be loaded before the rated/reviews
			# (undef in both argument-lists first) - otherwise we finish
			# too early since $limit equals the number of *ratings* only.
			# Ugly code but correct in theory:
			# 
			my $numrated = scalar( grep{ defined $_->{rating} } values %revs ); 
			goto DONE if $numrated >= $limit;
		}
	}
	

	# Dict-search works well with many ratings but sometimes poorly with few (waste of time).
	# Woolf's "To the Lighthouse" has 5514 text reviews: 948 found without dict-search, 3057 with
	goto DONE if $rigor <  2;
	goto DONE if $rigor == 2 && $limit < 3000;
	
 	my $stalltime = $rigor * 60;  
	my $t0        = time;  # Stuff above might already take 60s
	my $ra_dict   = $rigor < 10 ? \@_REVSRCHDICT_OPTIMIZED : \@_REVSRCHDICT;
	
	for my $word (@$ra_dict)
	{
		goto DONE if time-$t0 > $stalltime || scalar keys %revs >= $limit;
		
		my $numbefore = scalar keys %revs;
		
		_extract_revs( \%revs, $pfn, $ffn, $since, _html( _revs_url( $bid, undef, undef, $word ) ) );
		
		$t0 = time if scalar keys %revs > $numbefore;  # Resets stall-timer
	}
	
DONE:
	
	%$rh = ( %$rh, %revs ) if $rh;  # Merge
}




=head2 C<void> greadfolls(I<{ rh_into, from_user_id, on_progress =E<gt> sub{}, 
			incl_authors =E<gt> 1 }>)

=over

=item * queries Goodreads.com for the friends and followees list of the given user

=item * I<rh_into>: C<(id =E<gt> L<%user|"%user">,...)> 

=item * I<on_progress>: see C<gmeter()>

=item * Precondition: gsetcookie()

=item * returns friends AND followees

=back

=cut

sub greadfolls
{
	my (%args) = @_;
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $uid    = gverifyuser( $args{ from_user_id });
	my $iau    = defined $args{ incl_authors } ? $args{ incl_authors } : 1;
	my $pfn    = $args{ on_progress  } || sub{};
	my $pag;
	
	$pag = 1; while( _extract_followees( $rh, $pfn, $iau, _html( _followees_url( $uid, $pag++ ) ) ) ) {};
	$pag = 1; while( _extract_friends  ( $rh, $pfn, $iau, _html( _friends_url  ( $uid, $pag++ ) ) ) ) {};
}




=head2 C<void> greadsimilaraut(I<{ rh_into, author_id, on_progress =E<gt> sub{} }>)

=over

=item * reads the Goodreads.com list of authors who are similar to the given author

=item * I<rh_into>: C<(id =E<gt> L<%user|"%user">,...)>

=item * I<on_progress>: see C<gmeter()>

=item * increments I<'_seen'> counter of each author if already in I<%$rh_into>

=back

=cut

sub greadsimilaraut
{
	my (%args) = @_;
	my $rh     =_require_arg( 'rh_into', $args{ rh_into });
	my $aid    = gverifyuser( $args{ author_id });
	my $pfn    = $args{ on_progress } || sub{};
	
	# Just 1 page:
	_extract_similar_authors( $rh, $aid, $pfn, _html( _similar_authors_url( $aid ) ) );
}




=head2 C<void> gsearch(I<{ ra_into, phrase, is_exact =E<gt> 0, 
			on_progress =E<gt> sub{}, num_ratings =E<gt> 0,
			ra_order_by =E<gt> [ 'stars', 'num_ratings', 'year' ]
			}>)

=over

=item * searches the Goodreads.com database for books that match a given phrase

=item * I<ra_into>: C<(L<%book|"%book">,...)> 

=item * I<order_by>: array with property names from C<(L<%book|"%book">,...)> 

=item * I<on_progress>: see C<gmeter()>

=item * supports percent progress functions: $pfn-E<gt>( $books_loaded, $books_total )

=back

=cut

sub gsearch
{
	my (%args) = @_;
	my $ra     =    _require_arg( 'ra_into', $args{ ra_into });
	my $q      = lc _require_arg( 'phrase',  $args{ phrase  });
	my $pfn    = $args{ on_progress }  || sub{};
	my $n      = $args{ num_ratings }  || 0;
	my $e      = $args{ is_exact    }  || 0;
	my $ra_ord = $args{ ra_order_by }  || [ 'stars', 'num_ratings', 'year' ];
	my $pag    = 1;
	my @tmp;
	
	while( _extract_search_books( \@tmp, $pfn, _html( _search_url( $q, $pag++ ) ) ) ) {};
	
	# Select and sort:
	@tmp = grep{ $_->{num_ratings}           >= $n } @tmp;
	@tmp = grep{ index( lc $_->{title}, $q ) != -1 } @tmp if $e;
	@$ra = sort  # TODO check index vs number of elements
	{
		$b->{ $ra_ord->[0] } <=> $a->{ $ra_ord->[0] } ||
		$b->{ $ra_ord->[1] } <=> $a->{ $ra_ord->[1] } ||
		$b->{ $ra_ord->[2] } <=> $a->{ $ra_ord->[2] }
	} @tmp;
}




=head2 C<string> amz_book_html( I<L<%book|"%book">> )

=over

=item * HTML body of an Amazon article page

=back

=cut

sub amz_book_html
{
	return _html( _amz_url( shift ) );
}





###############################################################################

=head1 PRIVATE URL-GENERATION ROUTINES



=head2 C<string> _amz_url( I<L<%book|"%book">> )

=over

=item * Requires at least {isbn=E<gt>string}

=back

=cut

sub _amz_url
{
	my $book = shift;
	return $book->{isbn} ? "http://www.amazon.de/gp/product/$book->{isbn}" : undef;
}




=head2 C<string> _shelf_url( I<$user_id, $shelf_name, $page_number = 1> )

=over

=item * URL for a page with a list of books (not all books)

=item * "&print=true" allows 200 items per page with a single request, 
        which is a huge speed improvement over loading books from the "normal" 
        view with max 20 books per request.
        Showing 100 books in normal view is oddly realized by 5 AJAX requests
        on the Goodreads.com website.

=item * "&per_page" in print-view can be any number if you work with your 
        own shelf, otherwise max 200 if print view; ignored in non-print view

=item * "&view=table" puts I<all> book data in code, although invisible (display=none)

=item * "&sort=rating" is important for `friendrated.pl` with its book limit:
        Some users read 9000+ books and scraping would take forever. 
        We sort lower-rated books to the end and just scrape the first pages:
        Even those with 9000+ books haven't top-rated more than 2700 books.

=item * "&shelf" supports intersection "shelf1%2Cshelf2" (comma)

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _shelf_url  
{
	my $uid = shift;
	my $slf = shift;	
	my $pag = shift || 1;
	
	$slf =~ s/#/%23/g;  # "#ALL#" shelf
	$slf =~ s/,/%2C/g;  # Shelf intersection
	
	return "https://www.goodreads.com/review/list/${uid}?"
	     . "&print=true"
	     . "&shelf=${slf}"
	     . "&page=${pag}"
	     . "&sort=rating"
	     . "&order=d"
	     . "&view=table"
	     . "&title="
	     . "&per_page=200";
}




=head2 C<string> _followees_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of the people $user is following

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _followees_url
{
	my $uid = shift;
	my $pag = shift || 1;
	return "https://www.goodreads.com/user/${uid}/following?page=${pag}";
}




=head2 C<string> _friends_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of people befriended to C<$user_id>

=item * "&sort=date_added" (as opposed to 'last online') avoids 
        moving targets while reading page by page

=item * "&skip_mutual_friends=false" because we're not doing
        this just for me

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _friends_url
{
	my $uid = shift;
	my $pag = shift || 1;
	return "https://www.goodreads.com/friend/user/${uid}?"
	     . "&page=${pag}"
	     . "&skip_mutual_friends=false"
	     . "&sort=date_added";
}




=head2 C<string> _book_url( I<$book_id> )

=cut

sub _book_url
{
	my $bid = shift;
	return "https://www.goodreads.com/book/show/${bid}";
}




=head2 C<string> _user_url( I<$user_id, $is_author = 0> )

=cut

sub _user_url
{
	my $uid   = shift;
	my $is_au = shift || 0;
	return 'https://www.goodreads.com/'.( $is_au ? 'author' : 'user' )."/show/${uid}";
}




=head2 C<string> _revs_url( I<$book_id, $str_sort_newest_oldest = undef, 
		$search_text = undef, $rating = undef, $page_number = 1> )

=over

=item * "&sort=newest" and "&sort=oldest" reduce the number of reviews for 
        some reason (also observable on the Goodreads website), 
        so only use if really needed (&sort=default)

=item * "&search_text=example", max 30 hits, invalidates sort order argument

=item * "&rating=5"

=item * the maximum of retrievable pages is 10 (300 reviews), see
        https://www.goodreads.com/topic/show/18937232-why-can-t-we-see-past-page-10-of-book-s-reviews?comment=172163745#comment_172163745

=item * seems less throttled, not true for text-search

=back

=cut

sub _revs_url
{
	my $bid  = shift;
	my $sort = shift || undef;
	my $rat  = shift || undef;
	my $txt  = shift || undef;
	my $pag  = shift || 1;
	return "https://www.goodreads.com/book/reviews/${bid}?"
		.( $sort && !$txt ? "sort=${sort}&"       : '' )
		.( $txt           ? "search_text=${txt}&" : '' )
		.( $rat           ? "rating=${rat}&"      : '' )
		.( $txt           ? "" : "page=${pag}"         );
}




=head2 C<string> _rev_url( I<$review_id> )

=cut

sub _rev_url
{
	my $rid = shift;
	return "https://www.goodreads.com/review/show/${rid}";
}




=head2 C<string> _author_books_url( I<$user_id, $page_number = 1> )

=cut

sub _author_books_url
{
	my $uid = shift;
	my $pag = shift || 1;
	return "https://www.goodreads.com/author/list/${uid}?per_page=100&page=${pag}";
}




=head2 C<string> _author_followings_url( I<$author_id, $page_number = 1> )

=cut

sub _author_followings_url
{
	my $uid = shift;
	my $pag = shift || 1;
	return "https://www.goodreads.com/author_followings?id=${uid}&page=${pag}";
}




=head2 C<string> _similar_authors_url( I<$author_id> )

=over

=item * page number > N just returns same page, so no easy stop criteria;
        not sure, if there's more than page, though

=back

=cut

sub _similar_authors_url
{
	my $uid = shift;
	return "https://www.goodreads.com/author/similar/${uid}";
}




=head2 C<string> _search_url( I<phrase_str, $page_number = 1> )

=over

=item * "&q=" URL-encoded, e.g., linux+%40+"häse (linux @ "häse)

=back

=cut

sub _search_url
{
	my $q   = uri_escape( shift );
	my $pag = shift;
	return "https://www.goodreads.com/search?page=${pag}&tab=books&q=${q}";
}




#==============================================================================

=head1 PRIVATE HTML-EXTRACTION ROUTINES



=head2 C<L<%book|"%book">> _extract_book( $book_page_html_str )

=cut

sub _extract_book
{
	my $htm = shift;
	my %bk;
	
	return undef if !$htm;
	
	$bk{ id          } = $htm =~ /id="book_id" value="([^"]+)"/                         ? $1 : undef;
	$bk{ isbn        } = $htm =~ /<meta content='([^']+)' property='books:isbn'/        ? $1 : ''; # ISBN13
	$bk{ img_url     } = $htm =~ /<meta content='([^']+)' property='og:image'/          ? $1 : '';
	$bk{ title       } = $htm =~ /<meta content='([^']+)' property='og:title'/          ? decode_entities( $1 ) : '';
	$bk{ num_pages   } = $htm =~ /<meta content='([^']+)' property='books:page_count'/  ? $1 : $_NOBOOKIMGURL;
	$bk{ num_reviews } = $htm =~ /(\d+)[,.]?(\d+) review/           ? $1.$2 : 0;  # 1,600 -> 1600
	$bk{ num_ratings } = $htm =~ /(\d+)[,.]?(\d+) rating/           ? $1.$2 : 0;  # 1,600 -> 1600
	$bk{ avg_rating  } = $htm =~ /itemprop="ratingValue">([0-9.]+)/ ? $1    : 0;  # # 3.77
	$bk{ stars       } = int( $bk{ avg_rating } + 0.5 );
	$bk{ url         } = _book_url( $bk{id} );
	$bk{ rh_author   } = undef;  # TODO
	$bk{ year        } = undef;  # TODO
	
	return %bk;
}




=head2 C<bool> _extract_books( I<$rh_books, $on_book_fn, $on_progress_fn, $shelf_tableview_html_str> )

=over

=item * I<$rh_books>: C<(id =E<gt> L<%book|"\%book">,...)>

=back

=cut

sub _extract_books
{
	my $rh  = shift;
	my $bfn = shift;
	my $pfn = shift;
	my $htm = shift;
	my $ret = 0;
	
	# TODO verify if shelf is the given one or redirected by GR to #ALL# bc misspelled	
	
	while( $htm =~ /<tr id="review_\d+" class="bookalike review">(.*?)<\/tr>/gs ) # each book row
	{	
		my $row = $1;
		my $tit = $row =~ />title<\/label><div class="value">\s*<a[^>]+>\s*(.*?)\s*<\/a>/s  ? $1 : '';
		   $tit =~ s/\<[^\>]+\>//g;         # remove HTML tags "Title <span>(Volume 2)</span>"
		   $tit =~ s/( {1,}|[\r\n])/ /g;    # reduce spaces
		   $tit = decode_entities( $tit );  # &quot -> "
		my %au;
		my %bk;
		
		$au{ id          } = $row =~ /author\/show\/([0-9]+)/       ? $1                    : undef;
		$au{ name        } = $row =~ /author\/show\/[^>]+>([^<]+)/  ? decode_entities( $1 ) : '';
		$au{ url         } = _user_url( $au{id}, 1 );
		$au{ works_url   } = _author_books_url( $au{id} );
		$au{ is_author   } = 1;
		$au{ is_private  } = 0;
		$au{ _seen       } = 1;
		
		$bk{ id          } = $row =~ /data-resource-id="([0-9]+)"/                                ? $1 : undef;
		$bk{ isbn        } = $row =~ />isbn<\/label><div class="value">\s*([0-9X\-]*)/            ? $1 : '';
		$bk{ num_reviews } = undef;  # Not available here!
		$bk{ num_ratings } = $row =~ />num ratings<\/label><div class="value">\s*([0-9]+)/        ? $1 : 0;
		$bk{ img_url     } = $row =~ /<img [^>]* src="([^"]+)"/                                   ? $1 : $_NOBOOKIMGURL;
		$bk{ year        } = $row =~ />date pub<\/label><div class="value">\s*[^<]*(\d{4})\s*</s  ? $1 : 0;  # "2017" and "Feb 01, 2017" (there's also "edition date pub")
		$bk{ title       } = $tit;
		$bk{ user_rating } = () = $row =~ /staticStar p10/g;        # Counts occurances
		$bk{ url         } = _book_url( $bk{id} );
		$bk{ avg_rating  } = 0; # TODO
		$bk{ stars       } = int( $bk{ avg_rating } + 0.5 );
		$bk{ rh_author   } = \%au;
		
		$ret++ unless exists $rh->{$bk{id}};  # Don't count duplicates (multiple shelves)
		$rh->{$bk{id}} = \%bk if $rh;
		$bfn->( \%bk );
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_author_books( I<$rh_books, $on_book_fn, $on_progress_fn, $html_str> )

=over

=item * I<$rh_books>: C<(id =E<gt> L<%book|"\%book">,...)>

=back

=cut

sub _extract_author_books
{
	# Book without title on https://www.goodreads.com/author/list/1094257
	
	my $rh    = shift;
	my $bfn   = shift;
	my $pfn   = shift;
	my $htm   = shift or return 0;
	my $auimg = $htm =~ /(https:\/\/images.gr-assets.com\/authors\/.*?\.jpg)/gs  ? $1 : $_NOUSERIMGURL;
	my $aid   = $htm =~ /author\/show\/([0-9]+)/                                 ? $1 : undef;
	my $aunm  = $htm =~ /<h1>Books by ([^<]+)/                                   ? decode_entities( $1 ) : '';
	my $ret   = 0;
	
	while( $htm =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row = $1;
		my %au;
		my %bk;
		
		$au{ id          } = $aid;
		$au{ name        } = $aunm;
  		$au{ img_url     } = $auimg;
		$au{ url         } = _user_url( $aid, 1 );
		$au{ works_url   } = _author_books_url( $aid );
		$au{ is_author   } = 1;
		$au{ is_private  } = 0;
		$au{ _seen       } = 1;
		
		$bk{ id          } = $row =~ /book\/show\/([0-9]+)/           ? $1    : undef;
		$bk{ num_ratings } = $row =~ /(\d+)[,.]?(\d+) rating/         ? $1.$2 : 0;  # 1,600 -> 1600
		$bk{ img_url     } = $row =~ /src="[^"]+/                     ? $1    : $_NOBOOKIMGURL;
		$bk{ title       } = $row =~ /<span itemprop='name'>([^<]+)/  ? decode_entities( $1 ) : '';
		$bk{ url         } = _book_url( $bk{id} );
		$bk{ rh_author   } = \%au;
		
		$ret++; # Count duplicates too: 10 books of author A, 9 of B; called for single author
		$rh->{$bk{id}} = \%bk;
		$bfn->( \%bk );
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_followees( I<$rh_users, $on_progress_fn, $incl_authors, $following_page_html_str> )

=over

=item * I<$rh_users>: C<(user_id =E<gt> L<%user|"\%user">,...)>

=back

=cut

sub _extract_followees
{
	my $rh  = shift;
	my $pfn = shift;
	my $iau = shift;
	my $htm = shift;
	my $ret = 0;
	
	while( $htm =~ /<div class='followingItem elementList'>(.*?)<\/a>/gs )
	{
		my $row = $1;
		my $uid = $row =~   /\/user\/show\/([0-9]+)/   ? $1 : undef;
		my $aid = $row =~ /\/author\/show\/([0-9]+)/   ? $1 : undef;	
		my %us;
		
		$us{ id        } = $uid ? $uid : $aid;
		$us{ name      } = $row =~ /img alt="([^"]+)/  ? decode_entities( $1 )     : '';
		$us{ img_url   } = $row =~ /src="([^"]+)/      ? $1                        : $_NOUSERIMGURL;
		$us{ works_url } = $aid                        ? _author_books_url( $aid ) : '';
		$us{ url       } = _user_url( $us{id}, $aid );
		$us{ is_author } = defined $aid;
		$us{ is_friend } = 0;
		$us{ _seen     } = 1;
			
		next if !$iau && $us{is_author};
		$ret++;
		$rh->{$us{id}} = \%us;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_friends( I<$rh_users, $on_progress_fn, $incl_authors, $friends_page_html_str> )

=over

=item * I<$rh_users>: C<(user_id =E<gt> L<%user|"\%user">,...)> 

=back

=cut

sub _extract_friends
{
	my $rh  = shift;
	my $pfn = shift;
	my $iau = shift;
	my $htm = shift;
	my $ret = 0;
	
	while( $htm =~ /<tr>\s*<td width="1%">(.*?)<\/td>/gs )
	{
		my $row = $1;
		my $uid = $row =~   /\/user\/show\/([0-9]+)/   ? $1 : undef;
		my $aid = $row =~ /\/author\/show\/([0-9]+)/   ? $1 : undef;
		my %us;
		
		$us{ id        } = $uid ? $uid : $aid;
		$us{ name      } = $row =~ /img alt="([^"]+)/  ? decode_entities( $1 )     : '';
		$us{ img_url   } = $row =~     /src="([^"]+)/  ? $1                        : $_NOUSERIMGURL;
		$us{ works_url } = $aid                        ? _author_books_url( $aid ) : '';
		$us{ url       } = _user_url( $us{id}, $aid );
		$us{ is_author } = defined $aid;
		$us{ is_friend } = 1;
		$us{ _seen     } = 1;
		
		next if !$iau && $us{ is_author };
		$ret++;
		$rh->{$us{id}} = \%us;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_revs( I<$rh_revs, $on_progress_fn, $since_time_piece, $reviews_xhr_html_str> )

=over

=item * I<$rh_revs>: C<(review_id =E<gt> L<%review|"\%review">,...)>

=back

=cut

sub _extract_revs
{
	my $rh           = shift;
	my $pfn          = shift;
	my $ffn          = shift;
	my $since_tpiece = shift;
	my $htm          = shift or return 0;  # < is \u003c, > is \u003e,  " is \" literally
	my $bid          = $htm =~ /%2Fbook%2Fshow%2F([0-9]+)/  ? $1 : undef;
	my $ret          = 0;
	
	while( $htm =~ /div id=\\"review_\d+(.*?)div class=\\"clear/gs )
	{		
		my $row = $1;
		
		# Avoid username "0" eval to false somewhere -> "0" instead of 0
		#
		# [x] Parse-error "Jan 01, 1010" https://www.goodreads.com/review/show/1369192313
		# [x] img alt=\"David T\"   
		# [x] img alt=\"0\"
		# [ ] img alt="\u0026quot;Greg Adkins\u0026quot;\"  TODO
		
		my $dat        = $row =~ /([A-Z][a-z]+ \d+, (19[7-9][0-9]|2\d{3}))/  ? $1 : undef;
		my $dat_tpiece = $dat ? Time::Piece->strptime( $dat, '%b %d, %Y' ) : $_EARLIEST; 
		
		next if $dat_tpiece < $since_tpiece;
		
		my %us;
		my %rv;
		
		# There's a short and a long text variant both saved in $row
		my $txts = $row =~ /id=\\"freeTextContainer[^"]+"\\u003e(.*?)\\u003c\/span/  ? decode_entities( $1 ) : '';
		my $txt  = $row =~ /id=\\"freeText[0-9]+\\" style=\\"display:none\\"\\u003e(.*?)\\u003c\/span/  ? decode_entities( $1 ) : '';
		   $txt  = $txts if length( $txts ) > length( $txt );
		
   		$txt =~ s/\\"/"/g;
		$txt =~ s/\\u(....)/ pack 'U*', hex($1) /eg;  # Convert Unicode codepoints such as \u003c
		$txt =~ s/<br \/>/\n/g;
		
		$us{ id         } = $row =~ /\/user\/show\/([0-9]+)/ ? $1 : undef;
		$us{ name       } = $row =~ /img alt=\\"(.*?)\\"/    ? ($1 eq '0' ? '"0"' : decode_entities( $1 )) : '';
  		$us{ img_url    } = $_NOUSERIMGURL;  # TODO
		$us{ url        } = _user_url( $us{id} );
		$us{ _seen      } = 1;
		
		$rv{ id         } = $row =~ /\/review\/show\/([0-9]+)/ ? $1 : undef;
		$rv{ text       } = $txt;
		$rv{ rating     } = () = $row =~ /staticStar p10/g;  # Count occurances
		$rv{ rating_str } = $rv{rating} ? ('[' . ($rv{text} ? 'T' : '*') x $rv{rating} . ' ' x (5-$rv{rating}) . ']') : '[added]';
		$rv{ url        } = _rev_url( $rv{id} );
		$rv{ date       } = $dat_tpiece;
		$rv{ book_id    } = $bid;
		$rv{ rh_user    } = \%us;
		
		if( $ffn->( \%rv ) )  # Filter
		{
			$ret++ unless exists $rh->{$rv{id}};  # Don't count duplicates (multiple searches for same book)
			$rh->{$rv{id}} = \%rv;
		}
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_similar_authors( I<$rh_into, $author_id_to_skip, 
			$on_progress_fn, $similar_page_html_str> )

=cut

sub _extract_similar_authors
{
	my $rh          = shift;
	my $uid_to_skip = shift;
	my $pfn         = shift;
	my $htm         = shift;
	my $ret         = 0;
	
	while( $htm =~ /<li class='listElement'>(.*?)<\/li>/gs )
	{	
		my $row = $1;
		my %au;
		$au{id} = $row =~ /author\/show\/([0-9]+)/  ? $1 : undef;
		
		next if $au{id} eq $uid_to_skip;
		
		$ret++;  # Incl. duplicates: 10 similar to author A, 9 to B; A and B can incl same similar authors
				
		if( exists $rh->{$au{id}} )
		{
			$rh->{$au{id}}->{_seen}++;  # similarauth.pl
			next;
		}

		$au{ name       } = $row =~ /class="bookTitle" href="\/author\/show\/[^>]+>([^<]+)/  ? decode_entities( $1 ) : '';
		$au{ img_url    } = $row =~ /(https:\/\/images\.gr-assets\.com\/authors\/[^"]+)/     ? $1 : $_NOUSERIMGURL;
		$au{ url        } = _user_url( $au{id}, 1 );
		$au{ works_url  } = _author_books_url( $au{id} );
		$au{ is_author  } = 1;
		$au{ is_private } = 0;
		$au{ _seen      } = 1;
		
		$rh->{$au{id}} = \%au;
	}
	
	$pfn->( $ret );
	return $ret;
}




=head2 C<bool> _extract_search_books( I<$ra_books, $on_progress_fn, $search_result_html_str>  )

=over

=item * result pages sometimes have different number of items: 
        P1: 20, P2: 16, P3: 19

=item * website says "about 75 results" but shows 70 (I checked that manually).
        So we fake "100%" to the progress indicator function at the end,
        otherwise it stops with "93%".

=item * I<ra_books>: C<(L<%book|"\%book">,...)> 

=back

=cut

sub _extract_search_books
{
	my $ra  = shift;
	my $pfn = shift;
	my $htm = shift;
	my $ret = 0;
	my $max = $htm =~ /Page \d+ of about (\d+) results/  ? $1 : 0;
	
	# We check against the stated number of results, alternative exit 
	# conditions: Page 100 (Page 100+x == Page 100), or "NO RESULTS."
	if( scalar @$ra >= $max )
	{
		$pfn->( 1, 1 );
		return 0;
	}
	
	while( $htm =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row = $1;
		my %au;
		my %bk;
		
		$au{ id          } = $row =~ /\/author\/show\/([0-9]+)/  ? $1 : undef;
		$au{ name        } = $row =~ /<a class="authorName" [^>]+><span itemprop="name">([^>]+)/  ? decode_entities( $1 ) : '';
		$au{ url         } = _user_url        ( $au{id}, 1 );
		$au{ works_url   } = _author_books_url( $au{id}    );
		$au{ img_url     } = $_NOUSERIMGURL;
		$au{ is_author   } = 1;
		$au{ is_private  } = 0;
		$au{ _seen       } = 1;
		
		$bk{ id          } = $row =~ /book\/show\/([0-9]+)/           ? $1    : undef;
		$bk{ num_ratings } = $row =~ /(\d+)[,.]?(\d+) rating/         ? $1.$2 : 0;  # 1,600 -> 1600
		$bk{ avg_rating  } = $row =~ /([0-9.,]+) avg rating/          ? $1    : 0;  # 3.8
		$bk{ stars       } = int( $bk{ avg_rating } + 0.5 );
		$bk{ year        } = $row =~ /published\s+(\d+)/              ? $1    : 0;  # 2018
		$bk{ img_url     } = $row =~ /src="([^"]+)/                   ? $1    : $_NOBOOKIMGURL;
		$bk{ title       } = $row =~ /<span itemprop='name'>([^<]+)/  ? decode_entities( $1 ) : '';
		$bk{ url         } = _book_url( $bk{id} );
		$bk{ rh_author   } = \%au;
		
		push( @$ra, \%bk );
		$ret++;  # There are no duplicates, no extra checks
	}
	
	$pfn->( $ret, $max );
	return $ret;
}




###############################################################################

=head1 PRIVATE I/O PLUMBING SUBROUTINES




=head2 C<int> _check_page( I<$url, $any_html_str> )

=over

=item * returns $_STATOKAY, $_STATWARN (ignore), $_STATERROR (retry)

=item * warns if sign-in page (https://www.goodreads.com/user/sign_in) or in-page message

=item * warns if "page unavailable, Goodreads request took too long"

=item * warns if "page not found" 

=item * error if page unavailable: "An unexpected error occurred. 
        We will investigate this problem as soon as possible â€” please 
        check back soon!"

=item * error if over capacity (TODO UNTESTED):
        "<?>Goodreads is over capacity.</?> 
        <?>You can never have too many books, but Goodreads can sometimes
        have too many visitors. Don't worry! We are working to increase 
        our capacity.</?>
        <?>Please reload the page to try again.</?>
        <a ...>get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DejvR6dUwAActHc.jpg
        https://pbs.twimg.com/media/CwMBEJAUIAA2bln.jpg
        https://pbs.twimg.com/media/CFOw6YGWgAA1H9G.png  (with title)

=item * error if maintenance mode (TODO UNTESTED):
        "<?>Goodreads is down for maintenance.</?>
        <?>We expect to be back within minutes. Please try again soon!<?>
        <a ...>Get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DgKMR6qXUAAIBMm.jpg
        https://i.redditmedia.com/-Fv-2QQx2DeXRzFBRKmTof7pwP0ZddmEzpRnQU1p9YI.png

=item * error if website temporarily unavailable (TODO UNTESTED):
        "Our website is currently unavailable while we make some improvements
        to our service. We'll be open for business again soon,
        please come back shortly to try again. <?>
        Thank you for your patience." (No Alice error)
        https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/hostedimages/1404319071i/10224522.png

=back

=cut

sub _check_page
{
	my $url = shift;
	my $htm = shift;
	
	# Try to be precise, don't stop just because someone wrote a pattern 
	# in his review or a book title. Characters such as < and > are 
	# encoded in user texts:
	
	warn( "\n[WARN] Sign-in for $url => Cookie invalid or not set: gsetcookiefile()\n" )
		and return $_STATWARN
			if $htm =~ /<head>\s*<title>\s*Sign in\s*<\/title>/s;
	
	warn( "\n[WARN] Not found: $url\n" )
		and return $_STATWARN
			if $htm =~ /<head>\s*<title>\s*Page not found\s*<\/title>/s;
	
	warn( "\n[ERROR] Goodreads.com \"temporarily unavailable\".\n" )
		and return $_STATERROR
			if $htm =~ /Our website is currently unavailable while we make some improvements/s; # TODO improve
			
	warn( "\n[ERROR] Goodreads.com encountered an \"unexpected error\".\n" )
		and return $_STATERROR
			if $htm =~ /<head>\s*<title>\s*Goodreads - unexpected error\s*<\/title>/s;
	
	warn( "\n[ERROR] Goodreads.com is over capacity.\n" )
		and return $_STATERROR
			if $htm =~ /<head>\s*<title>\s*Goodreads is over capacity\s*<\/title>/s;
	
	warn( "\n[ERROR] Goodreads.com is down for maintenance.\n" )
		and return $_STATERROR
			if $htm =~ /<head>\s*<title>\s*Goodreads is down for maintenance\s*<\/title>/s;
	
	
	return $_STATOKAY;
}




=head2 C<string> _html( I<$url> )

=over

=item * HTML body of a web document

=item * might stop process on severe problems

=back

=cut

sub _html
{
	my $url = shift or return '';
	my $htm;
	
	$htm = $_cache->get( $url ) 
		if $_cache_age ne $EXPIRES_NOW;
	
	return $htm 
		if defined $htm;
	
DOWNLOAD:
	state $curl;
	my    $curl_ret;
	my    $state;
	
	$curl = WWW::Curl::Easy->new if !$curl;

	$curl->setopt( $curl->CURLOPT_URL,            $url        );
	$curl->setopt( $curl->CURLOPT_REFERER,        $url        );  # https://www.goodreads.com/...  [F5]
	$curl->setopt( $curl->CURLOPT_USERAGENT,      $_USERAGENT );
	$curl->setopt( $curl->CURLOPT_COOKIE,         $_cookie    ) if $_cookie;
	$curl->setopt( $curl->CURLOPT_HTTPGET,        1           );
	$curl->setopt( $curl->CURLOPT_FOLLOWLOCATION, 1           );
	$curl->setopt( $curl->CURLOPT_HEADER,         0           );
	$curl->setopt( $curl->CURLOPT_WRITEDATA,      \$htm       );
	
	# Performance options:
	# - don't hang too long, better disconnect and retry
	# - reduce number of SSL handshakes (reuse connection)
	# - reduce SSL overhead
	$curl->setopt( $curl->CURLOPT_TIMEOUT,        60  );
	$curl->setopt( $curl->CURLOPT_CONNECTTIMEOUT, 60  );
	$curl->setopt( $curl->CURLOPT_FORBID_REUSE,   0   );  # CURL default
	$curl->setopt( $curl->CURLOPT_FRESH_CONNECT,  0   );  # CURL default
	$curl->setopt( $curl->CURLOPT_TCP_KEEPALIVE,  1   );
	$curl->setopt( $curl->CURLOPT_TCP_KEEPIDLE,   120 );
	$curl->setopt( $curl->CURLOPT_TCP_KEEPINTVL,  60  );
	$curl->setopt( $curl->CURLOPT_SSL_VERIFYPEER, 0   );
	
	$curl_ret = $curl->perform;
	
	warn( sprintf( "\n[ERROR] %s %s\n", $curl->strerror( $curl_ret ), $curl->errbuf ) )
		unless $curl_ret == $_STATOKAY;
	
	$state = $curl_ret == $_STATOKAY ? _check_page( $url, $htm ) : $_STATERROR;
	
	$_cache->set( $url, $htm, $_cache_age ) 
		if $state == $_STATOKAY;
	
	if( $state == $_STATERROR )
	{
		say "[INFO ] Retrying in 3 minutes... Press CTRL-C to exit";
		$curl = undef;  # disconnect
		sleep 3*60;
		goto DOWNLOAD;
	}
	
	return $htm;
}





1;
__END__


